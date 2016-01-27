resource_name :domain_join
property :domain, String, required: true
property :domain_user, String, required: true
property :domain_password, String, required: true
property :ou, String, required: false

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
  if Chef::Config[:node_name] != node['hostname'] and Chef::Config[:node_name] != node['fqdn'] and node['ad-join']['windows']['update_hostname'] == true
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
        {:name => 'legalnoticecaption', :type => :string, :data => warning_caption},
        {:name => 'legalnoticetext', :type => :string, :data => warning_text}
      ]
      only_if { node['ad-join']['windows']['visual_warning'] == true }
      action :nothing
    end
    
    # Installs task for chef-client run after reboot, needed for ohai reload
    windows_task 'chef ad-join' do
      user 'SYSTEM'
      command 'chef-client -L C:\chef\chef-ad-join.log'
      run_level :highest
      frequency :onstart
      notifies :create, 'registry_key[warning]', :immediately
      only_if { node['kernel']['cs_info']['domain_role'].to_i == 0 || node['kernel']['cs_info']['domain_role'].to_i == 2 }
      action :create
    end
    
    powershell_script 'ad-join' do
      code <<-EOH
      $adminname = "#{domain}\\#{domain_user}"
      $password = "#{domain_password}" | ConvertTo-SecureString -asPlainText -Force
      $credential = New-Object System.Management.Automation.PSCredential($adminname,$password)
      
      if ( '#{newcomputername}' -eq $(hostname) ) {
        Write-Host "Skipping computer rename since already named: #{newcomputername}"
      }
      else {
        Write-Host "Renaming computer from $($hostname) to #{newcomputername}"
        Rename-Computer -NewName '#{newcomputername}'
      }
      sleep 5
      Add-computer -DomainName #{domain} -OUPath "#{ou}" -Credential $credential -force -Options JoinWithNewName,AccountCreate -PassThru #-Restart

      # Old way, somtimes Domain controller busy error occured
      # Add-Computer  #{newcomputername} -DomainName #{domain} -OUPath #{ou} -Credential $credential -Restart -PassThru
      # Add-Computer -ComputerName Server01 -LocalCredential Server01\Admin01 -DomainName Domain02 -Credential Domain02\Admin02 -Restart -Force
      EOH
      only_if { node['kernel']['cs_info']['domain_role'].to_i == 0 || node['kernel']['cs_info']['domain_role'].to_i == 2 }
      notifies :reboot_now, 'reboot[Restart Computer]', :immediately
    end
    
    # Reboot the computer a second time
    # Needed on windows systems to apply some group policy objects (like timezone)
    file 'c:\\Windows\\chef-ad-join.txt' do
      content "Placed by ad-join cookbook. Cookbook will keep rebooting windows until server is part of a domain and this file exists. DONT DELETE"
      action :create_if_missing
      only_if { node['ad-join']['windows']['double_reboot'] == true }
      notifies :reboot_now, 'reboot[Restart Computer]', :immediately
    end

    windows_task 'chef ad-join' do
      action :delete
      notifies :delete, 'registry_key[warning]', :delayed
    end   

  when 'linux'
    #TODO implement linux support
    Chef::Log.fatal("Only windows currently supported, linux support planned for future release")
  else
    Chef::Log.fatal("Platform: #{node['platform']} not supported")
  end
  
end

#TODO implement domain leave actions
# action :leave do
#   
# end
