# GitHub Runner Installation Guide

## Overview

The GitHub Actions runner must be installed **manually** on the `gh-runner` VM (10.10.30.10) because:
- Your infrastructure is in a private VPN
- GitHub Actions public runners cannot access your Proxmox/VMs
- The runner needs to be inside your VPN to execute workflows

## Prerequisites

Before running the installation script:

1. **VM Running**: The `gh-runner` VM must already be created by Terraform and running
2. **Ansible Provisioned**: Run Ansible playbooks first to install dependencies:
   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml
   ```
3. **GitHub Token**: Generate a runner registration token from GitHub:
   - **Repository runner**: `https://github.com/<owner>/<repo>/settings/actions/runners/new`
   - **Organization runner**: `https://github.com/organizations/<org>/settings/actions/runners/new`

## Installation Steps

### Step 1: SSH to the Runner VM

```bash
ssh root@10.10.30.10
```

### Step 2: Run the Installation Script

The script is copied to `/opt/github-runner/install-github-runner.sh` by Ansible.

**For Repository-level runner:**

```bash
export GITHUB_OWNER=your-github-username
export GITHUB_REPO=LOGISTIA
export RUNNER_TOKEN=replace-with-runner-token
/opt/github-runner/install-github-runner.sh
```

**For Organization-level runner:**

```bash
export GITHUB_ORG=your-org-name
export RUNNER_TOKEN=replace-with-runner-token
/opt/github-runner/install-github-runner.sh
```

> Replace `your-github-username`, `LOGISTIA`, `your-org-name`, and `ghs_xxxx...` with actual values.

### Step 3: Verify Installation

```bash
systemctl status actions.runner.*
```

You should see the runner service running (if all is well).

### Step 4: Check the Runner in GitHub

Once registered, the runner appears in:
- **Repository**: `https://github.com/<owner>/<repo>/settings/actions/runners`
- **Organization**: `https://github.com/organizations/<org>/settings/actions/runners`

It should show as "Idle" or "Running".

## Using the Runner in Workflows

Once registered, specify `runs-on: self-hosted` in workflow jobs that need access to your VPN/Proxmox:

```yaml
jobs:
  my-job:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4
      - run: terraform plan
```

## Troubleshooting

### Check Runner Logs

```bash
journalctl -u actions.runner.* -f
```

### Stop/Restart the Runner

```bash
sudo systemctl stop actions.runner.*
sudo systemctl restart actions.runner.*
```

### Unregister the Runner

If you need to remove the runner:

```bash
cd /opt/github-runner
sudo ./config.sh remove --token $RUNNER_TOKEN
```

### Script is not executable

```bash
chmod +x /opt/github-runner/install-github-runner.sh
```

## Manual Terraform & Ansible Deployment

Since the public GitHub runners cannot reach your VPN, you must:

1. **Terraform Apply**: Run locally or on a machine with Proxmox access:
   ```bash
   cd infra/terraform
   terraform apply plan.tfplan
   ```

2. **Ansible Deploy**: Run after VMs are created:
   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml
   ```

Once the self-hosted runner is working, you can create a workflow job to run these automatically:

```yaml
deploy:
  runs-on: self-hosted
  steps:
    - uses: actions/checkout@v4
    - run: cd infra/terraform && terraform apply plan.tfplan
    - run: ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml
```

## What the Script Does

The `install-github-runner.sh` script:

1. Installs required dependencies (if not already present)
2. Downloads the latest GitHub Actions runner
3. Registers the runner with GitHub using your token
4. Creates a systemd service running as `github-runner`
5. Enables and starts the service

The runner will automatically:
- Start on VM boot
- Reconnect if disconnected
- Update itself when new versions are available
