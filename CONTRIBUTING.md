# Contributing

Reproduce on staging first. Open an issue with versions, redacted errors and exact steps. For code changes, explain the problem, resulting behaviour and validation. Add a regression test for behaviour fixes; keep changes focused.

Lua uses four spaces with vorp_stables/stylua.toml. Web files use two spaces and the resource Prettier configuration. Keep config sections readable, technical logs English, player text in both locales and original notices intact.

Run `python tests/run.py` and the UI suite. Never commit credentials, server.cfg, DB dumps, private identifiers, local diagnostic/admin resources, recordings or dependency folders.

Reports and pull requests are welcome. Maintenance is best effort, with no response-time, lifetime-support or custom-integration commitment. Exploits belong in private reporting, not ordinary issues.

Use [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/): `fix(inventory): describe the correction`, `feat(stables): describe the addition`, or `docs: describe the documentation change`. Keep unrelated changes in separate commits and mark breaking changes explicitly.
