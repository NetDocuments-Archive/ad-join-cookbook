# This is a simple example that joins the example.com domain_join
# More than likely you will want to put the domain_password in a databag "data_bag_item('users','binduser')['password']"

domain_join 'foobar' do
  domain 'example.com'
  domain_user 'binduser'
  domain_password 'correct-horse-battery-staple'
  ou 'OU=US,OU=West,OU=Web,DC=example,DC=com'
end

# For linux machines, add users to sudoers file
# Make sure sudoers cookbook is included in metadata of wrapper cookbook
# In your role/environment/profile define your sudoers users

# {
#   "mycompnay-ad-join": {
#     "kerberos_realm": [
#        "EXAMPLE",
#        "COM"
#     ],
#     "sudoers": [{
#       "name": "IT",
#       "user": "%exampleco\\\\IT",
#       "runas": "ALL",
#       "commands": [
#         "ALL"
#       ]
#     },{
#       "name": "tomcat",
#       "user": "tomcat",
#       "runas": "tomcat",
#       "commands": [
#         "whoami"
#       ]
#     }
#   ]
#   }
# }

# Itterate over all sudo users
node['mycompany-ad-join']['sudoers'].each do |s|
  sudo s['user'] do
    name s['name'] if s['name'] # The name of file in /etc/sudoers.d
    user s['user']
    runas s['runas'] if s['runas']
    commands s['commands'] if s['commands']
  end
end

# AD users won't get a home directory created automatically unless pam_mkhomedir.so is defined
file '/etc/pam.d/CHEF-mkhomedir' do
  content 'session required    pam_mkhomedir.so skel=/etc/skel/ umask=0022'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

ruby_block 'desc' do
  block do
    file = Chef::Util::FileEdit.new('/etc/sssd/sssd.conf')
    file.insert_line_if_no_match('dyndns_update*', 'dyndns_update = true')
    file.insert_line_if_no_match('dyndns_refresh_interval*', 'dyndns_refresh_interval = 43200')
    file.insert_line_if_no_match('dyndns_update_ptr*', 'dyndns_update_ptr = true')
    file.insert_line_if_no_match('dyndns_ttl*', 'dyndns_ttl = 3600')
    file.write_file
  end
  notifies :restart, 'service[sssd]', :immediately
  only_if { node['os'] == 'linux' }
end

service 'sssd' do
  action [:nothing]
end
