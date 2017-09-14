ad-join Cookbook
============================

Library cookbook that will join an Active Directory domain


## Tested OS's

- Windows 2012R2  
- Ubuntu 14.04 (experimental)
- Ubuntu 16.04 (experimental)


## Usage

This cookbook is a library cookbook and is intended to be used by your own wrapper cookbook. See the [test/cookbooks directory](./test/cookbooks) for examples.
While the examples show running separate cookbooks for windows and linux, this isn't required. It is possible for one wrapper cookbook to manage both windows and linux hosts.


### Actions

- join
- leave

It contains a custom resource named `domain_join` with the following properties

- domain
- domain_user
- domain_password
- ou
- server (optional)
- update_hostname (optional, windows only, Set to false if you want the domain name/hostname to be different from the chef node name. (see [#5](https://github.com/NetDocuments/ad-join-cookbook/issues/5)).)
- double_reboot (optional, windows only, Will continue to reboot windows until joined to domain and breadcrumb `c:\\Windows\\chef-ad-join.txt` exists. Useful since timezone doesn't always sync after first reboot. )
- visual_warning true (optional, windows only, display a login warning to anyone who connects via RDP to the machine before chef has finished the reboots and the converge. This will override any group policy your company might have in place for displaying custom login messages.)
- hide_sensitive (optional, linux only, hide password used in realmd command, set to false for debugging)

example:  

```ruby
domain_join 'foobar' do
  domain          'example.com'
  domain_user     'binduser'
  domain_password 'correct-horse-battery-staple'
  ou              'OU=US,OU=West,OU=Web,DC=example,DC=com'
  server          'DC01'
  update_hostname true
  double_reboot true
  visual_warning true
  hide_sensitive true
  action :join
end
```

visual_warning

![](http://cl.ly/3l1I1n3X0q1G/Screenshot%202016-01-21%2012.49.45.png)


The ou must be formatted with `OU=` before each organizational unit and `DC=` before each domain component. see [test/cookbooks directory](./test/cookbooks) for an example of how to derive the OU from attributes.


## Behind the scenes

If you bootstrapped the node with the name option; e.g.

    knife bootstrap -N us-web01

Then that is the name that will be used to join the domain (not the hostname since windows randomly generates it on first boot)

**The name cannot include control characters, leading or trailing spaces, or any of the following characters: / \\ [ ].**

### Windows


In most cases, Windows hostnames must be 15 characters or less.

The cookbook creates a windows scheduled task that runs chef as soon as the VM is started. The scheduled task is deleted after all the reboots.

The cookbook will restart windows twice since some group policy objects (like the time zone) are not applied on first boot. You can change this behavior by changing the following attribute to false.

    default['ad-join']['windows']['double_reboot'] = true  

This cookbook basically runs this powershell command, then reboots

    $adminname = "EXAMPLE.COM\\bob"
    $password = 'correct-horse-battery-staple' | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($adminname,$password)
    Add-computer -DomainName <EXAMPLE.COM> -OUPath <OU=FOO> -Server "<DC1.EXAMPLE.COM>'} -Credential $credential -force -Options JoinWithNewName,AccountCreate -PassThru


## Ubuntu

ad-join can join ubuntu machines to active directory. (experimental. Bug reports / pull requests encouraged)
It does not reboot or manage any of the additional files that might be required for a complete ad join

```ruby
domain_join 'foobar' do
  domain          'EXAMPLE.COM'
  domain_user     'binduser'
  domain_password 'correct-horse-battery-staple'
  ou              'OU=US,OU=West,OU=Web,DC=example,DC=com'
  server          'DC01'
  hide_sensitive true
  action :join
end
```

Common pitfalls

- Hostnames longer than 15 characters will be truncated
- NetBios names are not supported (Windows 2000 domain controllers )
- Domain is cAsE SenSITive. In most cases this needs to be all UPPERCASE.
- Debugging can be difficult, temporarily set `'hide_sensitive' false` to get additional information. domain_password will be shown in plain text.

**The ad-join cookbook is as unopinionated as possible. It will not configure `sudoers` file, `/etc/pam.d` or `/etc/krb5.conf`. Use the sudoers cookbook in your wrapper cookbook to manage those services. See [test/cookbooks/ad-join-linux directory](./test/cookbooks/ad-join-linux) for examples on how to manage those files**

This cookbook basically runs this bash command

    echo "correct-horse-battery-staple" | sudo realm join --verbose EXAMPLE.COM --user bob@EXAMPLE.COM --computer-ou OU=foobar --install=/


## Troubleshooting

### Ubuntu


```
realm: No such realm found
```

Realm is case sensitive. Try EXAMPLE.COM instead of example.com

```
realm: Not authorized to perform this action
```

Not all packages installed successfully. Verify `adcli` and `packagekit` are installed. Please open github issue if you find missing packages.

```
! Couldn't get kerberos ticket for: foo@example.com: KDC reply did not match expectations
adcli: couldn't connect to example.com domain: Couldn't get kerberos ticket for: foo@example.com: KDC reply did not match expectations
```

The domain is case sensitive. Try changing `example.com` to `EXAMPLE.COM`

```
DNS update failed: NT_STATUS_INVALID_PARAMETER
```

Make sure a fqdn is setup `hostname -f`

https://wiki.samba.org/index.php/Troubleshooting_Samba_Domain_Members

License and Authors
-------------------
Authors:  
Volodymyr Babchynskyy vbabch@softserveinc.com  
Spencer Owen sowen@netdocuments.com  
