# ASCII Text-Based Workflow and Architecture Diagrams

This document provides ASCII text-based diagrams for the key workflows and architectures in our project. These diagrams are intended to complement the Mermaid diagrams and provide a more accessible alternative that can be viewed directly in a terminal or without rendering.

## Minikube Architecture

```
+-----------------------------------------------------------------------+
|                                                                       |
|                          MINIKUBE CLUSTER                             |
|                                                                       |
|  +-------------------------+        +-------------------------+        |
|  |                         |        |                         |        |
|  |      CONTROL NODE       |        |      WORKER NODE 1      |        |
|  |                         |        |                         |        |
|  |  +-------------------+  |        |  +-------------------+  |        |
|  |  |                   |  |        |  |                   |  |        |
|  |  |  kube-apiserver   |  |        |  | Target Containers |  |        |
|  |  |                   |  |        |  |                   |  |        |
|  |  +-------------------+  |        |  +-------------------+  |        |
|  |                         |        |                         |        |
|  |  +-------------------+  |        |  +-------------------+  |        |
|  |  |                   |  |        |  |                   |  |        |
|  |  |       etcd        |  |        |  |   Scanner Pods    |  |        |
|  |  |                   |  |        |  |                   |  |        |
|  |  +-------------------+  |        |  +-------------------+  |        |
|  |                         |        |                         |        |
|  +-------------------------+        +-------------------------+        |
|                                                                       |
|                                                                       |
|                           +-------------------------+                  |
|                           |                         |                  |
|                           |      WORKER NODE 2      |                  |
|                           |                         |                  |
|                           |  +-------------------+  |                  |
|                           |  |                   |  |                  |
|                           |  |  Debug Containers |  |                  |
|                           |  |                   |  |                  |
|                           |  +-------------------+  |                  |
|                           |                         |                  |
|                           |  +-------------------+  |                  |
|                           |  |                   |  |                  |
|                           |  |   Sidecar Pods    |  |                  |
|                           |  |                   |  |                  |
|                           |  +-------------------+  |                  |
|                           |                         |                  |
|                           +-------------------------+                  |
|                                                                       |
+-----------------------------------------------------------------------+
                        |                |                |
                        |                |                |
                        v                v                v
          +------------------+  +------------------+  +------------------+
          |                  |  |                  |  |                  |
          |   CINC Profiles  |  | Service Accounts |  |     SAF CLI      |
          |   (Compliance    |  |    and RBAC      |  |  (Reporting &    |
          |    Controls)     |  |  (Access Control)|  |  Thresholds)     |
          |                  |  |                  |  |                  |
          +------------------+  +------------------+  +------------------+
```

## Standard Container Scanning Workflow (Approach 1)

```
              START STANDARD CONTAINER SCANNING
                           |
                           v
+----------------------------------------------------------+
|                                                          |
|              STEP 1: SETUP & PREPARATION                 |
|                                                          |
|  +------------------+          +--------------------+    |
|  |                  |          |                    |    |
|  |     Identify     |--------->|  Create RBAC and   |    |
|  |     Target       |          |  Service Account   |    |
|  |     Container    |          |                    |    |
|  |                  |          |                    |    |
|  +------------------+          +--------------------+    |
|                                          |               |
|                                          v               |
|                      +------------------------------------+
|                      |                                    |
|                      |       Generate Short-lived         |
|                      |       Security Token               |
|                      |                                    |
|                      +------------------------------------+
|                                          |               |
|                                          v               |
|                      +------------------------------------+
|                      |                                    |
|                      |       Create Restricted            |
|                      |       Kubeconfig File              |
|                      |                                    |
|                      +------------------------------------+
|                                                          |
+----------------------------------------------------------+
                           |
                           v
+----------------------------------------------------------+
|                                                          |
|                STEP 2: SCANNING EXECUTION                |
|                                                          |
|  +------------------+          +--------------------+    |
|  |                  |          |                    |    |
|  |    Run CINC      |          |    Process with    |    |
|  |    Auditor with  |<---------|    SAF CLI &       |    |
|  |    k8s-container |          |    Check Threshold |    |
|  |    Transport     |          |                    |    |
|  +------------------+          +--------------------+    |
|          |                                              |
|          v                                              |
|  +------------------+          +--------------------+    |
|  |                  |          |                    |    |
|  |    Generate      |--------->|    Clean up RBAC   |    |
|  |    Reports and   |          |    & Service       |    |
|  |    Validations   |          |    Account         |    |
|  |                  |          |                    |    |
|  +------------------+          +--------------------+    |
|                                                          |
+----------------------------------------------------------+
                           |
                           v
                       SCAN COMPLETE
```

