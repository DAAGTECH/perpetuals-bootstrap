# perpetuals-bootstrap

One script that gets a Linux or macOS machine ready for the `perpetuals-helpers` Claude plugin
(the private repository DAAGTECH/perpetuals-claude-helpers). This repository is public so the
script can be downloaded before you've signed in to GitHub. It holds no secrets.

```bash
curl -fsSL https://raw.githubusercontent.com/DAAGTECH/perpetuals-bootstrap/v2/install-tools.sh | bash
```

It installs what's missing, then signs you in to GitHub:

| | Linux | macOS |
|---|---|---|
| Python 3.10+ | your package manager | Homebrew |
| git | your package manager | Apple's command-line tools (with Homebrew) |
| GitHub CLI (`gh`) | GitHub's own package repository (apt, dnf, zypper); Arch's `github-cli` | Homebrew |
| Azure CLI (`az`), optional, it asks | Microsoft's script (Ubuntu, Debian); Microsoft's repository (RHEL family); skipped elsewhere | Homebrew |
| Notifications | `notify-send` (libnotify) | `terminal-notifier` |
| Claude Code, it asks | Anthropic's installer (no sudo; `~/.local/bin`) | Anthropic's installer |

On macOS it installs Homebrew first if needed. Every command that needs sudo is shown and runs
only after you answer `y`. At the end it runs `gh auth login` (answer GitHub.com, HTTPS, Yes,
Login with a web browser), checks that you can see the plugin's repository, and offers
`az login`. If new terminals won't find `claude`, it offers to add `~/.local/bin` to your PATH.

Then run `claude` (the first time it signs you in through the browser; it needs a Pro, Max,
Team or Enterprise account) and ask it to install the plugin from
https://github.com/DAAGTECH/perpetuals-claude-helpers.

The commands are the vendors' own, from GitHub's, Microsoft's and Anthropic's install docs
(checked 2026-11-19).

## Where it's tested

| System | Result |
|---|---|
| Ubuntu 24.04, Debian 12 | everything, including the Azure CLI |
| Fedora 41, Arch, openSUSE Tumbleweed | everything except the Azure CLI, which Microsoft doesn't support there |
| Rocky Linux 9 (RHEL 9) | installs, but `python3` stays 3.9 on RHEL 9, so the plugin's tools won't run |
| openSUSE Leap 15 | installs, but `python3` stays 3.6, so the plugin's tools won't run |
| Alpine | not supported (stops with a message) |
| macOS | not tested yet |
| Windows | not supported |

Tested in containers, answering yes to every question, on 2026-11-19.

## Versions

The command above pins tag `v1`. Tags are protected and `main` changes only through reviewed
pull requests. A change ships as a new tag (`v2`, ...), and the command in the plugin's README
and the slides moves to it.
