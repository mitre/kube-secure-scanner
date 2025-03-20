# Container Scanning Workflow Diagrams

This document provides WCAG-compliant Mermaid diagrams illustrating the key scanning workflows, CI/CD integrations, and architecture patterns in our container security platform. These diagrams follow our project's color standards and are designed to display properly in both light and dark modes.

## Minikube Architecture

```mermaid
flowchart TD
    subgraph MiniKubeCluster["MINIKUBE CLUSTER"]
        direction TB
        subgraph ControlNode["CONTROL NODE"]
            direction TB
            apiserver["kube-apiserver"]
            etcd["etcd"]
        end
        
        subgraph WorkerNode1["WORKER NODE 1"]
            direction TB
            containers["Target Containers"]
            scanner_pods["Scanner Pods"]
        end
        
        subgraph WorkerNode2["WORKER NODE 2"]
            direction TB
            debug_containers["Debug Containers"]
            sidecar_pods["Sidecar Pods"]
        end
    end
    
    MiniKubeCluster --- cinc["CINC Profiles\n(Compliance Controls)"]
    MiniKubeCluster --- rbac["Service Accounts\nand RBAC\n(Access Control)"]
    MiniKubeCluster --- saf["SAF CLI\n(Reporting &\nThresholds)"]
    
    %% WCAG-compliant styling for subgraph labels - works in both light/dark
    style MiniKubeCluster fill:none,stroke:#505050,stroke-width:4px
    style ControlNode fill:none,stroke:#0066CC,stroke-width:4px
    style WorkerNode1 fill:none,stroke:#0066CC,stroke-width:4px
    style WorkerNode2 fill:none,stroke:#0066CC,stroke-width:4px
    
    %% Component styling
    style apiserver fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style etcd fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style containers fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scanner_pods fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug_containers fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sidecar_pods fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cinc fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF

```

## Kubernetes API Approach Workflow

