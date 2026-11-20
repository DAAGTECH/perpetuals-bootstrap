#!/usr/bin/env bash
# Install the tools the perpetuals-helpers Claude plugin needs, on Linux or macOS:
# Python 3.10+, the GitHub CLI (gh), optionally the Azure CLI (az), a notifier, then sign in to GitHub.
#
#   curl -fsSL https://raw.githubusercontent.com/DAAGTECH/perpetuals-bootstrap/v1/install-tools.sh | bash
#
# Every command that needs sudo is shown first and runs only after you answer y.
# The install commands are the vendors' own (GitHub's and Microsoft's install docs, checked
# 2026-11-19). Nothing here reads or stores a secret: gh keeps its own login.
#
# Options (as environment variables, for testing): BOOTSTRAP_YES=1 answers yes to everything
# and skips the GitHub sign-in; BOOTSTRAP_AZ=1 or 0 answers the Azure CLI question.

set -euo pipefail

REPO=DAAGTECH/perpetuals-claude-helpers
GH_KEY_URL=https://cli.github.com/packages/githubcli-archive-keyring.gpg
GH_RPM_REPO=https://cli.github.com/packages/rpm/gh-cli.repo

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
note() { printf '  %s\n' "$*"; }
die()  { printf '\nerror: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Piped into bash, stdin is this script, so questions read from the terminal.
ask() {
  local answer
  if [ "${BOOTSTRAP_YES:-0}" = 1 ]; then return 0; fi
  [ -r /dev/tty ] || die "no terminal to ask on; run this in a terminal window"
  printf '%s [y/N] ' "$1" > /dev/tty
  read -r answer < /dev/tty
  case "$answer" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# Run a root command after showing it and getting a yes. As root (a container), no sudo.
as_root() {
  local shown="$*"
  printf '\n  will run (as root): %s\n' "$shown"
  ask "  run it?" || die "stopped; nothing more was changed"
  if [ "$(id -u)" = 0 ]; then bash -c "$*"; else sudo bash -c "$*"; fi
}

python_ok() {
  have python3 && python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)'
}

# ---------------------------------------------------------------- macOS
mac() {
  if ! have brew; then
    say "Homebrew isn't installed. Its own installer (brew.sh) asks for your password."
    ask "Install Homebrew now?" || die "Homebrew is needed on macOS; see https://brew.sh"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$b" ]; then eval "$("$b" shellenv)"; break; fi
    done
    have brew || die "brew still not found; run the 'Next steps' lines Homebrew printed, then run this again"
    note "Homebrew printed 'Next steps': run those lines too, or brew won't be found in new terminals."
  fi
  local pkgs=()
  python_ok || pkgs+=(python)
  have gh || pkgs+=(gh)
  have terminal-notifier || pkgs+=(terminal-notifier)
  if ! have az && want_az; then pkgs+=(azure-cli); fi
  if [ ${#pkgs[@]} -gt 0 ]; then
    say "Installing with Homebrew: ${pkgs[*]}"
    brew install "${pkgs[@]}"
  fi
}

# ---------------------------------------------------------------- Linux
pm() {
  if have apt-get; then echo apt
  elif have dnf5; then echo dnf5
  elif have dnf; then echo dnf
  elif have zypper; then echo zypper
  elif have pacman; then echo pacman
  else echo none; fi
}

linux_gh() {
  have gh && return 0
  say "Installing the GitHub CLI from GitHub's own repository"
  case "$1" in
    apt)
      note "Not Ubuntu's own gh package (GitHub says those versions are broken), and not the snap."
      as_root "apt-get update -qq && apt-get install -y -qq wget ca-certificates gnupg >/dev/null \
&& mkdir -p -m 755 /etc/apt/keyrings \
&& wget -qO /etc/apt/keyrings/githubcli-archive-keyring.gpg $GH_KEY_URL \
&& chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& mkdir -p -m 755 /etc/apt/sources.list.d \
&& echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" > /etc/apt/sources.list.d/github-cli.list \
&& apt-get update -qq && apt-get install -y gh" ;;
    dnf5) as_root "dnf install -y dnf5-plugins && dnf config-manager addrepo --from-repofile=$GH_RPM_REPO && dnf install -y gh" ;;
    dnf)  as_root "dnf install -y 'dnf-command(config-manager)' && dnf config-manager --add-repo $GH_RPM_REPO && dnf install -y gh" ;;
    zypper) as_root "zypper --non-interactive addrepo $GH_RPM_REPO && zypper --non-interactive --gpg-auto-import-keys ref && zypper --non-interactive install gh" ;;
    pacman)
      note "Arch doesn't support partial upgrades, so pacman -Syu also upgrades the rest of the system."
      as_root "pacman -Syu --needed --noconfirm github-cli" ;;
    *) die "no supported package manager; install gh from https://github.com/cli/cli#installation" ;;
  esac
}

