Basic use of this vagrant:

```bash
export RESEAL=true
export IMAGE='CentOS 7-1603 (2016-04-05)'
vagrant up --provider=openstack && \
  nova image-create --poll vagrant-hostname 'CentOS 7 - basebuild - 20160523' \
  && vagrant destroy
```

Assumptions:

* You have vagrant installed with the vagrant-openstack-provider plugin
* You have a the appropriate openstack variables set in your environment
* You have a 'dummy' vagrant box that looks similar to the following @
  `~/.vagrant.d/boxes/dummy/0/openstack/Vagrantfile`

*NOTE*: The following is rather Vexxhost specific

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby ts=2 sw=2 sts=2 et :

Vagrant.configure("2") do |config|

  config.vm.provider :openstack do |os, override|
    os.openstack_auth_url = ENV['OS_AUTH_URL']
    os.flavor = 'v1-standard-1'
    os.region = ENV['OS_REGION_NAME']

    os.tenant_name = ENV['OS_TENANT_NAME']
    os.username = ENV['OS_USERNAME']
    os.password = ENV['OS_PASSWORD']

    if ENV['NETID']
      os.networks = [ ENV['NETID'] ]
    end

    if ENV['VEXXHOST_CP']
      os.availability_zone = 'ca-ymq-2'
    end

    # personal default instance names
    os.server_name = 'vagrant-hostname'
  end
end
```