```mermaid
flowchart TD
    start([START KUBERNETES API APPROACH]) --> step1
    
    subgraph step1["STEP 1: SETUP & PREPARATION"]
        direction TB
        identify["Identify Target Container"] --> create_rbac["Create RBAC and Service Account"]
        create_rbac --> generate_token["Generate Short-lived Security Token"]
        generate_token --> create_kubeconfig["Create Restricted Kubeconfig File"]
    end
    
    step1 --> step2
    
    subgraph step2["STEP 2: SCANNING EXECUTION"]
        direction TB
        run_cinc["Run CINC Auditor with k8s-container Transport"] --> process["Process with SAF CLI & Check Threshold"]
        process --> generate_reports["Generate Reports and Validations"]
        generate_reports --> cleanup["Clean up RBAC & Service Account"]
    end
    
    step2 --> complete([SCAN COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling with WCAG-compliant colors
    style identify fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style generate_token fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_kubeconfig fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style generate_reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cleanup fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Debug Container Approach Workflow

```mermaid
flowchart TD
    start([START DEBUG CONTAINER APPROACH]) --> step1
    
    subgraph step1["STEP 1: ATTACH DEBUG CONTAINER"]
        direction TB
        identify["Identify Distroless Target Container"] --> create_debug["Create Ephemeral Debug Container"]
        create_debug --> deploy_cinc["Deploy CINC Auditor in Debug Container"]
    end
    
    step1 --> step2
    
    subgraph step2["STEP 2: PERFORM SCANNING THROUGH DEBUG CONTAINER"]
        direction TB
        chroot["Chroot to Target Container Filesystem"] --> run_cinc["Run CINC Auditor Against Target"]
        run_cinc --> export_results["Export Scan Results to Host System"]
        export_results --> process["Process Results with SAF CLI"]
        process --> terminate["Terminate Debug Container & Clean Up"]
    end
    
    step2 --> complete([SCAN COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling with WCAG-compliant colors
    style identify fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_debug fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style deploy_cinc fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style chroot fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style export_results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style terminate fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
```

## Sidecar Approach Workflow

```mermaid
flowchart TD
    start([START SIDECAR APPROACH]) --> step1
    
    subgraph step1["STEP 1: DEPLOY POD WITH SIDECAR"]
        direction TB
        deploy_target["Deploy Target Container in Pod"] --> deploy_sidecar["Deploy Scanner Sidecar Container"]
        deploy_sidecar --> shared_namespace["Enable Shared Process Namespace"]
    end
    
    step1 --> step2
    
    subgraph step2["STEP 2: PERFORM SCAN USING SIDECAR"]
        direction TB
        find_process["Sidecar Finds Target Process"] --> access_fs["Access Target via /proc/PID/root"]
        access_fs --> run_cinc["Run CINC Auditor Against Target"]
        run_cinc --> store_results["Store Results in Shared Volume"]
        store_results --> process_results["Process Results with SAF CLI"]
        process_results --> retrieve_results["Retrieve Results from Sidecar"]
    end
    
    step2 --> complete([SCAN COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling
    style deploy_target fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style deploy_sidecar fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style shared_namespace fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style find_process fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style access_fs fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style store_results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process_results fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style retrieve_results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Enhanced Kubernetes API Approach Workflow

```mermaid
flowchart TD
    start([START ENHANCED KUBERNETES API APPROACH]) --> step1
    
    subgraph step1["STEP 1: CONTAINER DETECTION AND SETUP"]
        direction TB
        identify["Target Container Identification"] --> plugin["Modified train-k8s-container Plugin"]
        plugin --> detect["Auto-Detect if Container is Distroless"]
        detect -->|Regular| standard["Use Standard Direct Exec Connection"]
        detect -->|Distroless| debug["Use Debug Container Fallback"]
        debug --> create_debug["Create Temporary Debug Container"]
    end
    
    standard --> step2
    create_debug --> step2
    
    subgraph step2["STEP 2: SCANNING EXECUTION"]
        direction TB
        run_cinc["Run CINC Auditor Scan"] --> process["Process Results with SAF CLI"]
    end
    
    step2 --> step3
    
    subgraph step3["STEP 3: CLEANUP (FOR DISTROLESS)"]
        direction TB
        cleanup["Terminate and Clean Up Resources"]
    end
    
    step3 --> complete([SCAN COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    style step3 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling
    style identify fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style plugin fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style detect fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style standard fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_debug fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cleanup fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## GitLab CI Kubernetes API Approach with Services

```mermaid
flowchart TD
    start([GITLAB CI WITH SERVICES]) --> stage1
    
    subgraph stage1["STAGE 1: PIPELINE SETUP"]
        direction TB
        pipeline_start["GitLab CI Pipeline Begins"] --> start_service["Start CINC Auditor Scanner Service"]
        start_service --> deploy["Deploy Target Container"]
    end
    
    stage1 --> stage2
    
    subgraph stage2["STAGE 2: SECURITY SETUP"]
        direction TB
        create_rbac["Create RBAC & Service Account"] --> generate_token["Generate Short-lived Security Token"]
        generate_token --> create_kubeconfig["Create Restricted kubeconfig"]
    end
    
    stage2 --> stage3
    
    subgraph stage3["STAGE 3: SCANNING & REPORTING"]
        direction TB
        execute_scan["Execute Scan in Service Container"] --> process["Process Results with SAF CLI"]
        process --> copy_results["Copy Results & Generate Reports"]
        copy_results --> cleanup["Clean Up Resources"]
    end
    
    stage3 --> complete([COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Stage styling with WCAG-compliant colors - works in both light/dark
    style stage1 fill:none,stroke:#DD6100,stroke-width:4px
    style stage2 fill:none,stroke:#DD6100,stroke-width:4px
    style stage3 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling with WCAG-compliant colors
    style pipeline_start fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style start_service fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style deploy fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style generate_token fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_kubeconfig fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style execute_scan fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style copy_results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cleanup fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## GitLab CI Sidecar Approach

```mermaid
flowchart TD
    start([GITLAB CI SIDECAR APPROACH]) --> stage1
    
    subgraph stage1["STAGE 1: DEPLOYMENT"]
        direction TB
        pipeline_start["GitLab CI Pipeline Begins"] --> deploy["Deploy Pod with Target and Sidecar"]
        deploy --> shared_namespace["Enable Shared Process Namespace"]
    end
    
    stage1 --> stage2
    
    subgraph stage2["STAGE 2: SCANNING"]
        direction TB
        sidecar_start["Sidecar Scanner Starts"] --> scan["Scan Target via /proc Filesystem"]
        scan --> store_results["Store Results in Shared Volume"]
    end
    
    stage2 --> stage3
    
    subgraph stage3["STAGE 3: RESULTS PROCESSING"]
        direction TB
        retrieve["Retrieve Results from Sidecar"] --> process["Process Results and Generate Reports"]
        process --> upload["Upload Results & Clean Up Resources"]
    end
    
    stage3 --> complete([COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Stage styling with WCAG-compliant colors - works in both light/dark
    style stage1 fill:none,stroke:#DD6100,stroke-width:4px
    style stage2 fill:none,stroke:#DD6100,stroke-width:4px
    style stage3 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling with WCAG-compliant colors
    style pipeline_start fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style deploy fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style shared_namespace fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sidecar_start fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scan fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style store_results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style retrieve fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style upload fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## GitHub Actions Kubernetes API Approach

```mermaid
flowchart TD
    start([GITHUB ACTIONS KUBERNETES API APPROACH]) --> step1
    
    subgraph step1["STEP 1: ENVIRONMENT SETUP"]
        direction TB
        workflow_start["GitHub Actions Workflow Start"] --> setup_k8s["Setup Kubernetes Cluster"]
        setup_k8s --> install["Install CINC Auditor & Plugin"]
    end
    
    step1 --> step2
    
    subgraph step2["STEP 2: TARGET DEPLOYMENT"]
        direction TB
        deploy["Deploy Target Container"] --> create_rbac["Create RBAC & Service Account"]
        create_rbac --> generate_token["Generate Token & kubeconfig"]
    end
    
    step2 --> step3
    
    subgraph step3["STEP 3: SCAN & REPORT"]
        direction TB
        run_cinc["Run CINC Auditor Against Target"] --> process["Process Results with SAF CLI"]
        process --> generate_reports["Generate Reports & Clean Up"]
    end
    
    step3 --> complete([COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    style step3 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling with WCAG-compliant colors
    style workflow_start fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style setup_k8s fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style install fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style deploy fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style generate_token fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style generate_reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## GitHub Actions Sidecar Approach

```mermaid
flowchart TD
    start([START GITHUB ACTIONS SIDECAR APPROACH]) --> step1
    
    subgraph step1["STEP 1: ENVIRONMENT SETUP"]
        direction TB
        workflow_start["GitHub Actions Workflow Start"] --> setup_k8s["Setup Kubernetes Cluster"]
        setup_k8s --> build_image["Build Scanner Container Image"]
    end
    
    step1 --> step2
    
    subgraph step2["STEP 2: DEPLOYMENT & SCANNING"]
        direction TB
        deploy["Deploy Pod with Target and Scanner"] --> shared_namespace["Configure Shared Process Namespace"]
        shared_namespace --> scanner_scan["Sidecar Scans Target Container"]
    end
    
    step2 --> step3
    
    subgraph step3["STEP 3: RESULTS PROCESSING"]
        direction TB
        wait["Wait for Completion"] --> retrieve["Retrieve Results"]
        retrieve --> process["Process Results & Generate Reports"]
        process --> upload["Upload Results & Clean Up"]
    end
    
    step3 --> complete([COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    style step3 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling with WCAG-compliant colors
    style workflow_start fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style setup_k8s fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style build_image fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style deploy fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style shared_namespace fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scanner_scan fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style wait fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style retrieve fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style upload fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## End-to-End Security Architecture

```mermaid
flowchart TD
    start([START]) --> principles
    
    subgraph principles["SECURITY PRINCIPLES"]
        direction TB
        least_privilege["Principle of Least Privilege"] --> token["Short-lived Token Generation"]
        namespace["Namespace Isolation"] --> no_privileges["No Permanent Elevated Privileges"]
    end
    
    principles --> controls
    
    subgraph controls["IMPLEMENTATION CONTROLS"]
        direction TB
        rbac["Resource-specific RBAC Controls"] --> security_first["Security First Design"]
        audit["Audit Trail of Scan Access"] --> cleanup["Automatic Cleanup"]
    end
    
    controls --> compliance
    
    subgraph compliance["COMPLIANCE VALIDATION"]
        direction TB
        threshold["Threshold-based Validation with SAF CLI"]
    end
    
    compliance --> complete([END])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Section styling with WCAG-compliant colors - works in both light/dark
    style principles fill:none,stroke:#DD6100,stroke-width:4px
    style controls fill:none,stroke:#DD6100,stroke-width:4px
    style compliance fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling
    style least_privilege fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style token fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style namespace fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style no_privileges fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style security_first fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style audit fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cleanup fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style threshold fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```