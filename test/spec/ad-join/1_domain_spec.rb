require 'spec_helper'

# Check if PC connected to domain
describe command '(gwmi win32_computersystem).partofdomain' do
  its(:stdout) { should match 'True' }
end

# Check in which domain PC
describe command 'Get-WmiObject Win32_ComputerSystem | Select -Expand Domain' do
  its(:stdout) { should match 'ndlab.local' }
end
