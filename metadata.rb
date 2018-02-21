name             'ad-join'
maintainer       'NetDocuments'
maintainer_email 'sowen@netdocuments.com'
license          'All rights reserved'
description      'Joins windows computers to Active Directory (LDAP) Domain'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url       'https://github.com/NetDocuments/ad-join-cookbook/issues'
source_url       'https://github.com/NetDocuments/ad-join-cookbook'
version          '5.1.0'

depends 'windows', '>= 1.36.0'

supports 'windows'
supports 'ubuntu'

# linux support requires apt_update resource introduced in chef 12.7
# Chef 13 has many changes to windows scheduled tasks and reboots https://github.com/NetDocuments/ad-join-cookbook/issues
chef_version '>= 12.7.0', '< 13.0.0'
# https://github.com/chef/chef/issues/6824#issuecomment-367141438
chef_version '>= 13.4.19', '<= 13.6.4'
chef_version '> 13.8.0'
