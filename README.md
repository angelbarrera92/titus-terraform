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
- **Titus Agent**: Titus agents or slaves are EC2 machines that must be deployed in an autoscalling group. [The instructions in the titus manual](https://netflix.github.io/titus/install/agent/) have been followed to lift the agent. In the documentation it is described that the file `/etc/mesos-attributes.sh` must be modified to configure it with the data of the machine resources that have been chosen. In this proof of concept we have chosen T2.large instances. To find out how many ENIs and EIPs can be associated with the type of machine selected, you must visit the official [AWS documentation.](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html). In this example: `ResourceSet-ENIs-3-12` *(3 ENIS and 12 EIPs)*.

#### IAM
Following the netflix tutorial, three IAM roles are created. one of them will be for the instances that run containers and the other two will be roles that the containers will assume.
The role of the instances, in this proof of concept, has administrator permission *(not suitable for production)*. The other two roles (`titusappwiths3InstanceProfile` and `titusappnos3InstanceProfile`) have administrator permissions on S3 (`titusappwiths3InstanceProfile`) and the other on EC2 (`titusappnos3InstanceProfile`).
***This feature has not been tested in this proof of concept.***

The role ARN that appears on the terraform output is the one with administrator privileges over S3 (`titusappwiths3InstanceProfile`).

#### Security Groups
As far as the security groups are concerned, [the netflix documentation](https://netflix.github.io/titus/install/prereqs-amazon/) has been fully followed. It has only been customized to be able to parameterize the reliable IP of the bastion at the entrance of port 22. Also, as the [documentation indicates]((https://netflix.github.io/titus/install/prereqs-amazon/)), the security group called `titusapp` has been customized for the specific use case. In this case you have been given complete freedom from outgoing and only incoming connections from the bastion node using port 22. The security group identifier `titusapp` is displayed on the terraform output.


# WIP...
```
terraform init
terraform plan -var public_key=/home/angel/.ssh/id_rsa.pub -var trusted_cidr=2.137.30.82/32
terraform apply -var public_key=/home/angel/.ssh/id_rsa.pub -var trusted_cidr=2.137.30.82/32
```



## Problems encountered
During the construction of this proof of concept, several problems have been encountered. Luckily, the titus development team has exposed a [public slack channel](https://titusoss.herokuapp.com/) where I found personalized help ;)

### Metatron
Once the infrastructure was set up, launching a sample job would cause an error in the logs of the mesos agent:

```bash
cat /var/lib/mesos/slaves/64b1f518-f8d6-4f21-8d4f-39360b8f12f2-S0/frameworks/TitusFramework/executors/docker-executor/runs/latest
Cannot create Titus executor: Failed to initialize Metatron trust store: lstat /metatron: no such file or directory
```

The titus development team mentioned a possible solution to me. Create the file `/etc/profile.d/titus_environment.sh` in the agent whose content was: `METATRON_ENABLED=false`
This didn't work or not at all. The solution, rudimentary, I found in desperation: `touch /metatron`. This solution is implemented in the [initialization script of mesos agents](./scripts/cloud-init-agent.yml.tpl) so this error should not occur again.

### instanceGroups activation
Again, when we tried to start a job, we found that it did not start the job. But again, the Netflix team referred me to more (somewhat fragmented???) [documentation](https://github.com/Netflix/titus-control-plane).

> By default, all titus-agent containers will join a cluster named unknown-instanceGroup. Before any tasks can be scheduled, that cluster needs to be activated. Note that this is necessary every time the Titus master is restarted, since instanceGroup state is not being persisted:

So you must launch that request to the api rest, important, from the titus gateway node. If you have used the default variables of this terraform project, the request will be:

```bash
curl localhost:7001/api/v3/agent/instanceGroups/titusagent/lifecycle \
  -X PUT -H "Content-type: application/json" -d \
  '{"instanceGroupId": "titusagent", "lifecycleState": "Active"}'
```

*Note: replace `titusagent` if you change the default variables*

### Job examples
Well, once the group of instances of the mesos agents is activated, we proceed to follow the [titus tutorial](https://netflix.github.io/titus/test/batch/) to launch a job.

A new problem arises, the examples are written for the API in version 2. But this version of the API is disabled, with version 3 being the active version. *(data provided by netflix engineers @ [slack](https://titusoss.herokuapp.com/))*. So again, we must go to [other documentation](https://github.com/Netflix/titus-control-plane) to look for a valid example *(api version 3)*.

## Documentation to have on the radar
- https://queue.acm.org/detail.cfm?id=3158370
- https://medium.com/netflix-techblog/titus-the-netflix-container-management-platform-is-now-open-source-f868c9fb5436
- https://www.youtube.com/watch?v=ySdqDGfEOHo
- https://www.youtube.com/watch?v=4OLlKGT7aVQ *(fully recommended)*
- https://www.youtube.com/watch?v=6QLMvBkJtOU
- https://www.infoq.com/news/2018/04/titus-container-platform
- https://github.com/Netflix/titus-control-plane
- https://github.com/Netflix/titus-api-definitions/blob/master/doc/titus-v3-spec.md


## TODO
There are some manual steps, such as upload the master and gateway debian (.deb) files and installing it.