## Distroless Container - Debug Container Approach (Approach 2)

```
         START DEBUG CONTAINER APPROACH FOR DISTROLESS CONTAINERS
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|              STEP 1: ATTACH DEBUG CONTAINER                    |
|                                                                |
|  +--------------------+        +-------------------------+     |
|  |                    |        |                         |     |
|  |    Identify        |------->|  Create Ephemeral       |     |
|  |    Distroless      |        |  Debug Container with   |     |
|  |    Target Container|        |  kubectl debug command  |     |
|  |                    |        |                         |     |
|  +--------------------+        +-------------------------+     |
|                                           |                    |
|                                           v                    |
|                       +----------------------------------+     |
|                       |                                  |     |
|                       |     Deploy CINC Auditor in       |     |
|                       |     Ephemeral Debug Container    |     |
|                       |                                  |     |
|                       +----------------------------------+     |
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|              STEP 2: PERFORM SCANNING THROUGH DEBUG CONTAINER  |
|                                                                |
|  +--------------------+        +-------------------------+     |
|  |                    |        |                         |     |
|  |    Chroot to       |------->|  Run CINC Auditor       |     |
|  |    Target Container|        |  Against Target         |     |
|  |    Filesystem      |        |  Container Root         |     |
|  |                    |        |                         |     |
|  +--------------------+        +-------------------------+     |
|                                           |                    |
|                                           v                    |
|                       +----------------------------------+     |
|                       |                                  |     |
|                       |     Export Scan Results to       |     |
|                       |     Host System                  |     |
|                       |                                  |     |
|                       +----------------------------------+     |
|                                           |                    |
|                                           v                    |
|  +--------------------+        +-------------------------+     |
|  |                    |        |                         |     |
|  |    Process Results |------->|  Terminate Debug        |     |
|  |    with SAF CLI    |        |  Container & Clean Up   |     |
|  |    Threshold Check |        |  Resources              |     |
|  |                    |        |                         |     |
|  +--------------------+        +-------------------------+     |
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
                           SCAN COMPLETE
```

## Sidecar Container Approach (Approach 3)

