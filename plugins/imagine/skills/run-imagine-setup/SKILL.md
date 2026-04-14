---
name: run-imagine-setup
description: "Configure the active image provider's MCP server — resolves the provider from imagine-config.json, checks for its API key environment variable, and guides the user to set it in their shell profile so the plugin-declared MCP server can authenticate"
model: haiku
effort: low
user-invocable: true
allowed-tools: Bash, Read, Edit, Write
---

# Image Provider MCP Setup

You are configuring access to the image provider's MCP server for Claude Code. The MCP server itself is declared at the plugin level in `plugins/imagine/.mcp.json`; the active provider and its API key env var are declared in `plugins/imagine/imagine-config.json`. Your job is to ensure the correct env var is set so the plugin can authenticate.

Follow every step exactly.

## Step 1: Resolve the active provider

Read `plugins/imagine/imagine-config.json` and extract:

- `activeProvider` — the provider key
- `providers[activeProvider].apiKeyEnvVar` — the env var name (e.g., `FAL_KEY`)
- `providers[activeProvider].apiKeyUrl` — where the user creates an API key

If the file is missing or the active provider has no `apiKeyEnvVar`, tell the user the config is incomplete and stop.

## Step 2: Switch providers (optional)

If the user's intent is to switch the active provider rather than configure the current one, ask which provider they want to activate. Valid options are the keys under `providers` in `imagine-config.json`. Update `activeProvider` in that file with the chosen value, then continue with the newly active provider's settings.

If the user did not ask to switch, skip this step.

## Step 3: Check whether the API key is already set

Run, substituting the resolved env var name:

```bash
[ -n "$<API_KEY_ENV_VAR>" ] && echo "<API_KEY_ENV_VAR> is set" || echo "<API_KEY_ENV_VAR> is NOT set"
```

If the output says the variable is set, tell the user it is already configured and skip to Step 6.

## Step 4: Prompt for the API key

Tell the user, substituting the resolved `apiKeyUrl` and `apiKeyEnvVar`:

> To authenticate with the `<activeProvider>` MCP server, you need an API key.
> You can create one at `<apiKeyUrl>`
>
> Please paste your API key now (it will not be stored in any file by this skill — you will add it to your shell profile yourself in the next step):

Wait for the user to provide the key. Accept it from their next message.

## Step 5: Guide the user to persist the API key

Detect the user's shell by running:

```bash
echo "$SHELL"
```

Based on the result, tell the user the appropriate shell profile file:

- `/bin/zsh` or `/usr/bin/zsh` -> `~/.zshrc`
- `/bin/bash` or `/usr/bin/bash` -> `~/.bashrc` (or `~/.bash_profile` on macOS)
- `/bin/fish` or `/usr/bin/fish` -> `~/.config/fish/config.fish`
- Anything else -> advise the user to add it to their shell's startup file

Then instruct them, substituting the resolved env var name:

> Add the following line to `<detected-profile-file>`:
>
> **For bash/zsh:**
> ```bash
> export <API_KEY_ENV_VAR>="<the key you pasted>"
> ```
>
> **For fish:**
> ```fish
> set -gx <API_KEY_ENV_VAR> "<the key you pasted>"
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

## Step 6: Confirm and show next steps

Tell the user, substituting the active provider name:

> The `<activeProvider>` MCP server is declared by the imagine plugin itself (see `plugins/imagine/.mcp.json`). Once `<API_KEY_ENV_VAR>` is exported in your shell environment and Claude Code has been restarted, the MCP tools will authenticate automatically.
>
> You can invoke image generation with:
>
>   `/run-imagine <your prompt>`
>
> Example:
>
>   `/run-imagine a photorealistic fox sitting in a neon-lit alley, cinematic`
>
> If tools are not yet visible after restart, verify `<API_KEY_ENV_VAR>` is set in the new session with `echo $<API_KEY_ENV_VAR>`.
