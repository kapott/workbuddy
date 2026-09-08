# install-sway.sh stops after "Checking for an existing secret store"

## Context

`./install-sway.sh --config-only --dry-run` on `endling`, a machine with a KDE wallet in
`~/.local/share/kwalletd` and no gnome-keyring.

## Problem

The script printed its section headers, reached the last one and ended there:

```
== Checking for an existing secret store
```

No error, no `== Next` block, no `sway --validate`. Exit status 2.

`secret_store_report` counted each store with `ls` piped into `wc -l`:

```bash
kwl="$(ls -1 "${XDG_DATA_HOME:-$HOME/.local/share}"/kwalletd/*.kwl 2>/dev/null | wc -l)"
keyring="$(ls -1 "${XDG_DATA_HOME:-$HOME/.local/share}"/keyrings/*.keyring 2>/dev/null | wc -l)"
```

`~/.local/share/keyrings` does not exist, so `ls` exits 2. `set -o pipefail` hands that
status to the whole pipeline, a plain assignment takes the status of its command
substitution, and `set -e` ends the script. The `2>/dev/null` hides the message, which is
why nothing is printed. Reproduce it on its own:

```bash
$ bash -c 'set -euo pipefail; v="$(ls -1 /nonexistent/*.kwl 2>/dev/null | wc -l)"; echo reached'; echo $?
2
```

Note that this only fires when one of the two stores is missing. On a machine with both,
or with neither directory present in a way `ls` tolerates, the script runs to the end.

## Solution

Count with `nullglob` and an array. No external command, so nothing can fail:

```bash
local data="${XDG_DATA_HOME:-$HOME/.local/share}"
local -a kwl keyring

shopt -s nullglob
kwl=("$data"/kwalletd/*.kwl)
keyring=("$data"/keyrings/*.keyring)
shopt -u nullglob

if [ "${#kwl[@]}" -gt 0 ]; then
```

`${#kwl[@]}` replaces the scalar in every later comparison.

The general rule: under `set -euo pipefail`, `var="$(cmd | wc -l)"` is a statement that can
end the script, and `2>/dev/null` on the failing command makes it end silently. Either
append `|| true` to the pipeline or, better, do not shell out to count files.

### Hypotheses that were wrong

**Not the missing chezmoi config.** `chezmoi: warning: config file template has changed`
appears a few lines earlier and is unrelated; the script survives it.

**Not `--dry-run`.** The same exit happens on a real run, after the backups and the
`chezmoi apply` have already done their work, which is what makes it easy to miss.

See also [install-sway-leaves-config-directories-empty.md](install-sway-leaves-config-directories-empty.md).
