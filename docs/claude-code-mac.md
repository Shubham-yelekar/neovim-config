# Claude Code — Mac setup

Personal Mac notes. The work Windows box runs Claude Code on the company plan via
OAuth; this machine is on **API billing with my own key**, so the auth and cost
sections differ from work. Don't copy the auth bits across.

- [Install](#install)
- [Subscription or API?](#subscription-or-api)
- [Limits](#limits)
- [Commands worth knowing](#commands-worth-knowing)
- [Customization](#customization)
- [Notes](#notes)

## Install

Needs macOS 13.0+ and 4 GB RAM. `ripgrep` ships with Claude Code, so nothing to
install for search.

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

This puts a launcher at `~/.local/bin/claude` symlinked into
`~/.local/share/claude/versions/`, and **auto-updates in the background**.

Homebrew is the alternative and fits the rest of the brew setup in the root
README, but it does *not* auto-update and the default cask runs about a week
behind:

```sh
brew install --cask claude-code          # stable channel, ~1 week behind
brew install --cask claude-code@latest   # ships immediately
brew upgrade claude-code                 # manual; brew never does this for you
```

Native installer wins here. Auto-update is worth more than brew consistency on a
machine I'm learning on, and a newly released model sometimes needs a newer
Claude Code than the stable channel serves.

### PATH

The installer does not reliably add `~/.local/bin` to PATH — it silently didn't
on Windows. Add it to the Claude Code section of [`../mac/zsh/.zshrc`](../mac/zsh/.zshrc):

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Because `.zshrc` is in this repo, that's committed once and every future Mac is
covered. The Windows registry PATH is not portable like that.

### Verify

```sh
exec zsh
claude --version      # prints e.g. 2.1.292 (Claude Code)
claude doctor         # read-only diagnostics: install health, settings errors
```

`claude doctor` is the first thing to run when anything is off. It validates
settings files and reports the last auto-update attempt without starting a
session.

### Auth — API key via Keychain

The key never goes in a file in this repo. **This repo is public.** Store it in
the login Keychain:

```sh
security add-generic-password -a "$USER" -s anthropic-api-key -w
```

The `-w` with no value prompts, so the key stays out of `.zsh_history`.

Then point Claude Code at it in `~/.claude/settings.json` — in `$HOME`, **not**
in this repo:

```json
{
  "apiKeyHelper": "security find-generic-password -a $USER -s anthropic-api-key -w"
}
```

`apiKeyHelper` is the mechanism that matters, because Claude Code reads it no
matter how the process was launched. The `claude()` wrapper function in `.zshrc`
only covers interactive shells — **Neovim spawns the binary directly, so the
wrapper never runs and nvim integration gets no key.** Keep the wrapper if you
like, but `apiKeyHelper` is what makes `<leader>Ac` work.

## Subscription or API?

Claude Code needs a **Pro, Max, Team, Enterprise, or Console (API) account.**
The free claude.ai plan does not include Claude Code at all.

Current Opus pricing per million tokens:

| Model | Input | Output | Cache read |
|---|---|---|---|
| `claude-opus-5-5` | $4.00 | $20.00 | $0.20 |
| `claude-opus-5` | $5.00 | $25.00 | $0.25 |

Always pin **Opus 5.5**, never Opus 5 — it's newer, same 1M context, and 25%
cheaper.

### The cache TTL is the deciding factor

Cache reads are 20× cheaper than fresh input ($0.20 vs $4.00), and Claude Code
resends the whole conversation on every turn, so cache hit rate *is* the bill.
The catch:

| Billing | Prompt cache lifetime |
|---|---|
| Pro / Max subscription | **1 hour** |
| API key | **5 minutes** (default) |
| Subscription, past limit on usage credits | 5 minutes |

That gap decides the question. Code review, learning, and planning means long
pauses — reading a diff, thinking about a design. On API billing, any pause over
five minutes blows the cache, and the next message reprocesses the entire context
at full input price instead of the cached rate. A session with four such pauses
pays for its full context five times.

So:

- **Bursty, uninterrupted sessions** → API is cheaper. Pay only for what you use,
  no monthly commitment.
- **Long sessions with reading gaps** (the realistic pattern for review and
  learning) → the subscription's 1-hour cache is worth more than it looks, and
  flat pricing removes the variance.

### How to decide without guessing

Start on API, then measure for two weeks:

```
/usage
```

Read the `Prompt cache (main)` line — it reports the share of input tokens served
from cache, the miss count, and whether the cache is warm. **If cache hit rate is
low and misses are frequent, that's the 5-minute TTL, and a subscription will be
cheaper.** Over roughly $50/month, switch to Max.

For reference, Anthropic reports ~$13/developer/active-day across enterprise
deployments. That's all-day agentic coding, not evening review work — treat it as
a ceiling, not an estimate.

## Limits

Different ceilings, different fixes. The error message tells you which one.

| Message | What it is | Does `/model` help? |
|---|---|---|
| "hit your session limit" | Rolling 5-hour window, subscription | **No** — shared across all models |
| "hit your weekly limit" | Weekly window, subscription | **No** — shared across all models |
| "hit your Opus limit" | Per-model-family cap | **Yes** — switch to Sonnet |
| "hit your spend limit" | Usage credits hit a cap you set | No; raise the limit |
| Context / auto-compact warning | **Not a limit.** Conversation near the compact threshold | No; `/clear` or `/compact` |

On API billing there are no usage windows at all — you're billed per token, with
org-level TPM/RPM rate limits and optional workspace spend caps instead.

When you do hit a subscription limit:

- `/usage-credits` to buy past it (opens claude.ai settings)
- `/rate-limit-options` to wait for the reset and auto-continue the interrupted
  task. Claude Code sometimes offers this on its own.

Background token use — conversation summarization for `--resume`, status checks —
runs under about $0.04 per session even when idle.

## Commands worth knowing

Type `/` to see everything. These are the ones that actually come up.

### Cost and context — the ones that matter on API billing

| Command | Does |
|---|---|
| `/usage` | Token usage, cost estimate, and the prompt-cache line. `d`/`w` toggles 24h/7d |
| `/context` | What's eating the context window right now |
| `/clear` | Fresh session. **Costs nothing and resets the cost counter** |
| `/compact` | Summarize history to free space. Takes an argument: `/compact focus on the API surface` |
| `/insights` | HTML report on how you work — friction points, misunderstood requests. Writes `~/.claude/usage-data/report.html` |

`/clear` between unrelated tasks is the single highest-leverage habit. Stale
context is resent on *every* subsequent message.

### Model and effort

| Command | Does |
|---|---|
| `/model` | Switch model mid-session |
| `/effort` | Thinking depth: `low` → `max`. The main quality/cost dial |
| `/config` | Defaults, including auto-update channel |

Effort is the lever to reach for before downgrading the model. Low effort on
Opus 5.5 often beats high effort on an older model. Planning and learning
conversations do fine at `low`/`medium`; save `high` for review passes where
correctness matters.

### Session management

| Command | Does |
|---|---|
| `/rename` | Name the session **before** `/clear` so you can find it again |
| `/resume` | Return to an earlier session |
| `/rewind` | Restore conversation *and* code to a checkpoint. Also double-tap Escape |
| `/status` | Active auth, settings sources, versions |
| `/doctor` | Same diagnostics as `claude doctor`, from inside a session |

### Keys

- **Shift+Tab** — cycle to plan mode. Claude explores and proposes before
  editing. Worth it for anything non-trivial; prevents paying twice when the
  first direction is wrong.
- **Escape** — stop immediately. Course-correct early rather than letting a wrong
  approach run.
- **Escape, Escape** — rewind to a checkpoint.

## Customization

### CLAUDE.md

Per-project instructions, loaded at session start. **Keep it under 200 lines** —
every line is in context on every message, even for unrelated work. Compaction
behavior can be steered from it:

```markdown
# Compact instructions

When compacting, focus on test output and code changes.
```

### Skills over CLAUDE.md

Detailed workflow instructions belong in skills, not CLAUDE.md. Skills load
**on demand** when invoked; CLAUDE.md is always resident. Moving a long PR-review
checklist into a skill cuts base context on every session.

### settings.json

`~/.claude/settings.json` for user-wide, `.claude/settings.json` for
project-shared, `.claude/settings.local.json` for machine-local.

**`settings.local.json` is gitignored in this repo** — see the rule in
[`../.gitignore`](../.gitignore). It holds granted permissions and credential
helpers, which differ per machine and must never be committed here.

```json
{
  "apiKeyHelper": "security find-generic-password -a $USER -s anthropic-api-key -w",
  "autoUpdatesChannel": "latest"
}
```

### Hooks

Shell commands on tool events. The useful pattern is preprocessing to shrink
context — a `PreToolUse` hook that greps a 10,000-line log for `ERROR` and
returns only matches turns tens of thousands of tokens into hundreds. Verify with
`/hooks`.

### Subagents

Delegate verbose work — running tests, fetching docs, processing logs — so the
output stays in the subagent's context and only a summary comes back. Set
`model: haiku` in the subagent config for simple tasks; subagents otherwise
inherit the session model, so Opus subagents get expensive fast.

### Neovim

See [`../mac/nvim/lua/shubu/plugins/claudecode.lua`](../mac/nvim/lua/shubu/plugins/claudecode.lua).
Keymaps are under `<leader>A`, **not** the upstream default `<leader>a` — that's
Harpoon add here. Requires `snacks.nvim`, which lazy pulls in automatically.

## Notes

- **`apiKeyHelper`, not the shell wrapper, is what nvim needs.** A zsh function
  only exists in interactive shells. Neovim spawns `claude` directly.
- **Never put the API key in this repo.** It's public. Keychain + `apiKeyHelper`.
- **Opus 5.5 can't disable thinking.** Neither can Sonnet 5.5 or the Fable
  models. Lower `/effort` instead; `MAX_THINKING_TOKENS` is ignored on
  adaptive-reasoning models.
- **`/clear` is free, `/compact` is not.** Compaction reads the whole
  conversation it summarizes, so it's itself a large request. When continuity
  doesn't matter, clear.
- **Long idle sessions still cost money on a subscription.** Scheduled tasks and
  cross-session messages fire on their own and send full context each time.
- **Prefer CLI tools over MCP servers** for things like `gh`. No per-tool listing
  overhead in context.
- **Session cost in `/usage` is a local estimate** computed from token counts at
  list price, not an invoice. Authoritative billing is the Claude Console.
