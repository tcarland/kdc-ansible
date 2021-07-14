KDC-Ansible
============

An Ansible Playbook for installing a pair of MIT KDC's configured and
replicating. This assumes ssh key logins have already been configured 
for the hosts, or at least from the Ansible server to both KDC servers 
or from the primary to the secondary instance if this playbook is to be 
run from the master.

The playbooks currently support the following distributions:
- rhel7.x
- centos7.x
- ubuntu 20.04 (or debian equivalent)


## Running the Playbook:

A script is provided to simplify execution of the main playbook `kdc-site.yml`.
```
$ ./bin/kdc-install.sh [inventory_name|env]
```

Which is equivalent to the ansible command:
```
$ ansible-playbook -i inventory/${env}/hosts kdc-site.yml
```

Clients can be installed with the *./bin/kdc-clients.sh* script which will
run the *kdc-clients.yml* playbook on a provided list of hosts. The client
playbook directly installs krb5 client prerequisites and the */etc/krb5.conf*
file.

Given an inventory name of *myenv*, as in *./inventory/myenv/hosts*, then 
the client playbook can be applied by running the following:
```
./bin/kdc-client.sh myenv host1 host2 host3
```

Note the command and inventory references above are relative to the project root.


## Configuration:

Create an inventory for a KDC pair (two hosts to run in a master/slave 
configuration, referred to as `primary` and `secondary` from here out. 
The playbook currently only accounts for a single secondary KDC.  
For a given inventory you might have a *hosts* file of the following:
```
[primary]
kdc01

[secondary]
kdc02

[kdc:children]
primary
secondary

[clients]
```

  The cluster configuration is defined in the inventory *vars* file coupled
with a *vault* file for passwords.  The *vars* define the *fqdn* of the KDCs 
and the Kerberos Realm as follows:
```yaml
---
kdc_primary_hostname: 'kdc01.c.mydomain.internal'
kdc_secondary_hostname: 'kdc02.c.mydomain.internal'

# property kdc_primary_realm should be lowercase
kdc_primary_realm: 'mydomain.com'

# kerberos_realm is in the Kerb format in all caps
kerberos_realm: 'MYDOMAIN.COM'

kdc_admin_user: 'adminuser'
kdc_admin_principal: '{{ kdc_admin_user }}/admin'
```

A corresponding *vault* file defines the KDC secrets:
```yaml
---
kdc_db_password: 'somepassword'
kdc_admin_password: 'somepassword'
```

### Install Notes 

- **kprop decrypt integrity check failed**:  
  On re-deployments, there can be issues setting the host keytab in
`/etc/krb5.keytab`. If attempting to re-deploy with a fresh database,
pre-existing keytab files can cause kprop to fail. Remove any pre-existing
host keytab files prior to a fresh install.

- TODO: Add some uninstall notes

<br>

---
## KDC Usage:

- Add a new admin principal
  ```
  MYPW="mytmppw"
  USERNAME="adminuser"
  ank +needchange -pw $TMPPW  $USERNAME/admin
  ```

- Add a new host to realm.
  From the primary host, add the host principal.
  ```
  ank -randkey host/fqdn@REALM
  ```

- Add the host entry to a keytab either by running `kadmin -q ktadd principal` 
  on the host to create the keytab in the standard location of `/etc/krb5.keytab`.  
  From a master use `-k` to output a keytab file.
  ```
  ktadd -k host.keytab host/fqdn@REALM
  ```

- Create a new database:
  ```
  kdb5_util create -s
  ```

- Destroy a database:
  ```
  kdb5_util destroy
  ```

- Change the Password for a Principal
  ```
  kadmin.local:  cpw user@REALM.COM
  Enter password for principal "user@REALM.COM":
  Re-enter password for principal "user@REALM.COM":
  Password for "user@REALM.COM" changed.
  ```

- Change password via kpasswd
  ```
  [root@admin ~]# kpasswd tca
  Password for tca@REALM.COM:
  Enter new password:
  Enter it again:
  ```

- Delete a Principal
  ```
  kadmin.local:  delete_principal testuser
  Are you sure you want to delete the principal "testuser@REALM.COM"? (yes/no): yes
  Principal "testuser@REALM.COM" deleted.
  Make sure that you have removed this principal from all ACLs before reusing.
  ```

- Create a Policy
  ```
  kadmin.local:  add_policy -minlength 1 -minlength 5 -maxlife "999 days" -maxfailure 3 testpolicy
  ```

- List policies
  ```
  kadmin.local:  list_policies
  testpolicy
  ```

- Modify a Principal to use a Policy
  ```
  kadmin.local:  modify_principal -policy testpolicy tca2
  Principal "tca2@REALM.COM" modified.
  ```

- Unlock a Principal
  ```
  kadmin.local:  modify_principal -unlock tca2
  Principal "tca2@REALM.COM" modified.
  ```

- Modify a Policy
  ```
  kadmin.local:  modify_policy -minlength 3 testpolicy
  ```

- Viewing a Kerberos Policy's Attributes
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

- Add Principals to a Keytab
  ```
  kadmin.local:  ktadd -norandkey -k /tmp/tmp.keytab tca2@REALM.COM
  Entry for principal tca2@REALM.COM with kvno 1, encryption type aes256-cts-hmac-sha1-96 added to keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1, encryption type aes128-cts-hmac-sha1-96 added to keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1, encryption type des3-cbc-sha1 added to keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1, encryption type arcfour-hmac added to keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1, encryption type des-hmac-sha1 added to keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1, encryption type des-cbc-md5 added to keytab WRFILE:/tmp/tmp.keytab.
  ```

- Display Keylist (Principals) in a Keytab File
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

- Remove Keylist(Principal) from a Keytab File
  ```
  kadmin.local:  ktremove -k /tmp/tmp.keytab tca2@REALM.COM
  Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
  Entry for principal tca2@REALM.COM with kvno 1 removed from keytab WRFILE:/tmp/tmp.keytab.
  ```

- Authentication using Keytab
  ```
  kinit -kt /etc/security/phd/keytab/hdfs.service.keytab hdfs/hdm.xxx.com@REALM.COM
  ```

<br>

---

## KDC Configuration - Primary/Secondary (aka. master/slave) 

This section describes the general process performed by Ansible. The 
Kerberos Database is a file that gets replicated to the secondary host.
The primary KDC first creates a database, an admin principal, and two 
host principals for our primary and secondary KDC Servers.

The examples below show `$kdc_secondary_hostname` as a variable, such as:
```
kdc_secondary_hostname="kdc02.mycluster.internal"
REALM="MYDOMAIN.COM"
```

### Primary KDC Server

- Create KDC Database:
  ```
  /usr/sbin/kdb5_util create -s -P <passwd>
  ```

- Add an Admin Principal
  ```
  kadmin.local -q "addprinc myuser/admin
  ```

- Add a Host Principal and Keytab
  ```
  ktadmin.local -q "addprinc -randkey host/$(hostname -f)"
  kadmin.local -q "ktadd host/$(hostname -f)@REALM.COM"
  ```

- Add a Host Principal for the secondary KDC server on primary
  ```
  kadmin.local -q "addprinc -randkey host/$kdc_secondary_hostname"
  ```

- Start the services
  ```
  systemctl enable krb5kdc && systemctl start krb5kdc
  systemctl enable kadmin && systemctl start kadmin
  ```

### Secondary KDC Server

For automation purposes, it is easier to run *create* on the db file 
to seed the `.k5.REALM stash file rather than to acquire and distribute. 
As long as the same password is used as the primary and kadmin is not 
yet started on the secondary, the db propagation will properly overwrite 
the db.

- Create the KDC Database
  ```
  /usr/sbin/kdb5_util create -s -P <pw>
  ```

- Acquire the host key from the primary KDC. Note the use of `kadmin` instead 
  of `kadmin.local` which would connect to the secondary and not the primary.
  ```
  kadmin -p tca/admin -q "ktadd host/$kdc_secondary_hostname@REALM.COM"
  ```

- Start kpropd only.
  ```
  systemctl enable kprop && systemctl start kprop
  ```

### Propogate Primary KDC DB to Secondary 

- Run a dump on the primary.
  ```
  kdb5_util dump /var/kerberos/krb5kdc/kdb_datatrans
  ```

- Send to secondary:
  ```
  kprop -f /var/kerberos/krb5kdc/kdb_datatrans $kdc_secondary_hostname"
  ```

- On success of DB propagation, start the secondary KDC.
  ```
  systemctl enable krb5kdc && systemctl start krb5kdc
  ```

- Setup a crontab job to run the dump and kprop commands regularly.
  ```
  $ echo "*/5 * * * * /sbin/kdb5_util dump /var/kerberos/krb5kdc/kdb_datatrans && \
  /sbin/kprop -f /var/kerberos/krb5kdc/kdb_datatrans $kdc_secondary_hostname 2>&1 >/dev/null" > kprop.crontab
  $ crontab kprop.crontab
  ```

### Automating the Creation of New Kerberos Principals

You can use the kadmin.local command in a script to automate the creation of new  
Principals. This is useful when you want to add many new principals to the 
database.

The following shell script line shows the creation of new principals:

```
awk '{ print "ank +needchange -pw", $2, $1 }' < /tmp/princnames | \
time /usr/sbin/kadmin.local> /dev/null
```

This reads in a file named `princnames`. The file contains principal names 
and their passwords, and adds them to the Kerberos database. The file would 
contain a principal and the respective password as a spece delimited pair on 
one line.

 - The `ank` command *adds a new key*, and `ank` is an alias for the 
  `add_principal` command.

 - The `+needchange` option configures the principal so that the end user is 
  prompted for a new password at first login.

 - Requiring a password change helps to ensure that the passwords set in the 
  `princnames` file are not such a security risk.
