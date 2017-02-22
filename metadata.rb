name             'ad-join'
maintainer       'NetDocuments'
maintainer_email 'sowen@netdocuments.com'
license          'All rights reserved'
description      'Joins windows computers to Active Directory (LDAP) Domain'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '4.12.0'

depends 'windows', '>= 1.36.0'

supports 'windows'
