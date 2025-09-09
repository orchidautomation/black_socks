# Claude Code Project Configuration

## Available Subagents

### linear-prd-generator
Generates Product Requirements Documents from Linear issues.
- Triggered by @claude mentions in Linear
- Uses TaskMaster to parse and expand requirements
- Updates Linear with generated content

### task-executor
Executes TaskMaster tasks sequentially.
- Respects task dependencies
- Updates Linear status in real-time
- Creates atomic commits for each task

### linear-sync
Maintains synchronization between Linear and TaskMaster.
- Bidirectional status updates
- Dependency management
- Progress tracking

## MCP Servers

### Required (Project-level)
- **taskmaster-ai**: Task management and PRD generation (v0.18+ with Claude Code!)
  - Supports multiple AI providers (Anthropic, OpenAI, Perplexity, etc.)
  - Claude Code support: `sonnet --claude-code` or `opus --claude-code` (no API key needed)
  - Research model: Can use Perplexity for up-to-date information
  - Fallback models: Automatic failover if primary model fails
  
- **github**: Repository operations
  - Requires GITHUB_TOKEN in environment

### Required (Global)
- **linear**: Linear API access
  - Install globally: `claude mcp add linear --scope user --transport sse https://mcp.linear.app/sse`
  - Uses OAuth authentication

## Workflows

### Linear-TaskMaster Integration
**Trigger**: @claude mention in Linear issue

**Process**:
1. Extract issue details from Linear
2. Generate PRD using TaskMaster
3. Create subtasks with dependencies
4. Update Linear issue with PRD
5. Create Linear sub-issues for each task
6. Execute tasks sequentially
7. Create PR when complete

## Rules and Best Practices

### Task Management
- Always use TaskMaster for task breakdown
- Create atomic commits for each subtask
- Update Linear in real-time during execution
- Respect task dependencies

### Linear Integration
- PRD goes in issue description
- Each TaskMaster task becomes a Linear sub-issue
- Status updates are bidirectional
- Link all PRs to Linear issues

### Code Quality
- Follow existing code conventions
- Use project's existing libraries
- Create incremental, testable changes
- Run linting and tests before committing

### Model Configuration (TaskMaster v0.18+)
- Primary model: `sonnet --claude-code` (no API key needed)
- Research model: Perplexity (optional, requires API key)
- Fallback: Not needed with Claude Code

## Environment Variables

Required in GitHub Actions:
```yaml
env:
  LINEAR_API_KEY: ${{ secrets.LINEAR_API_KEY }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  PERPLEXITY_API_KEY: ${{ secrets.PERPLEXITY_API_KEY }} # Optional
```

## Command Examples

Initialize TaskMaster:
```
Initialize taskmaster-ai in my project
```

Set models (v0.18+):
```
Change the main model to sonnet --claude-code
# Or via CLI:
task-master models --set-main sonnet --claude-code
```

Parse PRD:
```
Parse my PRD and generate tasks
```

Execute next task:
```
What's the next task and can you implement it?
```

## Project Structure

```
.claude/
├── agents/           # Subagent definitions
├── workflows/        # Workflow definitions
├── mcp.json         # MCP server configuration
└── CLAUDE.md        # This file

.taskmaster/
├── docs/            # PRDs and documentation
├── tasks/           # Generated task files
└── config.json      # TaskMaster configuration
```

## Troubleshooting

### TaskMaster not using Claude Code (v0.18+)
- Run `task-master models` to verify
- Use `task-master models --set-main sonnet --claude-code`
- Or `task-master models --set-main opus --claude-code`
- No API key should be required

### Linear not updating
- Check Linear MCP server is running
- Verify OAuth authentication
- Check webhook configuration

### Tasks not executing
- Verify dependencies are met
- Check TaskMaster initialization
- Review task status in Linear