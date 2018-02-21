5.1.0
-----
Change schedule task modify to make more chef 13 friendly

5.0.4
-----
Fix typo in metadata

5.0.3
-----

Work around bug with chef 13
https://github.com/chef/chef/issues/6824#issuecomment-367141438

-----
Fix leave action on chef 13 (#31)

5.0.1
-----
Fix scheduled task not running on windows

5.0.0
-----
Adds Ubuntu support  
Fix Chef 13. Requires 13.4.19 or greater (or >=12.7) (#12, #20, #23)

4.12.1
------
Throws error if running on chef 11 or chef 13
Temporary fix until this issue is fixed https://github.com/NetDocuments/ad-join-cookbook/issues/23

4.12.0
------
Fixes issue #19
Fixes deprecation warning for chef 13

4.11.1
------
Fix berkshelf supermarket url

4.11.0
------
Abort if hostname is longer than 15 characters on windows

4.10.0
------
Adds domain leave functionality (#16 metalseargolid)

4.9.0
-----
Fix: Scheduled task wont run if time zone changes on reboot (#13)

4.8.0
-----
Fix: No longer gives deprecation warnings if 'server' is nil. (#9)

4.7.0
-----
Improvement: Adds name to scheduled task, removing need for workaround http://bit.ly/1WDZ1kn
Change: Changes c:\\windows\\chef-ad-join.txt to windows friendly path c:/windows/chef-ad-join.txt

4.6.1
-----
Fix: Warning registry key not cleaned up

4.6.0
-----
Add: 'server' parameter to allow for specifying a specific domain controller
Fix: Warning message wouldn't be displayed (#4)

4.5.0
-----
Fix: Passwords with special characters now work properly (#7 Thanks opsline-radek)
Fix: OU Parameter is now truly optional (#6 Thanks opsline-radek)

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
