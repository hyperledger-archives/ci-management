Basic use:

  - Create dummy box

    $ tar cvzf dummy.tar.gz -C vagrant-dummy-box ./Vagrantfile ./metadata.json
    $ vagrant box add --name 'dummy' dummy.tar.gz && rm dummy.tar.gz

  - Make changes to 'bootstrap.sh'

  - Test the vagrant box

    $ vagrant up --provider=openstack && vagrant ssh

Resealing:

  - Pass an image NAME listed from "glance image-list" to './reseal.sh'

    $ ./reseal.sh 'Ubuntu 14.04.4 LTS (2016-02-17)'

Assumptions:

  * You have vagrant installed with the vagrant-openstack-provider plugin

    $ vagrant plugin install vagrant-openstack-provider

  * You have a the appropriate openstack variables set in your environment
    Vexxhost example: https://secure.vexxhost.com/console/#/account/credentials

    ``` bash
    #! /bin/bash
    # ~/.openrc

    export OS_TENANT_NAME=...
    export OS_USERNAME=...
    export OS_PASSWORD=...
    export AUTH_URL=...
    export OS_REGION_NAME=...
    ```

    $ source ~/.openrc

  * You have the OpenStack nova, glance, and neutron clients installed

    $ pip install python-{nova,glance,neutron}client

  * You have a 'dummy' vagrant box that uses the openstack provider
    (see Basic Use)
