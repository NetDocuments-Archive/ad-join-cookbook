ad-join Cookbook
============================

This is a library cookbook that will join a windows computer to a windows AD domain

## Requirements

Chef >= 12.5.1  

This leverages [custom resources](https://docs.chef.io/custom_resources.html) so it will not work on chef versions older than 12.5.1

Tested on:

Windows 2012R2  


## Usage

This cookbook is a library cookbook and is intended to be used by your own wrapper cookbook. See the [recipes directory](./recipes) for examples. 

It contains a custom resource named `domain_join` that takes 4 properties

- domain
- domain_user
- domain_password
- ou

```ruby
domain_join 'foobar' do
  domain          'example.com'
  domain_user     'binduser'
  domain_password 'correct-horse-battery-staple'
  ou              'OU=US,OU=West,OU=Web,DC=example,DC=com'
end
```

The ou must be formatted with `OU=` before each organizational unit and `DC=` before each domain component. see [recipes/example_complex.rb](./recipes/example_complex.rb) for an example of how to derive the OU from attributes. 


### Behind the scenes

If you bootstrapped the node with the name option; e.g.

    knife bootstrap -N us-web01
    
Then that is the name that will be used to join the domain (not the hostname since windows randomly generates it on first boot)

The cookbook creates a windows scheduled task that runs chef as soon as the VM is started. The scheduled task is deleted after all the reboots. 

The cookbook will restart windows twice since some group policy objects (like the time zone) are not applied on first boot. You can change this behavior by changing the following attribute to false. 

    default['ad-join']['windows']['double_reboot'] = true  



License and Authors
-------------------
Authors:  
Volodymyr Babchynskyy vbabch@softserveinc.com  
Spencer Owen sowen@netdocuments.com  