linux_python() {
  python_ok && return 0
  say "Python 3.10 or later is needed"
  case "$1" in
    apt) as_root "apt-get update -qq && apt-get install -y python3" ;;
    dnf5|dnf) as_root "dnf install -y python3" ;;
    zypper) as_root "zypper --non-interactive install python311" ;;
    pacman) as_root "pacman -Syu --needed --noconfirm python" ;;
  esac
  python_ok || note "python3 is still older than 3.10; install a newer Python before running setup."
}

linux_notify() {
  have notify-send && return 0
  say "notify-send (desktop notifications for the traffic agent) isn't installed"
  case "$1" in
    apt) as_root "apt-get update -qq && apt-get install -y libnotify-bin" ;;
    dnf5|dnf) as_root "dnf install -y libnotify" ;;
    zypper) as_root "zypper --non-interactive install libnotify-tools" ;;
    pacman) as_root "pacman -Syu --needed --noconfirm libnotify" ;;
  esac
}

linux_az() {
  have az && return 0
  want_az || return 0
  case "$1" in
    apt)
      say "Installing the Azure CLI with Microsoft's script"
      as_root "apt-get install -y -qq curl >/dev/null && curl -fsSL 'https://azurecliprod.blob.core.windows.net/\$root/deb_install.sh' | bash" ;;
    *)
      note "Microsoft documents the Azure CLI for Ubuntu/Debian and RHEL only. Skipping it here; see"
      note "https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux (the traffic agent works without it)." ;;
  esac
}

linux() {
  local p; p=$(pm)
  linux_python "$p"
  linux_gh "$p"
  linux_notify "$p"
  linux_az "$p"
}

# ---------------------------------------------------------------- both
want_az() {
  case "${BOOTSTRAP_AZ:-}" in 1) return 0 ;; 0) return 1 ;; esac
  ask "Also install the Azure CLI (optional: CI failures then carry their branch)?"
}

sign_in() {
  if [ "${BOOTSTRAP_YES:-0}" = 1 ]; then return 0; fi
  if ! gh auth status >/dev/null 2>&1; then
    say "Sign in to GitHub. Answer: GitHub.com, HTTPS, Yes, Login with a web browser."
    gh auth login < /dev/tty
  fi
  gh auth setup-git
  if gh repo view "$REPO" >/dev/null 2>&1; then
    say "Done. You can see $REPO."
    note "Next: start Claude anywhere and ask it to install the plugin from https://github.com/$REPO"
  else
    say "Done, but your GitHub account can't see $REPO yet: ask David for access."
  fi
}

main() {
  case "$(uname -s)" in
    Darwin) mac ;;
    Linux) linux ;;
    *) die "only Linux and macOS are supported; Windows is on the roadmap (docs/windows.md in $REPO)" ;;
  esac
  python_ok || note "python3 is older than 3.10; the plugin's tools need 3.10 or later."
  have gh || die "gh didn't install"
  say "Installed: $(python3 --version 2>&1), $(gh --version | head -1)$(have az && printf ', azure-cli')"
  sign_in
}

main "$@"
