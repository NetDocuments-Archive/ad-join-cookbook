require 'serverspec'
require 'pathname'
require 'winrm'
set :backend, :winrm
set :os, family: 'windows'

if ENV['ADMINUSERNAME']
  user = ENV['ADMINUSERNAME']
else
  user = 'test.local\\Administrator'
end
if ENV['USERPASSWORD']
  pass = ENV['USERPASSWORD']
else
  pass = 'CHANGE_ME!'
end
endpoint = "http://#{ENV['TARGET_HOST']}:5985/wsman"
# endpoint = "http://10.254.130.109:5985/wsman"
# endpoint = "http://ad-join:5985/wsman"
# endpoint = "http://#{ENV['TEAMCITY_PROJECT_NAME']}-#{ENV['BUILD_NUMBER']}:5985/wsman"
# winrm = ::WinRM::WinRMWebService.new(endpoint, :ssl, :user => user, :pass => pass, :basic_auth_only => true)
winrm = ::WinRM::WinRMWebService.new(endpoint, :ssl, user: user, pass: pass, disable_sspi: true)
winrm.set_timeout 300 # 5 minutes max timeout for any operation
Specinfra.configuration.winrm = winrm
