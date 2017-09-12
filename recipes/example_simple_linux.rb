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

# If you have one way trusts between multiple domains, you can only login if you specify the root domain (e.g user@CORP.EXAMPLE.COM)
# user@CORP.EXAMPLE.COM
# user@LAB.EXAMPLE.COM
# By changing default_realm you make it so users don't have to remember type in the full domain when logging in to other trusted domains
file '/etc/krb5.conf' do
  content <<-EOH
[libdefaults]
default_realm CORP.EXAMPLE.COM
ticket_lifetime = 24h
renew_lifetime = 7d
  EOH
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end
