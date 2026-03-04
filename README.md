# Robotron Agent

**OpenClaw acts as your autonomous agent** — continuously receiving information from external sources and intelligently taking action based on what it finds.

## Overview

This repository contains a customized OpenClaw configuration built as a simple, reliable, self-hosted monitoring agent. It is built on the open-source [OpenClaw project](https://github.com/openclaw/openclaw) (formerly Clawdbot → Moltbot) and configured to:

- Run on a dedicated Ubuntu VirtualBox VM
- Use Discord as the primary interaction channel
- Receive real-time data and notifications from an Oracle Autonomous Database via a Discord webhook (initiated by APEX-exposed web services)
- Trigger, test, and manage Oracle interactions through SQL Developer
- Display the agent's full LLM-powered reasoning, tool calls, decisions, and responses live in Discord — making it easy to follow exactly what the agent is thinking and doing

## Architecture

```
   SQL Developer
(manual DB interaction)
        |
Oracle Autonomous DB
        │
   APEX Web Service
        │
  Discord Webhook ──► Discord Server ◄──► OpenClaw Agent ◄──► LLM API                                 
```

## Why This Setup?

- **Transparent reasoning** — Chat with the agent directly in Discord and see its full LLM reasoning, tool calls, and decisions live as they happen.
- **Real-time DB integration** — Pulls notifications and alerts directly from Oracle Autonomous Database using APEX-exposed web services, with no complex polling or server-side agents required.
- **Simple, unified channel** — Discord acts as both input (ask questions or trigger checks) and output (the agent responds and handles actions in the same interface).
- **Self-hosted and low-overhead** — Runs on your own machine with zero vendor lock-in beyond an LLM API key.
- **Secure tunnel via Tailscale** — Exposes only what is necessary, to only the devices that need access, without opening public ports.

OpenClaw delivers a persistent, tool-equipped AI agent that feels like a quiet, always-on team member — ideal for transparent, low-friction monitoring.

---

## Security Notes

OpenClaw agents have significant access (tools, channels, code execution). Follow these practices:

- Use least-privilege LLM API keys and Discord bot tokens
- Run in an isolated environment (VM or container)
- Review all skills before enabling them
- Never expose the agent publicly without strong authentication
- Rotate secrets regularly and never commit them to version control

See the [official OpenClaw security documentation](https://github.com/openclaw/openclaw) for full guidance.

---

## Configuration Template

See `openclaw.example.json` for a sanitized template of this setup, including Discord and Telegram channel configs.

**To use:**
1. Copy it to `~/.openclaw/openclaw.json` (or set the `OPENCLAW_CONFIG_PATH` environment variable)
2. Replace all placeholders with your real values (Discord token, LLM key, etc.)
3. Restart the OpenClaw gateway

---

## Quick Start

### Prerequisites

- An isolated machine or VM (e.g., VirtualBox Ubuntu VM, AWS EC2, or Hetzner VPS)
- Node.js 22+ (`node -v` to verify; LTS recommended)
- npm (included with Node.js)
- Git
- An LLM API key (OpenAI, Anthropic Claude, Grok, Gemini, or a local Ollama instance)
- A Tailscale account (for secure remote access)

---

### 1. Clone the Repository

```bash
git clone https://github.com/brantdrayer/robotron.git
cd robotron
```

### 2. Install OpenClaw Globally

```bash
npm install -g openclaw@latest
```

### 3. Run the Onboarding Wizard

```bash
openclaw onboard --install-daemon
```

The `--install-daemon` flag is optional but recommended if you want the agent to run continuously (24/7). Follow the prompts to complete initial configuration.

### 4. Hatch the Agent

After the onboarding wizard completes, you'll need to "hatch" your agent — providing it with identity and context.

When prompted (or run `openclaw tui` if already onboarded):
- Select **Hatch in TUI (recommended)**
- Answer the bot's questions about its name, your name, personality, and role
- Once hatched, you can interact with the agent directly in the terminal

---

## Setting Up the Discord Channel

### Create a Discord Bot

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application and add a Bot to it
3. Copy the bot token — keep it secure and never commit it to version control

### Invite the Bot to Your Server

1. In the OAuth2 URL Generator, select the `bot` scope and grant basic permissions (Read Messages, Send Messages)
2. Use the generated invite link to add the bot to a private Discord server

### Connect Discord in OpenClaw

```bash
openclaw configure
```

When prompted for channels, select Discord and paste your bot token. Then:

```bash
# View pending pairing requests
openclaw devices list

# Approve the channel
openclaw pairing approve discord <Pairing Code>
```

> Ensure `allowBots` is set to `true` in your config file.

**Quick Test:** @mention the bot in your Discord server and ask it a question — it should respond like a standard LLM.

---

## Adding a Discord Webhook

A Discord webhook provides a public HTTPS endpoint that Oracle APEX can call to deliver messages directly into the Discord channel.

### Create the Webhook

1. In Discord, go to **Server Settings > Integrations > Webhooks**
2. Click **New Webhook**, configure it, and copy the webhook URL

### Test the Webhook

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "username": "Oracle Alert",
    "content": "<@YOUR_BOT_USER_ID> Your message here"
  }' \
  https://discord.com/api/webhooks/YOUR_WEBHOOK_URL
```

> **Important:** To trigger a bot response, `@mention` the bot in the `content` field as shown above.

## Setting Up Tailscale

[Tailscale](https://tailscale.com) creates a secure, encrypted mesh network between your devices. This allows the OpenClaw VM to be reached remotely — by Oracle APEX, your development machine, or other services — without exposing any ports publicly. It requires at least 2 devices to set up.

### Install Tailscale on the VM

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Authenticate via the URL displayed in the terminal. The VM will receive a stable Tailscale IP (e.g., `100.x.x.x`).

### Use Tailscale Serve for HTTPS

`tailscale serve` exposes a local port over HTTPS within your Tailscale network, providing a clean, TLS-terminated URL for any local service:

```bash
# Expose a local service on port 18789 (OpenClaw gateway default) to your Tailscale network over HTTPS
sudo tailscale serve https://127.0.0.1:18789
```

This is useful if OpenClaw exposes a local HTTP API or dashboard that you want to access securely from other Tailscale devices.

### Verify Connectivity

```bash
# From another Tailscale device
ping <vm-tailscale-ip>
curl https://<vm-tailscale-hostname>
```

> Tailscale devices must be on the same tailnet, or have appropriate ACLs configured in the [Tailscale admin console](https://login.tailscale.com/admin/acls).

---

## Oracle Autonomous Database

This setup uses Oracle Autonomous Database (ADB) as the data source, with Oracle APEX exposing web services that push notifications to the Discord webhook. You can find information on how to set one up in the [Oracle Documentation](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/index.html).

### Configure Wallet

Oracle Autonomous Database recommends using mTLS. You will need to download the wallet zip file from the Oracle Console and use it for authentication in SQL Developer.

## SQL Developer Installation

Oracle SQL Developer provides a GUI for connecting to and managing Oracle Autonomous Database — useful for testing queries, running PL/SQL, and triggering web services manually. It can be downloaded and installed [here](https://www.oracle.com/tools/downloads/sqldeveloper-downloads.html) 

### Connect to Autonomous Database

- In SQL Developer, create a new connection.
   - **Connection Type:** Cloud Wallet
   - **Configuration File:** Browse to the downloaded `.zip` wallet
   - **Service:** Select the appropriate service level (e.g., `<dbname>_low`)
   - **Username / Password:** Your ADB admin or application credentials
- Click **Test**, then **Connect**

- Optionally enable DMBS output in SQL Developer to test the connection before trying to send a message.

### Hit the Discord Webhook from the ADB using Apex Web Service

Below is an example statement that invokes APEX_WEB_SERVICE.MAKE_REST_REQUEST to send an https message to Discord.

```plsql
DECLARE
  l_url      VARCHAR2(4000) := 'DISCORD_WEBHOOK_URL';
  l_payload  CLOB           := '{
    "username": "DB Alert Bot",
    "content": "<@BOT_USER_ID> Test Message"
  }';
  l_response CLOB;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Sending to: ' || l_url);
  DBMS_OUTPUT.PUT_LINE('Payload preview: ' || DBMS_LOB.SUBSTR(l_payload, 200, 1));

  apex_web_service.g_request_headers.delete();

  -- Set the Content-Type header
  apex_web_service.g_request_headers(1).name  := 'Content-Type';
  apex_web_service.g_request_headers(1).value := 'application/json';

  l_response := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
    p_url         => l_url,
    p_http_method => 'POST',
    p_body        => l_payload
);

  -- Discord success = HTTP 204 ? response CLOB is empty/null
  IF l_response IS NULL OR LENGTH(l_response) = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Success: HTTP 204 (No Content) - message sent!');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Response (unexpected but here it is):');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(l_response, 1000, 1));
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    -- If you get ORA-24247 network ACL ? rare in Autonomous for public HTTPS, but check
    RAISE;
END;
/
```

If that message is successfull, it will return: 
`Success: HTTP 204 (No Content) - message sent!`

