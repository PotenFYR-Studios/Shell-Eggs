#!/usr/bin/env bash
# docs/cname-setup.sh
# Hybrid domain for GitHub Pages deploy:
#   - If the repo has Pages configured with a custom domain (or a CNAME file /
#     CUSTOM_DOMAIN secret exists), the deploy keeps it.
#   - Otherwise the default *.github.io repo domain is used.
#
# The Pages deploy workflow (pages.yml) runs this before building. Nothing to
# configure here for the default domain; to use a custom domain either:
#   a) set it once in repo Settings -> Pages -> Custom domain (recommended), or
#   b) add a repository secret CUSTOM_DOMAIN=shell.example.com - this script
#      then writes the CNAME file automatically on every deploy.

set -u
cd "$(dirname "$0")"

DOMAIN="${CUSTOM_DOMAIN:-}"

# a) already configured via Settings -> Pages (CNAME file kept in repo)?
if [ -z "${DOMAIN}" ] && [ -f CNAME ]; then
    DOMAIN=$(head -n1 CNAME | tr -d '[:space:]')
fi

if [ -n "${DOMAIN}" ]; then
    printf '%s\n' "${DOMAIN}" > CNAME
    echo "[cname] custom domain active: ${DOMAIN}"
else
    # Default github.io domain: ensure no stale CNAME ships into the artifact.
    rm -f public/CNAME CNAME
    echo "[cname] no custom domain set - using default: potenfyr-studios.github.io/Shell-Eggs"
fi
