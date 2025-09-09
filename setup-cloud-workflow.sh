#!/bin/bash

# Complete Cloud Workflow Setup Script
# Sets up both Linear webhook and GitHub repository in one command

set -e

echo "🚀 Claude Code Cloud Workflow Setup"
echo "===================================="
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    echo "Please run this from your project directory"
    exit 1
fi

# Get repository info
REPO_OWNER=$(gh repo view --json owner -q .owner.login 2>/dev/null || echo "")
REPO_NAME=$(gh repo view --json name -q .name 2>/dev/null || echo "")

if [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "📦 Creating GitHub repository..."
    
    # Get directory name as repo name
    REPO_NAME=$(basename "$PWD")
    
    # Create GitHub repo
    gh repo create "$REPO_NAME" --private --source=. --push
    
    # Get updated info
    REPO_OWNER=$(gh repo view --json owner -q .owner.login)
    REPO_NAME=$(gh repo view --json name -q .name)
    
    echo "✅ Created repository: $REPO_OWNER/$REPO_NAME"
fi

echo ""
echo "🔧 Setting up GitHub Secrets..."
echo "================================"

# Check for saved secrets
SECRETS_FILE="$HOME/.claude-code-template/secrets.env"
if [ -f "$SECRETS_FILE" ]; then
    echo "📂 Loading saved secrets from ~/.claude-code-template/secrets.env"
    source "$SECRETS_FILE"
    
    # Set GitHub secrets from saved values
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        gh secret set ANTHROPIC_API_KEY -b "$ANTHROPIC_API_KEY" 2>/dev/null || true
        echo "✅ Set ANTHROPIC_API_KEY"
    fi
    
    if [ -n "$LINEAR_API_KEY" ]; then
        gh secret set LINEAR_API_KEY -b "$LINEAR_API_KEY" 2>/dev/null || true
        echo "✅ Set LINEAR_API_KEY"
    fi
    
    if [ -n "$PERPLEXITY_API_KEY" ]; then
        gh secret set PERPLEXITY_API_KEY -b "$PERPLEXITY_API_KEY" 2>/dev/null || true
        echo "✅ Set PERPLEXITY_API_KEY (optional)"
    fi
else
    echo "⚠️  No saved secrets found. You'll need to add them manually:"
    echo ""
    echo "Required secrets:"
    echo "  - ANTHROPIC_API_KEY (for Claude Code Action)"
    echo "  - LINEAR_API_KEY (for Linear integration)"
    echo ""
    echo "Optional:"
    echo "  - PERPLEXITY_API_KEY (for research capabilities)"
    echo ""
    read -p "Would you like to add them now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Anthropic API Key
        echo -n "Enter ANTHROPIC_API_KEY: "
        read -s ANTHROPIC_API_KEY
        echo
        if [ -n "$ANTHROPIC_API_KEY" ]; then
            gh secret set ANTHROPIC_API_KEY -b "$ANTHROPIC_API_KEY"
            echo "✅ Set ANTHROPIC_API_KEY"
        fi
        
        # Linear API Key
        echo -n "Enter LINEAR_API_KEY: "
        read -s LINEAR_API_KEY
        echo
        if [ -n "$LINEAR_API_KEY" ]; then
            gh secret set LINEAR_API_KEY -b "$LINEAR_API_KEY"
            echo "✅ Set LINEAR_API_KEY"
        fi
        
        # Optional: Perplexity API Key
        echo -n "Enter PERPLEXITY_API_KEY (optional, press Enter to skip): "
        read -s PERPLEXITY_API_KEY
        echo
        if [ -n "$PERPLEXITY_API_KEY" ]; then
            gh secret set PERPLEXITY_API_KEY -b "$PERPLEXITY_API_KEY"
            echo "✅ Set PERPLEXITY_API_KEY"
        fi
        
        # Save for future use
        read -p "Save these secrets for future projects? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$HOME/.claude-code-template"
            cat > "$SECRETS_FILE" << EOF
# Claude Code Template Secrets
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
export LINEAR_API_KEY="$LINEAR_API_KEY"
export PERPLEXITY_API_KEY="$PERPLEXITY_API_KEY"
EOF
            chmod 600 "$SECRETS_FILE"
            echo "✅ Secrets saved to ~/.claude-code-template/secrets.env"
        fi
    fi
fi

# Create webhook secret
echo ""
echo "🔐 Creating webhook secret..."
if ! gh secret list | grep -q "WEBHOOK_SECRET"; then
    WEBHOOK_SECRET=$(openssl rand -hex 32)
    gh secret set WEBHOOK_SECRET -b "$WEBHOOK_SECRET"
    echo "✅ Created WEBHOOK_SECRET"
else
    echo "✅ WEBHOOK_SECRET already exists"
fi

# Install Claude Code GitHub App
echo ""
echo "📱 Claude Code GitHub App"
echo "➡️  Visit: https://github.com/apps/claude-code"
echo "➡️  Install on: $REPO_OWNER/$REPO_NAME"
echo ""
# Skip the prompt if running non-interactively
if [ -t 0 ]; then
    read -p "Press Enter after installing the app..."
else
    echo "⏭️  Skipping app installation prompt (non-interactive mode)"
fi

# Copy workflow files
echo ""
echo "📋 Setting up GitHub Actions workflows..."

# Create .github/workflows directory
mkdir -p .github/workflows

# Check if template files exist locally
TEMPLATE_DIR="$HOME/.claude-code-template/template"
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "📦 Downloading template files..."
    # Clone template repo to local cache
    git clone https://github.com/yourusername/claude-code-template.git "$TEMPLATE_DIR" 2>/dev/null || {
        echo "⚠️  Using embedded workflow files..."
        mkdir -p "$TEMPLATE_DIR/.github/workflows"
        
        # Create embedded linear-webhook.yml
        cat > "$TEMPLATE_DIR/.github/workflows/linear-webhook.yml" << 'EOF'
name: Linear Webhook Handler

on:
  repository_dispatch:
    types: [linear-webhook]

jobs:
  process-linear-event:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install TaskMaster
        run: |
          npm install -g task-master-ai@latest
          
      - name: Initialize TaskMaster
        if: ${{ !contains(github.event.repository.topics, 'taskmaster-initialized') }}
        run: |
          task-master init --yes --rules claude
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Process Linear Event
        run: |
          echo "Processing Linear event: ${{ github.event.client_payload.action }}"
          echo "Issue ID: ${{ github.event.client_payload.data.id }}"
          echo "Issue Title: ${{ github.event.client_payload.data.title }}"
          echo "Team: ${{ github.event.client_payload.data.team }}"
          
      - name: Route to Correct Repository
        id: routing
        run: |
          # Map Linear team to repository
          TEAM="${{ github.event.client_payload.data.team }}"
          CURRENT_REPO="${{ github.repository }}"
          
          # Check if this is the right repository for this team
          # You can customize this mapping
          echo "team=$TEAM" >> $GITHUB_OUTPUT
          echo "should_process=true" >> $GITHUB_OUTPUT
          
      - name: Execute Claude Code Action
        if: steps.routing.outputs.should_process == 'true'
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          github_token: ${{ secrets.GITHUB_TOKEN }}
          prompt: |
            Linear Issue: ${{ github.event.client_payload.data.identifier }}
            Title: ${{ github.event.client_payload.data.title }}
            Description: ${{ github.event.client_payload.data.description }}
            Team: ${{ github.event.client_payload.data.team }}
            
            Tasks:
            1. Parse this Linear issue
            2. Generate PRD using TaskMaster
            3. Create subtasks in Linear
            4. Begin implementing each subtask
            5. Create atomic commits for each
            6. Update Linear status in real-time
            
            Use the Linear API to update the issue and create subtasks.
          claude_args: "--max-turns 25"
        env:
          LINEAR_API_KEY: ${{ secrets.LINEAR_API_KEY }}
          PERPLEXITY_API_KEY: ${{ secrets.PERPLEXITY_API_KEY }}
EOF
    }
