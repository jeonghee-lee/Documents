# OpenClaw User Guide
> Practical guide for frequent day-to-day usage

---

## Table of Contents

1. [What is OpenClaw?](#what-is-openclaw)
2. [Core Concepts](#core-concepts)
3. [Cron Jobs (Scheduled Tasks)](#cron-jobs)
4. [Sending Messages to the Agent](#sending-messages-to-the-agent)
5. [Skills](#skills)
6. [Models](#models)
7. [Gateway](#gateway)
8. [Channels (Telegram)](#channels)
9. [Memory & Workspace](#memory--workspace)
10. [System Health & Diagnostics](#system-health--diagnostics)
11. [Configuration](#configuration)
12. [Daemon & Services](#daemon--services)
13. [Useful One-Liners](#useful-one-liners)
14. [File Reference](#file-reference)

---

## What is OpenClaw?

OpenClaw is a self-hosted AI agent platform that runs on your machine. It connects an AI model (Gemini) to your communication channels (Telegram), tools (Gmail, Calendar, GitHub, web search), and automation (cron jobs, webhooks).

Your setup:
- **Agent name:** Crazyking (main agent)
- **Model:** `google-gemini-cli/gemini-2.5-flash` (fast), fallback: `gemini-3-pro-preview`
- **Channel:** Telegram (`@jhbest_bot`)
- **Timezone:** Asia/Singapore (UTC+8)
- **Config dir:** `~/.openclaw/`

---

## Core Concepts

| Concept | What it is |
|---|---|
| **Agent** | The AI persona that responds (Crazyking) |
| **Session** | A conversation context (main or isolated) |
| **Skill** | A tool the agent can use (gmail, gog, search) |
| **Cron job** | A scheduled automated task |
| **Heartbeat** | A periodic background check (~30min) |
| **Gateway** | The local API server (port 18789) |
| **Channel** | Where messages are delivered (Telegram) |

---

## Cron Jobs

Cron jobs run the agent on a schedule and deliver results to Telegram.

### View Current Jobs

```bash
openclaw cron list
openclaw cron list --all        # include disabled
openclaw cron list --json       # machine-readable
openclaw cron status
```

### Add a New Cron Job

```bash
openclaw cron add \
  --name "job-name" \
  --description "What this does" \
  --cron "0 8 * * *" \
  --tz "Asia/Singapore" \
  --agent main \
  --session isolated \
  --message "Your prompt to the agent here" \
  --announce \
  --to "5405814655" \
  --timeout-seconds 120
```

**Common cron expressions:**

| Schedule | Expression |
|---|---|
| Every day at 8:00 AM SGT | `0 8 * * *` |
| Every day at 9:00 AM SGT | `0 9 * * *` |
| Weekdays at 8:00 AM SGT | `0 8 * * 1-5` |
| Every hour | `0 * * * *` |
| Every 30 minutes | `*/30 * * * *` |
| Every Monday at 9 AM SGT | `0 9 * * 1` |
| 1st of each month at 9 AM SGT | `0 9 1 * *` |

### Edit an Existing Job (CLI — recommended)

```bash
# Change schedule time
openclaw cron edit morning-briefing --cron "0 8 * * *" --tz "Asia/Singapore"

# Change the message/prompt
openclaw cron edit morning-briefing --message "New prompt here"

# Enable or disable
openclaw cron edit morning-briefing --enable
openclaw cron edit morning-briefing --disable

# Change timeout
openclaw cron edit morning-briefing --timeout-seconds 180
```

### Edit an Existing Job (file — quick)

```bash
# Direct file edit
nano ~/.openclaw/cron/jobs.json
```

> The cron expression is in `schedule.expr`. After editing, the scheduler picks it up automatically.

### Enable / Disable / Remove

```bash
openclaw cron enable morning-briefing
openclaw cron disable morning-briefing
openclaw cron rm morning-briefing
```

### Trigger a Job Immediately (test/debug)

```bash
openclaw cron run morning-briefing
```

### View Run History

```bash
openclaw cron runs                          # last 50 runs
openclaw cron runs --id <job-id> --limit 10
```

### Your Current Job: morning-briefing

- **Schedule:** 8:00 AM SGT daily (`0 8 * * *`)
- **Delivers to:** Telegram (ID: 5405814655)
- **Task:** Check urgent Gmail, today's/tomorrow's calendar via gog, Singapore weather
- **Session:** isolated (clean context each run)
- **File:** `~/.openclaw/cron/jobs.json`

---

## Sending Messages to the Agent

### From the Terminal

```bash
# Simple message
openclaw agent -m "What's the weather in Singapore?"

# With thinking (for complex tasks)
openclaw agent -m "Analyze my last 10 emails" --thinking

# Specify agent explicitly
openclaw agent -m "Your message" --agent main

# Deliver result to Telegram
openclaw agent -m "Check my calendar" --deliver --channel telegram

# JSON output
openclaw agent -m "Status update" --json

# With timeout
openclaw agent -m "Long task" --timeout 300
```

### From Telegram

Just message `@jhbest_bot` directly. The agent (Crazyking) responds using Gemini.

---

## Skills

Skills are tools the agent can call during a conversation.

### Check Skill Status

```bash
openclaw skills list
openclaw skills check
openclaw doctor --deep          # full skill health check
```

### Your Enabled Skills

| Skill | Purpose | Status |
|---|---|---|
| `gog` | Google Workspace (Gmail, Calendar, Drive) via OAuth | Working |
| `ddg-search` | DuckDuckGo web search (no API key needed) | Working |
| `weather` | Weather lookups | Working |
| `gmail` | Gmail via IMAP (separate from gog) | Needs fix |
| `github` | GitHub API access | Token expired |

### Update a Skill's Config

```bash
# Update GitHub token
openclaw config set skills.entries.github.env.GITHUB_TOKEN "ghp_YOUR_NEW_TOKEN"

# Update Gmail app password
openclaw config set skills.entries.gmail.env.GMAIL_APP_PASS "xxxx xxxx xxxx xxxx"

# Enable a skill
openclaw config set skills.entries.SKILLNAME.enabled true

# Disable a skill
openclaw config set skills.entries.SKILLNAME.enabled false
```

### Add a Skill to Allowed Bundled List

```bash
openclaw config set skills.allowBundled '["weather","gmail","gog","github","ddg-search"]'
```

---

## Models

### Check Current Model

```bash
openclaw models list
openclaw models status --agent main
```

### Switch Model

```bash
# Set the primary model (fast)
openclaw models set primary "google-gemini-cli/gemini-2.5-flash"

# Set a slower but smarter fallback
openclaw models set fallbacks '["google-gemini-cli/gemini-3-pro-preview"]'
```

**Your model stack:**
- Primary: `gemini-2.5-flash` — fast, good for daily tasks
- Fallback: `gemini-3-pro-preview` — slower, used for complex reasoning

---

## Gateway

The gateway is the local API server OpenClaw uses internally.

### Common Commands

```bash
openclaw gateway status
openclaw gateway health
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
openclaw gateway usage-cost      # token/cost tracking
```

### Gateway Details

- **URL:** `http://localhost:18789`
- **Mode:** local (loopback only, not exposed externally)
- **Auth:** token-based

---

## Channels

### Telegram

Your bot (`@jhbest_bot`) is the primary channel.

```bash
openclaw channels list
openclaw channels status
openclaw channels logs           # view recent message logs
```

### Pairing a New Device

```bash
openclaw qr                      # show QR code to pair
openclaw pairing list            # list pending pairings
openclaw pairing approve         # approve a pairing request
openclaw devices list            # list paired devices
```

---

## Memory & Workspace

The agent's memory lives in `~/.openclaw/workspace/`.

### Key Files

| File | Purpose |
|---|---|
| `workspace/MEMORY.md` | Long-term memory (loaded in main sessions) |
| `workspace/AGENTS.md` | Agent behavior rules |
| `workspace/SOUL.md` | Agent personality (Crazyking) |
| `workspace/USER.md` | Your profile (JHbest) |
| `workspace/HEARTBEAT.md` | Periodic background check tasks |
| `workspace/memory/YYYY-MM-DD.md` | Daily session logs |

### Search Memory

```bash
openclaw memory status
openclaw memory search "keyword"
openclaw memory index             # rebuild memory index
```

### Edit the Agent's Long-term Memory

```bash
nano ~/.openclaw/workspace/MEMORY.md
```

> Add facts, preferences, or context you want the agent to always remember.

### Edit Heartbeat Tasks

```bash
nano ~/.openclaw/workspace/HEARTBEAT.md
```

> Heartbeat runs every ~30 minutes and silently checks for anything worth notifying you about (emails, calendar, weather). It stays quiet between 23:00–08:00 SGT.

---

## System Health & Diagnostics

### Quick Status Check

```bash
openclaw status
openclaw health
openclaw doctor
```

### Deep Diagnostics

```bash
openclaw doctor --deep
openclaw doctor --repair         # auto-fix detected issues
openclaw status --all --usage
openclaw status --json
```

### View Logs

```bash
openclaw logs                    # recent logs
openclaw logs --follow           # live tail
openclaw logs --limit 100
openclaw logs --json
```

### Sessions

```bash
openclaw sessions                # list active sessions
openclaw sessions --json
openclaw sessions --active
```

---

## Configuration

### Read Config Values

```bash
openclaw config get                          # all config
openclaw config get agents.defaults.model
openclaw config get skills.allowBundled
```

### Set Config Values

```bash
openclaw config set KEY "value"

# Examples:
openclaw config set commands.ownerDisplay "raw"
openclaw config set channels.telegram.streaming "partial"
```

### Remove a Config Key

```bash
openclaw config unset KEY
```

### Open Full Config Wizard

```bash
openclaw configure
openclaw configure --section skills
```

### Backup & Restore

The config file is `~/.openclaw/openclaw.json`.
Backups are auto-created as `openclaw.json.bak*`.

```bash
# Manual backup
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.manual-bak

# Restore from backup
cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json
```

---

## Daemon & Services

The daemon keeps OpenClaw running in the background.

```bash
openclaw daemon status
openclaw daemon start
openclaw daemon stop
openclaw daemon restart
openclaw daemon install          # install as system service
openclaw daemon uninstall
```

---

## Useful One-Liners

```bash
# Check everything is healthy
openclaw doctor --deep

# See what's scheduled
openclaw cron list --all

# Manually trigger morning briefing
openclaw cron run morning-briefing

# Check run history for morning-briefing
openclaw cron runs --limit 5

# Change cron job time (e.g. 8 AM → 7 AM SGT)
openclaw cron edit morning-briefing --cron "0 7 * * *" --tz "Asia/Singapore"

# Ask agent a quick question from terminal
openclaw agent -m "What's the weather in Singapore today?"

# Ask agent with result delivered to Telegram
openclaw agent -m "Summarize my unread emails" --deliver --channel telegram

# Restart agent/services
openclaw daemon restart

# Check gateway health
openclaw gateway health

# View live logs
openclaw logs --follow

# Update OpenClaw
openclaw update status
openclaw update wizard
```

---

## File Reference

```
~/.openclaw/
├── openclaw.json              # Main config (models, channels, skills, gateway)
├── .env                       # Environment variables (API keys)
├── cron/
│   └── jobs.json              # Scheduled cron jobs
├── workspace/
│   ├── MEMORY.md              # Agent long-term memory
│   ├── SOUL.md                # Agent personality
│   ├── USER.md                # Your profile
│   ├── HEARTBEAT.md           # Background check tasks
│   ├── AGENTS.md              # Agent behavior rules
│   └── memory/
│       └── YYYY-MM-DD.md      # Daily session logs
├── logs/
│   └── commands.log           # Command history log
└── identity/
    └── device.json            # Device identity & keys
```

---

## Quick Reference Card

| Task | Command |
|---|---|
| List cron jobs | `openclaw cron list` |
| Change cron time | `openclaw cron edit <name> --cron "0 8 * * *" --tz "Asia/Singapore"` |
| Trigger job now | `openclaw cron run <name>` |
| Add new cron job | `openclaw cron add --name ... --cron ... --message ...` |
| Remove cron job | `openclaw cron rm <name>` |
| Send agent a message | `openclaw agent -m "..."` |
| Check system health | `openclaw doctor --deep` |
| View logs | `openclaw logs --follow` |
| Restart daemon | `openclaw daemon restart` |
| List skills | `openclaw skills list` |
| Switch model | `openclaw models set primary "..."` |
| Backup config | `cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak` |
