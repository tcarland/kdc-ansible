KDC-Ansible 
============

Ansible Playbook for installing a pair of MIT KDC's on GCP Instances. 
This assumes ssh passwordless logins have already been configured 
for the instances.

```
ansible-playbook -i inventory/${gcp_inv} kdc-install.yml
```

Clients can be installed via the *./bin/krbclient.sh* script which will 
run the *kdc-client.yml* playbook on a provided list of hosts. The client 
playbook simply installs krb5 client prerequisites and the */etc/krb5.conf* 
file.
