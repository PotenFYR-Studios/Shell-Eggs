## Summary

<!-- Briefly describe what this PR does. -->

## Type

- [ ] New shell type (registry + handler + SHELLs.md + tests)
- [ ] Bug fix
- [ ] Docs / README update
- [ ] CI / workflow change
- [ ] Egg JSON change
- [ ] Other

## Checklist

- [ ] `bash tests/test-coverage.sh` passes (all 54 ids have handlers)
- [ ] `bash tests/test-payloads.sh` passes (all reverse payloads emit)
- [ ] `bash -n entrypoint.sh && bash -n run.sh` (shell syntax OK)
- [ ] `jq empty egg-shell-multi.json` (JSON valid)
- [ ] `cd docs && bun install && bun run build` succeeds
- [ ] Any new shell has a `scripts/shell-init-<id>.sh` handler
- [ ] Any new shell is documented in `SHELLs.md`
- [ ] Any new egg variable is reflected in the egg JSON and tested

## Security impact

<!-- If this change touches entrypoint.sh, run.sh, any shell handler, the Dockerfile, or the CI pipeline, explain the security implications. -->

## License

By submitting this PR, I agree my contributions are licensed under the Apache-2.0 WITH Commons Clause license covering this repository.
