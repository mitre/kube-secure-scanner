# GitLab Components Example

This directory gives resources you can use to add jobs to a GitLab CI/CD pipeline for deploying a container to a kubernetes cluster, scan it with InSpec, and tear it back down. This method permits you to run container configuration management scans (i.e. check against security benchmarks) without having to modify the image (i.e. by punching a new port through the network layer).

## Basic Pattern

We are going to create a namespace of the Kubernetes cluster specifically for pipeline activities and pass GitLab only enough permissions to run scans against a pod in that isolated namespace.

### Assumptions

- You have a Kubernetes cluster (or even just a minikube)
- You have permissions to add the resources defined below
- You have a GitLab repo 
- You have permissions to add pipeline secrets to that repo (or to the overall GitLab instance)
- You have the kubectl, jq and base64 utilities available
- You have created a custom image with InSpec and Kubectl present, as well as the InSpec plugin for Kubernetes (more on this below)
## Resources on Kubernetes

Deploy the `inspec-rbac.yaml` manifest to your cluster. This will create
- a namespace (`pipeline`)
- a service account (`pipeline`)
- a role (`pipeline-role`)
- a role binding to attach the role to the service account we just made (`pipeline-rolebinding`)
- a service account secret token that we can use as a credential in the GitLab CI pipeline (`pipeline-secret`)

