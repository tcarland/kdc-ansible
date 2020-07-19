KDC-Ansible
============

Ansible Playbook for installing a pair of MIT KDC's configured and replicating.
This assumes ssh key logins have already been configured for the hosts, or at
least from the Ansible server to both KDC servers or from the master to the
slave instance if this playbook is to be run from the master.

The playbooks currently function with RHEL or CentOS flavors of Linux.


## Running the Playbook:

A script is provided to simplify execution of the main playbook `kdc-site.yml`.
```
$ ./bin/kdc-install.sh [inventory_name|env]
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
with a *vault* file for passwords.  The *vars* define the *fqdn* of the master
and slave KDCs and the Kerberos Realm as follows:
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

Caveat:

**kprop decrypt integrity check failed**:  
  On re-deployments, there can be issues setting the host keytab in
`/etc/krb5.keytab`. If attempting to re-deploy with a fresh database,
pre-existing keytab files can cause kprop to fail. Remove any pre-existing
host keytab files prior to a fresh install.


KDC usage:

Add a new admin principal
```
MYPW="mytmppw"
USERNAME="adminuser"
ank +needchange -pw $TMPPW  $USERNAME/admin
```

Add a new host to realm.
From master add the host principal.
```
ank -randkey host/fqdn@REALM
```
Add the host entry to a keytab either by running
`kadmin -q ktadd principal` on the host to create the keytab in the
standard location of `/etc/krb5.keytab`.  From a master use `-k` to output
a keytab file.
```
ktadd -k host.keytab host/fqdn@REALM
```

Create a new database:
```
kdb5_util create -s
```

Destroy a database:
```
kdb5_util destroy
```

Change the Password for a Principal
```
kadmin.local:  cpw user@REALM.COM
Enter password for principal "user@REALM.COM":
Re-enter password for principal "user@REALM.COM":
Password for "user@REALM.COM" changed.
```

Change password via kpasswd
```
[root@admin ~]# kpasswd tca
Password for tca@REALM.COM:
Enter new password:
Enter it again:
```

Delete a Principal
```
kadmin.local:  delete_principal testuser
Are you sure you want to delete the principal "testuser@REALM.COM"? (yes/no): yes
Principal "testuser@REALM.COM" deleted.
Make sure that you have removed this principal from all ACLs before reusing.
```

Create a Policy
```
kadmin.local:  add_policy -minlength 1 -minlength 5 -maxlife "999 days" -maxfailure 3 testpolicy
```

List policies
```
kadmin.local:  list_policies
testpolicy
```

Modify a Principal to use a Policy
```
kadmin.local:  modify_principal -policy testpolicy tca2
Principal "tca2@REALM.COM" modified.
```

Unlock a Principal
```
kadmin.local:  modify_principal -unlock tca2
Principal "tca2@REALM.COM" modified.
```

Modify a Policy
```
kadmin.local:  modify_policy -minlength 3 testpolicy
```

Viewing a Kerberos Policy's Attributes
```
kadmin.local:  get_policy testpolicy
Policy: testpolicy
Maximum password life: 86313600
Minimum password life: 0
Minimum password length: 3
Minimum number of password character classes: 1
Number of old keys kept: 1
Reference count: 0
Maximum password failures before lockout: 3
Password failure count reset interval: 0 days 00:00:00
Password lockout duration: 0 days 00:00:00
Delete a Policy
kadmin.local:  delete_policy testpolicy
```

Add Principals to a Keytab
```
kadmin.local:  ktadd -norandkey -k /tmp/tmp.keytab tca2@REALM.COM
Entry for principal tca2@REALM.COM with kvno 1, encryption type aes256-cts-hmac-sha1-96 added to keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1, encryption type aes128-cts-hmac-sha1-96 added to keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1, encryption type des3-cbc-sha1 added to keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1, encryption type arcfour-hmac added to keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1, encryption type des-hmac-sha1 added to keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1, encryption type des-cbc-md5 added to keytab WRFILE:/tmp/tmp.keytab.
```

Display Keylist (Principals) in a Keytab File
```
[root@admin ~]# klist -kt /tmp/tmp.keytab
Keytab name: FILE:/tmp/tmp.keytab
KVNO Timestamp         Principal
---- ----------------- --------------------------------------------------------
   1 06/10/14 22:08:00 tca2@REALM.COM
   1 06/10/14 22:08:00 tca2@REALM.COM
   1 06/10/14 22:08:00 tca2@REALM.COM
   1 06/10/14 22:08:00 tca2@REALM.COM
   1 06/10/14 22:08:00 tca2@REALM.COM
   1 06/10/14 22:08:00 tca2@REALM.COM
```

Remove Keylist(Principal) from a Keytab File
```
kadmin.local:  ktremove -k /tmp/tmp.keytab tca2@REALM.COM
Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
```

Authentication using Keytab
```
kinit -kt /etc/security/phd/keytab/hdfs.service.keytab hdfs/hdm.xxx.com@REALM.COM
```
