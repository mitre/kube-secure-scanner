# Custom Development

This guide covers custom development and extension of the Secure CINC Auditor Kubernetes Container Scanning solution.

## Overview

The scanner solution can be extended and customized to meet specific requirements. This guide covers custom script development, plugin creation, and integration with other systems.

## Custom Script Development

For advanced users who need to develop custom deployment scripts:

```bash
#!/bin/bash
# custom-deployment.sh

# Configuration variables
NAMESPACE="security-scanner"
SCANNER_IMAGE="cinc/auditor:latest"
PROFILE_PATH="/path/to/profiles"
THRESHOLD_FILE="/path/to/thresholds.yml"
TOKEN_DURATION="1h"

# Create namespace
kubectl create namespace $NAMESPACE

# Create RBAC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scanner-sa
  namespace: $NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: scanner-role
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: scanner-rolebinding
subjects:
  - kind: ServiceAccount
    name: scanner-sa
    namespace: $NAMESPACE
roleRef:
  kind: ClusterRole
  name: scanner-role
  apiGroup: rbac.authorization.k8s.io
EOF

# Create scanner job
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: scanner-job
  namespace: $NAMESPACE
spec:
  template:
    spec:
      serviceAccountName: scanner-sa
      containers:
      - name: scanner
        image: $SCANNER_IMAGE
        command:
        - /bin/sh
        - -c
        - |
          cinc-auditor exec $PROFILE_PATH -t k8s-container://target-container --namespace default
      restartPolicy: Never
  backoffLimit: 1
EOF

# Wait for job completion
kubectl wait --for=condition=complete job/scanner-job -n $NAMESPACE --timeout=300s

# Get results
pod=$(kubectl get pods -n $NAMESPACE -l job-name=scanner-job -o jsonpath='{.items[0].metadata.name}')
kubectl logs $pod -n $NAMESPACE > results.json

# Validate results
echo "Validating results against thresholds..."
saf validate -i results.json -f $THRESHOLD_FILE

# Cleanup
kubectl delete job scanner-job -n $NAMESPACE
```

## Best Practices for Custom Scripts

Follow these best practices when developing custom scripts:

1. **Error Handling**: Implement robust error handling and logging
2. **Idempotency**: Make scripts idempotent to allow retries
3. **Parameterization**: Make scripts configurable through parameters
4. **Documentation**: Document script purpose, parameters, and usage
5. **Testing**: Test scripts in isolated environments before production use

```bash
#!/bin/bash
# Example of a well-structured custom script

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# Script information
# Name: enhanced-scanner.sh
# Description: Enhanced scanner deployment with custom configurations
# Usage: ./enhanced-scanner.sh [options]
# Options:
#   -n, --namespace NAMESPACE    Namespace to deploy scanner (default: scanner-system)
#   -i, --image IMAGE            Scanner image to use (default: cinc/auditor:latest)
#   -p, --profile PROFILE        Profile path (default: profiles/baseline)
#   -t, --timeout SECONDS        Scan timeout in seconds (default: 300)
#   -h, --help                   Show this help message

# Default values
NAMESPACE="scanner-system"
IMAGE="cinc/auditor:latest"
PROFILE="profiles/baseline"
TIMEOUT=300

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -i|--image)
      IMAGE="$2"
      shift 2
      ;;
    -p|--profile)
      PROFILE="$2"
      shift 2
      ;;
    -t|--timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./enhanced-scanner.sh [options]"
      echo "Options:"
      echo "  -n, --namespace NAMESPACE    Namespace to deploy scanner (default: scanner-system)"
      echo "  -i, --image IMAGE            Scanner image to use (default: cinc/auditor:latest)"
      echo "  -p, --profile PROFILE        Profile path (default: profiles/baseline)"
      echo "  -t, --timeout SECONDS        Scan timeout in seconds (default: 300)"
      echo "  -h, --help                   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
handle_error() {
  log "ERROR: $1"
  exit 1
}

# Verify kubectl is installed
if ! command -v kubectl &> /dev/null; then
  handle_error "kubectl not found, please install kubectl"
fi

# Main functionality
log "Starting scanner deployment in namespace $NAMESPACE"

# Create namespace if it doesn't exist
kubectl get namespace $NAMESPACE &> /dev/null || kubectl create namespace $NAMESPACE

# Rest of the script...
```

## Custom Profile Development

Develop custom security profiles for specific requirements:

```ruby
# Example custom profile: kubernetes-custom.rb
control 'K8S-CUSTOM-1' do
  impact 1.0
  title 'Ensure containers do not run with privileged flag'
  desc 'Running containers with the privileged flag gives them full access to the host system.'
  
  containers = json('/api/v1/pods').pod.each_with_object([]) do |pod, arr|
    pod.spec.containers.each do |container|
      arr << {
        'pod' => pod.metadata.name,
        'container' => container.name,
        'privileged' => container.securityContext.privileged
      }
    end
  end
  
  containers.each do |container|
    describe "Container #{container['pod']}/#{container['container']}" do
      it 'should not have privileged flag set to true' do
        expect(container['privileged']).not_to eq true
      end
    end
  end
end
```

