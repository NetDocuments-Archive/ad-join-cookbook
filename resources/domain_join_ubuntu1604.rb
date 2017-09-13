resource_name :domain_join
property :domain, String, required: true
property :domain_user, String, required: true
property :domain_password, String, required: true
property :ou, [String, NilClass], required: false, default: nil
property :server, [String, NilClass], required: false, default: nil
property :update_hostname, [true, false], required: false, default: true
property :double_reboot, [true, false], required: false, default: true
property :visual_warning, [true, false], required: false, default: true
property :sensitive, [true, false], required: false, default: true

default_action :join
provides :domain_join, os: 'linux'


Chef::Log.warn( "node['ad-join']['windows']['update_hostname'] deprecated") if !!(node['ad-join']['windows']['update_hostname'])
Chef::Log.warn( "node['ad-join']['windows']['visual_warning'] deprecated") if !!(node['ad-join']['windows']['visual_warning'])
Chef::Log.warn( "node['ad-join']['windows']['update_hostname'] deprecated") if !!(node['ad-join']['windows']['visual_warning'])

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
  if Chef::Config[:node_name] != node['hostname'] && Chef::Config[:node_name] != node['fqdn'] && update_hostname == true
    # Abort if hostname is more than 15 characters long on windows
    raise if Chef::Config[:node_name].length > 15

    newcomputername = Chef::Config[:node_name]

    ohai 'reload' do
      action :reload
    end

  else
    newcomputername = node['hostname']
  end

  apt_update 'update' do
    ignore_failure true
    action :nothing
  end

  # AD Join loosely based on this document https://help.ubuntu.com/lts/serverguide/sssd-ad.html
  # https://tutel.me/c/unix/questions/256626/sssd+realm+discover+not+authorized+to+perform+this+action
  %w(realmd sssd-tools sssd libnss-sss libpam-sss adcli packagekit).each do |pkg|
    package pkg do
      action :install
      notifies :update, 'apt_update[update]', :before
    end
  end

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
    sensitive new_resource.sensitive
  end

end

action :leave do
  raise "Linux can't yet unjoin from domain"
end
