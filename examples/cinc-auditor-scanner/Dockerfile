FROM ruby:3.0-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    procps \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install CINC Auditor
RUN curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor

# Install train-k8s-container plugin
RUN cinc-auditor plugin install train-k8s-container

# Install SAF CLI
RUN npm install -g @mitre/saf

# Create directories for profiles and results
RUN mkdir -p /opt/profiles /results

# Set up working directory
WORKDIR /opt/scanner

# Add a sample profile for testing
COPY profiles/ /opt/profiles/

# Set the entrypoint to the shell for flexibility
ENTRYPOINT ["/bin/bash"]
CMD ["-c", "sleep infinity"]