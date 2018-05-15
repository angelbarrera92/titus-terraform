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
- **Titus Agent**: Titus agents or slaves are EC2 machines that must be deployed in an autoscalling group. [The instructions in the titus manual](https://netflix.github.io/titus/install/agent/) have been followed to lift the agent. In the documentation it is described that the file `/etc/mesos-attributes.sh` must be modified to configure it with the data of the machine resources that have been chosen. In this proof of concept we have chosen ~~T2.large~~ m4.large instances. To find out how many ENIs and EIPs can be associated with the type of machine selected, you must visit the official [AWS documentation.](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html). In this example: `ResourceSet-ENIs-3-12` *(3 ENIS and 12 EIPs)*.

#### IAM
Following the netflix tutorial, three IAM roles are created. one of them will be for the instances that run containers and the other two will be roles that the containers will assume.
The role of the instances, in this proof of concept, has administrator permission *(not suitable for production)*. The other two roles (`titusappwiths3InstanceProfile` and `titusappnos3InstanceProfile`) have administrator permissions on S3 (`titusappwiths3InstanceProfile`) and the other on EC2 (`titusappnos3InstanceProfile`).
***This feature has not been tested in this proof of concept.***

The role ARN that appears on the terraform output is the one with administrator privileges over S3 (`titusappwiths3InstanceProfile`).

#### S3 Bucket
One of the failures suffered during the testing of this orchestrator was the absence of an S3 bucket. So a bucket is created that is supposed to be used for log storage.

**Please, attention, be careful**. The names of the buckets are unique globally, so it is strongly recommended to change the value of the variable (`s3_log_bucket_nam`). By default the value is: `titus-log-bucket-terraform-example`.

#### Security Groups
As far as the security groups are concerned, [the netflix documentation](https://netflix.github.io/titus/install/prereqs-amazon/) has been fully followed. It has only been customized to be able to parameterize the reliable IP of the bastion at the entrance of port 22. Also, as the [documentation indicates]((https://netflix.github.io/titus/install/prereqs-amazon/)), the security group called `titusapp` has been customized for the specific use case. In this case you have been given complete freedom from outgoing and only incoming connections from the bastion node using port 22 and 80. The security group identifier `titusapp` is displayed on the terraform output.

## Fuck, stop writing and tell me how to execute it.
As requirements, we need to have an amazon account available with enough permissions to create such a cluster, and have terraform installed on our PCs *(jq is needed also)*.
Then, we cloned this wonderful repository and initiated terraform:
```
$ git clone https://github.com/angelbarrera92/titus-terraform.git && cd titus-terraform
$ terraform init
```
Now the party begins....
```bash
$ terraform plan -var public_key=~/.ssh/id_rsa.pub -var trusted_cidr=`curl -s ifconfig.co`/32
...
Plan: 36 to add, 0 to change, 0 to destroy.
...
$ terraform apply -auto-approve -var public_key=~/.ssh/id_rsa.pub -var trusted_cidr=`curl -s ifconfig.co`/32
...
Apply complete! Resources: 36 added, 0 changed, 0 destroyed.

Outputs:

agent_asg_name = titusagent
bastion_ip = 34.245.<PRIVATE>
default_role_arn = arn:aws:iam::<PRIVATE>:role/titusappwiths3InstanceProfile
default_sg_id = sg-<PRIVATE>
gateway_ip = 30.0.100.130
master_ip = 30.0.100.24
prereqs_ip = 30.0.100.194
vpc_id = vpc-<PRIVATE>
...
$ aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=titusagent" "Name=instance-state-name,Values=running" | jq -r .Reservations[].Instances[].PrivateIpAddress
30.0.100.140
```
Now you will have all the data to start playing.

### Set up your ssh connection
We're going to use the bastion as a jump host. This is why we will configure it in our ssh connection configuration file. If you look, all connections to IPs 30.0.* will go against the jump settings.

```bash
$ cat ~/.ssh/config
Host 30.0.*
    User ubuntu
    ProxyCommand ssh ubuntu@34.245.<PRIVATE> nc %h %p
```
*Be careful not to get into conflict with any of your ssh settings.*

### Let's make sure everything's up.
#### prereqs Machine
First we must go to the prerequisite machine:
```
$ ssh `terraform output prereqs_ip`
ubuntu@ip-30-0-100-194:~$ docker ps
CONTAINER ID        IMAGE                                             COMMAND                  CREATED             STATUS              PORTS                                        NAMES
758a742b4308        mesosphere/mesos-master:1.0.1-2.0.93.ubuntu1404   "mesos-master mesos-…"   15 seconds ago      Up 14 seconds                                                    mesomaster
72a3d170f460        jplock/zookeeper:3.4.10                           "/opt/zookeeper/bin/…"   38 seconds ago      Up 38 seconds       2888/tcp, 0.0.0.0:2181->2181/tcp, 3888/tcp   zookeeper
```
And we must check that the docker daemon is working and two containers are up, `mesos master` and a `zookeeper`.

#### titus master
Now we must go to the titus master node and check that the service is alive:
```
$ ssh `terraform output master_ip`
ubuntu@ip-30-0-100-24:~$ service titus-server-master status
● titus-server-master.service - Titus Master
   Loaded: loaded (/lib/systemd/system/titus-server-master.service; enabled; vendor preset: enabled)
   Active: active (running)
```
We can check that the service is marked as active

#### titus gateway
We'll check the status of the api gateway.
```
$ ssh `terraform output gateway_ip`
ubuntu@ip-30-0-100-130:~$ service titus-server-gateway status
● titus-server-gateway.service - Titus Gateway
   Loaded: loaded (/lib/systemd/system/titus-server-gateway.service; enabled; vendor preset: enabled)
   Active: active (running)
```
We can check that the service is marked as active. We'll be back to this node soon.

#### titus agent
Finally, we will check the condition of the slave.
```
$ ssh `aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=titusagent" "Name=instance-state-name,Values=running" | jq -r .Reservations[].Instances[].PrivateIpAddress`
ubuntu@ip-30-0-100-140:~$ service mesos-agent status
● mesos-agent.service - Mesos
   Loaded: loaded (/lib/systemd/system/mesos-agent.service; enabled; vendor preset: enabled)
   Active: active (running)
```

We can check that the service is marked as active. We'll be back to this node soon.

### The game begins
We get inside the gateway node:
```
$ ssh `terraform output gateway_ip`
```
And we execute the following request to the api:
```
ubuntu@ip-30-0-100-130:~$ curl localhost:7001/api/v3/agent/instanceGroups/titusagent/lifecycle \
  -X PUT -H "Content-type: application/json" -d \
  '{"instanceGroupId": "titusagent", "lifecycleState": "Active"}'
```
This request indicates that our autoscalling group is ready to receive jobs. we can check the state of it:
```
ubuntu@ip-30-0-100-130:~$ curl localhost:7001/api/v3/agent/instanceGroups/titusagent
{
  "id": "titusagent",
  "instanceType": "m4.large",
  "instanceResources": {
    "cpu": 0,
    "gpu": 0,
    "memoryMB": 0,
    "diskMB": 0,
    "networkMbps": 0
  },
  "tier": "Flex",
  "min": 0,
  "desired": 1,
  "current": 1,
  "max": 1,
  "isLaunchEnabled": false,
  "isTerminateEnabled": false,
  "autoScaleRule": {
    "min": 0,
    "max": 1000,
    "minIdleToKeep": 2,
    "maxIdleToKeep": 5,
    "coolDownSec": "600",
    "priority": 100,
    "shortfallAdjustingFactor": 8
  },
  "lifecycleStatus": {
    "state": "Active",
    "detail": "",
    "timestamp": "1526381441646"
  },
  "launchTimestamp": "1526381441646",
  "attributes": {
  }
}
```

Now we'll launch an example job. ***Please replace the <PRIVATE> values with your real values.***
```
ubuntu@ip-30-0-100-130:~$ curl localhost:7001/api/v3/jobs \
  -X POST -H "Content-type: application/json" -d \
  '{
    "applicationName": "localtest",
    "owner": {"teamEmail": "me@me.com"},
    "container": {
      "image": {"name": "alpine", "tag": "latest"},
      "entryPoint": ["/bin/sleep", "1h"],
      "securityProfile": {"iamRole": "arn:aws:iam::<PRIVATE>:role/titusappwiths3InstanceProfile", "securityGroups": ["sg-<PRIVATE>"]}
    },
    "batch": {
      "size": 1,
      "runtimeLimitSec": "3600",
      "retryPolicy":{"delayed": {"delayMs": "1000", "retries": 3}}
    }
  }'
```
Now we must go to the only slave we have and check that there is a docker container running.
```
$ ssh `aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=titusagent" "Name=instance-state-name,Values=running" | jq -r .Reservations[].Instances[].PrivateIpAddress`
ubuntu@ip-30-0-100-140:~$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
ba08bde76fdf        alpine:latest       "/bin/sleep 1h"     57 seconds ago      Up 56 seconds                           57bf28b1-8393-4afb-900e-33e371e92b50
```
And effectively, we have a docker container running. **We have tested the deployment of a job on the Netflix infrastructure, titus.**

### The game continues, nginx service example

After trying out jobs, I talked to the guys on the titus team to see how to launch services. After several attempts *(errors described below)*, I was finally able to deploy a basic nginx and check that it works perfectly. I also wanted to test the aws metadata service proxy *(role and permissions isolation)*.
In order to do that:
We get inside the gateway node:
```
$ ssh `terraform output gateway_ip`
```
Now we'll launch an example job service. ***Please replace the <PRIVATE> values with your real values.***
```
ubuntu@ip-30-0-100-130:~$ curl localhost:7001/api/v3/jobs \
  -X POST -H "Content-type: application/json" -d \
'{
  "owner": {
    "teamEmail": "me@example.com"
  },
  "applicationName": "myServiceApp",
  "capacityGroup": "myServiceApp",
  "jobGroupInfo": {
    "stack": "myStack",
    "detail": "detail",
    "sequence": "002"
  },
  "attributes": {
    "key1": "value1"
  },
  "container": {
    "resources": {
      "cpu": 1.0,
      "memoryMB": 128,
      "diskMB": 100,
      "networkMbps": 128,
      "allocateIP": true
    },
    "securityProfile": {
      "securityGroups": [
        "sg-<PRIVATE>"
      ],
      "iamRole": "arn:aws:iam::<PRIVATE>:role/titusappwiths3InstanceProfile"
    },
    "image": {
      "name": "tutum/nginx",
      "tag": "latest"
    },
    "env": {
      "MY_ENV": "myEnv"
    },
    "softConstraints": {
      "constraints": {
        "UniqueHost": "true",
        "ZoneBalance": "true"
      }
    },
    "hardConstraints": {}
  },
  "service": {
    "capacity": {
      "min": 1,
      "max": 1,
      "desired": 1
    },
    "enabled": true,
    "retryPolicy": {
      "delayed": {
        "delayMs": "1000"
      }
    },
    "migrationPolicy": {
      "selfManaged": {}
    }
  }
}'
```
As we can see, the description of a service is somewhat different from that of a job **although the API address is the same**.

Now we must go to the only slave we have and check that there is a docker container running.
```
$ ssh `aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=titusagent" "Name=instance-state-name,Values=running" | jq -r .Reservations[].Instances[].PrivateIpAddress`
ubuntu@ip-30-0-100-140:~$ docker ps
CONTAINER ID        IMAGE                COMMAND             CREATED             STATUS              PORTS               NAMES
09da68238ce0        tutum/nginx:latest   "/usr/sbin/nginx"   24 minutes ago      Up 24 minutes                           8ad0dccc-657f-419a-b67e-33f886aee567
```
To test the service we need to get the new ip from the network interface that the titus vpc driver has created. With the container identifier we can execute the following command:
```
ubuntu@ip-30-0-100-140:~$ docker inspect 09da68238ce0 | jq -r '.[0].Config.Labels."titus.vpc.ipv4"'
30.0.100.55
```
It is in this ip where our nginx is available. The security group that we have created, titusapp, which is the one that has been configured when launching the service, allows access to port 80 from the bastion. So we must go to the bastion and invoke that IP:

```
$ ssh ubuntu@`terraform output bastion_ip`
ubuntu@ip-30-0-1-14:~$ curl 30.0.100.55
<html>
<head>
    <title>Hello world!</title>
    <style>
    body {
        background-color: white;
        text-align: center;
        padding: 50px;
        font-family: "Open Sans","Helvetica Neue",Helvetica,Arial,sans-serif;
    }

    #logo {
        margin-bottom: 40px;
    }
    </style>
