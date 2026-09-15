# Homebrew-on-Linux Multi-Prefix Installer

**Homebrew's official Linux installer with interactive prefix selection.**

This repository provides Homebrew's upstream `install.sh` with a patch that adds:

- **Interactive prefix selection**: Choose from preset modes or custom paths ≤26 bytes
- **Tested & upstream-integrated**: `/opt/homebrew` on Ubuntu in its standard support window, with glibc ≥2.39; Homebrew's CI covers this
- **Rootless mode**: `~/.brew` installs with zero sudo required; not in Homebrew's test matrix, but works reliably for standard packages
- **Prefix length validation**: Enforces ≤26 byte limit (Homebrew bottle ELF relocation constraint)

**Status**: Homebrew 7.0.2+ officially supports custom prefixes ≤26 bytes. This installer enables that support with user-friendly prefix selection. Works on Homebrew 7.0.1+ (uses a temporary compatibility bridge for 7.0.1).

## Quick Start

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jtbrough/homebrew-linux/main/install.sh)"
```

Interactive menu lets you choose `/opt/homebrew`, `~/.brew`, `/home/linuxbrew/.linuxbrew`, or a custom path. See [Non-Interactive Installation](#non-interactive--scripted-installation) below for CI/scripted usage.

## How It Works

Homebrew's installer with prefix selection added. We track the upstream baseline (`patches/install.sh.orig`) and merge updates via `make patch`: review the diff, then commit. When Homebrew ships security fixes, you can quickly pull them in without rewriting the patch.

## Technical Background

Homebrew Linux x86_64 bottles are compiled against `/home/linuxbrew/.linuxbrew` (26 bytes). When installed to any target prefix ≤26 bytes, Homebrew's ELF relocation engine truncates and null-pads `DT_RPATH` / `DT_RUNPATH` in-place without recompilation. This enables stock bottles to work in custom prefixes natively.

## Installation Options

The installer (`install.sh`) supports interactive selection or non-interactive CLI flags:

| Option | Flag | Tested | Sudo | Best For |
|---|---|---|---|---|
| **System-wide** | `--opt` | Ubuntu (in support window) + glibc ≥2.39 | One-time setup | Multi-user systems, macOS parity |
| **Rootless** | `--user` | Community-tested | Never | Non-root users, HPC, containers |
| **Legacy** | `--legacy` | Ubuntu (in support window) + glibc ≥2.39 | One-time setup | Existing Linuxbrew docs compatibility |
| **Custom** | `--prefix=<path>` | N/A | Depends | Custom deployment paths ≤26 bytes |

> `/opt/homebrew` and `/home/linuxbrew/.linuxbrew` work on Ubuntu within its standard support window (20.04 LTS and later) with glibc ≥2.39; Homebrew's CI covers these. Rootless mode (`~/.brew`) works reliably but isn't in Homebrew's test matrix.

> After initial setup, running `brew` and installing packages from bottles **never requires sudo**.

## Staying Synchronized with Homebrew

When Homebrew releases a new installer version:

```bash
# 1. Update the tracked baseline
wget https://raw.githubusercontent.com/Homebrew/install/master/install.sh -O patches/install.sh.orig.new

# 2. Review the diff
diff patches/install.sh.orig patches/install.sh.orig.new

# 3. If safe to merge, replace and regenerate our patch
mv patches/install.sh.orig.new patches/install.sh.orig
make patch

# 4. Commit and push
git commit -am "chore: sync upstream Homebrew installer changes"
```

The CI gates (`make diff-check`) prevent our patch from drifting out of sync.

## Non-Interactive / Scripted Installation

**System-wide (`/opt/homebrew`):**
```bash
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jtbrough/homebrew-linux/main/install.sh)" --opt
```

**100% Rootless (`~/.brew` — zero sudo required):**
```bash
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jtbrough/homebrew-linux/main/install.sh)" --user
```

**Custom Prefix ($\le 26$ bytes):**
```bash
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jtbrough/homebrew-linux/main/install.sh)" --prefix=/opt/brew
```

## License

BSD 2-Clause License. [LICENSE](LICENSE)
