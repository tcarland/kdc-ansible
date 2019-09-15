KDC-Ansible 
============

Ansible Playbook for installing a pair of MIT KDC's on GCP. 
This assumes ssh passwordless logins have already been configured 
for the instances.

```
gcp_env="di-trace3-west1"

$ ./bin/kdc-install.sh $gcp_env
 
   #  or the equivelant
$ ansible-playbook -i inventory/${gcp_env} kdc-install.yml
```

Clients can be installed via the *./bin/krb_client.sh* script which will 
run the *kdc-client.yml* playbook on a provided list of hosts. The client 
playbook simply installs krb5 client prerequisites and the */etc/krb5.conf* 
file.


Configure:

  Create an inventory for master/slave KDC consisting of two hosts. The playbook 
currently only accounts for one slave KDC.  So for inventory 'foo' you might have 
hosts file of the following:
```
[master01]
kdc01

[master02]
kdc02

[masters:children]
master01
master02
```

  The cluster configuration is defined in the inventory vars file coupled with 
a *vault* file for passwords.  The *vars* also define the fqdn of the master and
slave KDC as follows:
```
---
kdc_master_hostname: 'kdc01.c.mydomain.internal'
kdc_slave_hostname: 'kdc02.c.mydomain.internal'

# kdc_primary_realm should be lowercase
kdc_primary_realm: 'mydomain.com'
# kerberos_realm is Kerb format of all caps
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

