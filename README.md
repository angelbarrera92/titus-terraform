# Titus deployed with terraform
This repository serves as proof of concept for netflix's titus platform.

## What is Titus?
![Titus logo](./assets/titus.png)

>   Titus is a container management platform that provides scalable and reliable container execution and cloud-native integration with Amazon AWS. Titus was built internally at Netflix and is used in production to power Netflix streaming, recommendation, and content systems.

*source of information: [**netflix.github.io/titus**](https://netflix.github.io/titus/)*

## Motivation
You're wondering why the fuck I'm doing this...
Netflix has demonstrated on countless occasions that as an engineering company they are a reference to follow. After seeing [the announcement that Netflix was releasing titus to the open source community](https://medium.com/netflix-techblog/titus-the-netflix-container-management-platform-is-now-open-source-f868c9fb5436), I had no choice but to try the platform that Netflix uses for its product.

After having deployed platforms with Kubernetes and Openshift, I had to try the Netflix platform, titus, based on Mesos.

## Let's get the fuck on with it.
### Disclaimer
The deployment of titus that we are going to test **is not suitable for a productive environment**. This should serve as a proof of concept for understanding the components of Titus.

### What the fuck are we gonna build?
We are going to deploy a minimal infrastructure using terraform. The component diagram will look like this:

![Titus Diagram](./assets/aws-diagram.png)


The infrastructure shall contain the following components:

#### EC2
- **Bastion:** It will be our entry point to the Titus platform. We'll use it as a jump host to get to the rest of the nodes. This will be the only machine exposed to the internet *(public subnet)*.
- **Titus prereqs**: This machine contains the requirements set out in [the titus documentation](https://netflix.github.io/titus/install/prereqs/). In this machine are deployed the service of Mesos (master) and Zookeeper (1 single node). To orient the deployment to an environment closer to production, a zookeeper cluster should be created in 3 different availability zones of at least 3 nodes. You must also separate the mesos node and try to deploy it in high availability.
- **Titus Master**: This machine deploys the debian package relative to the titus master. To facilitate the deployment of this infrastructure, the git project containing the titus master was compiled locally and the resulting debian package is uploaded to this same repository under the [deb folder](./deb). Compiled tag: [v0.1.0-rc.57](https://github.com/Netflix/titus-control-plane/tree/v0.1.0-rc.57). [The instructions in the titus manual](https://netflix.github.io/titus/install/master/) have been followed to lift the master. Although to run the binary I use systemd instead of launching the binary by hand.
- **Titus Gateway**: This machine deploys the debian package relative to the titus gateway. To facilitate the deployment of this infrastructure, the git project containing the titus gateway was compiled locally  and the resulting debian package is uploaded to this same repository under the [deb folder](./deb). Compiled tag: [v0.1.0-rc.57](https://github.com/Netflix/titus-control-plane/tree/v0.1.0-rc.57). [The instructions in the titus manual](https://netflix.github.io/titus/install/master/) have been followed to lift the gateway. Although to run the binary I use systemd instead of launching the binary by hand.



#WIP...
```
terraform init
terraform plan -var public_key=/home/angel/.ssh/id_rsa.pub -var trusted_cidr=2.137.30.82/32
terraform apply -var public_key=/home/angel/.ssh/id_rsa.pub -var trusted_cidr=2.137.30.82/32
```
## TODO
There are some manual steps, such as upload the master and gateway debian (.deb) files and installing it.