```
            START SIDECAR CONTAINER APPROACH FOR SCANNING
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|               STEP 1: DEPLOY POD WITH SIDECAR                  |
|                                                                |
|  +--------------------+       +------------------------+       |
|  |                    |       |                        |       |
|  |   Deploy Target    |------>|   Deploy Scanner       |       |
|  |   Container in     |       |   Sidecar Container    |       |
|  |   Kubernetes Pod   |       |   in Same Pod          |       |
|  |                    |       |                        |       |
|  +--------------------+       +------------------------+       |
|                                          |                     |
|                                          v                     |
|                      +----------------------------------------+|
|                      |                                        ||
|                      |   Enable Shared Process Namespace      ||
|                      |   Between Containers in Pod            ||
|                      |   (shareProcessNamespace: true)        ||
|                      |                                        ||
|                      +----------------------------------------+|
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|               STEP 2: PERFORM SCAN USING SIDECAR               |
|                                                                |
|  +--------------------+       +------------------------+       |
|  |                    |       |                        |       |
|  |   Sidecar Finds    |------>|   Access Target        |       |
|  |   Target Process   |       |   Filesystem via       |       |
|  |   Using 'ps'       |       |   /proc/PID/root       |       |
|  |                    |       |                        |       |
|  +--------------------+       +------------------------+       |
|                                          |                     |
|                                          v                     |
|                      +----------------------------------------+|
|                      |                                        ||
|                      |   Run CINC Auditor Against             ||
|                      |   Target Container's Filesystem        ||
|                      |                                        ||
|                      +----------------------------------------+|
|                                          |                     |
|                                          v                     |
|  +--------------------+       +------------------------+       |
|  |                    |       |                        |       |
|  |   Store Results    |------>|   Process Results with |       |
|  |   in Shared        |       |   SAF CLI & Validate   |       |
|  |   Volume           |       |   Against Threshold    |       |
|  |                    |       |                        |       |
|  +--------------------+       +------------------------+       |
|                                          |                     |
|                                          v                     |
|                      +----------------------------------------+|
|                      |                                        ||
|                      |   Retrieve Results from Sidecar        ||
|                      |   via kubectl cp or Volume Mount       ||
|                      |                                        ||
|                      +----------------------------------------+|
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
                           SCAN COMPLETE
```

## Modified Transport Plugin Approach (Approach 1 - Enterprise)

```
            START MODIFIED TRANSPORT PLUGIN APPROACH
                            |
                            v
+------------------------------------------------------------+
|                                                            |
|          STEP 1: CONTAINER DETECTION AND SETUP             |
|                                                            |
|  +-----------------+        +----------------------+       |
|  |                 |        |                      |       |
|  |  Target         |------->|  Modified            |       |
|  |  Container      |        |  train-k8s-container |       |
|  |  Identification |        |  Plugin (Enhanced)   |       |
|  |                 |        |                      |       |
|  +-----------------+        +----------------------+       |
|                                       |                    |
|                                       v                    |
|                    +----------------------------------+    |
|                    |                                  |    |
|                    |  Auto-Detect if Container        |    |
|                    |  is Distroless (No Shell)        |    |
|                    |                                  |    |
|                    +----------------------------------+    |
|                             /           \                  |
|                            /             \                 |
|                           v               v                |
| +-------------------------+   +---------------------------+|
| |                         |   |                           ||
| |  If Regular Container:  |   |  If Distroless Container: ||
| |  Use Standard Direct    |   |  Automatically Use Debug  ||
| |  Exec Connection        |   |  Container Fallback       ||
| |                         |   |                           ||
| +-------------------------+   +---------------------------+|
|          |                                   |             |
|          |                                   v             |
|          |                    +---------------------------+|
|          |                    |                           ||
|          |                    |  Create Temporary Debug   ||
|          |                    |  Container Automatically  ||
|          |                    |                           ||
|          |                    +---------------------------+|
|          |                                   |             |
+------------------------------------------------------------+
                   |                          |
                   v                          v
+------------------------------------------------------------+
|                                                            |
|              STEP 2: SCANNING EXECUTION                    |
|                                                            |
|  +-----------------+        +----------------------+       |
|  |                 |        |                      |       |
|  |  Run CINC       |        |  Process Results     |       |
|  |  Auditor Scan   |------->|  with SAF CLI &      |       |
|  |  Transparently  |        |  Check Thresholds    |       |
|  |                 |        |                      |       |
|  +-----------------+        +----------------------+       |
|                                                            |
+------------------------------------------------------------+
                                |
                                v
+------------------------------------------------------------+
|                                                            |
|              STEP 3: CLEANUP (FOR DISTROLESS)              |
|                                                            |
|                    +---------------------------+           |
|                    |                           |           |
|                    |  If Debug Container Used: |           |
|                    |  Terminate and Clean Up   |           |
|                    |  Resources                |           |
|                    |                           |           |
|                    +---------------------------+           |
|                                                            |
+------------------------------------------------------------+
                                |
                                v
                          SCAN COMPLETE
```

