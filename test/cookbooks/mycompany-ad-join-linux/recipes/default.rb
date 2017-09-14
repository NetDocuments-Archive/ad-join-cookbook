# https://coderanger.net/derived-attributes/
ou_type    = node['mycompany-ad-join']['ou-type']
ou_site    = node['mycompany-ad-join']['ou-site']
ou_region  = node['mycompany-ad-join']['ou-region']
dc_domains = node['mycompany-ad-join']['dc-domains']

# Take the 3 variables, and construct a OU string with them
the_ou = [ou_type, ou_site, ou_region, 'Servers', 'ExampleCO']
the_ou = the_ou.compact # Remove undefined / nil values
the_ou_string = ''
the_ou.each do |an_ou|
  the_ou_string << "OU=#{an_ou},"
end
the_ou_string = the_ou_string.chomp(',')

unless node['mycompany-ad-join']['dc-domains']
  Chef::Application.fatal!('dc-domains attribute must be set in role / environment')
end

# Construct the string of the domain ('example.com')
the_dc_string = ''
dc_domains.each do |a_dc|
  the_dc_string << "DC=#{a_dc},"
end
the_dc_string = the_dc_string.chomp(',')

Chef::Log.info "ad-join string is #{the_ou_string},#{the_dc_string}"

# Call the domain_join custom resource in the ad-join library cookbook
domain_join 'default' do
  domain          node['mycompany-ad-join']['dc-domains'].join('.').to_s # example.com
  domain_user     data_bag_item('users', 'aduser')['username']
  domain_password data_bag_item('users', 'aduser')['password']
  ou              "#{the_ou_string},#{the_dc_string}"
  server          node['mycompany-ad-join']['server'] if node['mycompany-ad-join']['server']
  update_hostname false
  double_reboot true
  visual_warning true
  hide_sensitive node['mycompany-ad-join']['hide_sensitive']
  action :join
end

if node['os'] == 'linux'
  if defined? node['mycompany-ad-join']['sudoers']
    node['mycompany-ad-join']['sudoers'].each do |s|
      sudo s['user'] do
        name s['name'] if s['name'] # The name of file in /etc/sudoers.d
        user s['user']
        runas s['runas'] if s['runas']
        commands s['commands'] if s['commands']
      end
    end
  end

  cookbook_file '/etc/pam.d/CHEF-mkhomedir' do
    owner 'root'
    source 'CHEF-mkhomedir.txt'
    cookbook 'mycompany-ad-join'
    group 'root'
    mode '0644'
    action :create
  end

  package 'krb5-kdc-ldap' do
    action :install
  end

  kerberos_realm = node['mycompany-ad-join']['dc-domains'].join('.').upcase
  kerberos_realm = node['mycompany-ad-join']['kerberos_realm'].join('.').upcase if !!(node['mycompany-ad-join']['kerberos_realm'])

  template '/etc/krb5.conf' do
    source 'default/krb5.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(kerberos_realm: kerberos_realm)
    only_if { node['os'] == 'linux' }
  end

  # https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Windows_Integration_Guide/sssd-dyndns.html
  # WARNING, you can't have comments in /etc/sssd/sssd.conf http://bit.ly/2x0APnj
  # TODO: sssd service will error if domain_join action is :leave
  template '/etc/sssd/sssd.conf' do
    source 'default/sssd.conf.erb'
    variables(
      domain: node['mycompany-ad-join']['dc-domains'].join('.').downcase,
      kerberos_realm: kerberos_realm
    )
    owner 'root'
    group 'root'
    mode '0600'
    notifies :restart, 'service[sssd]', :delayed
    action :create
  end

  service 'sssd' do
    action [:nothing]
  end
end
