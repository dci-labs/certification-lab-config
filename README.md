# Template for a new DCI OpenShift project

Follow the requirements described in [the DCI
documentation](https://docs.distributed-ci.io/dci-openshift-agent/#systems-requirements)
to prepare the jumpbox.

## Instructions

Install the `dci-pipeline` and `dci-openshift-app-agent` rpm on your jumpbox.

All the files are expected to be installed into the home of the user
running the pipelines. Just replace `config` with your own locations
in the files (`<your company>-<lab>-config`).

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
