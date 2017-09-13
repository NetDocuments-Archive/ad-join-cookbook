ad-join Cookbook
============================

Library cookbook that will join a computer
## Requirements


|Cookbook Version|Min Chef Version|Max Chef Version|
| --- | --- | --- |
| 5.x | >= 12.7 | < 13 |
| 4.x  | >= 12.5.1 | < 13|

Chef 13 changes how windows scheduled tasks and reboots are handled.   
Currently only supports Chef 12.

[https://github.com/NetDocuments/ad-join-cookbook/issues](https://github.com/NetDocuments/ad-join-cookbook/issues)


## Tested OS's


- Windows 2012R2  
- Ubuntu 14.04 (experimental)
- Ubuntu 16.04 (experimental)

## Usage

This cookbook is a library cookbook and is intended to be used by your own wrapper cookbook. See the [recipes directory](./recipes) for examples.

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
  server          'DC01' #Optional
  update_hostname true
  double_reboot true
  visual_warning true
  hide_sensitive true
  action :join
end
```

visual_warning

![](http://cl.ly/3l1I1n3X0q1G/Screenshot%202016-01-21%2012.49.45.png)


The ou must be formatted with `OU=` before each organizational unit and `DC=` before each domain component. see [recipes/example_complex_windows.rb](./recipes/example_complex_windows.rb) for an example of how to derive the OU from attributes.


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

This cookbook has experimental support for joining ubuntu 16.04.   
It does not reboot or manage any of the additional files that might be required for a complete ad join

Common pitfalls

- Ubuntu 16.04 only
- Hostnames longer than 15 characters will be truncated
- NetBios names are not supported (Windows 2000 domain controllers )
- Domain is cAsE SenSITive. In most cases this needs to be all uppercase.
- Debugging can be difficult, temporarily set `'hide_sensitive' false` to get additional information

**The ad-join cookbook is as unopinionated as possible. It will not configure `sudoers` file, `/etc/pam.d` or `/etc/krb5.conf`. Use the sudoers cookbook in your wrapper cookbook to manage those services. See [recipes/example\_simple\_linux.rb](./recipes/example_simple_linux.rb) for examples on how to manage those files**

This cookbook basically runs this bash command

    echo "correct-horse-battery-staple" | sudo realm join --verbose EXAMPLE.COM --user bob@EXAMPLE.COM --computer-ou OU=foobar --install=/


## Troubleshooting

### Ubuntu

Unable to install packages
If using chef 12.0 to 12.9 you will need to manually include the apt recipe in the runlist to run `apt-get update`
If using chef 12.9 or newer, the package resource should auto detect that apt-get update hasn't run yet and run it automatically.


```
realm: No such realm found
```

Realm is case sensitive. Try EXAMPLE.COM instead of example.com

```
realm: Not authorized to perform this action
```

Not all packages installed successfully. Verify `adcli` and `packagekit` are installed

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