</head>
<body>
    <a href="http://tutum.co/"><img id="logo" src="logo.png" /></a>
    <h1>Hello world!</h1>
</body>
</html>
```
With this test we can verify that the service has been deployed perfectly. **We have tested the deployment of a service job on the Netflix infrastructure, titus.**

### Bonus track. Test roles at nginx service
If we go back to the titus slave where the nginx is running and we access the container we will be able to verify that it complies with the permissions that we have set at the time of deploying this service. To refresh your memory, the container should only have access to the amazon S3 service. Any request to another service should be refused (e.g. EC2).

```
$ ssh `aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=titusagent" "Name=instance-state-name,Values=running" | jq -r .Reservations[].Instances[].PrivateIpAddress`
ubuntu@ip-30-0-100-140:~$ docker ps
CONTAINER ID        IMAGE                COMMAND             CREATED             STATUS              PORTS               NAMES
09da68238ce0        tutum/nginx:latest   "/usr/sbin/nginx"   24 minutes ago      Up 24 minutes                           8ad0dccc-657f-419a-b67e-33f886aee567
ubuntu@ip-30-0-100-140:~$ docker exec -it 09da68238ce0 /bin/bash
root@8ad0dccc-657f-419a-b67e-33f886aee567:/# apt-get update && apt-get install curl
root@8ad0dccc-657f-419a-b67e-33f886aee567:/# curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
root@8ad0dccc-657f-419a-b67e-33f886aee567:/# python3 get-pip.py
root@8ad0dccc-657f-419a-b67e-33f886aee567:/# pip install awscli
root@8ad0dccc-657f-419a-b67e-33f886aee567:/# aws s3 ls
2018-05-15 10:31:08 titus-log-bucket-terraform-example
root@8ad0dccc-657f-419a-b67e-33f886aee567:/# aws ec2 describe-instances --filters Name=network-interface.vpc-id,Values=vpc-<PRIVATE> --region eu-west-1