## GitLab CI Pipeline with Services

```
                    GITLAB CI PIPELINE WITH SERVICES
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|                    STAGE 1: PIPELINE SETUP                     |
|                                                                |
|  +-------------------+         +----------------------+        |
|  |                   |         |                      |        |
|  |  GitLab CI        |-------->|  Start CINC Auditor  |        |
|  |  Pipeline Begins  |         |  Scanner as a        |        |
|  |                   |         |  Service Container   |        |
|  |                   |         |                      |        |
|  +-------------------+         +----------------------+        |
|                                           |                    |
|                                           v                    |
|                      +------------------------------------+    |
|                      |                                    |    |
|                      |  Deploy Target Container in        |    |
|                      |  Kubernetes Cluster                |    |
|                      |                                    |    |
|                      +------------------------------------+    |
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|                    STAGE 2: SECURITY SETUP                     |
|                                                                |
|  +-------------------+         +----------------------+        |
|  |                   |         |                      |        |
|  |  Create RBAC &    |-------->|  Generate Short-lived|        |
|  |  Service Account  |         |  Security Token      |        |
|  |  in Cluster       |         |                      |        |
|  |                   |         |                      |        |
|  +-------------------+         +----------------------+        |
|                                           |                    |
|                                           v                    |
|                      +------------------------------------+    |
|                      |                                    |    |
|                      |  Create Restricted kubeconfig      |    |
|                      |  with Minimal Permissions          |    |
|                      |                                    |    |
|                      +------------------------------------+    |
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|                    STAGE 3: SCANNING & REPORTING               |
|                                                                |
|  +-------------------+         +----------------------+        |
|  |                   |         |                      |        |
|  |  Execute Scan     |-------->|  Process Results     |        |
|  |  in Service       |         |  with SAF CLI in     |        |
|  |  Container        |         |  Service Container   |        |
|  |                   |         |                      |        |
|  +-------------------+         +----------------------+        |
|                                           |                    |
|                                           v                    |
|                      +------------------------------------+    |
|                      |                                    |    |
|                      |  Copy Results from Service         |    |
|                      |  to Pipeline & Generate Reports    |    |
|                      |                                    |    |
|                      +------------------------------------+    |
|                                           |                    |
|                                           v                    |
|                      +------------------------------------+    |
|                      |                                    |    |
|                      |  Clean Up Resources in Kubernetes  |    |
|                      |  (Pods, Service Accounts, RBAC)    |    |
|                      |                                    |    |
|                      +------------------------------------+    |
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
                         PIPELINE COMPLETE
```

## GitLab CI Sidecar Approach

```
                    GITLAB CI SIDECAR APPROACH
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|                    STAGE 1: DEPLOYMENT                         |
|                                                                |
|  +-------------------+         +----------------------+        |
|  |                   |         |                      |        |
|  |  GitLab CI        |-------->|  Deploy Pod with    |        |
|  |  Pipeline Begins  |         |  Target Container   |        |
|  |                   |         |  and Scanner Sidecar|        |
|  |                   |         |  in Same Pod        |        |
|  +-------------------+         +----------------------+        |
|                                           |                    |
|                                           v                    |
|                      +------------------------------------+    |
|                      |                                    |    |
|                      |  Enable Shared Process Namespace   |    |
|                      |  Between Target and Scanner        |    |
|                      |                                    |    |
|                      +------------------------------------+    |
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|                    STAGE 2: SCANNING                           |
|                                                                |
|  +-------------------+         +----------------------+        |
|  |                   |         |                      |        |
|  |  Sidecar Scanner  |-------->|  Scan Target via    |        |
|  |  Container Starts |         |  /proc Filesystem   |        |
|  |                   |         |  Access Method      |        |
|  |                   |         |                      |        |
|  +-------------------+         +----------------------+        |
|                                           |                    |
|                                           v                    |
|                      +------------------------------------+    |
|                      |                                    |    |
|                      |  Store Results in Shared Volume   |    |
|                      |  and Process with SAF CLI         |    |
|                      |                                    |    |
|                      +------------------------------------+    |
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
+----------------------------------------------------------------+
|                                                                |
|                    STAGE 3: RESULTS PROCESSING                 |
|                                                                |
|  +-------------------+         +----------------------+        |
|  |                   |         |                      |        |
|  |  Retrieve Scan    |-------->|  Process Results    |        |
|  |  Results from     |         |  and Generate       |        |
|  |  Sidecar Container|         |  Reports            |        |
|  |                   |         |                      |        |
|  +-------------------+         +----------------------+        |
|                                           |                    |
|                                           v                    |
|                      +------------------------------------+    |
|                      |                                    |    |
|                      |  Upload Results as Pipeline       |    |
|                      |  Artifacts & Clean Up Resources   |    |
|                      |                                    |    |
|                      +------------------------------------+    |
|                                                                |
+----------------------------------------------------------------+
                                |
                                v
                         PIPELINE COMPLETE
```

