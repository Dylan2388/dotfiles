# herdr config

Config for [herdr](https://herdr.dev). `config.toml` is the only hand-written
file here; the rest is plugin config or state herdr regenerates.

Plugins are not vendored: herdr installs them from GitHub into
`plugins/github/`, building or downloading their binaries as it goes. It shells
out to `git` for that (no `gh`, no GitHub API). To rebuild this setup elsewhere,
install them at HEAD (nothing is pinned):

```bash
herdr plugin install plannotator/herdr-annotate --yes
herdr plugin install ChmaraX/herdr-nvim --yes
herdr plugin install qu8n/herdr-automatic-rename --yes
herdr plugin install Crokily/herdr-lazygit --yes
herdr plugin install thanhdat77/herdr-navigator --yes
herdr plugin install jhochenbaum/herdr-hunk-diff --yes
herdr plugin install speardragon/herdr-plugin-manager --yes
herdr plugin install paulbkim-dev/vim-herdr-navigation --yes
herdr server reload-config
```

Then check `herdr plugin list` (eight, all `enabled`) and `herdr config check`
(`config: ok`).

## Plugins

Follow each repo's README for setup beyond the install command. `config.toml`
binds keys by plugin **id**, which often differs from the repo name.

The links below are `https://github.com/<owner>/<repo>` from the installed
registry — the same URL the plugin manager opens. To get them from it directly:
`prefix+p`, then `o` on a row opens that plugin's repo in the browser.

| Repo (install instructions) | id | Needs |
| --- | --- | --- |
| [plannotator/herdr-annotate](https://github.com/plannotator/herdr-annotate) | `annotate` | — |
| [ChmaraX/herdr-nvim](https://github.com/ChmaraX/herdr-nvim) | `chmarax.herdr-nvim` | its nvim half |
| [qu8n/herdr-automatic-rename](https://github.com/qu8n/herdr-automatic-rename) | `herdr-automatic-rename` | `~/.bashrc` shell hook |
| [Crokily/herdr-lazygit](https://github.com/Crokily/herdr-lazygit) | `herdr-lazygit` | `lazygit` |
| [thanhdat77/herdr-navigator](https://github.com/thanhdat77/herdr-navigator) | `herdr-navigator` | Rust toolchain; `zoxide` optional |
| [jhochenbaum/herdr-hunk-diff](https://github.com/jhochenbaum/herdr-hunk-diff) | `jhochenbaum.hunkdiff` | `git` |
| [speardragon/herdr-plugin-manager](https://github.com/speardragon/herdr-plugin-manager) | `ray.plugin-manager` | — |
| [paulbkim-dev/vim-herdr-navigation](https://github.com/paulbkim-dev/vim-herdr-navigation) | `vim-herdr-navigation` | `jq`; its editor half |

## Keys

Everything bound in `config.toml`, on top of herdr's own defaults.
`herdr-automatic-rename` has no keys — it renames on herdr events.

| Key | Action |
| --- | --- |
| `ctrl+1`…`ctrl+9` | focus agent 1-9 |
| `prefix+[` / `prefix+]` | previous / next agent |
| `ctrl+h` `ctrl+j` `ctrl+k` `ctrl+l` | move between Vim splits and herdr panes |
| `prefix+t` | navigator: jump to anything |
| `prefix+shift+t` | navigator: side pane |
| `prefix+shift+b` | navigator: jump to previous workspace |
| `prefix+p` | plugin manager |
| `prefix+g` / `prefix+shift+g` | lazygit in a split / in its own tab |
| `prefix+e` / `prefix+shift+e` | nvim sidebar / open file from agent output |
| `prefix+a` | annotate selection |
| `prefix+shift+a` | copy annotations as context |
| `prefix+ctrl+a` | copy annotations as context and archive |
| `prefix+m` | manage annotations |
| `prefix+o` / `prefix+shift+o` | review documents here / the agent's last reply |
| `prefix+alt+h` | hunk: review changes |
| `prefix+alt+a` / `prefix+alt+b` / `prefix+alt+c` / `prefix+alt+t` | hunk: review staged / branch vs base / last commit / last stash |
| `prefix+alt+s` | hunk: send review to agent |
| `prefix+alt+n` / `prefix+alt+p` | hunk: next / previous review comment |
| `prefix+alt+r` / `prefix+alt+x` | hunk: reload / close the review |

Some of these shadow herdr's own `prefix` keys — `prefix+t` and `prefix+shift+t`
most notably — so the built-in action on those keys is no longer reachable.
Global `ctrl+h/j/k/l` also costs readline's `ctrl+l` (clear) and `ctrl+k` (kill
line) in non-Vim panes; see `HERDR_NAV_PASSTHROUGH_RE` below.

## Also part of this setup

- `~/.config/nvim/lua/config/keymaps.lua` — sources vim-herdr-navigation's
  `editor/nvim.lua`. Must load after LazyVim's keymaps, hence this file rather
  than `after/plugin/`.
- `~/.config/nvim/lua/plugins/herdr-nvim.lua` — the nvim half of herdr-nvim.
- `~/.bashrc` — the herdr-automatic-rename shell hook, and
  `export HERDR_NAV_PASSTHROUGH_RE='^(herdr-navigator)$'` so the navigator's TUI
  keeps `ctrl+h/j/k/l` in its own pane. Read by a plugin the herdr *server*
  spawns, so start the server from a shell that exports it. Adding a TUI's
  process name there is also how you get readline's `ctrl+l`/`ctrl+k` back
  inside that pane.
- `plugins/config/herdr-navigator/config.toml` — `[[roots]]` points at `~`
  with `max_depth = 2`; adjust per machine.

Don't copy: `plugins.json`, `plugins/github/**`, `session.json`,
`release-notes.json`, `herdr-*.log`, `*.sock`, `.plugins.lock`, `*.bak.*`. When
this list goes stale, regenerate it from the live registry:

```bash
jq -r '.[] | select(.source.kind == "github") | "\(.source.owner)/\(.source.repo)"' plugins.json | sort
```
