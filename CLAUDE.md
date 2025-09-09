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
- **taskmaster-ai**: Task management and PRD generation
  - **Local Dev**: Claude Code works (`claude-code/sonnet`, `claude-code/opus`) - no API key
  - **GitHub Actions**: NEEDS Anthropic API key (Claude Code won't authenticate in CI/CD)
  - **Research**: Uses Perplexity API for real-time information
  
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

### Model Configuration
- Primary model: `claude-code/sonnet` (no API key needed)
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

Set models:
```
Change the main model to claude-code/sonnet
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

### TaskMaster not using Claude Code
- Run `taskmaster models` to verify
- Select `claude-code/sonnet` or `claude-code/opus`
- No API key should be required

### Linear not updating
- Check Linear MCP server is running
- Verify OAuth authentication
- Check webhook configuration

### Tasks not executing
- Verify dependencies are met
- Check TaskMaster initialization
- Review task status in Linear