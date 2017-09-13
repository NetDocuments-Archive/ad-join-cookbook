default['mycompany-ad-join'] = {
  'dc-domains' => [
    'example',
    'com'
  ],
  'ou-site' => 'mySite',
  'ou-type' =>  'Server',
  'server' => 'domaincontroller1.exapmle.com'
}

default['mycompany-ad-join']['kerberos_realm'] = [
  'EXAMPLE',
  'COM'
]

default['mycompany-ad-join']['sudoers'] = [
  {
    'name' => 'IT',
    'user' => '%exampleco\\\\IT',
    'runas' => 'ALL',
    'commands' => ['ALL']
  }
]