## Custom Integration Development

Develop custom integrations with other systems:

```ruby
# Example custom integration: slack-notifier.rb
require 'uri'
require 'net/http'
require 'json'

class SlackNotifier
  def initialize(webhook_url)
    @webhook_url = webhook_url
  end
  
  def notify(message, severity = :info)
    color = case severity
            when :info then "#36a64f"
            when :warning then "#ffcc00"
            when :critical then "#ff0000"
            else "#eeeeee"
            end
    
    payload = {
      text: "Scanner Notification",
      attachments: [
        {
          color: color,
          text: message,
          ts: Time.now.to_i
        }
      ]
    }
    
    send_notification(payload)
  end
  
  def notify_scan_results(results)
    stats = calculate_statistics(results)
    
    color = if stats[:critical] > 0
              "#ff0000"
            elsif stats[:high] > 0
              "#ff9900"
            elsif stats[:medium] > 0
              "#ffcc00"
            else
              "#36a64f"
            end
    
    payload = {
      text: "Scan Completed",
      attachments: [
        {
          color: color,
          title: "Scan Results Summary",
          fields: [
            {
              title: "Critical Findings",
              value: stats[:critical],
              short: true
            },
            {
              title: "High Findings",
              value: stats[:high],
              short: true
            },
            {
              title: "Medium Findings",
              value: stats[:medium],
              short: true
            },
            {
              title: "Low Findings",
              value: stats[:low],
              short: true
            }
          ],
          ts: Time.now.to_i
        }
      ]
    }
    
    send_notification(payload)
  end
  
  private
  
  def send_notification(payload)
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    
    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = payload.to_json
    
    response = http.request(request)
    
    unless response.code.to_i == 200
      puts "Error sending notification: #{response.code} - #{response.body}"
    end
  end
  
  def calculate_statistics(results)
    stats = { critical: 0, high: 0, medium: 0, low: 0 }
    
    results['profiles'].each do |profile|
      profile['controls'].each do |control|
        control['results'].each do |result|
          if result['status'] == 'failed'
            case control['impact']
            when 0.9..1.0
              stats[:critical] += 1
            when 0.7...0.9
              stats[:high] += 1
            when 0.4...0.7
              stats[:medium] += 1
            else
              stats[:low] += 1
            end
          end
        end
      end
    end
    
    stats
  end
end

# Usage
notifier = SlackNotifier.new('https://hooks.slack.com/services/YOUR/WEBHOOK/URL')
notifier.notify('Scanner started', :info)

# After scan completes
results = JSON.parse(File.read('results.json'))
notifier.notify_scan_results(results)
```

## Custom Helm Chart Development

Develop custom Helm charts for specialized deployments:

```yaml
# Example custom-scanner/Chart.yaml
apiVersion: v2
name: custom-scanner
description: A custom scanner for specialized environments
type: application
version: 0.1.0
appVersion: 1.0.0
dependencies:
  - name: scanner-infrastructure
    version: ">=1.0.0"
    repository: "file://../scanner-infrastructure"
```

```yaml
# Example custom-scanner/values.yaml
global:
  environment: production
  namespace: custom-scanner

scanner:
  image:
    repository: custom/scanner
    tag: latest
  
  customization:
    enabled: true
    features:
      - name: specialized-scans
        enabled: true
      - name: custom-reporting
        enabled: true
    
    configuration:
      specializedMode: true
      reportFormat: "custom-format"
```

```yaml
# Example custom-scanner/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "custom-scanner.fullname" . }}
  labels:
    {{- include "custom-scanner.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "custom-scanner.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "custom-scanner.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "custom-scanner.serviceAccountName" . }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.scanner.image.repository }}:{{ .Values.scanner.image.tag }}"
          imagePullPolicy: {{ .Values.scanner.image.pullPolicy }}
          env:
            - name: CUSTOM_MODE
              value: "{{ .Values.scanner.customization.configuration.specializedMode }}"
            - name: REPORT_FORMAT
              value: "{{ .Values.scanner.customization.configuration.reportFormat }}"
          volumeMounts:
            - name: config-volume
              mountPath: /config
            - name: custom-profiles
              mountPath: /profiles
      volumes:
        - name: config-volume
          configMap:
            name: {{ include "custom-scanner.fullname" . }}-config
        - name: custom-profiles
          configMap:
            name: {{ include "custom-scanner.fullname" . }}-profiles
```

## Related Topics

- [Helm Deployment](../helm-deployment.md)
- [Script Deployment](../script-deployment.md)
- [Deployment Verification](verification.md)
