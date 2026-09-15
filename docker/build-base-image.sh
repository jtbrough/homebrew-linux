#!/usr/bin/env bash
# Builds ubuntu-noble-local:24.04, a minimal Ubuntu 24.04 base image, via
# debootstrap against the official Ubuntu archive + `docker import`.
#
# Why not `docker pull ubuntu:24.04`: in this validation environment the
# egress proxy allows fixed archive hosts (archive.ubuntu.com) but rejects
# the signed, per-request CDN blob URLs Docker Hub/ECR pulls redirect
# through (production.cloudfront.docker.com, *.cloudfront.net), returning
# HTTP 403. debootstrap only talks to archive.ubuntu.com, so it works
# through the same policy unmodified.
set -euo pipefail

ROOTFS_DIR="$(mktemp -d)"
TARBALL="$(mktemp -u).tar.gz"
IMAGE_TAG="ubuntu-noble-local:24.04"

cleanup() { rm -rf "${ROOTFS_DIR}" "${TARBALL}"; }
trap cleanup EXIT

debootstrap --arch=amd64 noble "${ROOTFS_DIR}" http://archive.ubuntu.com/ubuntu
tar --numeric-owner -czf "${TARBALL}" -C "${ROOTFS_DIR}" .
docker import "${TARBALL}" "${IMAGE_TAG}"

echo "Built ${IMAGE_TAG}"
