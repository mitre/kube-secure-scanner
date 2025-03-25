# Plugin Modifications Implementation Guide

This document provides a detailed step-by-step guide for implementing the modifications to the train-k8s-container plugin to support distroless containers.

## Development Environment Setup

### Prerequisites

- Ruby development environment (Ruby 2.7+)
- Bundler (for dependency management)
- Git
- Kubernetes cluster with ephemeral container support
- kubectl configured with appropriate permissions

### Setting Up the Development Environment

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/your-username/train-k8s-container.git
cd train-k8s-container

# Create a feature branch
git checkout -b feature/distroless-support

# Install dependencies
bundle install
```

## File Structure

The key files to modify are:

```
lib/
  train/
    k8s/
      container/
        connection.rb         # Main connection class
        kubectl_exec_client.rb # Handles command execution
    transport/
      k8s_container.rb       # Transport entry point
spec/
  k8s_container/
    connection_spec.rb       # Tests for connection class
```

## Implementation Steps

### Step 1: Add Distroless Detection

Modify `lib/train/k8s/container/connection.rb` to add distroless detection:

```ruby
module Train::K8s
  class Container
    class Connection < Train::Plugins::Transport::BaseConnection
      # Add this method to the Connection class
      def distroless?(namespace, pod, container)
        cmd = ["kubectl", "exec", "-n", namespace, pod, "-c", container, "--", "/bin/sh", "-c", "echo test"]
        begin
          result = Train::Extras::CommandWrapper.run(cmd.join(" "), nil)
          return false # Container has shell
        rescue Train::Errors::CommandExecutionError
          return true # Container is likely distroless
        end
      end
      
      # Rest of the class...
    end
  end
end
```

### Step 2: Add Ephemeral Container Support

Add the ephemeral container setup method to the Connection class:

```ruby
def setup_ephemeral_container(namespace, pod, target_container)
  require 'securerandom'
  debug_container_name = "inspec-debug-#{SecureRandom.hex(4)}"
  debug_image = "alpine:latest" # or a custom image with needed tools
  
  # Create ephemeral container
  cmd = [
    "kubectl", "debug", pod, 
    "-n", namespace, 
    "--image=#{debug_image}", 
    "--target=#{target_container}", 
    "--container=#{debug_container_name}", 
    "--quiet", "-it", "--", "sleep", "3600"
  ]
  
  # Run in background
  pid = Process.spawn(cmd.join(" "), [:out, :err] => "/dev/null")
  Process.detach(pid)
  
  # Wait for ephemeral container to be ready
  sleep 5
  
  # Return ephemeral container info
  {
    name: debug_container_name,
    pid: pid
  }
end
```

### Step 3: Modify the Connection Initialization

Update the `initialize` and `close` methods in the Connection class:

```ruby
def initialize(options)
  super(options)
  @options = options
  @namespace = options[:namespace]
  @pod = options[:pod]
  @container = options[:container]
  
  # Detect if container is distroless
  if distroless?(@namespace, @pod, @container)
    @ephemeral = setup_ephemeral_container(@namespace, @pod, @container)
    @container = @ephemeral[:name] # Use ephemeral container for commands
    @using_ephemeral = true
  else
    @using_ephemeral = false
  end
  
  # Initialize kubernetes client
  @k8s_client = KubectlExecClient.new(
    namespace: @namespace,
    pod: @pod,
    container: @container,
    kubeconfig: @options[:kubeconfig]
  )
end

def close
  # Clean up ephemeral container if used
  if @using_ephemeral && @ephemeral[:pid]
    Process.kill('TERM', @ephemeral[:pid])
  end
end

# Add an accessor for the ephemeral container flag
def using_ephemeral?
  @using_ephemeral
