ad-join Cookbook
============================

This is a library cookbook that will join a  computer to a windows AD domain

## Requirements

Chef >= 12.5.1  

This leverages [custom resources](https://docs.chef.io/custom_resources.html) so it will not work on chef versions older than 12.5.1

Tested on:

Windows 2012R2  
Ubuntu 16.04

## Ubuntu 

This cookbook has limited support for linux. Common pitfalls

- Hostname must be 15 characters or less
- NetBios names are not supported (Windows 2000 domain controllers )
- Domain is cAsE SenSITive
- If the domain join fails, the domain password may be logged on the chef server in plain text. Take caution to roll your logs if that happens.

**The ad-join cookbook is as unopinionated as possible. It will not configure sudoers file or sssd.conf file. Use the sudoers or sssd cookbook in your wrapper cookbook to manage those services.**

The cookbook will overwrite '/etc/krb5.conf' and '/etc/samba/smb.conf'. Best to only run this cookbook on new machines. 

See troubleshooting section at bottom for additional information

## Attributes

    default['ad-join']['windows']['update_hostname'] = true
    
Set to false if you want the domain name/hostname to be different from the chef node name. (see [#5](https://github.com/NetDocuments/ad-join-cookbook/issues/5)).

    default['ad-join']['windows']['double_reboot'] = true

Will continue to reboot windows until joined to domain and breadcrumb `c:\\Windows\\chef-ad-join.txt` exists. 

    default['ad-join']['windows']['visual_warning'] = false

If `visual_warning = true`, windows will display a login warning to anyone who connects via RDP to the machine before chef has finished the reboots and the converge. This will override any group policy your company might have in place for displaying custom login messages. 

![](http://cl.ly/3l1I1n3X0q1G/Screenshot%202016-01-21%2012.49.45.png)

## Usage

This cookbook is a library cookbook and is intended to be used by your own wrapper cookbook. See the [recipes directory](./recipes) for examples. 

### Actions

- join
- leave

It contains a custom resource named `domain_join` that takes 5 properties

- domain
- domain_user
- domain_password
- ou
- server (optional)

example:  

```ruby
domain_join 'foobar' do
  domain          'example.com'
  domain_user     'binduser'
  domain_password 'correct-horse-battery-staple'
  ou              'OU=US,OU=West,OU=Web,DC=example,DC=com'
  server          'DC01' #Optional
  action :join
end
```

The ou must be formatted with `OU=` before each organizational unit and `DC=` before each domain component. see [recipes/example_complex.rb](./recipes/example_complex.rb) for an example of how to derive the OU from attributes. 


### Behind the scenes

If you bootstrapped the node with the name option; e.g.

    knife bootstrap -N us-web01
    
Then that is the name that will be used to join the domain (not the hostname since windows randomly generates it on first boot)

**The name cannot include control characters, leading or trailing spaces, or any of the following characters: / \\ [ ].**

In most cases, Windows hostnames must be 15 characters or less. 

The cookbook creates a windows scheduled task that runs chef as soon as the VM is started. The scheduled task is deleted after all the reboots. 

The cookbook will restart windows twice since some group policy objects (like the time zone) are not applied on first boot. You can change this behavior by changing the following attribute to false. 

    default['ad-join']['windows']['double_reboot'] = true  


## Troubleshooting

```
realm: No such realm found
```
Realm is case sensitive. Try EXAMPLE.COM instead of example.com

```
realm: Not authorized to perform this action
````

Not all packages installed successfully. Verify adcli and packagekit are installed

```
! Couldn't get kerberos ticket for: foo@example.com: KDC reply did not match expectations
adcli: couldn't connect to example.com domain: Couldn't get kerberos ticket for: foo@example.com: KDC reply did not match expectations
```

The domain is case sensitive. Try changing `example.com` to `EXAMPLE.COM`


License and Authors
-------------------
Authors:  
Volodymyr Babchynskyy vbabch@softserveinc.com  
Spencer Owen sowen@netdocuments.com  
