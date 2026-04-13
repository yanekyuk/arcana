---
name: fal-setup
description: "Configure fal.ai API access — prompts for API key and stores it so image generation works in this and future sessions"
model: haiku
effort: low
user-invocable: true
allowed-tools: Bash, Read
---

# fal.ai API Setup

You are configuring fal.ai API access for the image generation skill. Follow every step exactly.

## Step 1: Check for existing configuration

Check whether the API key is already available via environment variable or credentials file:

```bash
if [ -n "$FAL_KEY" ]; then
  echo "FAL_KEY_SET"
elif [ -f "$HOME/.config/fal/credentials" ]; then
  echo "CREDENTIALS_FILE_EXISTS"
else
  echo "NOT_CONFIGURED"
fi
```

- If `FAL_KEY_SET` — tell the user fal.ai is already configured via environment variable, skip to Step 4.
- If `CREDENTIALS_FILE_EXISTS` — tell the user fal.ai is already configured via credentials file, skip to Step 4.
- If `NOT_CONFIGURED` — continue to Step 2.

## Step 2: Prompt for the API key

Tell the user:

> To use fal.ai image generation, you need a fal.ai API key.
> You can create one at https://fal.ai/dashboard/keys
>
> Please paste your fal.ai API key now:

Wait for the user to provide the key. Accept it from their next message.

## Step 3: Store the API key

Save the key to a local credentials file:

```bash
mkdir -p "$HOME/.config/fal"
echo "<KEY>" > "$HOME/.config/fal/credentials"
chmod 600 "$HOME/.config/fal/credentials"
```

Substitute `<KEY>` with the key the user provided.

If the commands fail, report the error and stop.

## Step 4: Verify API access

Test that the key works by making a lightweight API call:

```bash
FAL_KEY="${FAL_KEY:-$(cat "$HOME/.config/fal/credentials")}"
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Key $FAL_KEY" \
  "https://fal.run/fal-ai/flux/schnell" \
  -X POST -d '{"prompt":"test","image_size":"square","num_images":1}' 2>/dev/null
```

- If the HTTP status is `200` — API key is valid, proceed.
- If the HTTP status is `401` or `403` — tell the user the API key is invalid and ask them to try again.
- If the request fails entirely — warn the user but do not block (network issues are transient).

## Step 5: Confirm and show next steps

Tell the user:

> fal.ai API access configured.
>
> Your API key is stored at `~/.config/fal/credentials`.
> You can also set the `FAL_KEY` environment variable instead (takes precedence over the file).
>
> You can now generate images with:
>
>   `/fal-image <your prompt>`
>
> Example:
>
>   `/fal-image a photorealistic fox sitting in a neon-lit alley, cinematic`
