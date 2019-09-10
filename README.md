KDC-Ansible v0.1.3
==================

Ansible Playbook for installing a pair of MIT KDC's on GCP Instances. 
This assumes ssh passwordless logins have already been configured 
for the instances.

```
ansible-playbook -i inventory/${gcp_inv} kdc-install.yml
```