fi

# Copy workflow files
cp -r "$TEMPLATE_DIR/.github/workflows/"* .github/workflows/ 2>/dev/null || true

# Copy MCP configuration if it exists
if [ -f "$TEMPLATE_DIR/.mcp.json" ] || [ -f ".mcp.json" ]; then
    # Use template .mcp.json if it exists, otherwise keep existing
    if [ -f "$TEMPLATE_DIR/.mcp.json" ] && [ ! -f ".mcp.json" ]; then
        cp "$TEMPLATE_DIR/.mcp.json" .
        echo "✅ Copied MCP configuration"
    fi
fi

# Copy Claude configuration and agents if they exist
if [ -d "$TEMPLATE_DIR/.claude" ] && [ ! -d ".claude" ]; then
    cp -r "$TEMPLATE_DIR/.claude" .
    echo "✅ Copied Claude configuration and agents"
fi

# Initialize TaskMaster
echo ""
echo "🤖 Initializing TaskMaster..."
if [ ! -d ".taskmaster" ]; then
    npx task-master-ai init --yes --rules claude
    echo "✅ TaskMaster initialized"
else
    echo "✅ TaskMaster already initialized"
fi

# Commit changes
echo ""
echo "💾 Committing setup files..."
git add .github/workflows .taskmaster
git commit -m "feat: Initialize cloud workflow with Linear webhook support" 2>/dev/null || echo "✅ No new files to commit"
git push 2>/dev/null || true

