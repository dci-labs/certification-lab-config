# DCI on OpenShift Partner Labs (OPL on ROSA)

## Demo

Here is a [demo](https://www.youtube.com/watch?v=I3KaNEpy3PE&ab_channel=RedKrie) of certification with DCI on OpenShift Partner Labs on ROSA, described below.

## Design proposal for DCI on OpenShift Partner Labs

DCI app-agent is designed to run on a jumpbox, a RHEL machine with an NFR subscription that has access to the OCP cluster. The user running DCI should have sudo permissions locally and admin permissions on the cluster.

In the case of the [OpenShift Partner Lab](https://connect.redhat.com/en/blog/introducing-openshift-partner-lab), which is ROSA (OCP on AWS), the standard installation does not create a dedicated jumpbox and proposes to use [ROSA CLI](https://docs.openshift.com/rosa/rosa_install_access_delete_clusters/rosa-sts-accessing-cluster.html) for cluster management.

To meet all the requirements, we could create a local RHEL8 Vagrant VM with an NFR subscription on the user's laptop and set it up as our jumpbox.

## Start Jumpbox VM, use RHEL8 subscription, and install DCI

We're going to run a [RHEL8 VM with Vagrant](https://app.vagrantup.com/generic/boxes/rhel8) and setup an NFR or [developer](https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux#general) subscription. This is just an example, feel free to use your preferred tools to setup RHEL VM.

1. Get a RHEL8 subscription.

Here you have two options:

Option 1. For local tests, you have a [RH developer subscription, allowing up to 16 subscriptions for personal usage](https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux#general).

Option 2. Partners should subscribe to [RHPS](https://github.com/dci-labs/dallas-internal-docs/blob/master/partner_rhel_and_ocp_subscription/access.redhat.com), previously called NFR (not-for-resale).
To request RHPS, follow these steps on the Technology Portal:
- Go to connect.redhat.com
- Click on Log In Log in as Technology Partner
- Click "My account"
- Click on "Partner subscriptions"
- Request Red Hat Partner Subscriptions
- After submitting the request, wait for about 15 minutes without closing the last page. The process is fully automated, and once completed, the subscription will be listed on the [Access page](https://github.com/dci-labs/dallas-internal-docs/blob/master/partner_rhel_and_ocp_subscription/access.redhat.com).

2. Clone the current repository:

```
$ git clone git@github.com:dci-labs/certification-lab-config.git
```

3. Replace <username> and <password> in provision.sh with your credentials for the Red Hat RHEL8 subscription: 

```
$ cd certification-lab-config
$ cat provision.sh
-- snip --
# Register the system with Red Hat Subscription Manager
# sudo subscription-manager register --username <username> --password <password> --auto-attach
-- snip --
```

4. Install Vagrant:

```
$ sudo dnf install -y vagrant
```

5. Start the RHEL VM using the provided Vagrantfile and connect to it via SSH. Vagrant provisioning will activate your Red Hat subscription, configure required repositories, and install DCI packages:

```
$ cd certification-lab-config
$ vagrant up
Bringing machine 'default' up with 'libvirt' provider...
==> default: Box 'generic/rhel8' could not be found. Attempting to find and install...
-- snip --
==> default: Machine booted and ready!
```

6. Copy our setup folders inside the Vagrant VM:

```
$ vagrant upload pipelines /home/vagrant/certification-lab-config/pipelines
$ vagrant upload ocp-workload /home/vagrant/certification-lab-config/ocp-workload
$ vagrant upload inventories /home/vagrant/certification-lab-config/inventories
```

7. SSH-connect to the Vagrant machine:

```
$ vagrant ssh
Register this system with Red Hat Insights: insights-client --register
Create an account or view all your systems at https://red.ht/insights-dashboard
```

8. Verify the setup:

```
[vagrant@rhel8 ~]$ cat /etc/redhat-release
Red Hat Enterprise Linux release 8.9 (Ootpa)
[vagrant@rhel8 ~]$ ll -lart certification-pipeline-config/
total 0
drwxrwxr-x. 3 vagrant vagrant  19 Jun 27 12:53 ocp-workload
drwx------. 4 vagrant vagrant 132 Jun 27 12:57 ..
drwxrwxr-x. 2 vagrant vagrant  88 Jun 27 12:57 pipelines
drwxrwxr-x. 5 vagrant vagrant  62 Jun 27 12:58 .
drwxrwxr-x. 3 vagrant vagrant  18 Jun 27 12:58 inventories
```

## Kubeconfig

DCI uses kubeconfig to execute workload and certification. If you are using an OCP cluster already deployed (ROSA, ARO), you may only have credentials. Obtain the token by logging in with your user/password to the OPL console (you should receive an email with that URL):

```
https://oauth-openshift.apps.xxxxxxxx-rhdci.openshiftpartnerlabs.com/oauth/token/request
```

Now use this token to login from the console
```
$ oc login --token=XXX --server=https://api.xxxxxxxx-rhdci.openshiftpartnerlabs.com:6443
```

After executing the `oc login` command on your machine, you can find it in your `$HOME`. Upload the kubeconfig generated in ~/.kube/config to your Vagrant machine:

```
$ vagrant upload ~/.kube/config /home/vagrant/cluster1/auth/kubeconfig
```

and set KUBECONFIG variable

```
$ vagrant ssh
[vagrant@rhel8 ~]$ export KUBECONFIG=/home/vagrant/cluster1/auth/kubeconfig
[vagrant@rhel8 ~]$ echo $KUBECONFIG
/home/vagrant/cluster1/auth/kubeconfig
```

## Configure DCI-queue

1. Create the required directories and files for DCI to work:

```
$ mkdir -p dci-cache-dir upload-errors .config/dci-pipeline
$ cat > .config/dci-pipeline/config <<EOF
PIPELINES_DIR=$HOME/certification-lab-config/pipelines
DEFAULT_QUEUE=pool
EOF
```

2. Download remoteci credentials from [www.distributed-ci.io](https://www.distributed-ci.io/remotecis) and save them locally in `~/.config/dci-pipeline/dci_credentials.yml`.
You can now customize the hooks, pipelines and inventories files for your own needs following [the DCI documentation](https://docs.distributed-ci.io/).

3. The inventories and pipelines expect `dci-queue` to be used with the following settings:

```
$ dci-queue add-pool pool
$ dci-queue add-resource pool cluster1

# Verify the pool
[vagrant@rhel8 ~]$ dci-queue list
The following pools were found:
  pool

# Verify the resource
[vagrant@rhel8 ~]$ dci-queue list pool
Resources on the pool pool: cluster1
Available resources on the pool pool: cluster1
Executing commands on the pool pool:
Queued commands on the pool pool:
```

# Run certification pipeline with DCI

Let's start from running a ready test pipeline:

```
[vagrant@rhel8 certification-pipeline-config]$ KUBECONFIG=$KUBECONFIG dci-pipeline-schedule workload
+ dci-queue schedule  pool env DCI_QUEUE=pool RES=@RESOURCE KUBECONFIG=/home/vagrant/cluster1/auth/kubeconfig /usr/share/dci-pipeline/dci-pipeline-helper  workload
[vagrant@rhel8 certification-pipeline-config]$ dci-queue list pool
Resources on the pool pool: cluster1
Available resources on the pool pool: cluster1
Executing commands on the pool pool:
Queued commands on the pool pool:
 2: env DCI_QUEUE=pool RES=@RESOURCE KUBECONFIG=/home/vagrant/cluster1/auth/kubeconfig /usr/share/dci-pipeline/dci-pipeline-helper workload (wd: /home/vagrant/certification-pipeline-config)
```

In case if something's wrong, the logs to debug are here under the job number: 

```
[vagrant@rhel8 certification-pipeline-config]$ cd ~/.dci-queue/log/pool/
```

In the [pipelines/certification-pipeline.yml](https://github.com/dci-labs/template-ocp-config/blob/main/pipelines/certification-pipeline.yml) file, you will find a stub configuration to certify containers, Helm charts, operators, and create CNF projects. Customize it by providing your credentials and certification items, and then run it using the following command:

```
$ KUBECONFIG=$KUBECONFIG dci-pipeline-schedule certification
```

Here is some documentation can could be helpful:
- [DCI UI (Use RH SSO to login)](https://www.distributed-ci.io/jobs?limit=20&offset=0&sort=-created_at&where=state:active)
- [DCI blog: Certification tests for OpenShift containers and operators: how to run with DCI](https://blog.distributed-ci.io/preflight-integration-in-dci.html)
- Detailed documentation for some certification-related roles: [Preflight](https://github.com/redhatci/ansible-collection-redhatci-ocp/tree/main/roles/preflight), [Chart Verifier](https://github.com/redhatci/ansible-collection-redhatci-ocp/tree/main/roles/chart_verifier), [CNF](https://github.com/redhatci/ansible-collection-redhatci-ocp/tree/main/roles/openshift_cnf), [create_certification_projects](https://github.com/redhatci/ansible-collection-redhatci-ocp/tree/main/roles/create_certification_project).

# (For the reference) How to manage your vagrant VM

```
# to start the VM
$ vagrant start

# to start the VM and force provisionning
$ vagrant start --provision

# to ssh-connect
$ vagrant ssh

# to ssh-disconnect
[vagrant@rhel8 ~]$ exit
logout

# to reconnect
$ vagrant ssh

# to stop
$ vagrant halt

# to stop and delete all traces of the vagrant machine
$ vagrant destroy
```