## GitHub Actions Workflow

```
                   GITHUB ACTIONS WORKFLOW
                               |
                               v
+---------------------------------------------------------------+
|                                                               |
|                   STEP 1: ENVIRONMENT SETUP                   |
|                                                               |
| +------------------+        +------------------------+        |
| |                  |        |                        |        |
| | GitHub Actions   |------->| Setup Kubernetes       |        |
| | Workflow Start   |        | Cluster (Kind)         |        |
| |                  |        |                        |        |
| +------------------+        +------------------------+        |
|                                         |                     |
|                                         v                     |
|                    +-------------------------------------+    |
|                    |                                     |    |
|                    | Install CINC Auditor &              |    |
|                    | train-k8s-container Plugin          |    |
|                    |                                     |    |
|                    +-------------------------------------+    |
|                                                               |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
|                                                               |
|                   STEP 2: TARGET DEPLOYMENT                   |
|                                                               |
| +------------------+        +------------------------+        |
| |                  |        |                        |        |
| | Deploy Target    |------->| Create RBAC &          |        |
| | Container in     |        | Service Account        |        |
| | Kubernetes       |        | for Scanner            |        |
| |                  |        |                        |        |
| +------------------+        +------------------------+        |
|                                         |                     |
|                                         v                     |
|                    +-------------------------------------+    |
|                    |                                     |    |
|                    | Generate Short-lived Token &        |    |
|                    | Create Restricted kubeconfig       |    |
|                    |                                     |    |
|                    +-------------------------------------+    |
|                                                               |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
|                                                               |
|                   STEP 3: SCAN & REPORT                       |
|                                                               |
| +------------------+        +------------------------+        |
| |                  |        |                        |        |
| | Run CINC Auditor |------->| Process Results with   |        |
| | Against Target   |        | SAF CLI & Threshold    |        |
| | Container        |        | Validation             |        |
| |                  |        |                        |        |
| +------------------+        +------------------------+        |
|                                         |                     |
|                                         v                     |
|                    +-------------------------------------+    |
|                    |                                     |    |
|                    | Generate Reports, Upload as         |    |
|                    | GitHub Artifacts & Clean Up         |    |
|                    |                                     |    |
|                    +-------------------------------------+    |
|                                                               |
+---------------------------------------------------------------+
                               |
                               v
                       WORKFLOW COMPLETE
```

## GitHub Actions Sidecar Approach

