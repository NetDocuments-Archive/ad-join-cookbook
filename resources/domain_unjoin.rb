resource_name :domain_unjoin
property :domain_user, String, required: true
property :domain_password, String, required: true
property :restart, [String, NilClass], required: false, default: true

default_action :unjoin

action :unjoin do
  if computer_exists?
    Chef::Log.debug('Removing computer from the domain')
    powershell_script "unjoin_#{domain_name}" do
      if node['os_version'] >= '6.2'
        cmd_text = 'Remove-Computer -UnjoinDomainCredential $mycreds -Force:$true'
        cmd_text << " -ComputerName #{name}"
        cmd_text << ' -Restart' if restart
        code <<-EOH
          $secpasswd = ConvertTo-SecureString '#{domain_pass}' -AsPlainText -Force
          $mycreds = New-Object System.Management.Automation.PSCredential ('#{domain_name}\\#{domain_user}', $secpasswd)
          #{cmd_text}
        EOH
      else
        cmd_text = "netdom remove #{name}"
        cmd_text << " /d:#{domain_name}"
        cmd_text << " /ud:#{domain_name}\\#{domain_user}"
        cmd_text << " /pd:#{domain_pass}"
        cmd_text << ' /reboot' if restart
        code cmd_text
      end
    end

    new_resource.updated_by_last_action(true)
  else
    Chef::Log.error('The computer is not a member of the domain, unable to unjoin.')
    new_resource.updated_by_last_action(false)
  end
end

def computer_exists?
  comp = Mixlib::ShellOut.new('powershell.exe -command \"get-wmiobject -class win32_computersystem -computername . | select domain\"').run_command
  stdout = comp.stdout.downcase
  Chef::Log.debug("computer_exists? is #{stdout.downcase}")
  stdout.include?(new_resource.domain_name.downcase)
end
