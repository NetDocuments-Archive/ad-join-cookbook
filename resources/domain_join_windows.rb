resource_name :domain_join
property :domain, String, required: true
property :domain_user, String, required: true
property :domain_password, String, required: true
property :ou, [String, NilClass], required: false, default: nil
property :server, [String, NilClass], required: false, default: nil
property :update_hostname, [true, false], required: false, default: true
property :double_reboot, [true, false], required: false, default: true
property :visual_warning, [true, false], required: false, default: true
property :hide_sensitive, [true, false, NilClass], required: false, default: nil

default_action :join
provides :domain_join, os: 'windows'
# TODO: limit to just windows 2012r2

Chef::Log.warn("node['ad-join']['windows']['update_hostname'] deprecated") if defined? node['ad-join']['windows']['update_hostname']
Chef::Log.warn("node['ad-join']['windows']['visual_warning'] deprecated") if defined? node['ad-join']['windows']['visual_warning']
Chef::Log.warn("node['ad-join']['windows']['update_hostname'] deprecated") if defined? node['ad-join']['windows']['visual_warning']

# ohai domain attributes
# node['kernel']['cs_info']['domain_role']

# StandaloneWorkstation = 0
# MemberWorkstation = 1`
# StandaloneServer = 2
# MemberServer = 3
# BackupDomainController = 4
# PrimaryDomainController = 5

action :join do
  # Set the computer name to the same name provided by -N parameter in  knife boostrap -N 'node01'
  if Chef::Config[:node_name] != node['hostname'] && Chef::Config[:node_name] != node['fqdn'] && new_resource.update_hostname == true
    # Abort if hostname is more than 15 characters long on windows
    raise if Chef::Config[:node_name].length > 15

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
    only_if { new_resource.visual_warning == true }
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
  # schtasks.exe won't allow this to be combined with task creation
  powershell_script 'ad-join sched task modify start date' do
    code <<-EOH
    schtasks.exe /Change /TN 'chef ad-join' /SD '06/09/2016' /ST '01:00'
    EOH
    only_if "schtasks.exe /Query /TN 'chef ad-join'"
  end

  powershell_script 'ad-join' do
    code <<-EOH
    $adminname = "#{new_resource.domain}\\#{new_resource.domain_user}"
    $password = '#{new_resource.domain_password}' | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($adminname,$password)

    if ( '#{newcomputername}' -eq $(hostname) ) {
      Write-Host "Skipping computer rename since already named: #{newcomputername}"
    }
    else {
      Write-Host "Renaming computer from $($hostname) to #{newcomputername}"
      Rename-Computer -NewName '#{newcomputername}'
    }
    sleep 5
    Add-computer -DomainName #{new_resource.domain} #{new_resource.ou.nil? ? '' : '-OUPath "' + new_resource.ou + '"'} #{new_resource.server.nil? ? '' : '-Server "' + new_resource.server + '"'} -Credential $credential -force -Options JoinWithNewName,AccountCreate -PassThru #-Restart

    # Old way, somtimes Domain controller busy error occured
    # Add-Computer  #{newcomputername} -DomainName #{new_resource.domain} -OUPath #{new_resource.ou} -Credential $credential -Restart -PassThru
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
    only_if { double_reboot == true }
    notifies :reboot_now, 'reboot[Restart Computer]', :immediately
  end

  windows_task 'remove chef ad-join' do
    task_name 'chef ad-join' # http://bit.ly/1WDZ1kn
    notifies :delete, 'registry_key[warning]', :delayed
    action :delete
  end
end

action :leave do
  reboot 'Restart Computer' do
    action :nothing
  end

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
    only_if { new_resource.visual_warning == true }
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
    # Chef 12 uses :change, Chef 13.4.19 uses :create to modify existing tasks http://bit.ly/2wbDTzP
    action :change if Gem::Requirement.create('~> 12').satisfied_by?(Gem::Version.create(Chef::VERSION))
  end

  powershell_script 'ad-join-leave' do
    code <<-EOH
    $adminname = "#{new_resource.domain}\\#{new_resource.domain_user}"
    $password = '#{new_resource.domain_password}' | ConvertTo-SecureString -asPlainText -Force
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
end
