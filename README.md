# Robotron 

**OpenClaw acts as your autonomous agent and action agent** — continuously receiving information from external sources and intelligently taking actions based on what it finds.

## My Customized Setup
This repo contains my customized OpenClaw configuration as a simple, reliable, self-hosted monitoring agent. Built on the open-source [OpenClaw project](https://github.com/openclaw/openclaw) (formerly Clawdbot → Moltbot), customized to:
- Run on a dedicated Ubunut VirtualBox VM
- Use Discord as the primary (and only) channel for all interaction
- Receive real-time data and notifications from Oracle databases via a Discord webhook (initiated by APEX-exposed web services)
- Trigger, test, and manage Oracle interactions through SQL Developer
- Display the agent's full LLM-powered reasoning, tool calls, decisions, and responses live in Discord — making it easy to follow exactly what the agent is thinking and doing

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

## Configuration Template
See `openclaw.example.json` for a sanitized template of my setup including discord and telegram channel configs.

To use:
1. Copy it to `~/.openclaw/openclaw.json` (or set `OPENCLAW_CONFIG_PATH` env var)
2. Replace placeholders with your real values (Discord token, LLM key, etc.)
3. Restart the gateway

Or use it as a reference for specific configuration elements.
## Quick Start – Get OpenClaw running

### Prerequisites
- Isolated computer or server (Many use an Cloud VM with AWS or Hertzner. For this setup I used a VirtualBox VM)
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
   Follow the prompts in the ui. This should automatically populate 
   
   <img width="679" height="580" alt="image" src="https://github.com/user-attachments/assets/8beb7160-10f3-4fb9-8149-876e05b3a454" />

4. **Hatching the Agent (Creating Your First AI Contractor)**
   - Once OpenClaw is installed and the onboarding wizard runs, you'll need to hatch your agent (give it context in your first conversation).

   When prompted during onboarding (or run `openclaw tui` later if already onboarded):
   - Select **Hatch in TUI (recommended)**.
   - Answer the bot's questions about what it should call itself and you, it's personality, etc.  
   - Now you can talk to it directly in the terminal!

## Setting Up the Discord Channel

Here's the basic outline of how to get Discord connected as the channel for OpenClaw:

1. **Create a Discord bot**
   - Go to the Discord Developer Portal (discord.com/developers/applications).
   - Make a new application and added a bot to it.
   - Copy the bot token (keep it secure — never share or commit).

2. **Invite the bot to a server**
   - Generate an invite link from the OAuth2 URL Generator (select bot scope + basic permissions like read/send messages).
   - Use the link to add the bot to a private Discord server (guild).

3. **Connect it in configuration**
   - Run `openclaw configure` (Or copy my config and add secrets).
   - When it asks about channels, choose Discord and paste the bot token.
   - Pair the channel via `openclaw pairing`
   - Make sure allowBots is set to true in config.   
4. **Quick test**
   - Message the bot in Discord
   - It should respond like a regular LLM chat in the discord channel.
