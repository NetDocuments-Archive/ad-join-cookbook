4.4.0
-----
Adds new attribute default['ad-join']['windows']['update_hostname']

4.3.0
-----
Adds warning attribute

4.2.0
-----
Fixes incorrect CWD in sched task (issue #3)
Fixes incorrect ohai fact "node['os']"

4.1.0
-----
Fixes powershell error when vm name is same as bootstrap name.  issue #2

4.0.2
-----
Updates metadata for supermarket

4.0.1
-----
Fixes attribute name for double reboot

4.0.0
-----
Created new git repo for public release on github

3.0.2
-----
Create breadcrumb only if missing

3.0.1
-----
Fixes OU not having quotes

3.0.0
-----
Complete rewrite to make it a library cookbook

2.0.2
-----
More verbose logging in scheduled task

2.0.1
-----
Reduces timeout to 30 seconds

1.0.0
-----
general cleanup, removed private domain name and so on, prepared for public release

0.9.0
-----
removed private usernames and passwords

0.8.1
-----
rubocop convention alerts accepted

0.8.0
-----
changed databag name

0.6.1
-----
rubocop check for line length now is 120 symbols

0.6.0
-----
rubocop and foodcritic inspections added

0.5.1
-----
icon added

0.5.0
-----
tests added

0.4.0
-----
Added possibility to run it on teamcity CI

0.3.0
-----
Fixed, directory server is unavailable issue, code commented for future use

0.2.0
-----
Passwords moved into databag

0.1.1
-----
added ohai reload for new fqdn resolution in chef

0.1.0
-----
Initial release of ad-join
