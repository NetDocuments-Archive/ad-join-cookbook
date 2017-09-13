ou_type    = node['foo']['type']
ou_site    = node['foo']['site']
ou_region  = node['foo']['region']
dc_domains = node['foo']['domains']

# Take the 3 OU's and make one long OU string
the_ou = [ou_type, ou_site, ou_region, 'Servers']
the_ou = the_ou.compact # Remove undefined / nil values
the_ou_string = ''
the_ou.each do |anOU|
  the_ou_string << "OU=#{anOU},"
end
# OU=Web,OU=Sydney,OU=AU,OU=Servers
the_ou_string = the_ou_string.chomp(',') # Remove trailing comma

# Take the DC's and make one long DC string
the_dc_string = ''
dc_domains.each do |aDC|
  the_dc_string << "DC=#{aDC},"
end
# DC=example,DC=com
the_dc_string = the_dc_string.chomp(',') # Remove trailing comma

Chef::Log.info "ad-join string is #{the_ou_string},#{the_dc_string}"

domain_join 'foobar' do
  domain           dc_domains.join('.').to_s
  domain_user      data_bag_item('users', 'ad-user')['username']
  domain_password  data_bag_item('users', 'ad-user')['password'] # 'correct-horse-battery-staple'
  ou               "#{the_ou_string},#{the_dc_string}" # 'OU=US,OU=West,OU=Web,DC=example,DC=com'
  server           'domaincontroller1.example.com'
  update_hostname true
  double_reboot true
  visual_warning true
  hide_sensitive true
end
