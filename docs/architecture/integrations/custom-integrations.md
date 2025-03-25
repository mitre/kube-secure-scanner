# Custom Integrations Architecture

This document details the architecture for integrating the Kubernetes CINC Secure Scanner with custom CI/CD platforms and external systems.

## Integration Overview

The custom integrations architecture provides guidance for integrating the scanning system with CI/CD platforms beyond GitHub Actions and GitLab CI, as well as with other external systems.

## Integration Architecture

The general architecture for custom integrations follows this pattern:

```mermaid
flowchart TD
    subgraph Platform["EXTERNAL PLATFORM"]
        direction TB
        workflow["Workflow Definition"]
        execution["Execution Environment"]
        triggers["Triggering Mechanism"]
    end
    
    subgraph Scanner["SCANNER COMPONENTS"]
        direction TB
        scripts["Scanner Scripts"]
        profiles["Security Profiles"]
        configuration["Scanner Configuration"]
    end
    
    subgraph Kubernetes["KUBERNETES ENVIRONMENT"]
        direction TB
        api["Kubernetes API"]
        rbac["RBAC Resources"]
        target["Target Containers"]
    end
    
    subgraph Results["RESULTS HANDLING"]
        direction TB
        processing["Results Processing"]
        storage["Results Storage"]
        reporting["Results Reporting"]
    end
    
    %% Component relationships
    Platform -->|integrates with| Scanner
    workflow -->|defines| execution
    triggers -->|activate| workflow
    execution -->|runs| scripts
    scripts -->|use| profiles
    scripts -->|apply| configuration
    Scanner -->|interacts with| Kubernetes
    scripts -->|create| rbac
    scripts -->|access| api
    scripts -->|scan| target
    Scanner -->|produces| Results
    processing -->|stores in| storage
    processing -->|generates| reporting
    
    %% WCAG-compliant styling
    style Platform fill:none,stroke:#0066CC,stroke-width:4px
    style Scanner fill:none,stroke:#DD6100,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style workflow fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style execution fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style triggers fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scripts fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style profiles fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style configuration fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style api fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style target fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style processing fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style storage fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reporting fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Supported Integration Platforms

The scanning system can be integrated with various platforms:

| Platform | Integration Type | Key Components |
|----------|-----------------|----------------|
| Jenkins | Pipeline script | Jenkins Pipeline DSL, shared library |
| CircleCI | Config file | .circleci/config.yml, orbs |
| Bamboo | Build plan | Build tasks, deployment projects |
| TeamCity | Build configuration | Build steps, parameters |
| Azure DevOps | Pipeline file | azure-pipelines.yml, tasks |
| AWS CodePipeline | Pipeline definition | CodeBuild projects, buildspec.yml |
| Spinnaker | Pipeline definition | Stages, triggers, notifications |
| Custom scripts | Direct execution | Bash/Python scripts, cron jobs |

## Integration Patterns

### 1. Direct Script Execution

The simplest pattern involves direct execution of scanner scripts:

```mermaid
flowchart TD
    A[Start Integration] --> B[Setup Environment]
    B --> C[Execute Scanner Scripts]
    C --> D[Process Results]
    D --> E[Report Status]
    E --> F[End Integration]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Container-based Integration

Using containers to package and run the scanner:

```mermaid
flowchart TD
    A[Start Integration] --> B[Pull Scanner Container]
    B --> C[Configure Container]
    C --> D[Run Container]
    D --> E[Extract Results]
    E --> F[Process Results]
    F --> G[End Integration]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style G fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 3. API-based Integration

Integrating through a custom API layer:

```mermaid
flowchart TD
    A[Start Integration] --> B[API Request]
    B --> C[API Service]
    C --> D[Scanner Service]
    D --> E[Kubernetes]
    D --> F[Results Service]
    F --> G[API Response]
    G --> H[End Integration]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style G fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style H fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Example Integrations

### Jenkins Pipeline Integration

