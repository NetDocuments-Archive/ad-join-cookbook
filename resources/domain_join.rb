resource_name :domain_join
property :domain, String, required: true
property :domain_user, String, required: true
property :domain_password, String, required: true
property :ou, [String, NilClass], required: false, default: nil
property :server, [String, NilClass], required: false, default: nil

default_action :join

# ohai domain attributes
# node['kernel']['cs_info']['domain_role']

# StandaloneWorkstation = 0
# MemberWorkstation = 1
# StandaloneServer = 2
# MemberServer = 3
# BackupDomainController = 4
# PrimaryDomainController = 5

action :join do
  # Set the computer name to the same name provided by -N parameter in  knife boostrap -N 'node01'
  if Chef::Config[:node_name] != node['hostname'] && Chef::Config[:node_name] != node['fqdn'] && node['ad-join']['windows']['update_hostname'] == true
    # Abort if hostname is more than 15 characters long on windows
    raise if node['os'] == 'windows' && Chef::Config[:node_name].length > 15

    newcomputername = Chef::Config[:node_name]
    # renew info about nodename on chef server after reload
    ohai 'reload' do
      action :reload
    end
  else
    newcomputername = node['hostname']
  end

  reboot 'Restart Computer' do
    action :nothing
  end

  case node['os']
  when 'windows'
    warning_caption = 'Chef is joining the domain'
    warning_text = 'The chef cookbook ad-join is currently in the middle of joining the domain, and the server is about to be restarted'
    warning_key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'

    # Display a warning incase anyone remotes into the machine before all reboots have finished
    # http://www.techrepublic.com/blog/windows-and-office/adding-messages-to-windows-7s-logon-screen/
    registry_key 'warning' do
      key warning_key
      values [
        { name: 'legalnoticecaption', type: :string, data: warning_caption },
        { name: 'legalnoticetext', type: :string, data: warning_text }
      ]
      only_if { node['ad-join']['windows']['visual_warning'] == true }
      action :nothing
    end

    # Installs task for chef-client run after reboot, needed for ohai reload
    windows_task 'chef ad-join' do
      task_name 'chef ad-join' # http://bit.ly/1WDZ1kn
      user 'SYSTEM'
      command 'chef-client -L C:\chef\chef-ad-join.log'
      run_level :highest
      frequency :onstart
      only_if { node['kernel']['cs_info']['domain_role'].to_i == 0 || node['kernel']['cs_info']['domain_role'].to_i == 2 }
      notifies :create, 'registry_key[warning]', :immediately # http://bit.ly/1WDZ1kn
      action :create
    end

    # Modify the start time to make sure GP doesn't set task into future
    # https://github.com/NetDocuments/ad-join-cookbook/issues/13
    # schedtask.exe won't allow this to be combined with task creation
    windows_task 'modify sched task start time' do
      task_name 'chef ad-join' # http://bit.ly/1WDZ1kn
      start_day '06/09/2016'
      start_time '01:00'
      only_if { node['kernel']['cs_info']['domain_role'].to_i == 0 || node['kernel']['cs_info']['domain_role'].to_i == 2 }
      action :change
    end

    powershell_script 'ad-join' do
      code <<-EOH
      $adminname = "#{new_resource.domain}\\#{domain_user}"
      $password = '#{domain_password}' | ConvertTo-SecureString -asPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential($adminname,$password)

      if ( '#{newcomputername}' -eq $(hostname) ) {
        Write-Host "Skipping computer rename since already named: #{newcomputername}"
      }
      else {
        Write-Host "Renaming computer from $($hostname) to #{newcomputername}"
        Rename-Computer -NewName '#{newcomputername}'
      }
      sleep 5
      Add-computer -DomainName #{new_resource.domain} #{ou.nil? ? '' : '-OUPath "' + ou + '"'} #{server.nil? ? '' : '-Server "' + server + '"'} -Credential $credential -force -Options JoinWithNewName,AccountCreate -PassThru #-Restart

      # Old way, somtimes Domain controller busy error occured
      # Add-Computer  #{newcomputername} -DomainName #{new_resource.domain} -OUPath #{ou} -Credential $credential -Restart -PassThru
      # Add-Computer -ComputerName Server01 -LocalCredential Server01\Admin01 -DomainName Domain02 -Credential Domain02\Admin02 -Restart -Force
      EOH
      only_if { node['kernel']['cs_info']['domain_role'].to_i == 0 || node['kernel']['cs_info']['domain_role'].to_i == 2 }
      notifies :reboot_now, 'reboot[Restart Computer]', :immediately
    end

    # Reboot the computer a second time
    # Needed on windows systems to apply some group policy objects (like timezone)
    file 'c:/Windows/chef-ad-join.txt' do
      content 'Placed by ad-join cookbook. Cookbook will keep rebooting windows until server is part of a domain and this file exists. DONT DELETE'
      action :create_if_missing
      only_if { node['ad-join']['windows']['double_reboot'] == true }
      notifies :reboot_now, 'reboot[Restart Computer]', :immediately
    end

    windows_task 'chef ad-join' do
      notifies :delete, 'registry_key[warning]', :delayed
      action :delete
    end

  when 'linux'

    case node['platform_version']
    when '16.04'
        # Installation based on this document https://help.ubuntu.com/lts/serverguide/sssd-ad.html
        # https://tutel.me/c/unix/questions/256626/sssd+realm+discover+not+authorized+to+perform+this+action
        %w(realmd sssd-tools sssd libnss-sss libpam-sss adcli packagekit).each do |pkg|
          package pkg do
            action :install
          end
        end

        # TODO: add or replace 'default_realm' in /etc/krb5.conf

        # https://answers.launchpad.net/ubuntu/+question/293540
        execute 'realm join' do
          environment 'DOMAIN_PASS' => domain_password
          command <<-EOH
          echo "${DOMAIN_PASS}" | sudo realm join --verbose #{new_resource.domain} --user #{domain_user}@#{new_resource.domain} --computer-ou #{ou} --install=/
          EOH
          not_if <<-EOH
          domain=$(sudo realm list -n| tr '[:upper:]' '[:lower:]');
          # echo domain is ${domain} > /tmp/domain;
          # echo "resource domain is #{new_resource.domain.downcase}" >> /tmp/domain;
          if [ "${domain}" != "#{new_resource.domain.downcase}" ]; then
            # echo "${domain} doesnt match #{new_resource.domain.downcase}" >> /tmp/domain;
            exit 1;
          else
            # echo "${domain} matches #{new_resource.domain.downcase}" >> /tmp/domain;
            exit 0;
          fi
          EOH
          sensitive true if node['ad-join']['linux']['hide_sensitive'] == true
        end

        cookbook_file '/etc/pam.d/CHEF-mkhomedir' do
          owner 'root'
          source "CHEF-mkhomedir.txt"
          cookbook 'ad-join'
          group 'root'
          mode '0644'
          action :create
        end

    else
      Chef::Log.fatal("Only Ubuntu 16.04 currently supported. Found: #{node['platform']}")
    end
  else
    Chef::Log.fatal("Platform: #{node['platform']} not supported")
  end
