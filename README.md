# Template for a new DCI OpenShift project

## Design proposal for DCI on OPL

DCI app-agent is designed to run on a jumpbox, a RHEL machine with an NFR subscription that has access to the OCP cluster. The user running DCI should have sudo permissions locally and admin permissions on the cluster.

In the case of the [OpenShift Partner Lab](https://connect.redhat.com/en/blog/introducing-openshift-partner-lab), which is ROSA (OCP on AWS), the standard installation does not create a dedicated jumpbox and proposes to use [ROSA CLI](https://docs.openshift.com/rosa/rosa_install_access_delete_clusters/rosa-sts-accessing-cluster.html) for cluster management.

To meet all the requirements, we could create a local RHEL VM with an NFR subscription on the user's laptop and set it up as our jumpbox.

## Start Jumpbox VM and configure RHEL subscription

We're going to run a [RHEL8 VM with Vagrant](https://app.vagrantup.com/generic/boxes/rhel8) and setup an NFR or [developer](https://developers.redhat.com/articles/faqs-no-cost-red-hat-enterprise-linux#general) subscription. This is just an example, feel free to use your preferred tools to setup RHEL VM.

1. Install Vagrant.

```
sudo dnf -y install vagrant
```

2. Copy Vagrantfile from this repository into your host machine.

```
$ pwd
/home/user/Documents/rhel_vm
$ cat Vagrantfile
Vagrant.configure("2") do |config|
    config.vm.box = "generic/rhel8"
  end
```

3. Start RHEL VM and connect to it via SSH.

```
$ vagrant up
Bringing machine 'default' up with 'libvirt' provider...
==> default: Box 'generic/rhel8' could not be found. Attempting to find and install...
-- snip --
==> default: Machine booted and ready!
$ vagrant ssh
Register this system with Red Hat Insights: insights-client --register
Create an account or view all your systems at https://red.ht/insights-dashboard
[vagrant@rhel8 ~]$ cat /etc/redhat-release
Red Hat Enterprise Linux release 8.9 (Ootpa)
```

4. Get RHEL subscription.

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

5. Activate RHEL subscription on the VM

```
[vagrant@rhel8 ~]$ subscription-manager register --username <username> --password <password> --auto-attach
```

6. Optional: How to manage your vagrant VM.

```
# to ssh-disconnect
[vagrant@rhel8 ~]$ exit
logout

# to reconnect
$ vagrant ssh

# to stop
$ vagrant halt

# to stop and delete all traces of the vagrant machine
$ vagrant detroy

# to start the VM
$ vagrant start
```

## Setup ROSA CLI user

We're going to run DCI as a ROSA user to have both local sudo access on the VM and admin access to the cluster. Please set up the ROSA user and assign sudo privileges to it. Use this user to install DCI packages in the next chapter.

## Install DCI packages

1. Install DCI repository and verify its presence.

```
[vagrant@rhel8 ~]$ sudo dnf -y install https://packages.distributed-ci.io/dci-release.el8.noarch.rpm
[vagrant@rhel8 ~]$ dnf repolist | grep dci
```

2. Install the dci-ansible package to pin the Ansible version to be 2.9.

```
$ sudo subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
$ sudo dnf install dci-ansible
$ ansible --version | grep core
```

3. Now install EPEL repositories, required by dci-openshift-agent.

```
$ sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
$ sudo dnf config-manager --set-enabled epel
$ sudo dnf config-manager --set-enabled epel-modular
```

4. Install the `dci-pipeline` and `dci-openshift-app-agent` rpm on your jumpbox.

```
$ sudo dnf install -y dci-openshift-agent
$ sudo dnf install -y dci-openshift-app-agent
$ sudo dnf install -y dci-pipeline
```

## Instructions

All the files are expected to be installed into the home of the user running the pipelines. Just replace `config` with your own locations in the files (`<your company>-<lab>-config`).

Add the credentials for your remoteci in `~/.config/dci-pipeline/dci_credentials.yml`.

Then create the required directories and files for DCI to work:

```ShellSession
$ cd
$ git clone git@github.com:dci-labs/<your company>-<lab>-config.git
$ mkdir -p dci-cache-dir upload-errors .config/dci-pipeline
$ cat > .config/dci-pipeline/config <<EOF
PIPELINES_DIR=$HOME/<your company>-<lab>-config/pipelines
DEFAULT_QUEUE=pool
EOF
```

You can now customize the hooks, pipelines and inventories files for
your own needs following [the DCI documentation](https://docs.distributed-ci.io/).

By default 2 job descriptions (`ocp-4.12` and `workload`) and their
associated hooks are present in the template.

The inventories are expecting `dci-queue` to be used with the
following settings:

```ShellSession
$ dci-queue add-pool pool
$ dci-queue add-resource pool cluster1
```

If you don't want to use `dci-queue`, just edit the the pipeline files
to not use dynamic paths.

## Launching a pipeline

For the full pipeline (OCP + workload):

```ShellSession
$ dci-pipeline-schedule ocp-4.12 workload
```

For only the workload:

```ShellSession
$ KUBECONFIG=$KUBECONFIG dci-pipeline-schedule workload
```

## Testing a PR

For testing a PR with the full pipeline:

```ShellSession
$ dci-pipeline-check https://github.com/dci-labs/<your company>-<lab>-config/pull/1 ocp-4.12 workload
```

Or only with the workload:

```ShellSession
$ dci-pipeline-check https://github.com/dci-labs/<your company>-<lab>-config/pull/1 $KUBECONFIG workload
```

# Certification with DCI

In the [pipelines/certification-pipeline.yml](https://github.com/dci-labs/template-ocp-config/blob/main/pipelines/certification-pipeline.yml) file, you will find a stub configuration to certify containers, Helm charts, operators, and create CNF projects. Customize it by providing your credentials and certification items, and then run it using the following command:

```ShellSession
$ KUBECONFIG=$KUBECONFIG dci-pipeline-schedule certification
```

Here is some documentation can could be helpful:
- [DCI UI (Use RH SSO to login)](https://www.distributed-ci.io/jobs?limit=20&offset=0&sort=-created_at&where=state:active)
- [DCI blog: Certification tests for OpenShift containers and operators: how to run with DCI](https://blog.distributed-ci.io/preflight-integration-in-dci.html)
- Detailed documentation for some certification-related roles: [Preflight](https://github.com/redhatci/ansible-collection-redhatci-ocp/tree/main/roles/preflight), [Chart Verifier](https://github.com/redhatci/ansible-collection-redhatci-ocp/tree/main/roles/chart_verifier), [CNF](https://github.com/redhatci/ansible-collection-redhatci-ocp/tree/main/roles/openshift_cnf), [create_certification_projects](https://github.com/redhatci/ansible-collection-redhatci-ocp/tree/main/roles/create_certification_project).
