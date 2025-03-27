# Testing Plugin Modifications

This document provides guidelines for testing the modifications to the train-k8s-container plugin, particularly for distroless container support.

## Testing Approach

Testing the plugin modifications requires a combination of unit tests, integration tests, and end-to-end tests. This ensures that the plugin works correctly across different scenarios and environments.

## Unit Testing

### Setting Up Unit Tests

Unit tests for the train-k8s-container plugin are written using RSpec. They can be found in the `spec` directory.

```bash
# Install testing dependencies
bundle install --with development

# Run the unit tests
bundle exec rake spec
```

### Key Unit Tests to Implement

1. **Distroless Detection Tests**

```ruby
describe '#distroless?' do
  context 'when container has a shell' do
    before do
      allow(Train::Extras::CommandWrapper).to receive(:run).and_return(double(stdout: "test\n", stderr: "", exit_status: 0))
    end
    
    it 'returns false' do
      expect(subject.distroless?('default', 'test-pod', 'test-container')).to be false
    end
  end
  
  context 'when container does not have a shell' do
    before do
      allow(Train::Extras::CommandWrapper).to receive(:run).and_raise(Train::Errors::CommandExecutionError.new('Error', '', '', 1))
    end
    
    it 'returns true' do
      expect(subject.distroless?('default', 'test-pod', 'test-container')).to be true
    end
  end
end
```

2. **Ephemeral Container Tests**

```ruby
describe '#setup_ephemeral_container' do
  before do
    allow(Process).to receive(:spawn).and_return(12345)
    allow(Process).to receive(:detach)
    allow_any_instance_of(Object).to receive(:sleep)
  end
  
  it 'creates an ephemeral container and returns its details' do
    result = subject.setup_ephemeral_container('default', 'test-pod', 'test-container')
    expect(result).to include(:name, :pid)
    expect(result[:pid]).to eq(12345)
    expect(result[:name]).to match(/^inspec-debug-/)
  end
end
```

3. **File Access Tests**

```ruby
describe '#file' do
  context 'with standard container' do
    before do
      subject.instance_variable_set(:@using_ephemeral, false)
    end
    
    it 'returns a Remote file instance' do
      expect(Train::File::Remote).to receive(:new).with(subject, '/etc/passwd')
      subject.file('/etc/passwd')
    end
  end
  
  context 'with distroless container' do
    before do
      subject.instance_variable_set(:@using_ephemeral, true)
      subject.instance_variable_set(:@options, { container: 'test-container' })
      allow(subject.instance_variable_get(:@k8s_client)).to receive(:run_command).and_return(double(stdout: "123\n", stderr: "", exit_status: 0))
    end
    
    it 'returns a Local file instance with modified path' do
      expect(Train::File::Local).to receive(:new).with(subject, '/proc/123/root/etc/passwd')
      subject.file('/etc/passwd')
    end
  end
end
```

## Integration Testing

### Setting Up a Test Environment

For integration testing, set up a Kubernetes cluster with both standard and distroless containers:

```bash
# Start minikube with ephemeral container support
minikube start --kubernetes-version=v1.23.0

# Deploy a standard container
kubectl create deployment nginx --image=nginx

# Deploy a distroless container
kubectl create deployment distroless --image=gcr.io/distroless/static-debian11
```

### Manual Integration Tests

1. Test with standard container:

```bash
# Run InSpec with modified plugin against standard container
INSPEC_LOG_LEVEL=debug inspec exec profile -t k8s-container://default/$(kubectl get pods -l app=nginx -o name | cut -d/ -f2)/nginx
```

2. Test with distroless container:

```bash
# Run InSpec with modified plugin against distroless container
INSPEC_LOG_LEVEL=debug inspec exec profile -t k8s-container://default/$(kubectl get pods -l app=distroless -o name | cut -d/ -f2)/distroless
```

### Automated Integration Tests

Create an integration test script:

```ruby
#!/usr/bin/env ruby
require 'json'

def run_test(name, namespace, pod, container)
  puts "Running test: #{name}"
  cmd = "inspec exec ./test-profile -t k8s-container://#{namespace}/#{pod}/#{container} --reporter json"
  output = `#{cmd}`
  begin
    result = JSON.parse(output)
    status = result['profiles'][0]['status'] == 'passed' ? "PASSED" : "FAILED"
    puts "Test #{name}: #{status}"
    puts "Summary: #{result['profiles'][0]['controls'].size} controls, #{result['profiles'][0]['controls'].count { |c| c['status'] == 'passed' }} passed"
  rescue => e
    puts "Error parsing results: #{e.message}"
    puts output
  end
