name 'mycompany-ad-join-linux'
maintainer 'NetDocuments'
maintainer_email 'user@example.com'
license 'All rights reserved'
description 'Wrapper cookbook for ad-join cookbook'
issues_url 'https://example.com'
source_url 'https://example.com'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

supports 'windows'

depends 'ad-join', '~> 5.0.0'
depends 'sudo', '~> 3.5.3'

chef_version '>= 12.7.0', '< 13.0.0'
chef_version '>= 13.4.19'
