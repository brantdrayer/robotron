# Robotron Agent

**OpenClaw acts as your autonomous agent** — continuously receiving information from external sources and intelligently taking action based on what it finds.
**OpenClaw acts as your autonomous agent** — continuously receiving information from external sources and intelligently taking action based on what it finds.

---

## Overview

Robotron is a self-hosted monitoring agent built on [OpenClaw](https://github.com/openclaw/openclaw). It runs continuously, receives real-time data from an Oracle Autonomous Database, and surfaces its full AI reasoning — tool calls, decisions, and responses — live in a Discord channel.

This guide walks through everything needed to get the stack running: installing OpenClaw, connecting Discord, setting up Oracle APEX as a data source, and verifying that data flows end-to-end. 

**Key capabilities:**

- **Transparent reasoning** — watch the agent think in real time inside Discord
- **Real-time DB integration** — Oracle APEX pushes alerts directly via Discord webhook, with no complex polling required
- **Unified channel** — Discord serves as both input and output
- **Self-hosted** — runs on your own VM with no vendor lock-in beyond an LLM API key

### ⚠️ **Security Limitation: 

The Discord webhook approach is intentionally simple — it's a fast way to get Oracle talking to OpenClaw, not a production-ready pattern. Webhook URLs carry their own authorization, meaning anyone who obtains the URL can post messages to your channel and potentially trigger the agent. Treat the URL like a secret, and consider a more hardened integration path before deploying this in a sensitive environment.

---

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

Each component has a defined role:

- **Oracle ADB** — stores data and triggers alerts via PL/SQL
- **APEX Web Service** — exposes HTTP endpoints that call the Discord webhook
- **Discord webhook** — delivers Oracle messages into a Discord channel, @mentioning the bot
- **OpenClaw agent** — reads the mention, reasons with an LLM, and replies in Discord

---

## Installation

### Prerequisites

Before starting, ensure the following are available on your target machine or VM:

- An isolated machine or VM (VirtualBox Ubuntu, AWS EC2, Hetzner VPS, or similar)
- Node.js 22+ — verify with `node -v`; LTS build recommended
- npm — included with Node.js
- An LLM API key (OpenAI, Anthropic Claude, Grok, Gemini, or a local Ollama instance)

### 1. Install Node.js

If Node.js is not yet installed, the recommended approach on Ubuntu is via the NodeSource repository:

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v   # should output v22.x.x or higher
```

### 2. Clone the Repository

```bash
git clone https://github.com/brantdrayer/robotron.git
cd robotron
```

### 3. Install OpenClaw

```bash
npm install -g openclaw@latest
```

Verify the installation:

```bash
openclaw --version
```

### 4. Run the Onboarding Wizard

```bash
openclaw onboard --install-daemon
```

The `--install-daemon` flag registers OpenClaw as a background service so it restarts automatically on reboot. Follow the prompts to complete initial configuration.

### 5. Hatch the Agent

"Hatching" gives the agent its identity — name, personality, and operating context. This step must be completed before the agent will respond meaningfully.

After onboarding completes, open the TUI:

```bash
openclaw tui
```

Then:

1. Select **Hatch in TUI (recommended)**
2. Answer the prompts: agent name, your name, personality, and role description
3. Once hatched, test the agent by sending it a message in the terminal

> The agent's role description directly shapes how it reasons and responds. A clear, specific description pays off during real monitoring.

---

## Integrations

### Discord

#### Create a Discord Bot

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application, then navigate to the **Bot** section and add a bot
3. Copy the bot token — store it securely and never commit it to version control
4. Under **OAuth2 > URL Generator**, select the `bot` scope and grant **Read Messages** and **Send Messages** permissions
5. Use the generated invite link to add the bot to a private Discord server

#### Connect Discord to OpenClaw

Run the configuration tool and select Discord when prompted for a channel type:

```bash
openclaw configure
```

Paste your bot token when asked. Then approve the pairing:

```bash
# List pending pairing requests
openclaw devices list

# Approve the Discord channel
openclaw pairing approve discord <Pairing Code>
```

> Ensure `allowBots` is set to `true` in your `openclaw.json` config — otherwise the agent will ignore webhook-delivered messages.

#### Quick Test

@mention the bot in your Discord server and ask it a simple question. It should respond like a standard LLM chat. If it doesn't respond, check that the bot token is correct and the pairing was approved.

---

### Discord Webhook

A Discord webhook provides a public HTTPS endpoint that Oracle APEX can POST to, delivering messages directly into a Discord channel. The agent picks up those messages when the webhook content @mentions the bot.

⚠️ **Security Note:** The Discord webhook approach is intentionally simple — it's a fast way to get Oracle talking to OpenClaw, not a production-ready pattern. Webhook URLs carry their own authorization, meaning anyone who obtains the URL can post messages to your channel and potentially trigger the agent. Treat the URL like a secret, and consider a more hardened integration path before deploying this in a sensitive environment.

#### Create the Webhook

1. In Discord, go to **Server Settings > Integrations > Webhooks**
2. Click **New Webhook**, configure its name and target channel, then copy the webhook URL

#### Test the Webhook

From any machine with `curl`, send a test POST. Include an @mention of the bot's **user ID** (not its name) in the `content` field — this is what triggers a bot response:

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "username": "Oracle Alert",
    "content": "<@YOUR_BOT_USER_ID> Test message from webhook"
  }' \
  https://discord.com/api/webhooks/YOUR_WEBHOOK_URL
```

A successful call returns HTTP 204 No Content. The bot should reply in the channel within a few seconds.

---

### Oracle Autonomous Database

Oracle Autonomous Database (ADB) is the data source for this setup. APEX-exposed web services fire PL/SQL that calls the Discord webhook, pushing alerts into the channel.

Full documentation for provisioning an ADB instance is available in the [Oracle ADB Serverless docs](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/index.html).

#### Configure the Wallet (mTLS)

Oracle ADB uses mutual TLS. You'll need to download the wallet zip from the Oracle Console for SQL Developer authentication.

1. In the Oracle Cloud Console, navigate to your ADB instance
2. Click **Database Connection > Download Wallet**
3. Set a wallet password and save the zip — you'll need this file in SQL Developer

---

### SQL Developer

Oracle SQL Developer provides a GUI for connecting to and querying ADB — useful for testing PL/SQL, running manual checks, and triggering webhook calls during development. Download it from the [Oracle downloads page](https://www.oracle.com/tools/downloads/sqldeveloper-downloads.html).

#### Connect to Autonomous Database

1. Open SQL Developer and create a new connection
2. Set **Connection Type** to **Cloud Wallet**
3. Browse to the wallet `.zip` file downloaded from the Oracle Console
4. Select the appropriate service level (e.g., `<dbname>_low` for most workloads)
5. Enter your ADB credentials, click **Test**, then **Connect**

> Enable DBMS Output (**View > DBMS Output**, then click the green **+** to attach your connection) to see `PUT_LINE` output when running PL/SQL test blocks.

#### Send a Message to Discord from PL/SQL

The following PL/SQL block uses `APEX_WEB_SERVICE.MAKE_REST_REQUEST` to POST a JSON payload to the Discord webhook. Replace the placeholder URL and bot user ID before running:

```plsql
DECLARE
  l_url      VARCHAR2(4000) := 'DISCORD_WEBHOOK_URL';
  l_payload  CLOB           := '{
    "username": "DB Alert Bot",
    "content": "<@BOT_USER_ID> Apex Test Message"
  }';
  l_response CLOB;
BEGIN
  apex_web_service.g_request_headers.delete();
  apex_web_service.g_request_headers(1).name  := 'Content-Type';
  apex_web_service.g_request_headers(1).value := 'application/json';

  l_response := APEX_WEB_SERVICE.MAKE_REST_REQUEST(
    p_url         => l_url,
    p_http_method => 'POST',
    p_body        => l_payload
  );

  IF l_response IS NULL OR LENGTH(l_response) = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Success: HTTP 204 (No Content) - message sent!');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Unexpected response: ' || DBMS_LOB.SUBSTR(l_response, 1000, 1));
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    RAISE;
END;
/
```

> A successful call returns HTTP 204 No Content, so `l_response` will be null or empty. If you receive `ORA-24247`, check network ACL configuration for your ADB instance.

---

### Tailscale (Optional)

Tailscale is not required for this webhook-based setup — Oracle APEX posts directly to the Discord webhook URL over public HTTPS, so no tunnel between APEX and the OpenClaw VM is needed.

Tailscale is useful if you want to **access the OpenClaw gateway from another device** — for example, to reach a local OpenClaw dashboard or API endpoint from your laptop without opening a public port.

#### Install Tailscale on the VM

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Authenticate using the URL shown in the terminal. The VM will be assigned a stable Tailscale IP (e.g., `100.x.x.x`) that persists across reboots.

#### Expose the OpenClaw Gateway via HTTPS

Use `tailscale serve` to give the local OpenClaw gateway a clean TLS-terminated URL, accessible from any device on your tailnet:

```bash
# Expose OpenClaw's default gateway port to your Tailscale network
sudo tailscale serve https://127.0.0.1:18789
```

#### Verify Connectivity

```bash
# From any other Tailscale device on the same tailnet
ping <vm-tailscale-ip>
curl https://<vm-tailscale-hostname>
```

> Devices must share a tailnet, or have appropriate ACLs configured in the [Tailscale admin console](https://login.tailscale.com/admin/acls), to communicate.

---

## Verify Setup Works

### 1. Run the Initial Tests

Work through these checks in order — each one confirms a layer of the stack before testing the next.

**Confirm OpenClaw is running:**
```bash
openclaw status
# If using the daemon:
systemctl status openclaw
```

**Test the Discord bot directly:**

@mention the bot in Discord with a plain question ("What is 2 + 2?"). It should respond within a few seconds. This confirms the bot token, pairing, and LLM API key are all working.

**Test the webhook independently:**

Send a test POST using `curl` (see the webhook section above). Confirm the message appears in Discord. This verifies the webhook endpoint is live and the channel is correct, separately from the database.

### 2. Check Integration Points

**Oracle to Discord path:**

Open SQL Developer, connect to ADB, and run the PL/SQL webhook block from the integrations section. Expected output in the DBMS Output pane:

```
Success: HTTP 204 (No Content) - message sent!
```

Watch the Discord channel at the same time — the message should appear within a second or two.

### 3. Confirm End-to-End Data Flow

This is the full integration test. It confirms that Oracle can trigger the agent and receive an intelligent response.

1. Run the PL/SQL block with content that @mentions the bot and includes a question or alert
2. The webhook message appears in Discord
3. The bot picks up the @mention and sends it to the LLM
4. The agent's reasoning and final response appear in Discord

If all four steps complete successfully, the full stack is operational.

---

## Troubleshooting

### Bot Does Not Respond in Discord

- Verify `allowBots: true` is set in `openclaw.json`
- Confirm the Discord pairing was approved: `openclaw devices list`
- Check that the LLM API key is valid and has available quota
- Confirm the webhook `content` field @mentions the bot's **user ID**, not its display name — IDs look like `<@123456789012345678>`

### Webhook Returns an Error

- Double-check the webhook URL — it should include both the webhook ID and token
- Confirm `Content-Type: application/json` is set in the request headers
- Test with `curl` before troubleshooting from PL/SQL to isolate where the failure is

### PL/SQL Raises ORA-24247

This error indicates a network ACL restriction on outbound calls. In Oracle ADB Serverless, outbound HTTPS to public endpoints is generally permitted by default, but may be restricted depending on your configuration. Check whether custom ACLs are blocking outbound HTTPS and refer to the Oracle `DBMS_NETWORK_ACL_ADMIN` documentation if adjustments are needed.

### SQL Developer Cannot Connect

- Ensure the wallet zip is the correct one for your specific ADB instance
- Confirm the service name matches a valid entry in the wallet's `tnsnames.ora`
- Verify the username and password against the Oracle Console credentials
- Use the **Test** button before **Connect** to isolate authentication vs. network issues

### OpenClaw Agent Starts But Doesn't Stay Running

- Check daemon logs: `journalctl -u openclaw -f`
- Verify the config file path is correct and the file is valid JSON
- Confirm the LLM API key in `openclaw.json` is not expired or over quota

---

## Security Notes

OpenClaw agents have significant access — tools, channels, and optionally code execution. Treat the agent like any privileged service account.

- Use least-privilege API keys — scope LLM keys and Discord tokens to only what is needed
- Run in an isolated environment — a dedicated VM or container is strongly preferred
- Review all OpenClaw skills before enabling them
- Never expose the agent publicly without strong authentication
- Rotate secrets regularly and never commit them to version control

See the [official OpenClaw security documentation](https://github.com/openclaw/openclaw) for full guidance.