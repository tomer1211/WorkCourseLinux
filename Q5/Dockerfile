# Use an official Ubuntu image
FROM ubuntu:20.04

# Disable interactive prompts
ARG DEBIAN_FRONTEND=noninteractive

# Install required packages (bash, coreutils, sed, gawk, etc.)
RUN apt-get update && apt-get install -y \
    bash \
    coreutils \
    sed \
    gawk \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy all files from Q5 into /app in the container
COPY . /app

# Ensure the q5.sh script is executable
RUN chmod +x q5.sh

# Run the q5.sh script
CMD ["./q5.sh"]
