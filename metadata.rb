name             'ad-join-cookbook'
maintainer       'ops'
maintainer_email 'ops@defisolutions.com'
license          'All rights reserved'
description      'Joins windows computers to Active Directory (LDAP) Domain'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '6.0.2'

# Removing Windows Depends. Cookbook works with latest windows built-in chef resources