end

# Get pods
nginx_pod = `kubectl get pods -l app=nginx -o name | cut -d/ -f2`.strip
distroless_pod = `kubectl get pods -l app=distroless -o name | cut -d/ -f2`.strip

# Run tests
run_test("Standard Container", "default", nginx_pod, "nginx")
run_test("Distroless Container", "default", distroless_pod, "distroless")
```

## End-to-End Testing

### Test with Real Profiles

Test the plugin with real compliance profiles to ensure it works in practical scenarios:

```bash
# Test with DevSec Linux Baseline
inspec exec https://github.com/dev-sec/linux-baseline -t k8s-container://default/nginx-pod/nginx

# Test with DevSec Linux Baseline against distroless container
inspec exec https://github.com/dev-sec/linux-baseline -t k8s-container://default/distroless-pod/distroless
```

### Test in CI/CD Environment

Test the plugin in a CI/CD environment to ensure it works in automated pipelines:

```yaml
# GitHub Actions workflow for testing
name: Test Plugin

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Kubernetes
        uses: engineerd/setup-kind@v0.5.0
        
      - name: Deploy test containers
        run: |
          kubectl create deployment nginx --image=nginx
          kubectl create deployment distroless --image=gcr.io/distroless/static-debian11
          kubectl wait --for=condition=available deployment/nginx deployment/distroless --timeout=60s
          
      - name: Install plugin
        run: |
          gem build train-k8s-container.gemspec
          gem install ./train-k8s-container-*.gem
          
      - name: Run tests
        run: ruby ./integration_test.rb
```

## Performance Testing

Measure the performance impact of the modifications:

```bash
# Time standard container scan
time inspec exec profile -t k8s-container://default/nginx-pod/nginx

# Time distroless container scan
time inspec exec profile -t k8s-container://default/distroless-pod/distroless
```

## Compatibility Testing

Test with different Kubernetes versions and configurations:

```bash
# Test with different Kubernetes versions
for k8s_version in 1.19.0 1.20.0 1.21.0 1.22.0 1.23.0; do
  echo "Testing with Kubernetes ${k8s_version}"
  minikube delete
  minikube start --kubernetes-version=${k8s_version}
  # Deploy test containers and run tests
  kubectl create deployment nginx --image=nginx
  kubectl create deployment distroless --image=gcr.io/distroless/static-debian11
  # Wait for pods to be ready
  kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s
  kubectl wait --for=condition=ready pod -l app=distroless --timeout=60s
  # Run tests
  ruby ./integration_test.rb
done
```

## Test Various Distroless Images

Test with different distroless container images to ensure compatibility:

```bash
# Test with various distroless images
distroless_images=(
  "gcr.io/distroless/static-debian11"
  "gcr.io/distroless/base-debian11"
  "gcr.io/distroless/java11-debian11"
  "gcr.io/distroless/nodejs16-debian11"
  "gcr.io/distroless/python3-debian11"
)

for image in "${distroless_images[@]}"; do
  echo "Testing with image: ${image}"
  kubectl create deployment test-distroless --image=${image}
  kubectl wait --for=condition=ready pod -l app=test-distroless --timeout=60s
  pod=$(kubectl get pods -l app=test-distroless -o name | cut -d/ -f2)
  inspec exec profile -t k8s-container://default/${pod}/test-distroless
  kubectl delete deployment test-distroless
done
```

## Debugging Tips

### Troubleshooting Test Failures

If tests fail, increase the log level for more detailed output:

```bash
INSPEC_LOG_LEVEL=debug inspec exec profile -t k8s-container://default/pod/container
```

Check for common issues:

- Kubernetes permissions - ensure your kubeconfig has proper permissions
- Ephemeral container support - verify your Kubernetes version supports it
- Image compatibility - ensure the debug image has the necessary tools

### Debugging Ephemeral Containers

To debug ephemeral containers directly:

```bash
# Start an ephemeral container manually
kubectl debug pod/distroless-pod -it --image=alpine -- sh

# Check process tree inside the ephemeral container
ps -ef

# Explore the filesystem of the target container
ls -la /proc/<PID>/root/

# Test commands on the target container filesystem
cat /proc/<PID>/root/etc/os-release
```

## Related Topics

- [Distroless Container Support](distroless.md)
- [Implementation Guide](implementation.md)
- [Kubernetes API Approach](../../approaches/kubernetes-api/index.md)
- [Debug Container Approach](../../approaches/debug-container/index.md)