An error occurred (UnauthorizedOperation) when calling the DescribeInstances operation: You are not authorized to perform this operation.
```
In this script, we installed curl, pip and awscli and ran a couple of AWS API queries. We see how the query to the S3 service works perfectly, while the EC2 service returns a result of lack of permissions.

If we leave the container and run these same commands on the slave, the slave must allow both queries since the slave uses a different role *(which in this case has permission for ALL)*.
```bash
root@8ad0dccc-657f-419a-b67e-33f886aee567:/# exit
ubuntu@ip-30-0-100-140:~$ aws s3 ls
2018-05-15 10:31:08 titus-log-bucket-terraform-example
ubuntu@ip-30-0-100-140:~$ aws ec2 describe-instances --filters Name=network-interface.vpc-id,Values=vpc-<PRIVATE> --region eu-west-1 | grep titus
                    "KeyName": "titus_deployer",
                            "GroupName": "titusmaster-mainvpc"
                                    "GroupName": "titusmaster-mainvpc"
                    "KeyName": "titus_deployer",
                            "GroupName": "titusmaster-mainvpc"
                                    "GroupName": "titusmaster-mainvpc"
                                    "GroupName": "titusapp"
                            "Description": "titus-managed",
                            "Value": "titusagent",
                        "Arn": "arn:aws:iam::<PRIVATE>:instance-profile/titusmasterInstanceProfile",
                    "KeyName": "titus_deployer",
                            "GroupName": "titusmaster-mainvpc"
                                    "GroupName": "titusmaster-mainvpc"
                        "Arn": "arn:aws:iam::<PRIVATE>:instance-profile/titusmasterInstanceProfile",
                    "KeyName": "titus_deployer",
                            "GroupName": "titusbastion"
                                    "GroupName": "titusbastion"
                    "KeyName": "titus_deployer",
                            "GroupName": "titusmaster-mainvpc"
                                    "GroupName": "titusmaster-mainvpc"
                        "Arn": "arn:aws:iam::<PRIVATE>:instance-profile/titusmasterInstanceProfile",
