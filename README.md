---
Title:  Azure AD Authentication to AWS Command Line Interface (cli)
Author:  Tim Lepple
Last Updated:  07.28.2023
Tags:  AWSCLI | azurecli | aws-azure-login
---

# AWS Azure Login Project

---
---

### Project Summary:
---
This repo is used to build a custom docker container that will run on `MacOS` with an M2 processor that will allow you to authenticate from a terminal window to Azure AD.   After authenticating to Azure AD, you will be able to execute AWS CLI commands as a `Federated user` for a short period of time (without the need to create `<AWS Access Keys>` and `<AWS Secret Keys>`.

*  Kudos to Brian Lachance for the shell script and python code used here!
*  This will only work on a MacOS with ARM Chipset.

---

### One Time Setup Step:

* These commands are all run from a `Terminal` window.
---

1. Pull this repository to your machine
```
git clone https://github.com/tlepple/aws_ad_auth.git
```

2.  Change to this new directory on your machine
```
cd ./aws_ad_auth
```

3.  Build a local image on your host
```
docker build --no-cache --platform=linux/arm64 -t arm64v8/alpine:aws-ad-auth-img .
```

4.  Create a `Docker Volume` that will persist to hold items created in your container
```
docker volume create awsadauth_vol1
```

5.  Create a new container from the image built above
```
docker compose up -d
```

6.  Connect to this new container:
*  This container does not run like most docker containers, it is operating more like a linux VM.   It will run continously until you shut it down.

```
docker exec -it aws-ad-auth bash
```
7.  Setup a local aws config file with profiles you have access to from Azure AD credentials
```
cd /app/pim

az login
```

*  This will return output similar to this:
```
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code <your specfic code> to authenticate.
```

8.  Authenticate to Azure AD:   
    1. Open a chrome browser on your host and give it the URL `https://microsoft.com/devicelogin`.   
    2. It will ask you to enter the code from your container `<your specfic code>`.   
    3. From here you will select your Microsoft AD account.  
    4. Then click the `Continue` button from the next screen.
    5. If all is working you should see the follow image.
    6. ![](./images/azure_ad_success.png)




9.  Extract from Azure AD account profiles you are authorized to access in preparation for next steps.
```
cd /app/pim

python3 create_config.py
```

10.  Setup aws configuration files with Account Profiles gathered in previous step.
```
. update_config.sh
```
*  It will prompt you for some input.   Sample output here:

```
Enter Azure AD Username: <input your AD email address here>
Enter AWS Session Role Name: <input your role name to include here> Example:  CDPOne_FullAccess
Updated configuration merged into ~/.aws/config successfully.
bash-5.1$ cat ~/.aws/config 
```

*  Set Up Complete

---
---

###   Verify all is working:

1.    Login from the terminal window
```
aws-azure-login --no-sandbox --profile <profile name value here>
```

2.    It will prompt you for your Azure AD Password.

3.    It will prompt you for a code from your 2-factor authentication device.

4.    If all works without error, you can see that it creates a new file with credentials here:  `cat ~/.aws/credentials`

5.    Test that it is working with a sample aws cli command:
```
export AWS_PROFILE=<profile name here>
AWS_DEFAULT_REGION=us-east-1

aws s3 ls
```

*  Reminder your docker container will run until you stop it.  Useful commands referenced below.

---
---

##  Docker Command Reference for Common Items:
```
# list all containers on host
docker ps -a

#  start an existing container
docker start aws-ad-auth

# connect to command line of this container
docker exec -it aws-ad-auth bash

#list running container
docker container ls -all

# stop a running container
docker container stop aaws-ad-auth

# remove a docker container
docker container rm aws-ad-auth

# list docker volumes
docker volume ls

# remove a docker volume
docker volume rm awsadauth_vol1
```
---
---
