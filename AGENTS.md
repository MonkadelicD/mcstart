# Repository Guidelines

## Project Structure & Module Organization

This repository contains a single executable utility, `mcstart`, plus `README.md` and `LICENSE`. Keep the Bash implementation in `mcstart`; place user-facing setup, usage, troubleshooting, and behavior documentation in `README.md`.

## Build, Test, and Development Commands

- `bash -n mcstart` — check the script for Bash syntax errors.
- `shellcheck mcstart` — perform static analysis when ShellCheck is available.
- `./mcstart <server-type> [version]` — run the script locally using an existing server directory under `~/mc-srvrs`.

There is no build step or bundled server asset. To test manually, use a lightweight local server directory and verify Java selection, tmux session creation, and documented exit codes.

## Coding Style & Naming Conventions

- Use POSIX-oriented Bash and retain `set -euo pipefail`.
- Use two-space indentation and align short `case` branches as in the existing script.
- Use lowercase snake case for variables and lowercase function names, except exported conventions such as `JAVA_HOME`.
- Preserve the section comments and keep comments focused on non-obvious behavior.
- Prefer quoted variable expansions. Validate user-controlled paths before use.

## Testing Guidelines

No automated test framework is configured. For every change, at minimum run:

```sh
bash -n mcstart
shellcheck mcstart
```

If ShellCheck reports unrelated pre-existing issues, note them in the pull request rather than mixing unrelated fixes into the change.

Any test command that uses tmux must not affect a previously existing tmux environment. Use a dedicated `TMUX_TMP_DIR`, a named `tmux -L <socket>` socket, or a disposable container. Never run broad teardown commands such as `tmux kill-server`; clean up only sessions created by the test.

## Commit & Pull Request Guidelines

History uses short, imperative commit subjects, often sentence-cased, with merge commits from descriptive branch names. Keep subjects under 72 characters and use the body for details or migration notes.

Pull requests should include a concise problem statement, the behaviors changed, validation performed, and any required Java/tmux/server-directory setup. Link related issues when available. For argument parsing, Java selection, OS detection, or path changes, show the commands and results used for verification.

## Security & Configuration Tips

Never commit server data, `eula.txt`, logs, or generated server files. Treat package installation through `sudo` as significant and test it on the documented Debian/Ubuntu, Fedora/RHEL/Rocky, and CentOS paths where possible.
