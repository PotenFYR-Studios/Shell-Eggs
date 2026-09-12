# Security Policy - Shell-Eggs

## Scope

Shell-Eggs is a **dual-use security tool** by PotenFYR Studios. It provides
shell environments for lab, testing, and authorized operations. This policy
covers the egg runtime, Docker image, panel integration, docs site, and CI
pipelines.

## Supported versions

Only the latest commit on the `master` branch is supported. The GHCR image
tag `:latest` tracks `master`. SHA-pinned tags are available for reproducible
deployments.

## What is in scope

- The Docker image (`Dockerfile`) and entrypoint (`entrypoint.sh`, `run.sh`).
- Shell handler scripts in `scripts/`.
- The egg JSON definition (`egg-shell-multi.json`).
- CI workflows (`.github/workflows/`).
- The docs site (`docs/`).

## What is out of scope

- Misconfigurations in the user's panel or Docker host.
- Network exposure of ports the user deliberately opens.
- Vulnerabilities in upstream packages (OpenSSH, socat, etc.): report those
  to the upstream project.

## Reporting a vulnerability

**Do not open a public issue.** Instead, either:

- Mark a GitHub issue with `[security]` in the title and avoid posting exploit
  details until a fix lands, **or**
- Email [support@potenfyr.in](mailto:support@potenfyr.in) with the subject
  `[Shell-Eggs Security]`.

We will acknowledge within 72 hours and provide a timeline for a fix.

## Security design

- **Generated credentials** (passwords, TLS certs, web tokens) are written
  mode-600 inside the container workspace and printed once on the console.
- **Hardened SSH profile** enforces keys-only auth (`AuthenticationMethods publickey`),
  no root login, `MaxAuthTries 2`, forwarding disabled.
- **CA-cert profile** enforces principal pinning: a cert signed for `carol`
  cannot log in as `mallory` (verified in CI).
- **Web shells** require a token (401 without it); the token is generated
  once and shown on the console.
- **Shells are dual-use tools.** They do not bypass authentication or
  authorization. They only work if the user has panel/Docker access.

## Disclosure

Vulnerabilities are disclosed after a fix is released. We follow a 90-day
disclosure timeline for confirmed issues.
