#!/bin/bash

# GitHub Actions Runner Setup Script
# Usage: ./setup-runner.sh <repo_url> <token> [runner_name] [labels] [work_dir]

set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 <repo_url> <token> [runner_name] [labels] [work_dir]"
    echo ""
    echo "Required arguments:"
    echo "  repo_url     - GitHub repository URL (e.g., https://github.com/owner/repo)"
    echo "  token        - GitHub runner registration token"
    echo ""
    echo "Optional arguments:"
    echo "  runner_name  - Name for the runner (default: hostname with timestamp)"
    echo "  labels       - Comma-separated labels (default: azure-linux)"
    echo "  work_dir     - Work directory name (default: _work)"
    echo ""
    echo "Examples:"
    echo "  $0 https://github.com/myorg/myrepo ABC123TOKEN"
    echo "  $0 https://github.com/myorg/myrepo ABC123TOKEN my-runner custom-label1,custom-label2"
    echo "  $0 https://github.com/myorg/myrepo ABC123TOKEN my-runner azure-linux,gpu custom_work"
    exit 1
}

# Check if minimum required arguments are provided
if [ $# -lt 2 ]; then
    echo "Error: Missing required arguments"
    echo ""
    usage
fi

# Parse arguments
REPO_URL="$1"
TOKEN="$2"
RUNNER_NAME="${3:-$(hostname)-$(date +%s)}"
LABELS="${4:-azure-linux}"
WORK_DIR="${5:-_work}"

# Runner version (you can update this to the latest version)
RUNNER_VERSION="2.329.0"
RUNNER_PACKAGE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
RUNNER_CHECKSUM="194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d"

echo "=== GitHub Actions Runner Setup ==="
echo "Repository URL: $REPO_URL"
echo "Runner Name: $RUNNER_NAME"
echo "Labels: $LABELS"
echo "Work Directory: $WORK_DIR"
echo "Runner Version: $RUNNER_VERSION"
echo "=================================="
echo ""

# Create and enter actions-runner directory
echo "Creating actions-runner directory..."
mkdir -p actions-runner
cd actions-runner

# Download the runner package
echo "Downloading GitHub Actions Runner v${RUNNER_VERSION}..."
curl -o "$RUNNER_PACKAGE" -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PACKAGE}"

# Verify checksum
echo "Verifying package integrity..."
echo "${RUNNER_CHECKSUM}  ${RUNNER_PACKAGE}" | shasum -a 256 -c

# Extract the package
echo "Extracting runner package..."
tar xzf "./${RUNNER_PACKAGE}"

# Configure the runner
echo "Configuring the runner..."
./config.sh --url "$REPO_URL" \
            --token "$TOKEN" \
            --name "$RUNNER_NAME" \
            --labels "$LABELS" \
            --work "$WORK_DIR" \
            --runnergroup "Default" \
            --unattended

# Start the runner in background
echo "Starting the runner in background..."
nohup ./run.sh > runner.log 2>&1 &
RUNNER_PID=$!

echo ""
echo "=== Setup Complete ==="
echo "Runner is now running in the background with PID: $RUNNER_PID"
echo "Log file: $(pwd)/runner.log"
echo ""
echo "Useful commands:"
echo "  View logs:        tail -f $(pwd)/runner.log"
echo "  Check if running: ps aux | grep run.sh"
echo "  Stop runner:      kill $RUNNER_PID"
echo "  Or stop runner:   pkill -f run.sh"
echo ""
echo "Runner directory: $(pwd)"
echo "======================"