```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: cinc
    image: registry.example.com/cinc-auditor:latest
    command:
    - cat
    tty: true
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
"""
        }
    }
    
    environment {
        PROFILE_PATH = 'examples/cinc-profiles/container-baseline'
        TARGET_NAMESPACE = 'default'
        TARGET_POD = 'web-app'
        TARGET_CONTAINER = 'web-container'
    }
    
    stages {
        stage('Setup') {
            steps {
                container('kubectl') {
                    sh 'kubectl apply -f test-pod.yaml'
                    sh 'kubectl wait --for=condition=Ready pod/$TARGET_POD --timeout=60s'
                }
            }
        }
        
        stage('Scan') {
            steps {
                container('cinc') {
                    sh """
                        cinc exec -t k8s-container://${TARGET_NAMESPACE}/${TARGET_POD}/${TARGET_CONTAINER} \
                            --input ${PROFILE_PATH} \
                            --reporter json:results.json
                    """
                }
            }
        }
        
        stage('Validate') {
            steps {
                container('cinc') {
                    sh """
                        if jq -e '.profiles[0].controls[] | select(.status == "failed")' results.json > /dev/null; then
                            echo "Security scan failed"
                            exit 1
                        else
                            echo "Security scan passed"
                        fi
                    """
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'results.json', allowEmptyArchive: true
        }
    }
}
```

### CircleCI Integration

```yaml
version: 2.1

jobs:
  scan:
    docker:
      - image: registry.example.com/scanner:latest
    steps:
      - checkout
      - setup_remote_docker
      - run:
          name: Setup Kubernetes
          command: |
            echo "${KUBECONFIG_CONTENT}" > kubeconfig.yaml
            export KUBECONFIG=kubeconfig.yaml
      - run:
          name: Deploy Target Container
          command: kubectl apply -f test-pod.yaml
      - run:
          name: Scan Container
          command: |
            ./scripts/scan-container.sh default test-pod test-container examples/cinc-profiles/container-baseline
      - run:
          name: Validate Results
          command: |
            if jq -e '.failure_count > 0' results/summary.json; then
              echo "Security scan failed"
              exit 1
            else
              echo "Security scan passed"
            fi
      - store_artifacts:
          path: results/
          destination: scan-results

workflows:
  security-scan:
    jobs:
      - scan
```

### AWS CodeBuild Integration

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      ruby: 2.7
    commands:
      - curl -LO "https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl"
      - chmod +x kubectl && mv kubectl /usr/local/bin/
      - gem install cinc-auditor-bin saf
      
  pre_build:
    commands:
      - mkdir -p ~/.kube
      - echo "${KUBECONFIG_CONTENT}" > ~/.kube/config
      - chmod 600 ~/.kube/config
      - kubectl apply -f test-pod.yaml
      - kubectl wait --for=condition=Ready pod/test-pod --timeout=60s
      
  build:
    commands:
      - cinc exec -t k8s-container://default/test-pod/test-container --input examples/cinc-profiles/container-baseline --reporter json:results.json
      
  post_build:
    commands:
      - saf validate results.json -c examples/thresholds/moderate.yml --reporter cli
      - |
        if [ $(jq '.failure_count' results.json) -gt 0 ]; then
          echo "Security scan failed"
          exit 1
        else
          echo "Security scan passed"
        fi

artifacts:
  files:
    - results.json
    - validation.json
  name: scan-results
```

## Custom API Integration

For programmatic integration, a custom API layer can be implemented:

```mermaid
flowchart TD
    subgraph API["CUSTOM API LAYER"]
        direction TB
        endpoints["API Endpoints"]
        auth["Authentication"]
        validation["Input Validation"]
    end
    
    subgraph Service["SCANNER SERVICE"]
        direction TB
        queue["Scan Queue"]
        worker["Scanner Worker"]
        storage["Result Storage"]
    end
    
    subgraph Clients["CLIENT INTEGRATIONS"]
        direction TB
        ci["CI/CD Systems"]
        scripts["Custom Scripts"]
        dashboards["Security Dashboards"]
    end
    
    Clients -->|request scan| API
    API -->|validates| validation
    API -->|authenticates| auth
    API -->|submits to| Service
    endpoints -->|defines| queue
    worker -->|processes from| queue
    worker -->|writes to| storage
    API -->|retrieves from| storage
    API -->|returns to| Clients
    
    %% WCAG-compliant styling
    style API fill:none,stroke:#0066CC,stroke-width:4px
    style Service fill:none,stroke:#DD6100,stroke-width:4px
    style Clients fill:none,stroke:#505050,stroke-width:4px
    
    %% Component styling
    style endpoints fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style auth fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style validation fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style queue fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style worker fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style storage fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style ci fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scripts fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style dashboards fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### API Endpoints