```

**With this test we have tested the isolation of permissions in containers provided by titus**

### Switching off
Let's destroy the infrastructure
```
$ terraform destroy --force
...
Destroy complete! Resources: 36 destroyed.
...
```

## Problems encountered
During the construction of this proof of concept, several problems have been encountered. Luckily, the titus development team has exposed a [public slack channel](https://titusoss.herokuapp.com/) where I found personalized help ;)

### Metatron
Once the infrastructure was set up, launching a sample job would cause an error in the logs of the mesos agent:

```bash
$ cat /var/lib/mesos/slaves/64b1f518-f8d6-4f21-8d4f-39360b8f12f2-S0/frameworks/TitusFramework/executors/docker-executor/runs/latest
Cannot create Titus executor: Failed to initialize Metatron trust store: lstat /metatron: no such file or directory
```

The titus development team mentioned a possible solution to me. Create the file `/etc/profile.d/titus_environment.sh` in the agent whose content was: `METATRON_ENABLED=false`
This didn't work or not at all. The solution, rudimentary, I found in desperation: `touch /metatron`. This solution is implemented in the [initialization script of mesos agents](./scripts/cloud-init-agent.yml.tpl) so this error should not occur again.

### instanceGroups activation
Again, when we tried to start a job, we found that it did not start the job. But again, the Netflix team referred me to more (somewhat fragmented???) [documentation](https://github.com/Netflix/titus-control-plane).

> By default, all titus-agent containers will join a cluster named unknown-instanceGroup. Before any tasks can be scheduled, that cluster needs to be activated. Note that this is necessary every time the Titus master is restarted, since instanceGroup state is not being persisted:

So you must launch that request to the api rest, important, from the titus gateway node. If you have used the default variables of this terraform project, the request will be:

```bash
$ curl localhost:7001/api/v3/agent/instanceGroups/titusagent/lifecycle \
  -X PUT -H "Content-type: application/json" -d \
  '{"instanceGroupId": "titusagent", "lifecycleState": "Active"}'
