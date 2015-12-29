require 'spec_helper'

describe file('C:\\opscode\chef\bin\chef-client.bat') do
  it { should be_file }
end

describe command('powershell.exe "Get-ChildItem Env:Path | Out-String -Width 2048 > c:\\path.txt"') do
  its(:exit_status) { should eq 0 }
end

describe file('c:\\path.txt') do
  it { should be_file }
end

describe file('c:\\path.txt') do
  its(:content) { should match 'chef' }
end