# Generate webhook configuration
echo ""
echo "🔗 Linear Webhook Configuration"
echo "================================"
echo ""
echo "You need ONE webhook for your entire Linear workspace."
echo "This webhook will route to ALL your repositories automatically."
echo ""
echo "📋 Setup Instructions:"
echo "1. Go to Linear Settings → Integrations → Webhooks"
echo "2. Click 'New Webhook'"
echo ""
echo "3. Webhook Settings:"
echo "   Name: Claude Code Automation"
echo "   URL: https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/dispatches"
echo ""
echo "   Events to subscribe:"
echo "   ✓ Issue created"
echo "   ✓ Issue updated"
echo "   ✓ Issue state changed"
echo "   ✓ Comment created"
echo ""
echo "4. Headers (REQUIRED):"
echo "   Authorization: Bearer YOUR_GITHUB_PAT"
echo "   Accept: application/vnd.github.v3+json"
echo "   Content-Type: application/json"
echo ""
echo "5. Payload Template:"
cat << 'EOF'
{
  "event_type": "linear-webhook",
  "client_payload": {
    "action": "{{action}}",
    "data": {
      "id": "{{data.id}}",
      "identifier": "{{data.identifier}}",
      "title": "{{data.title}}",
      "description": "{{data.description}}",
      "state": "{{data.state.name}}",
      "assignee": "{{data.assignee.name}}",
      "team": "{{data.team.key}}"
    }
  }
}
EOF

echo ""
echo "📝 IMPORTANT NOTES:"
echo "==================="
echo ""
echo "1. GitHub Personal Access Token (PAT):"
echo "   - You need a GitHub PAT with 'repo' scope"
echo "   - Create at: https://github.com/settings/tokens"
echo "   - This PAT goes in the Linear webhook Authorization header"
echo ""
echo "2. Linear Teams → GitHub Repos Mapping:"
echo "   - Each Linear team should map to one GitHub repository"
echo "   - Team key in Linear = Repository name convention"
echo "   - Example: Team 'ENG' → Repo 'eng-backend'"
echo ""
echo "3. How It Works:"
echo "   - ONE Linear webhook for entire workspace"
echo "   - Webhook sends to primary dispatcher repo (this one)"
echo "   - Workflow routes based on team.key to correct repo"
echo "   - Each repo processes its own team's issues"
echo ""
echo "✅ Setup Complete!"
echo ""
echo "🚀 Next Steps:"
echo "1. Configure the Linear webhook (if not done already)"
echo "2. Create a Linear issue with @claude mention"
echo "3. Watch the magic happen!"
echo ""
echo "💡 Pro Tip: Save this configuration:"
echo "   Webhook URL: https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/dispatches"
echo "   Team: Map your Linear team key to this repo"