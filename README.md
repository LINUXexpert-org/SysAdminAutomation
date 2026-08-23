# Linux System Administration Scripts

A collection of Bash scripts for routine Linux system administration:
backups, log handling, monitoring, user and service management, and package
updates.

Each script is distribution-agnostic, using only base utilities (`tar`,
`rsync`, `find`, `awk`, `grep`, `ss`/`netstat`, `systemctl`), carries its
usage in its header, and is released under the **GNU GPL v3.0**.

## Before you run these

**Most of these run as root and several change or delete things.** They are
written to be careful about it, but read the header of any script before you
point it at a system you care about.

The conventions are consistent across the collection:

| | |
|---|---|
| `--dry-run` | show what would happen, change nothing |
| confirmation prompts | anything destructive asks first |
| `--yes` / `ASSUME_YES=1` / `FORCE=1` | skip the prompt for unattended use |
| no tty, no override | the script **refuses** rather than proceeding unprompted |

That last row is the important one for cron: a destructive script with no
terminal to ask on will stop rather than guess.

All fifteen run under `set -euo pipefail`, and the repository is linted by
ShellCheck on every push.

## The scripts

### Backup and restore

- **`backup.sh`** `<source_dir> <dest_dir>` — archives a directory to
  `name-backup-YYYYmmdd-HHMMSS.tar.gz`. Refuses to overwrite an existing
  archive, and writes to a `.partial` name renamed only on success, so an
  interrupted run cannot leave a truncated file that looks like a backup.
- **`restore.sh`** `<archive.tar.gz> [target_dir]` — lists the archive
  contents, confirms, then extracts with `--no-same-owner` and
  `--no-same-permissions`. An archive chooses its own paths, ownership and
  modes, so as root those defaults matter.
- **`rsync_magic.sh`** `[--dry-run] [--inplace] [--yes] <source> <dest>` —
  rsync wrapper with checksums, ACLs, xattrs and a timestamped backup
  directory for anything `--delete` removes. Confirms before syncing,
  because reversing the two arguments erases the backup.
- **`zimbra_backup.sh`** / **`zimbra_restore.sh`** — per-mailbox Zimbra
  backup and restore, prompting for address and directory. The backup
  verifies its own output (size and gzip integrity) rather than trusting a
  zero exit status, and keeps a failed attempt as `.suspect` for inspection.

### Logs

- **`log_inspect.sh`** `[search <pattern> | tail <logfile>]` — searches
  `/var/log` or tails a log. Distinguishes "no matches" from "could not read
  everything", so an unprivileged search does not look like a clean one.
- **`log_rotate.sh`** `[--days N] [--purge-days N] [--dry-run] [--yes]` —
  compresses old `.log` files. **Skips files a running process still holds
  open**, which is why it is not a `logrotate` replacement: it cannot signal
  daemons or truncate in place, so it leaves those for the real thing.
  Deleting old archives is opt-in via `--purge-days`.

### Monitoring and inspection

- **`sys_monitor.sh`** — uptime, load, memory, disk, top processes.
- **`network_info.sh`** — interfaces, routes, listening ports, firewall
  rules (`iptables`, falling back to `nft`).
- **`security_audit.sh`** — world-writable files and directories, SUID/SGID
  binaries, listening ports. Run as root: `find` cannot descend where it may
  not read, so a clean report as an ordinary user means little.
- **`disk_cleanup.sh`** `[--clean] [--dry-run] [--age N] [--dirs A,B] [--yes]`
  — disk usage overview, and optional cleanup of package caches and old temp
  files. `--dirs` refuses protected system directories and confirms for
  anything outside `/tmp` and `/var/tmp`.

### System management

- **`process_monitor.sh`** `[kill <name|PID>]` — top consumers; the kill path
  prints what it matched and asks first, since `pkill` by name can match more
  than one process.
- **`service_manager.sh`** `<action> <service>` — start, stop, restart,
  status, enable, disable, list. `status` and `list` work as any user; the
  rest require root.
- **`user_manage.sh`** `<subcommand> …` — add/remove users and groups, group
  membership, lock/unlock. `listusers` and `listgroups` are open to anyone;
  everything else needs root. `deluser` removes the home directory, so it
  shows what will go and confirms.
- **`update_system.sh`** — detects the package manager (apt, dnf, yum,
  zypper, pacman) and applies updates unattended. Every branch passes `-y` or
  `--noconfirm`; on Arch in particular, `-Syuu --noconfirm` answers away the
  prompts that would otherwise warn about a partial upgrade.

## Contributing

ShellCheck runs on every push and pull request at `warning` severity, against
a clean tree — anything it reports is new. Run it locally before opening a PR:

```sh
shellcheck *.sh
```

Keep the existing conventions: `set -euo pipefail`, a root check on anything
that changes system state, `--dry-run` where it makes sense, and a
confirmation plus an unattended escape hatch for anything destructive.

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).
