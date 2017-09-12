# This is a simple example that joins the example.com domain_join
# More than likely you will want to put the domain_password in a databag "data_bag_item('users','binduser')['password']"

domain_join 'foobar' do
  domain 'example.com'
  domain_user 'binduser'
  domain_password 'correct-horse-battery-staple'
  ou 'OU=US,OU=West,OU=Web,DC=example,DC=com'
end
