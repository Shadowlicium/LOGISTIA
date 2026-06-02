#!/bin/bash
set -e

# GitHub Actions Runner Installation Script
# Usage: GITHUB_OWNER=myorg GITHUB_REPO=myrepo RUNNER_TOKEN=<token> ./install-github-runner.sh
# Or for org-level runner: GITHUB_ORG=myorg RUNNER_TOKEN=<token> ./install-github-runner.sh

RUNNER_HOME="/opt/github-runner"
RUNNER_USER="github-runner"
RUNNER_GROUP="github-runner"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== GitHub Actions Runner Installation ===${NC}"

# Check prerequisites
if [ -z "$RUNNER_TOKEN" ]; then
    echo -e "${RED}Error: RUNNER_TOKEN environment variable not set${NC}"
    echo "Generate a token from:"
    echo "  - Repository: https://github.com/<owner>/<repo>/settings/actions/runners"
    echo "  - Organization: https://github.com/organizations/<org>/settings/actions/runners"
    exit 1
fi

if [ -z "$GITHUB_OWNER" ] && [ -z "$GITHUB_ORG" ]; then
    echo -e "${RED}Error: Set either GITHUB_OWNER + GITHUB_REPO or GITHUB_ORG${NC}"
    exit 1
fi

# Determine registration URL
if [ -n "$GITHUB_ORG" ]; then
    RUNNER_URL="https://github.com/${GITHUB_ORG}"
    echo -e "${YELLOW}Registering as organization-level runner for: ${GITHUB_ORG}${NC}"
else
    RUNNER_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}"
    echo -e "${YELLOW}Registering as repository runner for: ${GITHUB_OWNER}/${GITHUB_REPO}${NC}"
fi

# Create runner directory
echo "Creating runner directory: ${RUNNER_HOME}"
mkdir -p "$RUNNER_HOME"
cd "$RUNNER_HOME"

# Download latest runner
echo "Downloading latest GitHub Actions Runner..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//')
RUNNER_URL_DL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

if [ -f "config.sh" ]; then
    echo -e "${YELLOW}Runner already installed, skipping download${NC}"
else
    wget -q "$RUNNER_URL_DL" -O runner.tar.gz
    tar xzf runner.tar.gz
    rm runner.tar.gz
    echo -e "${GREEN}Runner downloaded (v${RUNNER_VERSION})${NC}"
fi

# Set permissions
chown -R "$RUNNER_USER:$RUNNER_GROUP" "$RUNNER_HOME"

# Register runner
echo "Registering runner with GitHub..."
sudo -u "$RUNNER_USER" ./config.sh \
    --url "$RUNNER_URL" \
    --token "$RUNNER_TOKEN" \
    --name "$(hostname)-runner" \
    --work "_work" \
    --unattended \
    --replace

# Install as systemd service
echo "Installing systemd service..."
sudo ./svc.sh install "$RUNNER_USER"

# Enable and start service
echo "Enabling and starting runner service..."
sudo systemctl enable actions.runner.*
sudo systemctl start actions.runner.*

echo -e "${GREEN}=== Installation Complete ===${NC}"
echo "Runner status:"
sudo systemctl status actions.runner.* || true
echo ""
echo "To check runner logs:"
echo "  journalctl -u actions.runner.* -f"
echo ""
echo "To stop the runner:"
echo "  sudo systemctl stop actions.runner.*"
echo ""
echo "To restart the runner:"
echo "  sudo systemctl restart actions.runner.*"