```

*Note: replace `titusagent` if you change the default variables*

### Job examples
Well, once the group of instances of the mesos agents is activated, we proceed to follow the [titus tutorial](https://netflix.github.io/titus/test/batch/) to launch a job.

A new problem arises, the examples are written for the API in version 2. But this version of the API is disabled, with version 3 being the active version. *(data provided by netflix engineers @ [slack](https://titusoss.herokuapp.com/))*. So again, we must go to [other documentation](https://github.com/Netflix/titus-control-plane) to look for a valid example *(api version 3)*.

### Services examples
In the documentation (neither in the official titus nor in the netflix repositories) there is no example of service. Service understood as a program or application that exposes a port to which other services or end customers can connect. Example, nginx server. Luckily the titus team through their slack channel have been patient with me and have been helping me.

They gave me an example they use to debug. But this example does not expound any "port".
```json
{
  "owner": {
    "teamEmail": "me@example.com"
  },
  "applicationName": "myServiceApp",
  "capacityGroup": "myServiceApp",
  "jobGroupInfo": {
    "stack": "myStack",
    "detail": "detail",
    "sequence": "002"
  },
  "attributes": {
    "key1": "value1"
  },
  "container": {
    "resources": {
      "cpu": 1.0,
      "memoryMB": 512,
      "diskMB": 10000,
      "networkMbps": 128,
      "allocateIP": true
    },
    "securityProfile": {
      "securityGroups": [
        "sg"
      ],
      "iamRole": "myapp-role"
    },
    "image": {
      "name": "alpine",
      "tag": "latest"
    },
    "entryPoint": [
      "sleep",
      "99999"
    ],
    "env": {
      "MY_ENV": "myEnv"
    },
    "softConstraints": {
      "constraints": {
        "UniqueHost": "true",
        "ZoneBalance": "true"
      }
    },
    "hardConstraints": {}
  },
  "service": {
    "capacity": {
      "min": 1,
      "max": 1,
      "desired": 1
    },
    "enabled": true,
    "retryPolicy": {
      "delayed": {
        "delayMs": "1000"
      }
    },
    "migrationPolicy": {
      "selfManaged": {}
    }
  }
}
```
I wanted to try an example a little closer to a "real" environment. Deploy a nginx. So I adapted his example for a nginx.
```json
{
  "owner": {
    "teamEmail": "me@example.com"
  },
  "applicationName": "myServiceApp",
  "capacityGroup": "myServiceApp",
  "jobGroupInfo": {
    "stack": "myStack",
    "detail": "detail",
    "sequence": "002"
  },
  "attributes": {
    "key1": "value1"
  },
  "container": {
    "resources": {
      "cpu": 1.0,
      "memoryMB": 256,
      "diskMB": 500,
      "networkMbps": 128,
      "allocateIP": true
    },
    "securityProfile": {
      "securityGroups": [
        "sg-<PRIVATE>"
      ],
      "iamRole": "arn:aws:iam::<AWS_ID>:role/titusappwiths3InstanceProfile"
    },
    "image": {
      "name": "tutum/nginx",
      "tag": "latest"
    },
    "env": {
      "MY_ENV": "myEnv"
    },
    "softConstraints": {
      "constraints": {
        "UniqueHost": "true",
        "ZoneBalance": "true"
      }
    },
    "hardConstraints": {}
  },
  "service": {
    "capacity": {
      "min": 1,
      "max": 1,
      "desired": 1
    },
    "enabled": true,
    "retryPolicy": {
      "delayed": {
        "delayMs": "1000"
      }
    },
    "migrationPolicy": {
      "selfManaged": {}
    }
  }
}
```
In this case, I used a [tutum image containing a simple nginx](https://hub.docker.com/r/tutum/nginx/).

### VPC Driver does not support t2 instances
Once I get the example to deploy (service), when I run it I realize that titus does not configure a new network interface to the node where the nginx service is running. On the other hand, you can see that the nginx docker container is alive by exposing port 80.

After several steps of debugging and already knowing a little more about the titus architecture, I went to the directory where the binary files of titus are found. Then I run the binary that was supposed to handle all the network configuration.

```bash
$ sudo /apps/titus-executor/bin/titus-vpc-tool genconf
panic: Unknown family: t2
```

I reported this error in the slack channel and they immediately told me that the t2 intancias were not supported. They showed me where [the map of instances supported by titus is](https://github.com/Netflix/titus-executor/blob/master/vpc/limits.go). So the exclaves of titus must be instances m4, m5.... but not t2.

### Additional environment variables was needed
Again, the official titus documentation did not specify these variables. So, when debugging the execution of the jobs or services we found the problem that the following additional variables were needed: (Part of the [`cloud-init-agent.yml.tpl`](./scripts/cloud-init-agent.yml.tpl) file)
```
    - path: /etc/profile.d/titus_environment.sh
      permissions: '0755'
      content: |
                #!/bin/bash -x
                export METATRON_ENABLED=false
                export TITUS_LOG_BUCKET=${titus_log_bucket}
                export TITUS_REGISTRY=docker.io
                export NETFLIX_ACCOUNT=no-one
                export EC2_LOCAL_IPV4=$(hostname --ip-address)
```

## Documentation to have on the radar
- https://queue.acm.org/detail.cfm?id=3158370
- https://medium.com/netflix-techblog/titus-the-netflix-container-management-platform-is-now-open-source-f868c9fb5436
- https://www.youtube.com/watch?v=ySdqDGfEOHo
- https://www.youtube.com/watch?v=4OLlKGT7aVQ *(fully recommended)*
- https://www.youtube.com/watch?v=6QLMvBkJtOU
- https://www.infoq.com/news/2018/04/titus-container-platform
- https://github.com/Netflix/titus-control-plane
- https://github.com/Netflix/titus-api-definitions/blob/master/doc/titus-v3-spec.md
