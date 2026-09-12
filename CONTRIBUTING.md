# Contributing to Shell-Eggs

Thanks for your interest in improving Shell-Eggs. Shell eggs are dual-use tools and
must be contributed carefully. Please read this guide before opening a pull request.

## Development setup

- A Linux or macOS machine with **Docker** (all tests run in containers).
- **Bun** (for the docs site: `cd docs && bun install`).
- `git clone https://github.com/PotenFYR-Studios/Shell-Eggs.git`

```bash
# Build the universal image
docker build -t shell-eggs:dev .

# Run a quick boot test
docker run --rm -e SHELL_TYPE=ssh -e SHELL_USERS=alice -e SHELL_PASSWORDS=testpass \
  -e PANEL_STOP_WATCHER=0 -e AUTO_UPDATE_EGG=0 -p 2222:2222 shell-eggs:dev

# Run the full CI suite locally
bash tests/test-coverage.sh && bash tests/test-payloads.sh
```

### Docs site

```bash
cd docs
bun install
bun run dev      # Vite dev server on http://localhost:5173/Shell-Eggs/
bun run build    # production build into docs/dist
```

## Adding a new shell

1. Add one `register_shell` line to `scripts/shell-registry.sh` in the correct
   category section. The format is:

   ```bash
   register_shell <id> "<Display Name>" <category> <default_port> <needs_root> "<description>"
   ```

2. Create a handler script `scripts/shell-init-<id>.sh` that boots and supervises
   the new shell. Follow the convention of the existing handlers: source the
   shared payload functions from `scripts/shell-payloads.sh`.

3. Add the entry to `SHELLs.md` with the connection commands and key component
   explanations.

4. Add a boot test to `tests/test-coverage.sh` and, if it's a reverse shell,
   a payload emission test to `tests/test-payloads.sh`.

5. Run the full test suite: `bash tests/test-coverage.sh && bash tests/test-payloads.sh`

**The docs site auto-syncs from the registry.** The build runs
`docs/scripts/sync-data.ts` which reads `scripts/shell-registry.sh` +
`egg-shell-multi.json` and generates the typed catalog, so no manual
catalog.ts edits are needed.

## Egg JSON changes

`egg-shell-multi.json` is the Pterodactyl egg definition. Changes to it should
match the actual runtime behavior of the entrypoint. If you add variables or
change defaults, update the corresponding handler scripts and the
`docs/scripts/sync-data.ts` variable extraction logic.

## Pull requests

- One logical change per PR; include tests for behavior changes.
- New shells MUST include a handler script + CI coverage.
- CI must be green: shell boot tests, registry coverage, payload emission,
  egg JSON validation, and docs site build.
- For changes touching `entrypoint.sh` or `run.sh`, explain the behavior
  change clearly in the PR description.

## Reporting issues

Use [GitHub Issues](https://github.com/PotenFYR-Studios/Shell-Eggs/issues) for
bugs, shell requests, and panel compatibility reports. For security-sensitive
reports, see [SECURITY.md](SECURITY.md).

## License

By contributing you agree your contributions are licensed under the
Apache-2.0 WITH Commons Clause license covering the repository.
