# Development Environment Setup

## Overview
Complete setup guide for new developers joining the Mbodi engineering team. This reflects our actual development stack and tooling.

## Prerequisites
- [ ] MacBook (Apple Silicon recommended) or Linux workstation
- [ ] Admin access to install software
- [ ] GitHub account with Mbodi organization access
- [ ] Linear workspace invitation
- [ ] Notion workspace invitation
- [ ] Google Workspace account

## Core Environment Setup

### 1. Shell Configuration
Our team uses a standardized zsh configuration with custom tooling:

```bash
# Create local bin directory
mkdir -p ~/.local/bin

# Set up custom environment scripts
# (These will be provided during onboarding)
# ~/.local/bin/env - PATH management
# ~/.r.sh - Development tools setup (brew, pipx, uv, etc.)
# ~/.env.sh - Terminal colors and environment variables

# Add to ~/.zshrc (or create new file)
cat >> ~/.zshrc << 'EOF'
. "$HOME/.local/bin/env"
source ~/.r.sh
source ~/.env.sh

# Key bindings for word navigation
bindkey -e
bindkey $'\e[1;3D' backward-word
bindkey $'\e[1;3C' forward-word
bindkey $'\e[1;9D' backward-word
bindkey $'\e[1;9C' forward-word

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
EOF
```

### 2. Python Environment Management
We use Conda for Python environment management:

```bash
# Install Miniconda (done automatically by r.sh)
# Initialize conda for zsh
conda init zsh

# Restart shell or source ~/.zshrc
source ~/.zshrc
```

### 3. Code Editors
Primary editor is Cursor, with additional tools available:

```bash
# Cursor (primary editor) - install manually from https://cursor.sh
# The r.sh script will set EDITOR=cursor automatically

# Windsurf (AI-powered editor) - optional
# Download from https://codeium.com/windsurf
```

### 4. Essential Development Tools
These are automatically installed by the r.sh script:

```bash
# Core tools (installed automatically):
# - Homebrew (package manager)
# - pipx (Python app installer) 
# - uv (fast Python package manager)
# - bat (better cat)
# - gh (GitHub CLI)

# Manual verification after setup:
which brew pipx uv bat gh
```

## Repository Setup

### 1. Clone Core Repositories
```bash
# Create project directory structure
mkdir -p ~/corp/projects && cd ~/corp/projects

# Clone the main mb project (contains tooling and utilities)
git clone git@github.com:mbodi/mb.git

# Clone other project repositories as needed
# git clone git@github.com:mbodi/[project-name].git
```

### 2. MB Tool Setup
Our custom `mb` tool provides project management and development utilities:

```bash
# Navigate to mb project
cd ~/corp/projects/mb

# Create and activate conda environment
conda create -n mb python=3.11
conda activate mb

# Install mb tool in development mode
pip install -e .

# Set up shell completions
mkdir -p ~/.config/zsh/completions
# Completion file should be provided during onboarding

# Add completion to ~/.zshrc (if not already present)
echo 'source ~/.config/zsh/completions/mb.zsh' >> ~/.zshrc
```

### 3. Project Environment Configuration
```bash
# Each project may have its own conda environment
# Example for a new project:
conda create -n project-name python=3.11
conda activate project-name

# Install project-specific dependencies
pip install -r requirements.txt
# or
pip install -e .
```

## Daily Development Workflow

### 1. Environment Activation
```bash
# Start your day by activating the appropriate conda environment
conda activate mb  # for mb tool work
# or
conda activate project-name  # for specific project work

# Verify tools are available
which mb
mb --help  # should show available commands
```

### 2. Using the MB Tool
Our custom `mb` tool streamlines common development tasks:

```bash
# Common mb commands (examples - actual commands depend on implementation)
mb status          # Check project status
mb sync           # Sync with remote repositories  
mb test           # Run project tests
mb deploy         # Deploy to staging/production
mb env            # Environment management

# Use tab completion to discover available commands
mb <TAB><TAB>
```

### 3. Project-Specific Setup
Each project may have its own setup requirements:

```bash
# Navigate to project directory
cd ~/corp/projects/[project-name]

# Activate project environment
conda activate [project-name]

# Install/update dependencies
pip install -r requirements.txt
# or for development installs
pip install -e .

# Run project-specific setup
# (commands vary by project)
```

## Git Workflow Integration

### 1. Linear + GitHub Integration
Our workflow integrates Linear issues with GitHub:

```bash
# Create feature branch from Linear issue
# (Linear can auto-create branches with proper naming)
git checkout -b feature/LIN-123-implement-user-auth

# Make commits referencing Linear issue
git commit -m "feat: implement user authentication (LIN-123)"

# Push and create PR
git push origin feature/LIN-123-implement-user-auth
# GitHub PR will automatically update the Linear issue
```

### 2. Using MB Tool for Git Operations
```bash
# Use mb tool for enhanced git operations
mb branch create LIN-123    # Create branch from Linear issue
mb commit "feat: add feature"  # Commit with proper formatting
mb push                     # Push with Linear integration
mb pr create               # Create PR with Linear linking
```

## Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find process using port
lsof -ti:8000
kill -9 <PID>
```

#### Database Connection Error
```bash
# Check PostgreSQL status
brew services list | grep postgresql
brew services restart postgresql
```

#### Docker Issues
```bash
# Reset Docker
docker system prune -a
```

## Getting Help
- **Slack**: #engineering-help
- **Documentation**: [Internal Wiki](https://notion.so/mbodi)
- **Mentor**: Assigned during onboarding

## Next Steps
- [ ] Join team standup meetings
- [ ] Complete first starter task
- [ ] Set up monitoring dashboards
- [ ] Review architecture documentation
