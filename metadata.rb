name             'ad-join'
maintainer       'NetDocuments'
maintainer_email 'sowen@netdocuments.com'
license          'All rights reserved'
description      'Joins windows computers to Active Directory (LDAP) Domain'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
issues_url       'https://github.com/NetDocuments/ad-join-cookbook/issues'
source_url       'https://github.com/NetDocuments/ad-join-cookbook'
version          '4.12.0'

depends 'windows', '>= 1.36.0'

supports 'windows'

chef_version '~> 12'
