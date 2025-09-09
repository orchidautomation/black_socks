#!/bin/bash

# One-command project creator from claude-code-template
# Usage: ./create-project.sh my-awesome-project

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for project name
if [ -z "$1" ]; then
    echo "Usage: ./create-project.sh <project-name>"
    echo "Example: ./create-project.sh my-awesome-app"
    exit 1
fi

PROJECT_NAME="$1"
TEMPLATE_REPO="orchidautomation/claude-code-template"  # Change this to your template repo

echo -e "${BLUE}🚀 Creating new project: $PROJECT_NAME${NC}"
echo "================================================"
echo ""

# Step 1: Create repo from template using gh CLI
echo "1️⃣  Creating GitHub repository from template..."
gh repo create "$PROJECT_NAME" \
    --template="$TEMPLATE_REPO" \
    --public \
    --clone \
    --description="Created from Claude Code template"

# Step 2: Enter the directory
cd "$PROJECT_NAME"
echo -e "${GREEN}✓ Repository created and cloned${NC}"
echo ""

# Step 3: Install Claude Code GitHub App
echo "2️⃣  Installing Claude Code GitHub App..."
CURRENT_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Try to install app
if gh api repos/$CURRENT_REPO/installation &>/dev/null; then
    echo -e "${GREEN}✓ Claude Code app already installed${NC}"
else
    # Try automatic installation
    gh extension list | grep -q "claude" || gh extension install anthropics/claude-code-extension 2>/dev/null || true
    gh claude install-app 2>/dev/null || {
        echo -e "${YELLOW}⚠ Opening browser to install Claude Code app...${NC}"
        echo "Please install the app and press Enter to continue..."
        open "https://github.com/apps/claude-code/installations/new"
        read -p "Press Enter after installing the app..."
    }
fi
echo ""

# Step 4: Load and set secrets
echo "3️⃣  Setting up GitHub secrets..."

# Load saved secrets
CONFIG_FILE="$HOME/.claude-code-template/secrets.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo -e "${GREEN}✓ Loaded saved secrets${NC}"
    
    # Set secrets in the new repo
    [ ! -z "$LINEAR_API_KEY" ] && gh secret set LINEAR_API_KEY -b "$LINEAR_API_KEY" && echo "  ✓ LINEAR_API_KEY set"
    [ ! -z "$ANTHROPIC_API_KEY" ] && gh secret set ANTHROPIC_API_KEY -b "$ANTHROPIC_API_KEY" && echo "  ✓ ANTHROPIC_API_KEY set"
    [ ! -z "$PERPLEXITY_API_KEY" ] && gh secret set PERPLEXITY_API_KEY -b "$PERPLEXITY_API_KEY" && echo "  ✓ PERPLEXITY_API_KEY set"
else
    echo -e "${YELLOW}No saved secrets found. Creating them now...${NC}"
    
    # Get secrets interactively
    read -sp "Enter LINEAR_API_KEY: " LINEAR_API_KEY
    echo ""
    [ ! -z "$LINEAR_API_KEY" ] && gh secret set LINEAR_API_KEY -b "$LINEAR_API_KEY"
    
    read -sp "Enter ANTHROPIC_API_KEY (optional): " ANTHROPIC_API_KEY
    echo ""
    [ ! -z "$ANTHROPIC_API_KEY" ] && gh secret set ANTHROPIC_API_KEY -b "$ANTHROPIC_API_KEY"
    
    read -sp "Enter PERPLEXITY_API_KEY (optional): " PERPLEXITY_API_KEY
    echo ""
    [ ! -z "$PERPLEXITY_API_KEY" ] && gh secret set PERPLEXITY_API_KEY -b "$PERPLEXITY_API_KEY"
    
    # Save for next time
    mkdir -p "$HOME/.claude-code-template"
    chmod 700 "$HOME/.claude-code-template"
    cat > "$CONFIG_FILE" << EOF
export LINEAR_API_KEY='$LINEAR_API_KEY'
export ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY'
export PERPLEXITY_API_KEY='$PERPLEXITY_API_KEY'
EOF
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✓ Secrets saved for future use${NC}"
fi
echo ""

# Step 5: Initialize TaskMaster
echo "4️⃣  Initializing TaskMaster..."
if [ ! -d ".taskmaster" ]; then
    npx task-master-ai init --yes --rules claude 2>/dev/null || echo "  ⚠ TaskMaster init failed (optional)"
fi
echo ""

# Step 6: Test the setup
echo "5️⃣  Testing setup with a test issue..."
ISSUE_URL=$(gh issue create \
    --title "Test: @claude Integration" \
    --body "@claude - Please respond with 'Hello! I'm ready to help!' to confirm the integration works." \
    2>/dev/null) || echo "  ⚠ Could not create test issue"

if [ ! -z "$ISSUE_URL" ]; then
    echo -e "${GREEN}✓ Test issue created: $ISSUE_URL${NC}"
fi

# Final summary
echo ""
echo "================================================"
echo -e "${GREEN}✨ Project '$PROJECT_NAME' is ready!${NC}"
echo ""
echo "📁 Location: $(pwd)"
echo "🔗 GitHub: https://github.com/$CURRENT_REPO"
echo "⚡ Actions: https://github.com/$CURRENT_REPO/actions"
echo ""
echo "Next steps:"
echo "1. Check if the test issue triggered Claude"
echo "2. Start coding! Claude will respond to @mentions"
echo "3. Create Linear issues and mention @claude"
echo ""
echo "Happy coding! 🚀"