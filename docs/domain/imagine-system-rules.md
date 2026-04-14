---
title: "Imagine System Rules"
type: domain
tags: [imagine, image-generation, mcp, provider, config, fal]
created: 2026-04-14
updated: 2026-04-14
---

## Purpose

The `imagine` plugin provides provider-agnostic image generation. The skill layer never calls a specific provider directly; it resolves the active provider from `plugins/imagine/imagine-config.json` and dispatches to whichever MCP server that provider declares. Adding a new provider (e.g., Replicate, OpenAI Images) must not require editing any skill.

## Provider Model

A **provider** is an image-generation backend fronted by an MCP server. Providers are first-class entries in `imagine-config.json` under the `providers` map. Exactly one provider is active at a time, identified by the top-level `activeProvider` field.

Every provider entry must declare:

- `mcpToolPrefix` — the namespace of MCP tools exposed by this provider's server (e.g., `mcp__fal_ai__`). The `run-imagine` skill looks for MCP tools starting with this prefix to find the generation endpoint.
- `apiKeyEnvVar` — the environment variable the provider's MCP server reads to authenticate (e.g., `FAL_KEY`).
- `apiKeyUrl` — the URL where a user creates an API key for this provider.
- `defaultModel` — the model ID to use when the user gives no model preference.
- `defaultSize` — the image size to use when the user gives no size preference.
- `sizes` — the list of accepted size values for this provider.
- `models` — a map from model ID to per-model parameters (e.g., `numInferenceSteps`, `guidanceScale`, `bestFor`).
- `modelAliases` — a map from human keywords (e.g., `"fast"`, `"realistic"`) to model IDs, used when parsing user requests.
- `defaults` — per-generation defaults that apply regardless of model (e.g., `numImages`, `enableSafetyChecker`).

## Config Schema

The config file lives at `plugins/imagine/imagine-config.json`. Its top-level shape:

```json
{
  "activeProvider": "<provider-key>",
  "providers": {
    "<provider-key>": { ...provider entry... }
  }
}
```

Only one provider is active at a time. Additional providers may be declared in the `providers` map for future use without affecting behavior until `activeProvider` is switched to them.

## Skill Resolution Flow

Both user-invocable skills follow the same resolution pattern:

1. **`run-imagine`** — Reads `imagine-config.json`, resolves the active provider, looks up its `mcpToolPrefix`, and dispatches to a matching MCP tool. Model selection honors `modelAliases` first, then falls back to `defaultModel`. Size selection honors user intent bounded by the provider's `sizes` list.
2. **`run-imagine-setup`** — Reads `imagine-config.json`, resolves the active provider's `apiKeyEnvVar` and `apiKeyUrl`, and guides the user to export the key in their shell profile. Optionally allows switching `activeProvider` when the user's intent is to change providers rather than configure the current one.

Skills must not hardcode any provider name, env var, or tool prefix — all such values come from the config.

## MCP Server Declaration

Every declared provider must also have its MCP server entry in `plugins/imagine/.mcp.json` so Claude Code registers it at plugin install time. The server key (top-level key under the MCP object) typically matches the provider's prefix segment — for example, the `fal` provider's MCP server key is `fal-ai`, yielding tools named `mcp__fal_ai__*` that the provider's `mcpToolPrefix` targets.

Secrets in `.mcp.json` must use `${ENV_VAR}` interpolation referencing the provider's `apiKeyEnvVar`; they must never be hardcoded.

## Adding a Provider

To add a new provider without changing any skill code:

1. Add a server entry in `plugins/imagine/.mcp.json` using `${ENV_VAR}` for any credentials.
2. Add a `providers.<new-key>` entry in `imagine-config.json` with all required fields listed above.
3. Optionally set `activeProvider` to the new key when ready to cut over.

The two skills adapt automatically because every provider-specific value they need is resolved from the config at runtime.

## Default Provider

The default `activeProvider` is `fal`. This is the first supported provider and the baseline reference implementation. Its MCP server is declared in `plugins/imagine/.mcp.json` and its settings are fully populated in `imagine-config.json`.
