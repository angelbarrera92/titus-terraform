# WIP: titus-terraform
Titus Netflix Container Platform POC


```
terraform init
terraform plan -var public_key=/home/angel/.ssh/id_rsa.pub -var trusted_cidr=2.137.30.82/32
terraform apply -var public_key=/home/angel/.ssh/id_rsa.pub -var trusted_cidr=2.137.30.82/32
```
## TODO
There are some manual steps, such as upload the master and gateway debian (.deb) files and installing it. 
Also, there are some hardcodes on scripts. Those must be changed to templates. 