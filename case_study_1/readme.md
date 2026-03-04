# Case Study 1: Oracle ADB to OpenClaw via Discord 

## Overview

This case study consists of a self-hosted monitoring agent built on [OpenClaw](https://github.com/openclaw/openclaw) which receives data from an Oracle Autonomous Database, and shows it's response in a Discord channel.

This readme is an overview of the infrastructure, problems encountered, and solutions found.

### Security Notes

OpenClaw agents have a significant access. Follow these practices:

- Use least-privilege LLM API keys and Discord bot tokens
- Run in an isolated environment
- Review all skills before enabling
- Never expose the agent publicly without strong authentication
- Rotate secrets regularly and never commit to version control

**Note about Discord Webhooks**:
The Discord webhook approach is a simple fast way to get Oracle talking to OpenClaw, not a useable pattern. Webhook URLs carry their own authorization, meaning anyone who obtains the URL can post messages to your channel and trigger the agent. Treat the URL like a secret, and use a more secure path to deploy in any sensitive environment.

See the [official OpenClaw security documentation.](https://github.com/openclaw/openclaw)

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

Each component's role:

- **Oracle ADB** — stores data and triggers alerts via PL/SQL
- **APEX Web Service** — exposes HTTP endpoints that call the Discord webhook
- **Discord webhook** — delivers Oracle messages into a Discord channel, @mentioning the bot
- **OpenClaw agent** — reads the message, hits an LLM, and replies in Discord

---

### Problems Encountered: Solution

Webhook Not talking to Agent: @mention the bot, config allowBots: true
Bot not responding in discord: pair with openclaw devices list, openclaw pairing approve discord <xxx>, etc.
Fought with openclaw configure to make changes: edit directly in the openclaw.json file.









> Ensure `allowBots` is set to `true` in your `openclaw.json` config — otherwise the agent will ignore webhook-delivered messages.

#### Quick Test

@mention the bot in your Discord server and ask it a simple question. It should respond like a standard LLM chat. If it doesn't respond, check that the bot token is correct and the pairing was approved.

---

### Discord Webhook

A Discord webhook provides a public HTTPS endpoint that Oracle APEX can POST to, delivering messages directly into a Discord channel. The agent picks up those messages when the webhook content @mentions the bot.

⚠️ **Security Note:** The Discord webhook approach is intentionally simple — it's a fast way to get Oracle talking to OpenClaw, not a production-ready pattern. Webhook URLs carry their own authorization, meaning anyone who obtains the URL can post messages to your channel and potentially trigger the agent. Treat the URL like a secret, and consider a more hardened integration path before deploying this in a sensitive environment.

Testing Webhook
```
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

Configure the Wallet (mTLS)


---

### SQL Developer

Oracle SQL Developer provides a GUI for connecting to and querying ADB — useful for testing PL/SQL, running manual checks, and triggering webhook calls during development. Download it from the [Oracle downloads page](https://www.oracle.com/tools/downloads/sqldeveloper-downloads.html).

Connect to Autonomous Database

> Enable DBMS Output (**View > DBMS Output**, then click the green **+** to attach your connection) to see `PUT_LINE` output when running PL/SQL test blocks.

Send a Message to Discord from PL/SQL




Tailscale (Optional)

Tailscale is not required for this webhook-based setup — Oracle APEX posts directly to the Discord webhook URL over public HTTPS, so no tunnel between APEX and the OpenClaw VM is needed.

Tailscale is useful if you want to **access the OpenClaw gateway from another device** — for example, to reach a local OpenClaw dashboard or API endpoint from your laptop without opening a public port.

Install Tailscale on the VM






> Devices must share a tailnet, or have appropriate ACLs configured in the [Tailscale admin console](https://login.tailscale.com/admin/acls), to communicate.


Verify Setup Works

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
