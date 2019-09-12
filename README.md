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
