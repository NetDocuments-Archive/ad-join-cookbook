resource_name :domain_join
property :domain, String, required: true
property :domain_user, String, required: true
property :domain_password, String, required: true
property :ou, [String, NilClass], required: false, default: nil
property :server, [String, NilClass], required: false, default: nil
property :update_hostname, [true, false, NilClass], required: false, default: nil
property :double_reboot, [true, false, NilClass], required: false, default: nil
property :visual_warning, [true, false, NilClass], required: false, default: nil
property :hide_sensitive, [true, false], required: false, default: true

default_action :join
provides :domain_join, platform_version: '14.04', platform: 'ubuntu'

Chef::Log.warn("node['ad-join']['windows']['update_hostname'] deprecated") if defined? node['ad-join']['windows']['update_hostname']
Chef::Log.warn("node['ad-join']['windows']['visual_warning'] deprecated") if defined? node['ad-join']['windows']['visual_warning']
Chef::Log.warn("node['ad-join']['windows']['update_hostname'] deprecated") if defined? node['ad-join']['windows']['visual_warning']

action :join do
  apt_update 'update' do
    ignore_failure true
    action :update
  end

  # AD Join loosely based on this document https://help.ubuntu.com/lts/serverguide/sssd-ad.html
  # https://tutel.me/c/unix/questions/256626/sssd+realm+discover+not+authorized+to+perform+this+action
  %w(realmd sssd-tools sssd libnss-sss libpam-sss adcli packagekit samba-client samba-dsdb-modules).each do |pkg|
    package pkg do
      action :install
    end
  end

  # https://answers.launchpad.net/ubuntu/+question/293540
  execute 'realm join' do
    environment 'DOMAIN_PASS' => domain_password
    command <<-EOH
      echo "${DOMAIN_PASS}" | sudo realm join --verbose #{new_resource.domain} --user #{new_resource.domain_user}@#{new_resource.domain} --computer-ou #{new_resource.ou} --install=/
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
    sensitive hide_sensitive
  end
end

action :leave do
  execute 'realm leave' do
    environment 'DOMAIN_PASS' => domain_password
    command <<-EOH
      sudo realm leave
      EOH
    only_if <<-EOH
      domain=$(sudo realm list -n| tr '[:upper:]' '[:lower:]');
      if [ "${domain}" != "#{new_resource.domain.downcase}" ]; then
        exit 1;
      else
        exit 0;
      fi
      EOH
    sensitive new_resource.hide_sensitive
  end
end
