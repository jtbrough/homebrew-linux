# Homebrew-on-Linux Multi-Prefix Validation & Status

Goal: Prove Homebrew on Linux can install natively into custom prefixes (including `/opt/homebrew`, `~/.brew`, and custom paths $\le 26$ bytes) instead of `/home/linuxbrew/.linuxbrew`, while consuming stock precompiled bottles unmodified (their embedded RPATH/RUNPATH strings shrink from 26 bytes to $\le 26$ bytes, which fits in place with no relinking).

## Repo layout

```
patches/install.sh.orig             upstream Homebrew/install install.sh (unmodified baseline)
patches/opt-homebrew-prefix.patch   diff between upstream install.sh and our multi-prefix installer
scripts/install.sh                   multi-prefix dynamic installer (shellchecked, 0 findings)
docker/Dockerfile                    Ubuntu latest testbed (tester + seconduser unprivileged)
logs/step3-install.log               transcript of cold-install run
NOTES.md                             this technical validation notes log
README.md                            quickstart, flags, and usage documentation
```

## Upstream Integration Status: MERGED

* **Upstream PR**: [Homebrew/brew#23959](https://github.com/Homebrew/brew/pull/23959) merged into `main` by Mike McQuaid (`67f689ad19` / `c30b5ea19a`).
* **Docs Updated**: `docs/Support-Tiers.md`, `docs/Installation.md`, `docs/FAQ.md` officially updated to declare custom relocatable Linux prefixes $\le 26$ bytes as Tier 1 supported.
* **Release Target**: Homebrew 7.0.2.

---

## Step 1 — Dynamic Multi-Prefix Installer: COMPLETED

`scripts/install.sh` features:
1. **Interactive Menu**: Prompts for selection (`/opt/homebrew`, `~/.brew`, `/home/linuxbrew/.linuxbrew`, or custom path) when run in interactive TTY.
2. **CLI Flags**: `--opt`, `--user` / `--rootless`, `--legacy`, `--prefix=<path>`, `-p <path>`.
3. **Byte Length Validation**: Strict check enforcing `bytesize(HOMEBREW_PREFIX) <= 26`.
4. **Intelligent Permissions / Sudo Handling**:
   - For `~/.brew` (or any user-writable prefix): **Bypasses sudo completely**. No password prompt, no root checks.
   - For `/opt/homebrew` / `/home/linuxbrew`: Performs one-time sudo setup to initialize root directory permissions, then drops privileges.
5. **Bridge Shim for 7.0.1**: Injects non-destructive `check_prefix` monkey patch during installation so custom prefixes work seamlessly on 7.0.1 prior to 7.0.2 release.

Shellcheck status: **0 findings** (`shellcheck -S style scripts/install.sh`).

---

## Step 2 — Container Testbed: COMPLETED

Standard `ubuntu:latest` testbed with `podman`:
* Primary user: `tester` (sudo access).
* Secondary user: `seconduser` (unprivileged, strictly NO sudo access).
* Build dependencies: `build-essential`, `procps`, `curl`, `file`, `git`, `ca-certificates`, `binutils`, `pkg-config`, `patchelf`.

---

## Step 3 — Cold Install Validation: PASSED

* **Mode 1 (`/opt/homebrew` via `--opt`)**:
  - One-time sudo creates `/opt/homebrew` with owner `tester:tester`.
  - Homebrew repo initialized; Portable Ruby poured cleanly.
  - `brew --prefix` -> `/opt/homebrew`.

* **Mode 2 (`~/.brew` via `--user` as unprivileged `seconduser`)**:
  - Zero sudo prompts; 100% rootless installation.
  - Homebrew repo initialized in `~/.brew/Homebrew`; Portable Ruby poured into user cache.
  - `brew --prefix` -> `/home/seconduser/.brew`.

* **Mode 3 (Prefix Length Validation)**:
  - Input: `--prefix=/home/user/very/long/excessive/custom/prefix/here` (49 bytes).
  - Output: Aborts immediately with clear error stating the 26-byte ELF relocation limit.

---

## Step 4 — Bottle Pouring & ELF Truncation: PASSED

* Tested bottle installs: `hello` (2.12.3), `ripgrep` (15.2.0), `pcre2`, `gcc-libs`, `zlib-ng-compat`, `bzip2`.
* `readelf -d /opt/homebrew/bin/rg` confirmed in-place RPATH rewriting:
  ```
  Library rpath: [/opt/homebrew/Cellar/ripgrep/15.2.0/lib:/opt/homebrew/opt/gcc/lib/gcc/current:/opt/homebrew/opt/bzip2/lib:/opt/homebrew/opt/zlib-ng-compat/lib:/opt/homebrew/opt/pcre2/lib:/opt/homebrew/lib]
  ```
* Dynamic resolution (`ldd /opt/homebrew/bin/rg`) confirmed `libpcre2-8.so.0 => /opt/homebrew/opt/pcre2/lib/libpcre2-8.so.0`.
* Both `/opt/homebrew` and `~/.brew` run bottles natively without compilation.

---

## Step 5 — Non-ELF Embedded Paths & TLS: PASSED

Tested with `pkg-config`, `openssl@3`, `ca-certificates`, `python@3.12`:
* OpenSSL configs relocated to target prefix (`etc/openssl@3`).
* Python `sys.prefix` and standard library paths point to target prefix.
* CA certificates verify TLS connections successfully without host certificate bundle pollution.

---

## Step 6 — Source Compilation: PASSED

* Executed `brew install --build-from-source jq`.
* Dependency `oniguruma` poured from stock bottle; `jq` built cleanly against target prefix headers and linked against target prefix libraries.

---

## Step 7 — Multi-User & Rootless Isolation: PASSED

* `/opt/homebrew` binaries are world-executable and callable by unprivileged secondary users.
* `~/.brew` installs remain fully isolated to user home directory, ideal for atomic OS (`bootc` / OSTree) and unprivileged container/HPC environments.
