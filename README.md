# perpetuals-bootstrap

One script that gets a Linux or macOS machine ready for the `perpetuals-helpers` Claude plugin
(the private repository DAAGTECH/perpetuals-claude-helpers). This repository is public so the
script can be downloaded before you've signed in to GitHub. It holds no secrets.

```bash
curl -fsSL https://raw.githubusercontent.com/DAAGTECH/perpetuals-bootstrap/v1/install-tools.sh | bash
```

It installs what's missing, then signs you in to GitHub:

| | Linux | macOS |
|---|---|---|
| Python 3.10+ | your package manager | Homebrew |
| GitHub CLI (`gh`) | GitHub's own package repository (apt, dnf, zypper); Arch's `github-cli` | Homebrew |
| Azure CLI (`az`), optional, it asks | Microsoft's script on Ubuntu/Debian; skipped elsewhere | Homebrew |
| Notifications | `notify-send` (libnotify) | `terminal-notifier` |

On macOS it installs Homebrew first if needed. Every command that needs sudo is shown and runs
only after you answer `y`. At the end it runs `gh auth login` (answer GitHub.com, HTTPS, Yes,
Login with a web browser) and checks that you can see the plugin's repository.

Then start Claude and ask it to install the plugin from
https://github.com/DAAGTECH/perpetuals-claude-helpers.

The commands are the vendors' own, from GitHub's and Microsoft's install docs (checked
2026-11-19). Tested on Ubuntu 24.04, Fedora 41 and Arch; the macOS path isn't tested yet.

## Versions

The command above pins tag `v1`. Tags are protected and `main` changes only through reviewed
pull requests. A change ships as a new tag (`v2`, ...), and the command in the plugin's README
and the slides moves to it.
