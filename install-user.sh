#!/bin/bash

# Install claude-template command for current user (no sudo needed)

set -e

echo "🌍 Installing cct (Claude Code Template) command..."
echo ""

# Use user's local bin directory
USER_BIN="$HOME/.local/bin"
mkdir -p "$USER_BIN"

# Create the command
cat > "$USER_BIN/cct" << 'SCRIPT_END'
#!/bin/bash

# CCT - Claude Code Template Project Creator
# Usage: cct <project-name>

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TEMPLATE_REPO="orchidautomation/claude-code-template"

# Show help
if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "🤖 CCT - Claude Code Template"
    echo ""
    echo "Usage:"
    echo "  cct <project-name>    Create new AI-powered project"
    echo "  cct --setup-keys      Set up API keys"
    echo "  cct --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  cct my-app"
    echo "  cct todo-backend"
    echo ""
    exit 0
fi

# Setup keys
if [ "$1" = "--setup-keys" ]; then
    echo "🔑 Setting up API keys..."
    CONFIG_DIR="$HOME/.claude-code-template"
    CONFIG_FILE="$CONFIG_DIR/secrets.env"
    
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    
    echo "Enter your API keys:"
    echo ""
    read -p "LINEAR_API_KEY (from linear.app/settings/api): " LINEAR_KEY
    read -p "ANTHROPIC_API_KEY (optional): " ANTHROPIC_KEY
    read -p "PERPLEXITY_API_KEY (optional): " PERPLEXITY_KEY
    
    cat > "$CONFIG_FILE" << EOF
export LINEAR_API_KEY='$LINEAR_KEY'
export ANTHROPIC_API_KEY='$ANTHROPIC_KEY'
export PERPLEXITY_API_KEY='$PERPLEXITY_KEY'
EOF
    chmod 600 "$CONFIG_FILE"
    
    echo -e "${GREEN}✓ Keys saved! Now run: cct <project-name>${NC}"
    exit 0
fi

PROJECT_NAME="$1"

# Check for keys
CONFIG_FILE="$HOME/.claude-code-template/secrets.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}No keys found. Run: cct --setup-keys${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Creating: $PROJECT_NAME${NC}"
echo ""

# Create repo
echo "📦 Creating GitHub repo..."
gh repo create "$PROJECT_NAME" \
    --template="$TEMPLATE_REPO" \
    --public \
    --clone \
    --description="AI-powered with Claude Code" || exit 1

cd "$PROJECT_NAME"
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Install Claude app
echo "🤖 Installing Claude..."
if ! gh api repos/$REPO/installation &>/dev/null; then
    echo "Visit: https://github.com/apps/claude-code"
    echo "Install for: $REPO"
    read -p "Press Enter when done..."
fi

# Set secrets
echo "🔐 Setting secrets..."
source "$CONFIG_FILE"
[ "$LINEAR_API_KEY" ] && gh secret set LINEAR_API_KEY -b "$LINEAR_API_KEY"
[ "$ANTHROPIC_API_KEY" ] && gh secret set ANTHROPIC_API_KEY -b "$ANTHROPIC_API_KEY"
[ "$PERPLEXITY_API_KEY" ] && gh secret set PERPLEXITY_API_KEY -b "$PERPLEXITY_API_KEY"

# Test
echo "✅ Creating test issue..."
gh issue create -t "🎉 @claude ready?" -b "@claude - say hello!" 2>/dev/null || true

echo ""
echo -e "${GREEN}✨ Done! Project at: $(pwd)${NC}"
echo "📍 GitHub: https://github.com/$REPO"
echo "⚡ Actions: https://github.com/$REPO/actions"
SCRIPT_END

chmod +x "$USER_BIN/cct"

# Add to PATH if needed
if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
    echo ""
    echo "Adding $USER_BIN to PATH..."
    
    # Detect shell and add to appropriate config
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    echo "" >> "$SHELL_RC"
    echo "# Added by claude-code-template" >> "$SHELL_RC"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
    
    echo "Added to $SHELL_RC"
    echo ""
    echo "⚠️  Run this to activate: source $SHELL_RC"
    echo "   Or open a new terminal"
fi

# Also create cct-add command for existing repos
cat > "$USER_BIN/cct-add" << 'ADD_SCRIPT_END'
#!/bin/bash

# Add Claude Code to existing repository
# Usage: Run from inside any existing repo

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔧 Adding Claude Code to Existing Repo${NC}"
echo ""

# Check git repo
if [ ! -d .git ]; then
    echo -e "${RED}Error: Not in a git repository!${NC}"
    exit 1
fi

# Download and run the add-to-existing script
SCRIPT_URL="https://raw.githubusercontent.com/orchidautomation/claude-code-template/main/add-to-existing.sh"
curl -sL "$SCRIPT_URL" | bash
ADD_SCRIPT_END

chmod +x "$USER_BIN/cct-add"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Commands:"
echo "  cct <project>      # Create NEW project from template"
echo "  cct-add           # Add Claude to EXISTING repo (run from inside repo)"
echo "  cct --setup-keys   # Configure API keys"
echo "  cct --help        # Show help"
echo ""

# Check if cct is available
if command -v cct &> /dev/null; then
    echo "✓ cct command is ready!"
else
    echo "⚠️  Activate with: source ~/.zshrc (or ~/.bashrc)"
fi