```
                GITHUB ACTIONS SIDECAR APPROACH
                               |
                               v
+---------------------------------------------------------------+
|                                                               |
|                   STEP 1: ENVIRONMENT SETUP                   |
|                                                               |
| +------------------+        +------------------------+        |
| |                  |        |                        |        |
| | GitHub Actions   |------->| Setup Kubernetes       |        |
| | Workflow Start   |        | Cluster using Kind     |        |
| |                  |        |                        |        |
| +------------------+        +------------------------+        |
|                                         |                     |
|                                         v                     |
|                    +-------------------------------------+    |
|                    |                                     |    |
|                    | Build Scanner Container Image      |    |
|                    | with CINC Auditor & SAF CLI        |    |
|                    |                                     |    |
|                    +-------------------------------------+    |
|                                                               |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
|                                                               |
|                   STEP 2: DEPLOYMENT & SCANNING               |
|                                                               |
| +------------------+        +------------------------+        |
| |                  |        |                        |        |
| | Deploy Pod with  |------->| Configure Shared       |        |
| | Target Container |        | Process Namespace      |        |
| | and Scanner      |        | Between Containers     |        |
| | Sidecar          |        |                        |        |
| +------------------+        +------------------------+        |
|                                         |                     |
|                                         v                     |
|                    +-------------------------------------+    |
|                    |                                     |    |
|                    | Scanner Sidecar Automatically       |    |
|                    | Finds & Scans Target Container     |    |
|                    | via /proc/PID/root Access          |    |
|                    |                                     |    |
|                    +-------------------------------------+    |
|                                                               |
+---------------------------------------------------------------+
                               |
                               v
+---------------------------------------------------------------+
|                                                               |
|                   STEP 3: RESULTS PROCESSING                  |
|                                                               |
| +------------------+        +------------------------+        |
| |                  |        |                        |        |
| | Wait for Scan    |------->| Retrieve Results       |        |
| | Completion       |        | from Sidecar Container |        |
| |                  |        |                        |        |
| +------------------+        +------------------------+        |
|                                         |                     |
|                                         v                     |
| +------------------+        +------------------------+        |
| |                  |        |                        |        |
| | Process Results  |------->| Upload Results         |        |
| | with SAF CLI &   |        | as GitHub Artifacts    |        |
| | Generate Reports |        | & Clean Up Resources   |        |
| |                  |        |                        |        |
| +------------------+        +------------------------+        |
|                                                               |
+---------------------------------------------------------------+
                               |
                               v
                       WORKFLOW COMPLETE
```

## End-to-End Security Architecture

```
                   SECURITY ARCHITECTURE
                            |
                            v
+------------------------------------------------------+
|                                                      |
|                SECURITY PRINCIPLES                   |
|                                                      |
|  +------------------+      +------------------+      |
|  |                  |      |                  |      |
|  |   Principle of   |----->|   Short-lived    |      |
|  |   Least          |      |   Token          |      |
|  |   Privilege      |      |   Generation     |      |
|  |                  |      |                  |      |
|  +------------------+      +------------------+      |
|           |                        |                 |
|           v                        v                 |
|  +------------------+      +------------------+      |
|  |                  |      |                  |      |
|  |   Namespace      |<---->|   No Permanent   |      |
|  |   Isolation      |      |   Elevated       |      |
|  |                  |      |   Privileges     |      |
|  |                  |      |                  |      |
|  +------------------+      +------------------+      |
|                                                      |
+------------------------------------------------------+
                            |
                            v
+------------------------------------------------------+
|                                                      |
|               IMPLEMENTATION CONTROLS                |
|                                                      |
|  +------------------+      +------------------+      |
|  |                  |      |                  |      |
|  | Resource-specific|<---->|   Security       |      |
|  | RBAC Controls    |      |   First Design   |      |
|  | (Pod-specific)   |      |                  |      |
|  |                  |      |                  |      |
|  +------------------+      +------------------+      |
|           |                        |                 |
|           v                        v                 |
|  +------------------+      +------------------+      |
|  |                  |      |                  |      |
|  |   Audit Trail    |<---->|   Automatic      |      |
|  |   of Scan        |      |   Cleanup After  |      |
|  |   Access         |      |   Scan Completion|      |
|  |                  |      |                  |      |
|  +------------------+      +------------------+      |
|                                                      |
+------------------------------------------------------+
                            |
                            v
+------------------------------------------------------+
|                                                      |
|                COMPLIANCE VALIDATION                 |
|                                                      |
|  +--------------------------------------------------+|
|  |                                                  ||
|  |            Threshold-based Compliance            ||
|  |            Validation with SAF CLI               ||
|  |                                                  ||
|  |       * Minimum compliance percentage            ||
|  |       * Maximum critical/high failures           ||
|  |       * Enforced in CI/CD pipelines              ||
|  |                                                  ||
|  +--------------------------------------------------+|
|                                                      |
+------------------------------------------------------+
```