end

action :leave do

  reboot 'Restart Computer' do
    action :nothing
  end

  case node['os']
  when 'windows'
    warning_caption = 'Chef is leaving the domain'
    warning_text = 'The chef cookbook ad-join is currently in the middle of leaving the domain, and the server is about to be restarted'
    warning_key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'

    # Display a warning incase anyone remotes into the machine before all reboots have finished
    # http://www.techrepublic.com/blog/windows-and-office/adding-messages-to-windows-7s-logon-screen/
    registry_key 'warning' do
      key warning_key
      values [
        { name: 'legalnoticecaption', type: :string, data: warning_caption },
        { name: 'legalnoticetext', type: :string, data: warning_text }
      ]
      only_if { node['ad-join']['windows']['visual_warning'] == true }
      action :nothing
    end

    # Installs task for chef-client run after reboot, needed for ohai reload
    windows_task 'chef ad-join leave' do
      task_name 'chef ad-join leave' # http://bit.ly/1WDZ1kn
      user 'SYSTEM'
      command 'chef-client -L C:\chef\chef-ad-join.log'
      run_level :highest
      frequency :onstart
      only_if { node['kernel']['cs_info']['domain_role'].to_i == 1 || node['kernel']['cs_info']['domain_role'].to_i == 3 }
      notifies :create, 'registry_key[warning]', :immediately # http://bit.ly/1WDZ1kn
      action :create
    end

    # Modify the start time to make sure GP doesn't set task into future
    # https://github.com/NetDocuments/ad-join-cookbook/issues/13
    # schedtask.exe won't allow this to be combined with task creation
    windows_task 'chef ad-join leave start time' do
      task_name 'chef ad-join leave' # http://bit.ly/1WDZ1kn
      start_day '06/09/2016'
      start_time '01:00'
      only_if { node['kernel']['cs_info']['domain_role'].to_i == 1 || node['kernel']['cs_info']['domain_role'].to_i == 3 }
      action :change
    end

    powershell_script 'ad-join-leave' do
      code <<-EOH
      $adminname = "#{domain}\\#{domain_user}"
      $password = '#{domain_password}' | ConvertTo-SecureString -asPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential($adminname,$password)

      Remove-Computer -UnjoinDomainCredential $credential -Force -PassThru
      EOH
      only_if { node['kernel']['cs_info']['domain_role'].to_i == 1 || node['kernel']['cs_info']['domain_role'].to_i == 3 }
      notifies :reboot_now, 'reboot[Restart Computer]', :immediately
    end

    file 'C:/Windows/chef-ad-join.txt' do
      action :delete
    end

    windows_task 'chef ad-join task delete' do
      task_name 'chef ad-join leave' # http://bit.ly/1WDZ1kn
      notifies :delete, 'registry_key[warning]', :delayed
      action :delete
    end

  when 'linux'
    raise "Linux can't yet unjoin from domain"

  else
    Chef::Log.fatal("Platform: #{node['platform']} not supported")
  end
end
