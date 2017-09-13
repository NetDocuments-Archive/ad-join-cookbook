name             'ad-join'
maintainer       'NetDocuments'
maintainer_email 'sowen@netdocuments.com'
license          'All rights reserved'
description      'Joins windows computers to Active Directory (LDAP) Domain'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url       'https://github.com/NetDocuments/ad-join-cookbook/issues'
source_url       'https://github.com/NetDocuments/ad-join-cookbook'
version          '4.12.1'

depends 'windows', '>= 1.36.0'

supports 'windows'
supports 'ubuntu'

# linux support requires apt_update resource introduced in chef 12.7
# Chef 13 has many changes to windows scheduled tasks and reboots https://github.com/NetDocuments/ad-join-cookbook/issues
chef_version '>= 12.7.0', '< 13.0.0'
chef_version '> 13.3.0'
