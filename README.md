# glmc

A terminal coding agent for GLM models, built unmodified from the open-source
[ZCode](https://github.com/zai-org/ZCode) Agent CLI (Apache-2.0) and shipped as a
single Linux x64 binary.

glmc is not affiliated with or endorsed by Z.ai. "ZCode" is a name of its owner;
this project uses it only to identify the upstream source.

## Install and update

```sh
curl -fsSL https://raw.githubusercontent.com/chunnylab/glmc/main/install.sh | sh
```

The script downloads the latest release, checks it against `SHA256SUMS`, and
replaces `~/.local/bin/glmc` in one rename. Run the same command to update. Pin a
release with `GLMC_VERSION=<tag>`.

Uninstall: `rm ~/.local/bin/glmc; rm -rf ~/.local/share/glmc`.

## Use

```sh
glmc login --no-browser   # prints a Z.ai sign-in URL; open it on any device
glmc                      # full-screen TUI in the current directory
glmc -p "fix the failing test"        # one headless task
glmc -c -p "now run the whole suite"  # continue the latest session here
```

glmc shares `~/.zcode` with the ZCode desktop app, so both use the same login.
Headless `-p` runs default to `--mode yolo`; pass `--mode guarded` or `plan` to
require approval.

## How it is built

`build.sh <upstream-tag>` checks out that tag of `zai-org/ZCode`, builds the Agent
CLI with the Node and pnpm versions pinned by upstream, and runs upstream's own
SEA packager for `linux-x64`.

One change to the build, none to the code: upstream's SEA packager requires
`dist/index.js` in every workspace package the TUI depends on, but source-only
packages such as `@zcode/shared` have no build step. The TUI bundle already
inlines them, so `build.sh` writes an empty `export {};` stub to satisfy the check.

Telemetry: the CLI's OpenTelemetry exporter stays off unless you set an
`OTEL_EXPORTER_OTLP_*` endpoint yourself.

## License

Apache-2.0, as upstream. Each release ships upstream's `LICENSE`, `NOTICE.md`, and
`THIRD-PARTY-NOTICES.md`; the installer keeps them in `~/.local/share/glmc/`.
