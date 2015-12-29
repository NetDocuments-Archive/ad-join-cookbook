# This is a more complex example
# You might do something like this if you have multiple datacenters and a nested OU hiearchy
# Start by splitting your OU's out into role/enviroment attributes. Because chef
# does a deep merge, these attrbiutes could be split amounst several roles. see http://spuder.github.io/chef/design-pattern/chef-datacenter-pattern/
# {
#   "foo": {
#     "type": "Web",
#     "site": "Sydney",
#     "region": "AU",
#     "domains": [ "example","com" ]
# 
# }

# Desired outcome
# OU=Web,OU=Sydney,OU=AU,OU=Servers,DC=example,DC=com

ou_type    = node['foo']['type']
ou_site    = node['foo']['site']
ou_region  = node['foo']['region']
dc_domains = node['foo']['domains']

# Take the 3 OU's and make one long OU string
theOU = [ ou_type, ou_site, ou_region, 'Servers']
theOU = theOU.compact #Remove undefined / nil values
theOUString = ""
theOU.each do |anOU|
  theOUString << "OU=#{anOU},"
end
# OU=Web,OU=Sydney,OU=AU,OU=Servers
theOUString = theOUString.chomp(',') #Remove trailing comma

# Take the DC's and make one long DC string
theDCString = ""
dc_domains.each do |aDC|
  theDCString << "DC=#{aDC},"
end
# DC=example,DC=com
theDCString = theDCString.chomp(',') #Remove trailing comma

Chef::Log.info "ad-join string is #{theOUString},#{theDCString}"

domain_join 'foobar' do
  domain          node['foo']['domains'].join('.')  # example.com
  domain_user     'binduser'
  domain_password data_bag_item('users','binduser')['password']
  ou              "#{theOUString},#{theDCString}" # OU=Web,OU=Sydney,OU=AU,OU=Servers,DC=example,DC=com
end
