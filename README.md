KDC-Ansible
============

Ansible Playbook for installing a pair of MIT KDC's configured and replicating.
This assumes ssh key logins have already been configured for the instances, or at
least from the Ansible server to both KDC servers or from the master to the
slave instance if this playbook is to be run from the master.

The playbooks currently function with RHEL or CentOS flavors of Linux.


## Running the Playbook:

A script is provided to simplify execution of the main playbook, *kdc-site.yml*.
```
$ ./bin/kdc-install.sh [inventory_name]
```

Which is equivalent to the ansible command:
```
$ ansible-playbook -i inventory/${env} kdc-site.yml
```

Clients can be installed with the *./bin/kdc-clients.sh* script which will
run the *kdc-clients.yml* playbook on a provided list of hosts. The client
playbook simply installs krb5 client prerequisites and the */etc/krb5.conf*
file with the given inventory environment. So, given an inventory name of
*env*, as in *./inventory/env/hosts*, then we run a client playbook by
running the following:
```
./bin/kdc-client.sh env host1 host2 host3
```

Note the command and inventory references are relative to the project root.


## Configuration:

  Create an inventory for master/slave KDC consisting of two hosts. The
playbook currently only accounts for one slave KDC.  So for a given inventory
you might have a *hosts* file of the following:
```
[master01]
kdc01

[master02]
kdc02

[masters:children]
master01
master02
```

  The cluster configuration is defined in the inventory *vars* file coupled
with a *vault* file for passwords.  The *vars* define the fqdn of the master
and slave KDC and the Kerberos Realm as follows:
```
---
kdc_master_hostname: 'kdc01.c.mydomain.internal'
kdc_slave_hostname: 'kdc02.c.mydomain.internal'

# property kdc_primary_realm should be lowercase
kdc_primary_realm: 'mydomain.com'

# kerberos_realm is Kerb format in all caps
kerberos_realm: 'MYDOMAIN.COM'

kdc_admin_user: 'adminuser'
kdc_admin_principal: '{{ kdc_admin_user }}/admin'
```

And the corresponding *vault* file:
```
---
kdc_db_password: 'somepassword'
kdc_admin_password: 'somepassword'
```
