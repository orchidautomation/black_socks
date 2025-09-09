#!/bin/bash

# Install claude-template command globally
# Run this once to set up the global command

set -e

echo "🌍 Installing claude-template command globally..."
echo ""

# Create the global command script
INSTALL_DIR="/usr/local/bin"
COMMAND_NAME="claude-template"
TEMPLATE_REPO="orchidautomation/claude-code-template"  # Update this to your repo

# Check for sudo if needed
if [ -w "$INSTALL_DIR" ]; then
    SUDO=""
else
    SUDO="sudo"
    echo "Need sudo access to install to $INSTALL_DIR"
fi

# Create the global command
$SUDO tee "$INSTALL_DIR/$COMMAND_NAME" > /dev/null << 'SCRIPT_END'
#!/bin/bash

# Claude Template - Global Project Creator
# Usage: claude-template <project-name>

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TEMPLATE_REPO="orchidautomation/claude-code-template"  # Update this to match your repo

# Show help
if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Claude Code Template - Project Creator"
    echo ""
    echo "Usage:"
    echo "  claude-template <project-name>    Create new project"
    echo "  claude-template --help            Show this help"
    echo "  claude-template --setup-keys      Set up API keys"
    echo ""
    echo "Examples:"
    echo "  claude-template my-awesome-app"
    echo "  claude-template todo-backend"
    echo ""
    exit 0
fi

# Setup keys command
if [ "$1" = "--setup-keys" ]; then
    echo "🔑 Setting up API keys for claude-template..."
    echo ""
    
    CONFIG_DIR="$HOME/.claude-code-template"
    CONFIG_FILE="$CONFIG_DIR/secrets.env"
    
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
    
    echo "Enter your API keys (they'll be saved securely):"
    echo ""
    
    read -p "LINEAR_API_KEY (required, from https://linear.app/settings/api): " LINEAR_KEY
    read -p "ANTHROPIC_API_KEY (optional, press Enter to skip): " ANTHROPIC_KEY
    read -p "PERPLEXITY_API_KEY (optional, press Enter to skip): " PERPLEXITY_KEY
    
    cat > "$CONFIG_FILE" << EOF
export LINEAR_API_KEY='$LINEAR_KEY'
export ANTHROPIC_API_KEY='$ANTHROPIC_KEY'
export PERPLEXITY_API_KEY='$PERPLEXITY_KEY'
EOF
    chmod 600 "$CONFIG_FILE"
    
    echo ""
    echo -e "${GREEN}✓ API keys saved!${NC}"
    echo "You can now create projects with: claude-template <project-name>"
    exit 0
fi

PROJECT_NAME="$1"

echo -e "${BLUE}🚀 Creating Claude-powered project: $PROJECT_NAME${NC}"
echo "================================================"
echo ""

# Check for saved keys
CONFIG_FILE="$HOME/.claude-code-template/secrets.env"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠ No API keys found. Run 'claude-template --setup-keys' first${NC}"
    exit 1
fi

# Step 1: Create repo from template
echo "1️⃣  Creating GitHub repository..."
gh repo create "$PROJECT_NAME" \
    --template="$TEMPLATE_REPO" \
    --public \
    --clone \
    --description="AI-powered development with Claude Code" || {
    echo -e "${RED}Failed to create repo. Is gh CLI installed and authenticated?${NC}"
    exit 1
}

cd "$PROJECT_NAME"
CURRENT_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo -e "${GREEN}✓ Created and cloned: $CURRENT_REPO${NC}"

# Step 2: Install Claude App
echo ""
echo "2️⃣  Installing Claude Code app..."
if ! gh api repos/$CURRENT_REPO/installation &>/dev/null; then
    echo "Opening browser to install Claude Code app..."
    echo "Please install for: $CURRENT_REPO"
    open "https://github.com/apps/claude-code/installations/new" 2>/dev/null || \
        xdg-open "https://github.com/apps/claude-code/installations/new" 2>/dev/null || \
        echo "Visit: https://github.com/apps/claude-code/installations/new"
    read -p "Press Enter after installing..."
fi
echo -e "${GREEN}✓ Claude Code app ready${NC}"

# Step 3: Set secrets
echo ""
echo "3️⃣  Configuring secrets..."
source "$CONFIG_FILE"
[ ! -z "$LINEAR_API_KEY" ] && gh secret set LINEAR_API_KEY -b "$LINEAR_API_KEY"
[ ! -z "$ANTHROPIC_API_KEY" ] && gh secret set ANTHROPIC_API_KEY -b "$ANTHROPIC_API_KEY"
[ ! -z "$PERPLEXITY_API_KEY" ] && gh secret set PERPLEXITY_API_KEY -b "$PERPLEXITY_API_KEY"
echo -e "${GREEN}✓ Secrets configured${NC}"

# Step 4: Create test issue
echo ""
echo "4️⃣  Creating test issue..."
gh issue create \
    --title "🎉 @claude - Project initialized!" \
    --body "@claude - Reply with a welcome message to confirm you're ready!" \
    2>/dev/null || true

# Done!
echo ""
echo "================================================"
echo -e "${GREEN}✨ Project ready at: $(pwd)${NC}"
echo ""
echo "🔗 GitHub: https://github.com/$CURRENT_REPO"
echo "⚡ Check Actions: https://github.com/$CURRENT_REPO/actions"
echo ""
echo "Claude is now listening for @mentions! 🤖"
SCRIPT_END

# Make it executable
$SUDO chmod +x "$INSTALL_DIR/$COMMAND_NAME"

# Create short alias
$SUDO ln -sf "$INSTALL_DIR/$COMMAND_NAME" "$INSTALL_DIR/cct" 2>/dev/null || true

echo -e "✅ Global commands installed!"
echo ""
echo "You can now create projects from ANYWHERE with:"
echo ""
echo "  cct <project-name>              # Short version"
echo "  claude-template <project-name>  # Full version"
echo ""
echo "First time setup:"
echo "  cct --setup-keys"
echo ""
echo "Examples:"
echo "  cd ~/Desktop"
echo "  cct my-awesome-app       # Creates and sets up everything!"
echo "  cct todo-backend"
echo ""