If we look at `pipeline-role` resource specifically, we see that we are defining a very limited set of permissions to our pipeline service account. We can *only* interact with a single pod named `inspec-target`. Note the permission to `create` a `pods/exec` as well -- that gives us the permission to execute another command against a running pod (also *only* `inspec-target` pod). That `pods/exec` permission is why we can connect to the pod's containers with InSpec later. The same permission allows you to manually run `kubectl exec -it pod-name`, for example.

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
name: pipeline-role
namespace: pipeline
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "create", "delete"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["inspec-target"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceNames: ["inspec-target"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
```

Apply the `inspec-rbac.yaml` manifest:
```bash
kubectl apply -f inspec-rbac.yaml -n pipeline
```

Once you apply this manifest, you can read the service account token by looking at the `pipeline-secret`, which is stored encoded in base64:

```bash
kubectl get secret -n pipeline pipeline-secret -o json | jq -r  .data.token | base64 -d
```

The output will be the raw token. We want to take this value and create a kubeconfig file out of it. We've created a simple script for this.

## Generating Kubeconfig

Run `generate-kubeconfig.sh`:

```bash
./generate-kubeconfig.sh pipeline pipeline
```

(The script wants a namespace and a service account name as inputs, both of which happen to be "pipeline".)

The script will fetch your secret token and a certificate and enter it into a kubeconfig file structure. It will save the file and also print it to stdout in base64-encoded form, for convenience, because our next step will be to make this file a GitLab secret.

We now have a kubeconfig file that can serve as a credential that will allow the pipeline to authenticate to Kubernetes but only take a limited number of actions in a segregated namespace for safety.

## GitLab

### Create a Secret 

Log into your GitLab instance and create a new secret (either at the repository scope if you just want to run this one pipeline or at the entire instance scope if multiple repos will need to do this). The secret should be named PIPELINE_KUBECONFIG and it should be populated with the base64-encoded value of the pipeline kubeconfig we just generated (GitLab can't make a variable out of the entire file; it needs to be encoded).
### Construct a pipeline

Now you can write a GitLab CI file to stand up your test container on Kubernetes, scan it, and tear it back down. We'll create an example pipeline to demonstrate this. A real container image pipeline will need many more jobs -- for one thing, we'll need a job to build the container image in the first place for testing -- but we're focusing on InSpec CCE (Common Configuration Enumeration, synonymous in this context with "configuration management") scanning for now. Our hello-world container image for testing will be off-the-shelf UBI9.

### The runner image

All three of the jobs in this example use a sample image called `cinc-kubestation` as the job runner. We built a custom image using the Dockerfile for `cinc-workstation`, the community build of Chef's open source `chef-workstation` tool, and added in the kubectl utility and the plugin for InSpec that enables it to borrow kubectl for talking to the Kubernetes API. See the Dockerfile we used for this at https://github.com/mitre/chef-workstation/tree/cinc-kubestation. That image needs optimization and some cleanup but is functional.

(Technically only the scan job actually needs this image; the other two just need an image with kubectl present, but for simplicity's sake we are using the same image for all three jobs.)

### The  Repos

This example was created using two repos -- one serves as the pipeline component repository ("pipeline templates") and the other is the source code for the containerized application we want to build and test ("app"). We used a pipeline templates repo because it makes it easier to run multiple pipelines for separate applications, all of which reference the same job components stored elsewhere. See GitLab's [CI/CD Components documentation](https://docs.gitlab.com/ci/components/) for details.

### pipeline-templates

In your pipeline templates repo, create the following file tree:

```bash
tree
.
├── templates
    ├── delete_test_pod.yml
    ├── deploy_test_pod.yml
    └── scan.yml
```

This is the required structure for GitLab CI to be able to parse your components. Copy the files for `delete_test_pod.yml`, `deploy_test_pod.yml`, and `scan.yml` to a `templates` folder in your pipeline templates repo. Save and commit the changes, then push them to GitLab.

### app repo

In your app repo, create a `.gitlab-ci.yml` file that invokes the job components you saved in the template repo.

```yaml
include: # pull in templates from a separate repository 'pipeline-templates' at branch 'dev'
  - component: $CI_SERVER_FQDN/pipeline-templates/deploy_test_pod@dev
  - component: $CI_SERVER_FQDN/pipeline-templates/scan@dev
  - component: $CI_SERVER_FQDN/pipeline-templates/delete_test_pod@dev

stages:
  - deploy
  - scan
  - delete
```

You'll also want to create a file at the root of the app repo called `inputs.yml`, since the InSpec run is expecting you to pass it some parameters -- for now, we can populate the file to simply turn off the longer-running STIG scan requirements.

`inputs.yml`:
```yaml
disable_slow_controls: true
```

The `gitlab-ci.yml` file will now invoke your job templates when the pipeline is triggered. Again, real pipelines will have many more jobs and will be running scans against a container built from this repo's source code.
### The Components

Let's briefly look at what the job components do.
### Deploying the test pod

The deploy component will read the GitLab secret for your pipeline-kubeconfig, decode it back into a file, and then use it to launch a pod containing solely the container we are trying to scan.

```yaml
deploy_test_pod:
  stage: $[[ inputs.stage ]]
  image: $REGISTRY/cincproject/cinc-kubestation:0.0.1
  tags:
  - k8s
  script: |

	base64 -d <<< $PIPELINE_KUBECONFIG > pipeline-config.yml

    echo ">>> Starting test container <<< "
    cat <<EOF > inspec-target.yml
    apiVersion: v1
    kind: Pod
    metadata:
    name: inspec-target
    spec:
      containers:
      - name: inspec-target
	    image: $[[ inputs.image ]]
	    command: ['sh', '-c', 'sleep 10000']
    EOF

    kubectl --kubeconfig=pipeline-config.yml apply -f inspec-target.yml --validate=false
```

We create the manifest for a pod wrapping the image we want to create on-the-spot. We then use kubectl to apply the manifest using our pipeline-kubeconfig, which authenticates us as the `pipeline` service account, which has very limited permissions but those permissions do include the ability to create a pod in the `pipeline` namespace.

We also save the manifest we created as an artifact, so that we can reference it later.

```yaml
artifacts:
  name: "$CI_JOB_NAME"
  paths:
  - inspec-target.yml
```

### Scanning the test pod

Next we scan the pod in the `scan` job. This one has some similarities to the deploy step. First, we assemble our kubeconfig and run our scan with it in the `script` tag:

```yaml
base64 -d <<< $PIPELINE_KUBECONFIG > pipeline-kubeconfig.yml

export KUBECONFIG=pipeline-kubeconfig.yml

echo ">>> Vendoring InSpec profile $[[ inputs.profile ]] <<< "
cinc-auditor vendor $[[ inputs.profile ]]

echo ">>> Running InSpec <<< "

cinc-auditor exec $[[ inputs.profile ]] \
  -t k8s-container://pipeline/inspec-target/inspec-target \
  --input-file=$[[ inputs.inputs_file ]] \
  --enhanced-outcomes \
  --reporter cli json:$CI_PROJECT_DIR/reports/raw/inspec.json || true
```

Note that cinc-auditor uses the `-t`, or "target" flag, to indicate that we are attempting to scan a remote system. We use the `k8s-container` plugin to connect to a running container on the Kubernetes cluster. We must pass InSpec a string to tell it which container we want to scan -- a namespace, pod, and container. In this case, we are scanning in the `pipeline` namespace, and both our pod and our container are called `inspec-test`.

When this job executes, we will prove that we can run InSpec against a remote pod. The next part of the job serves to confirm that we cannot do *anything else.* We should not, for example, be capable of listing pods in any namespace other than the `pipeline` one. We should also not be capable of listing any resources other than pods in our namespace.

```yaml
echo ">>> Demonstrating that pipeline-kubeconfig is restricted in scope <<<"
kubectl get pods -n kube-system || true
kubectl get all -n pipeline || true
kubectl get pods -n pipeline || true
```

### Deleting the test pod

The `delete_test_pod` job is simple. It runs `kubectl delete` on the exact same manifest we applied earlier, since we helpfully saved the manifest as an artifact to make it available to later jobs.

```yaml
delete_test_pod:
  stage: $[[ inputs.stage ]]
  image: $REGISTRY/cincproject/cinc-kubestation:0.0.1
  tags:
  - k8s
  script: |
    base64 -d <<< $PIPELINE_KUBECONFIG > pipeline-config.yml
    kubectl --kubeconfig=pipeline-config.yml delete -f inspec-target.yml
```

Simple enough.

## Running the pipeline

Commit and push the changes to both the template and the app repos discussed above. Then use GitLab's UI to manually trigger the pipeline for the app repo. The output of the `scan` job will show the results of your scan (also saved as a JSON artifact) and also a number of error messages as our pipeline user attempts to call the API for information on resources it is not permitted to see (as well as some data about the pods that it is in fact allowed to access).