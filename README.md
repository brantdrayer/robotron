# Contractor

**OpenClaw acts as your autonomous contractor and action agent** — continuously receiving information from external sources and intelligently taking actions based on what it finds.

This repo contains my customized OpenClaw configuration as a simple, reliable, self-hosted monitoring agent. Built on the open-source [OpenClaw project](https://github.com/openclaw/openclaw) (formerly Clawdbot → Moltbot), customized to:
- Fully integrate with Discord as the primary (and only) channel
- Receive incoming data and notifications from Oracle databases through APEX-exposed web services
- Show all LLM-powered reasoning, decision-making, tool calls, and responses live in Discord conversations — so I can watch the agent think, respond, and act in real time

## Why This Setup?
- Keeps everything conversational and visible right in Discord — I chat with the agent, see its full reasoning with the LLM, tool calls, and decisions live as they happen.
- Pulls real-time data/notifications/alerts directly from my Oracle database using APEX-exposed web services (no complex polling or agents needed on the DB side).
- Simple integration: Discord acts as both input (I can ask questions or trigger checks) and output (agent responds, shows its thought process, and handles actions in the same chat).
- Self-hosted and low-overhead — runs on my own machine with zero vendor lock-in beyond the LLM API key.

OpenClaw delivers a persistent, tool-equipped AI agent that feels like a quiet, always-on team member — perfect for transparent, low-friction monitoring.

## Security Notes
OpenClaw agents have powerful access (tools, channels, code execution). Use:
- Least-privilege LLM keys and Discord bot token
- Isolated runtime (VM/container if possible)
- Review all skills before enabling
- Never expose publicly without strong auth

See official security docs.

## Quick Start – Get OpenClaw running

### Prerequisites
- Node.js 22+ (check with `node -v`; LTS recommended)
- npm (comes with Node)
- Git
- LLM API key (e.g., OpenAI, Anthropic Claude, Grok, Gemini, or local Ollama)
- Oracle APEX web service endpoint URL and any auth details

### Installation Steps (as done on my machine)
1. **Clone the repo** (to get my custom configs, skills, or .env.example)
   ```bash
   git clone https://github.com/brantdrayer/contractor.git
   cd contractor
2. **Install Openclaw globally**
   ```bash
   npm install -g openclaw@latest
3. **Run the OpenClaw onboarding command to setup intial configuration**
   ```bash
   openclaw onboard --install-daemon
   ```
   --install-daemon flag is optional. Recommended if you want it to run 24-7.
   Follow the prompts in the ui.
   
## Configuration Template
See `openclaw.example.json` for a sanitized template of my setup including discord and telegram channel configs.

To use:
1. Copy it to `~/.openclaw/openclaw.json` (or set `OPENCLAW_CONFIG_PATH` env var)
2. Replace placeholders with your real values (Discord token, LLM key, etc.)
3. Restart the gateway
