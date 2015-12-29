# -*- mode: ruby -*-
# vi: set ft=ruby :
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'
VAGRANT_LOG = 'debug'
if ENV['HOSTNAME']
  hostname = ENV['HOSTNAME']
else
  hostname = 'ad-join'
end
BOXFILE = 'Windows-Server-2012-r2-Standard-master-hyperv.box'
smb_username = ENV['ADMINUSERNAME'] if ENV['ADMINUSERNAME']
smb_password = ENV['USERPASSWORD'] if ENV['USERPASSWORD']

Vagrant.require_version '>= 1.7.0'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define hostname
  config.vm.box = BOXFILE
  config.vm.communicator = 'winrm'
  config.vm.synced_folder '.', '/vagrant', type: 'smb', smb_username:  smb_username, smb_password: smb_password

  # Admin user name and password
  config.winrm.username = 'vagrant'
  config.winrm.password = 'vagrant'

  config.vm.guest = :windows
  config.windows.halt_timeout = 300
  config.vm.boot_timeout = 900

  config.vm.network 'public_network', bridge: 'vSwitch'
  config.vm.network :forwarded_port, guest: 3389, host: 3389, id: 'rdp', auto_correct: true
  config.vm.network :forwarded_port, guest: 22, host: 2222, id: 'ssh', auto_correct: true

  config.vm.provider 'hyperv' do |v|
    v.vmname = hostname
    v.cpus = 2
    v.memory = 2048
    # v.maxmemory = 2048
    v.ip_address_timeout = 50_000
    v.vlan_id = 130
    config.vm.boot_timeout = 300_000
  end

  config.vm.provider :virtualbox do |v|
    # v.gui = true
    v.customize ['modifyvm', :id, '--memory', 2048]
    v.customize ['modifyvm', :id, '--cpus', 2]
    v.customize ['setextradata', 'global', 'GUI/SuppressMessages', 'all']
  end

  config.vm.provider :vmware_fusion do |v|
    # v.gui = true
    v.vmx['memsize'] = '2048'
    v.vmx['numvcpus'] = '2'
    v.vmx['ethernet0.virtualDev'] = 'vmxnet3'
    v.vmx['RemoteDisplay.vnc.enabled'] = 'false'
    v.vmx['RemoteDisplay.vnc.port'] = '5900'
    v.vmx['scsi0.virtualDev'] = 'lsisas1068'
  end

  config.vm.provider :vmware_workstation do |v|
    # v.gui = true
    v.vmx['memsize'] = '2048'
    v.vmx['numvcpus'] = '2'
    v.vmx['ethernet0.virtualDev'] = 'vmxnet3'
    v.vmx['RemoteDisplay.vnc.enabled'] = 'false'
    v.vmx['RemoteDisplay.vnc.port'] = '5900'
    v.vmx['scsi0.virtualDev'] = 'lsisas1068'
  end

  config.omnibus.chef_version = '11.18.12'
  config.berkshelf.berksfile_path = './Berksfile'
  config.berkshelf.enabled = true

  config.vm.provision 'shell', inline: '$localIpAddress=((ipconfig | findstr [0-9].\.)[0]).Split()[-1]; Write-Output "##teamcity[setParameter name=\'env.TARGET_HOST_IP\' value=\'$localIpAddress\']"'

  config.vm.provision :chef_solo do |chef|
    # chef.log_level = :debug
    chef.node_name = hostname
    chef.cookbooks_path = 'cookbooks'
    chef.add_recipe 'ad-join'
    chef.data_bags_path = 'data_bags'
  end
end