Example API endpoints for custom integration:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/scans` | POST | Create new scan |
| `/api/v1/scans/{id}` | GET | Get scan status |
| `/api/v1/scans/{id}/results` | GET | Get scan results |
| `/api/v1/profiles` | GET | List available profiles |
| `/api/v1/thresholds` | GET | List available thresholds |

### Example API Request

```json
{
  "target": {
    "namespace": "default",
    "pod": "web-app",
    "container": "web-container"
  },
  "scan": {
    "profile": "container-baseline",
    "threshold": "moderate"
  },
  "options": {
    "timeout": 300,
    "reportFormat": "json"
  },
  "callback": {
    "url": "https://ci-system.example.com/callbacks/scan-123",
    "authentication": {
      "type": "bearer",
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  }
}
```

## Event-Driven Integration

For event-driven architectures, the scanner can be triggered by events:

```mermaid
flowchart TD
    subgraph Sources["EVENT SOURCES"]
        direction TB
        container_deploy["Container Deployment"]
        image_publish["Image Publication"]
        scheduled_event["Scheduled Event"]
    end
    
    subgraph Bus["EVENT BUS"]
        direction TB
        events["Events"]
        routing["Event Routing"]
    end
    
    subgraph Handler["EVENT HANDLERS"]
        direction TB
        scanner_trigger["Scanner Trigger"]
        scanner_executor["Scanner Executor"]
    end
    
    subgraph Results["RESULTS HANDLERS"]
        direction TB
        notification["Notification Service"]
        storage["Storage Service"]
        remediation["Remediation Service"]
    end
    
    Sources -->|emit events to| Bus
    Bus -->|routes to| Handler
    Handler -->|produces| Results
    container_deploy -->|container.deployed| events
    image_publish -->|image.published| events
    scheduled_event -->|scan.scheduled| events
    events -->|matched by| routing
    routing -->|triggers| scanner_trigger
    scanner_trigger -->|initiates| scanner_executor
    scanner_executor -->|generates| notification
    scanner_executor -->|saves to| storage
    scanner_executor -->|may trigger| remediation
    
    %% WCAG-compliant styling
    style Sources fill:none,stroke:#0066CC,stroke-width:4px
    style Bus fill:none,stroke:#DD6100,stroke-width:4px
    style Handler fill:none,stroke:#217645,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style container_deploy fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style image_publish fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scheduled_event fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style events fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style routing fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scanner_trigger fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scanner_executor fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style notification fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style storage fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style remediation fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Security Considerations

When implementing custom integrations, consider these security aspects:

1. **Authentication**: Secure authentication mechanisms for API access
2. **Authorization**: Proper permission controls for scanning operations
3. **Credential Management**: Secure handling of Kubernetes credentials
4. **Network Security**: Secure communication between components
5. **Result Protection**: Protection of sensitive scan results

## Integration Best Practices

Follow these best practices for custom integrations:

1. **Modularity**: Keep integration components modular for flexibility
2. **Configuration**: Use configuration files for environment-specific settings
3. **Error Handling**: Implement robust error handling and reporting
4. **Scalability**: Design for scalability to handle multiple concurrent scans
5. **Monitoring**: Include monitoring and logging for visibility
6. **Documentation**: Maintain clear documentation for custom integrations
7. **Testing**: Thoroughly test integrations before production use
8. **Maintenance**: Plan for ongoing maintenance and updates

## Custom Integration Tools

Several tools and libraries can help with custom integrations:

| Tool | Purpose | Integration Use |
|------|---------|-----------------|
| REST APIs | Service communication | Build API integrations |
| Webhooks | Event notification | Trigger scans on events |
| Message Queues | Asynchronous processing | Queue scan requests |
| Docker | Containerization | Package scanner components |
| Kubernetes CRDs | Custom resources | Define scan specifications |
| OAuth/OIDC | Authentication | Secure API access |
| OpenAPI | API documentation | Document integration APIs |

## Additional Resources

For more information on custom integrations, see:

- [Enterprise Integration Analysis](../../overview/enterprise-integration-analysis.md)
- [Integration Overview](../../integration/overview.md)
- [Approach Mapping](../../integration/approach-mapping.md)