# git-credential-libsecret prints the secret

## Context

Moving `~/.git-credentials` into the wallet after switching `credential.helper` from `store` to
`libsecret` in `chezmoi/dot_gitconfig.tmpl`. The migration was a short script that read each URL,
fed it to the helper's `store` command and then read it back with `get` to check it round-tripped.

## Problem

The script printed the token it was migrating, even though the only `print` in it reported a
comparison result. `get` was called with its output captured, so `store` was the one talking:

```
$ printf 'protocol=https\nhost=echo-test.invalid\nusername=u\npassword=DUMMY123\n\n' \
    | /usr/lib/git-core/git-credential-libsecret store
username=u
password=DUMMY123
```

`store` writes the credential it just saved back to stdout. Git itself never notices, because it
reads nothing from a helper's `store`, so the behaviour stays invisible until something else is
watching that stream. Here that was an agent transcript, which meant a live Forgejo token had to be
revoked and reissued.

A hypothesis that was wrong: **the leak came from the `get` call.** It did not. That call already
used `capture_output=True`. Testing `store` on its own with a dummy value is what settled it.

## Solution

Redirect the helper's stdout whenever it is not a human reading it:

```bash
printf 'protocol=%s\nhost=%s\nusername=%s\npassword=%s\n\n' "$proto" "$host" "$user" "$token" \
    | /usr/lib/git-core/git-credential-libsecret store >/dev/null
```

In Python, `subprocess.run([...], input=payload, text=True, capture_output=True, check=True)` for
every helper call, `store` included, and compare inside the script rather than printing what came
back.

The wider rule: assume any credential helper may echo, and give all of them a closed stdout unless
you are deliberately reading the answer. `store`, `erase` and `approve`/`reject` have nothing to say
that a caller needs.
