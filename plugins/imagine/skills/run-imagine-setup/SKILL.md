---
name: fal-setup
description: "Configure the fal.ai MCP server — checks for the FAL_KEY environment variable and guides the user to set it in their shell profile so the plugin-declared MCP server can authenticate"
model: haiku
effort: low
user-invocable: true
allowed-tools: Bash, Read
---

# fal.ai MCP Setup

You are configuring access to the fal.ai MCP server for Claude Code. The MCP server itself is declared at the plugin level in `plugins/fal/.mcp.json` — your job is to ensure the `FAL_KEY` environment variable is set so the plugin can authenticate.

Follow every step exactly.

## Step 1: Check whether FAL_KEY is already set

Run:

```bash
[ -n "$FAL_KEY" ] && echo "FAL_KEY is set" || echo "FAL_KEY is NOT set"
```

If the output says `FAL_KEY is set`, tell the user it is already configured and skip to Step 4.

## Step 2: Prompt for the API key

Tell the user:

> To authenticate with the fal.ai MCP server, you need a fal.ai API key.
> You can create one at https://fal.ai/dashboard/keys
>
> Please paste your fal.ai API key now (it will not be stored in any file by this skill — you will add it to your shell profile yourself in the next step):

Wait for the user to provide the key. Accept it from their next message.

## Step 3: Guide the user to persist FAL_KEY

Detect the user's shell by running:

```bash
echo "$SHELL"
```

Based on the result, tell the user the appropriate shell profile file:

- `/bin/zsh` or `/usr/bin/zsh` → `~/.zshrc`
- `/bin/bash` or `/usr/bin/bash` → `~/.bashrc` (or `~/.bash_profile` on macOS)
- `/bin/fish` or `/usr/bin/fish` → `~/.config/fish/config.fish`
- Anything else → advise the user to add it to their shell's startup file

Then instruct them:

> Add the following line to `<detected-profile-file>`:
>
> **For bash/zsh:**
> ```bash
> export FAL_KEY="<the key you pasted>"
> ```
>
> **For fish:**
> ```fish
> set -gx FAL_KEY "<the key you pasted>"
> ```
>
> After saving, reload your shell or run:
>
> ```bash
> source <detected-profile-file>
> ```
>
> Then restart Claude Code so it picks up the new environment variable.

Do NOT write to the user's shell profile yourself — they must do it to keep the key out of any conversation log or repo history.

## Step 4: Confirm and show next steps

Tell the user:

> The fal.ai MCP server is declared by the fal plugin itself (see `plugins/fal/.mcp.json`). Once `FAL_KEY` is exported in your shell environment and Claude Code has been restarted, the MCP tools will authenticate automatically.
>
> You can invoke image generation with:
>
>   `/fal-image <your prompt>`
>
> Example:
>
>   `/fal-image a photorealistic fox sitting in a neon-lit alley, cinematic`
>
> If tools are not yet visible after restart, verify `FAL_KEY` is set in the new session with `echo $FAL_KEY`.