## Comparison of Approaches

```
+---------------------------------------------------------------------+
|                                                                     |
|                        APPROACH COMPARISON                          |
|                                                                     |
+---------------------------------------------------------------------+
|                                                                     |
|                        KEY CHARACTERISTICS                          |
|                                                                     |
+---------------------+----------------+-------------+----------------+
| FEATURE             | APPROACH 1     | APPROACH 2  | APPROACH 3     |
|                     | (Modified      | (Debug      | (Sidecar       |
|                     |  Plugin)       | Container)  | Container)     |
+---------------------+----------------+-------------+----------------+
| Works with all      |                |             |                |
| Kubernetes versions |      No        |     No      |      Yes       |
+---------------------+----------------+-------------+----------------+
| Works with          |                |             |                |
| existing pods       |      Yes       |     Yes     |      No        |
+---------------------+----------------+-------------+----------------+
| User experience     |    Seamless    |   Complex   |    Medium      |
| complexity          |                |             |                |
+---------------------+----------------+-------------+----------------+
| Implementation      |    Complex     |   Medium    |    Simple      |
| difficulty          |                |             |                |
+---------------------+----------------+-------------+----------------+

+---------------------------------------------------------------------+
|                                                                     |
|                      TECHNICAL REQUIREMENTS                         |
|                                                                     |
+---------------------+----------------+-------------+----------------+
| FEATURE             | APPROACH 1     | APPROACH 2  | APPROACH 3     |
|                     | (Modified      | (Debug      | (Sidecar       |
|                     |  Plugin)       | Container)  | Container)     |
+---------------------+----------------+-------------+----------------+
| Special K8s         |                |             |                |
| features needed     |      No        |     Yes     |      No        |
+---------------------+----------------+-------------+----------------+
| Ephemeral container |                |             |                |
| support required    |      No        |     Yes     |      No        |
+---------------------+----------------+-------------+----------------+
| Can scan distroless |                |             |                |
| containers          |      Yes       |     Yes     |      Yes       |
+---------------------+----------------+-------------+----------------+
| CI/CD               |                |             |                |
| integration ease    |    Simple      |   Complex   |    Medium      |
+---------------------+----------------+-------------+----------------+

+---------------------------------------------------------------------+
|                                                                     |
|                           IMPLEMENTATION STATUS                     |
|                                                                     |
+---------------------+----------------+-------------+----------------+
| FEATURE             | APPROACH 1     | APPROACH 2  | APPROACH 3     |
|                     | (Modified      | (Debug      | (Sidecar       |
|                     |  Plugin)       | Container)  | Container)     |
+---------------------+----------------+-------------+----------------+
| Development         | In Progress    | Complete    | Complete       |
| status              |                |             |                |
+---------------------+----------------+-------------+----------------+
| Security            |                |             |                |
| footprint           |    Medium      |   High      |    Medium      |
+---------------------+----------------+-------------+----------------+
| Recommended         | Enterprise     | Advanced    | Universal      |
| usage               | environments   | users       | compatibility  |
+---------------------+----------------+-------------+----------------+
| GitHub Actions      |                |             |                |
| example available   |      No        |     Yes     |      Yes       |
+---------------------+----------------+-------------+----------------+
| GitLab CI           |                |             |                |
| example available   |      No        |     Yes     |      Yes       |
+---------------------+----------------+-------------+----------------+
```