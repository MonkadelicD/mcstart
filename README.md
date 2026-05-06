# mcstart

Simple shell script to start Minecraft servers with automatic Java version detection.

## Requirements

- Minecraft server application (Forge, Paper, Spigot, Fabric, Vanilla, etc.)
- tmux
- Java 8, 17, and/or 21 (depending on server version)

## Directory Structure

Place `mcstart` in a directory on your `$PATH` (e.g., `~/bin` or `/usr/local/bin`).

mcstart expects each server type to have its own directory under `$HOME`,
with a subdirectory for each Minecraft version:

```
$HOME/
├── forge/
│   ├── 1.17.1/
│   ├── 1.19.2/
│   └── current -> 1.19.2
├── paper/
│   ├── 1.17.1/
│   ├── 1.19.3/
│   └── current -> 1.19.3
├── spigot/
│   └── ...
└── fabric/
    └── ...
```

### Symlinks

A `current` symlink inside each server type directory points to the most
recent version. If the version argument is omitted, `current` is the default.

### Version Suffixes (Multiple Servers, Same Version)

Append a `-suffix` to a version name to run multiple unique servers on the
same Minecraft version. The suffix can be any string except those containing
a hyphen.

```
forge/
├── 1.20.6/
├── 1.20.6-beware/
├── 1.20.6-solo/
├── current -> 1.20.6
└── beware -> 1.20.6-beware
```

You can create additional symlinks (e.g., `beware -> 1.20.6-beware`) for
convenient startup:

```
mcstart forge beware
```

### Server Jars

- **Forge:** Run the installer jar from within the version directory, then the
  script will use `run.sh` automatically.
- **Spigot, Paper, Fabric, Vanilla:** Name the jar as
  `<server-type>-<MC-version>.jar` (e.g., `paper-1.19.3.jar`).

## Usage

```
mcstart <server-type> [version]
```

- `<server-type>` — directory name under `$HOME` (forge, paper, spigot, etc.)
- `[version]` — version subdirectory or symlink name (default: `current`)

### Examples

```
mcstart forge 1.19.3
mcstart paper
mcstart forge beware
```

### JVM Memory

Override the default heap allocation with environment variables:

```
MC_MEM_MIN=2G MC_MEM_MAX=8G mcstart forge 1.19.3
```

Defaults are `1G` min and `4G` max if unset.

### Console Access

List running tmux sessions:

```
tmux list-sessions
```

Attach to a server console:

```
tmux attach-session -t MCServer_<server-type>
```

Detach from a tmux session with `Ctrl-B d`.

## Java Version Detection

The script automatically selects the appropriate Java version based on the
Minecraft release:

| MC Version       | Java Required |
|------------------|---------------|
| < 1.17           | Java 8        |
| 1.17 – 1.20.3    | Java 17       |
| ≥ 1.20.4         | Java 21       |

If a server fails to start, confirm that the matching Java version is
installed on your system.

## Exit Codes

| Code | Meaning                        |
|------|--------------------------------|
| 0    | Server started successfully    |
| 1    | Untested or unsupported OS     |
| 2    | Invalid server type or version |
| 3    | Failed to change directory     |
| 4    | tmux not available             |

## Troubleshooting

**"Could not find server directory"**
  - Verify the directory exists: `ls ~/forge/1.19.3`
  - Check the spelling matches the folder name exactly.

**"Untested or unsupported OS"**
  - mcstart supports Debian/Ubuntu, Fedora/RHEL/Rocky, and CentOS.
  - For other distros, you can add detection in the `case "$ID"` block.

**"Version could not be parsed"**
  - Directory names should start with a valid MC version number:
    `1.19.3`, `1.20.6-solo`, etc.

**"Failed to install tmux"**
  - Ensure `sudo` access is available or install tmux manually.

**tmux: Error connecting to /tmp/tmux-1000/default (permission denied)**
  - The tmux server runs under your user. If this persists, restart it:
    `tmux kill-server && tmux new-session -d`

**Server starts but immediately exits**
  - Check `server.properties` for the correct `server-port` setting.
  - Run the java command manually from the server directory to see the error.
  - Confirm the correct Java version is installed (see table above).
