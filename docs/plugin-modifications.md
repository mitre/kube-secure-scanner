# Modifying train-k8s-container for Distroless Support

This document outlines the changes needed in the InSpec train-k8s-container plugin to support scanning distroless containers using Kubernetes ephemeral containers.

## Current Plugin Architecture

The train-k8s-container plugin works by:

1. Creating a connection to a Kubernetes cluster via kubeconfig
2. Using `kubectl exec` to execute commands in the target container
3. Running InSpec controls that rely on command execution

Key files in the plugin that would need modification:

1. `lib/train/k8s/container/connection.rb` - Main connection class
2. `lib/train/k8s/container/kubectl_exec_client.rb` - Handles command execution
3. `lib/train/transport/k8s_container.rb` - Transport entry point

## Required Modifications

### 1. Distroless Detection

Add capability to detect distroless containers by attempting to execute a simple shell command and checking for failure:

```ruby
# in lib/train/k8s/container/connection.rb

def distroless?(namespace, pod, container)
  cmd = ["kubectl", "exec", "-n", namespace, pod, "-c", container, "--", "/bin/sh", "-c", "echo test"]
  begin
    result = Train::Extras::CommandWrapper.run(cmd.join(" "), nil)
    return false # Container has shell
  rescue Train::Errors::CommandExecutionError
    return true # Container is likely distroless
  end
end
```

### 2. Ephemeral Container Creation

Add functionality to create and connect to an ephemeral container:

```ruby
# in lib/train/k8s/container/connection.rb

def setup_ephemeral_container(namespace, pod, target_container)
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

### 3. Connection Strategy Switching

Modify the connection logic to choose between standard and ephemeral container approaches:

```ruby
# in lib/train/k8s/container/connection.rb

def initialize(options)
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
```

### 4. File Access for Distroless Containers

Modify file access methods to work through the ephemeral container:

```ruby
# in lib/train/k8s/container/connection.rb

def file(path)
  if @using_ephemeral
    # For distroless containers, access target container filesystem via /proc
    # First, get the process ID of the target container's entrypoint
    target_pid_cmd = "ps -ef | grep #{@options[:container]} | grep -v grep | awk '{print $2}' | head -1"
    target_pid = @k8s_client.run_command(target_pid_cmd).stdout.strip
    
    # Access target container's filesystem via /proc
    modified_path = "/proc/#{target_pid}/root#{path}"
    Train::File::Local.new(self, modified_path)
  else
    # Standard file access
    Train::File::Remote.new(self, path)
  end
end
```

### 5. Command Execution Handling

Update command execution to handle the distroless case:

```ruby
# in lib/train/k8s/container/kubectl_exec_client.rb

def run_command(command)
  if @connection.using_ephemeral?
    # In ephemeral container, we might need to modify commands to access the target container
    # This depends on how exactly we want to interact with the target container
    modified_command = command
    super(modified_command)
  else
    # Standard command execution
    super(command)
  end
end
```

## Implementation Strategy

1. **Fork the Repository**: Create a fork of the train-k8s-container plugin
2. **Create Branch**: Create a feature branch for distroless support
3. **Implement Changes**: Make the modifications outlined above
4. **Add Tests**: Create tests for distroless container detection and scanning
5. **Document**: Document the new capabilities and how to use them
6. **Submit PR**: Consider submitting a pull request to the upstream repository

## Integration with Our Project

After modifying the plugin, we would need to:

1. Update our Gemfile to point to our fork of the plugin
2. Update our scan-container.sh script to handle the new capabilities
3. Create documentation on how to scan distroless containers
4. Update our Helm chart to include the new plugin version
5. Test with various distroless container types

## Example Usage

With the modified plugin, the command to scan a distroless container would remain the same:

```bash
cinc-auditor exec my-profile -t k8s-container://namespace/pod/container
```

The plugin would automatically:
1. Detect the container is distroless
2. Create an ephemeral container
3. Execute the scan through the ephemeral container
4. Clean up the ephemeral container when done

## Potential Limitations

1. **Permissions**: Requires permissions to create ephemeral containers
2. **Kubernetes Version**: Requires Kubernetes v1.18+ for ephemeral containers
3. **Image Compatibility**: The debug image must have required tools
4. **Process Isolation**: May have issues with certain container runtimes

## References

1. [train-k8s-container repository](https://github.com/inspec/train-k8s-container)
2. [Kubernetes Ephemeral Containers](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/)
3. [Debugging with Ephemeral Containers](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container)