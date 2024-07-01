#!/bin/bash

# Register the system with Red Hat Subscription Manager
sudo subscription-manager register --username <username> --password <password> --auto-attach

# Install DCI repository and verify its presence
sudo dnf install -y https://packages.distributed-ci.io/dci-release.el8.noarch.rpm
dnf repolist | grep dci

# Install the dci-ansible package to pin the Ansible version to 2.9
sudo subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
sudo dnf install -y dci-ansible
ansible --version

# Install EPEL repositories, required by dci-openshift-agent
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf config-manager --set-enabled epel
sudo dnf config-manager --set-enabled epel-modular

# Install the Ansible runner repository
sudo dnf config-manager --add-repo https://releases.ansible.com/ansible-runner/ansible-runner.el8.repo

# Install the `dci-pipeline` and `dci-openshift-app-agent` RPMs on your jumpbox
sudo dnf install -y dci-openshift-agent
sudo dnf install -y dci-openshift-app-agent
sudo dnf install -y dci-pipeline
