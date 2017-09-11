# This is a simple example that joins the example.com domain_join
# More than likely you will want to put the domain_password in a databag "data_bag_item('users','binduser')['password']"

domain_join 'foobar' do
  domain 'example.com'
  domain_user 'binduser'
  domain_password 'correct-horse-battery-staple'
  ou 'OU=US,OU=West,OU=Web,DC=example,DC=com'
end

# For linux machines, add users to sudoers file

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
    name s['name'] if s['name'] #The name of file in /etc/sudoers.d
    user s['user']
    runas s['runas'] if s['runas']
    commands s['commands'] if s['commands']
  end
end
