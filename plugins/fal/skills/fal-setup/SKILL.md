---
name: fal-setup
description: "Configure the fal.ai MCP server — prompts for API key and registers the HTTP MCP transport so image generation tools become available in this session"
model: haiku
effort: low
user-invocable: true
allowed-tools: Bash, Read
---

# fal.ai MCP Setup

You are configuring the fal.ai MCP server for Claude Code. Follow every step exactly.

## Step 1: Check for existing configuration

Run the following and check whether `fal-ai` already appears in the output:

```bash
claude mcp list
```

If `fal-ai` is already listed, tell the user it is already configured and skip to Step 4.

## Step 2: Prompt for the API key

Tell the user:

> To connect the fal.ai MCP server, you need a fal.ai API key.
> You can create one at https://fal.ai/dashboard/keys
>
> Please paste your fal.ai API key now (it will not be stored in any file):

Wait for the user to provide the key. Accept it from their next message.

## Step 3: Register the MCP server

Run the following command, substituting `<KEY>` with the key the user provided:

```bash
claude mcp add --transport http fal-ai \
  https://mcp.fal.ai/mcp \
  --header "Authorization: Bearer <KEY>"
```

If the command exits with a non-zero status, report the error and stop.

## Step 4: Confirm and show next steps

Tell the user:

> fal.ai MCP server registered as `fal-ai`.
>
> The image generation tools are now available. You can invoke them with:
>
>   `/fal-image <your prompt>`
>
> Example:
>
>   `/fal-image a photorealistic fox sitting in a neon-lit alley, cinematic`
>
> The MCP tools will be active in new Claude Code sessions automatically.
> If tools are not yet visible, restart your current session.
