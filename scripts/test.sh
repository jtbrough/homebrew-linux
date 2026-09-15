#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# string formatters
if [[ -t 1 ]]; then
  BOLD="\033[1m"
  GREEN="\033[1;32m"
  RED="\033[1;31m"
  BLUE="\033[1;34m"
  RESET="\033[0m"
else
  BOLD=""
  GREEN=""
  RED=""
  BLUE=""
  RESET=""
fi

log_info() { printf "${BLUE}==>${BOLD} %s${RESET}\n" "$*"; }
log_pass() { printf "${GREEN}✔ PASS:${RESET} %s\n" "$*"; }
log_fail() { printf "${RED}✘ FAIL:${RESET} %s\n" "$*" >&2; exit 1; }

# Detect container runtime
if command -v podman >/dev/null 2>&1; then
  CONTAINER_ENGINE="podman"
elif command -v docker >/dev/null 2>&1; then
  CONTAINER_ENGINE="docker"
else
  log_fail "Neither podman nor docker found in PATH."
fi

log_info "Using container engine: ${CONTAINER_ENGINE}"

# 1. Build testbed image
log_info "Building test container image (homebrew-linux-opt:test)..."
${CONTAINER_ENGINE} build -t homebrew-linux-opt:test -f "${REPO_DIR}/docker/Dockerfile" "${REPO_DIR}"
log_pass "Container image built successfully."

# 2. Test prefix length rejection (> 26 bytes)
log_info "Testing validation: rejection of prefix > 26 bytes..."
if ${CONTAINER_ENGINE} run --rm homebrew-linux-opt:test \
  /usr/local/bin/homebrew-install.sh --prefix=/home/user/very/long/excessive/custom/prefix/here >/dev/null 2>&1; then
  log_fail "Installer should have rejected prefix > 26 bytes but succeeded!"
else
  log_pass "Prefix length validation correctly rejected path > 26 bytes."
fi

# 3. Test Mode: Rootless ~/.brew (unprivileged seconduser, NO sudo)
log_info "Testing Mode: Rootless (~/.brew) as unprivileged user with ZERO sudo access..."
${CONTAINER_ENGINE} run --rm --user seconduser -w /home/seconduser homebrew-linux-opt:test \
  bash -c "/usr/local/bin/homebrew-install.sh --user && \
           eval \"\$(/home/seconduser/.brew/bin/brew shellenv)\" && \
           brew --version && \
           brew install --formula hello && \
           hello" >/dev/null 2>&1
log_pass "Rootless (~/.brew) installed and poured bottles with zero root privileges."

# 4. Test Mode: System-wide /opt/homebrew (sudo setup)
log_info "Testing Mode: System-wide (/opt/homebrew) with one-time sudo..."
${CONTAINER_ENGINE} run --rm homebrew-linux-opt:test \
  bash -c "/usr/local/bin/homebrew-install.sh --opt && \
           eval \"\$(/opt/homebrew/bin/brew shellenv)\" && \
           brew --version && \
           brew install --formula hello && \
           hello" >/dev/null 2>&1
log_pass "System-wide (/opt/homebrew) installed and poured bottles cleanly."

log_info "${GREEN}All test matrix suites passed successfully!${RESET}"