end
```

### Step 4: Modify File Access for Distroless Containers

Update the `file` method to work with distroless containers:

```ruby
def file(path)
  if @using_ephemeral
    # For distroless containers, access target container filesystem via /proc
    # First, get the process ID of the target container's entrypoint
    target_pid_cmd = "ps -ef | grep #{@options[:container]} | grep -v grep | awk '{print $2}' | head -1"
    target_pid = @k8s_client.run_command(target_pid_cmd).stdout.strip
    
    if target_pid.empty?
      logger.warn("Could not find PID for target container #{@options[:container]}")
      # Fallback to standard file access
      Train::File::Remote.new(self, path)
    else
      # Access target container's filesystem via /proc
      modified_path = "/proc/#{target_pid}/root#{path}"
      logger.debug("Accessing #{path} via #{modified_path}")
      # Use Local file implementation since we're inside the ephemeral container
      Train::File::Local.new(self, modified_path)
    end
  else
    # Standard file access
    Train::File::Remote.new(self, path)
  end
end
```

### Step 5: Update the Command Execution Client

Modify `lib/train/k8s/container/kubectl_exec_client.rb` to handle distroless containers:

```ruby
module Train::K8s
  class Container
    class KubectlExecClient
      # Add a reference to the connection
      attr_reader :connection
      
      # Update the initializer to store the connection reference
      def initialize(options)
        @namespace = options[:namespace]
        @pod = options[:pod]
        @container = options[:container]
        @kubeconfig = options[:kubeconfig]
        @connection = options[:connection]
      end
      
      # Modify the run_command method
      def run_command(command)
        # Build the kubectl exec command
        cmd = build_kubectl_exec_command(command)
        
        # Execute the command and handle the result
        result = execute_cmd(cmd)
        
        # Return the result as a CommandResult
        CommandResult.new(result.stdout, result.stderr, result.exit_status)
      end
      
      private
      
      def build_kubectl_exec_command(command)
        # Build kubectl exec command with proper options
        ["kubectl", "exec", "-n", @namespace, @pod, "-c", @container, "--", "/bin/sh", "-c", command]
      end
      
      def execute_cmd(cmd)
        # Execute the command and handle errors
        begin
          Train::Extras::CommandWrapper.run(cmd.join(" "), nil)
        rescue Train::Errors::CommandExecutionError => e
          # Return the failed command result
          OpenStruct.new(
            stdout: e.stdout,
            stderr: e.stderr,
            exit_status: e.exit_status
          )
        end
      end
    end
  end
end
```

### Step 6: Update the Transport Class

Modify `lib/train/transport/k8s_container.rb` to pass the connection reference to the exec client:

```ruby
module Train::Transport
  class K8sContainer < Train.plugin(1)
    name "k8s-container"
    
    # ... existing code ...
    
    def connection(options = {})
      @connection ||= Train::K8s::Container::Connection.new(options)
    end
  end
end
```

Make sure the KubectlExecClient receives the connection reference in the Connection class:

```ruby
# In lib/train/k8s/container/connection.rb

def initialize(options)
  # ... existing code ...
  
  # Initialize kubernetes client with reference to this connection
  @k8s_client = KubectlExecClient.new(
    namespace: @namespace,
    pod: @pod,
    container: @container,
    kubeconfig: @options[:kubeconfig],
    connection: self  # Add this line
  )
end
```

## Adding Tests

Add tests for the new functionality in `spec/k8s_container/connection_spec.rb`:

```ruby
require 'spec_helper'

describe Train::K8s::Container::Connection do
  let(:options) do
    {
      namespace: 'default',
      pod: 'test-pod',
      container: 'test-container',
      kubeconfig: '/path/to/kubeconfig'
    }
  end
  
  subject { described_class.new(options) }
  
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
  
  # Add more tests for other functionality
end
```

## Building and Installing the Plugin

```bash
# Build the gem
gem build train-k8s-container.gemspec

# Install the gem locally for testing
gem install ./train-k8s-container-x.y.z.gem
```

## Related Topics

- [Distroless Container Support](distroless.md)
- [Testing Guide](testing.md)
- [Kubernetes API Approach](../../approaches/kubernetes-api/index.md)