---
name: sandbox-allow-host
description: Let sandboxed commands on this machine reach a host the sandbox refused, after the user asked for it. Also lists or removes the hosts this machine added.
argument-hint: "<host or URL> | --list | --remove <host>"
disable-model-invocation: true
allowed-tools: Bash
---

# sandbox-allow-host: let the sandbox reach a host on this machine

Sandboxed Bash reaches every host through `WebFetch(domain:*)`, except one that resolves to this machine's own
address, such as a GitLab running on the same machine: the proxy refuses it with `resolved to one of this host's
addresses`. Such a host has to be named in `sandbox.network.allowedDomains`. The harness ships no hosts there; this
skill adds one for this machine only, through `uskn-harness sandbox-allow-host`, which writes
`~/.config/uskn-harness/settings.json` and applies the user settings. The user typed `/sandbox-allow-host`; letting
the sandbox reach a host loosens a guard, so it is the user's call.

## Steps

### 1. Read the argument

- `--list`: run `uskn-harness sandbox-allow-host --list` and show it. Done.
- `--remove <host>`: run `uskn-harness sandbox-allow-host --remove <host>`, then go to step 4.
- A host name (`gl.example.test`) or a URL: go to step 2.
- Empty: ask which host, and wait.

### 2. Take the host name

The command takes the host name alone. From a URL, drop the `https://` (or `http://`) prefix, any `user@`, the
`:port`, and the path: `https://gl.example.test:8443/api/v4` gives `gl.example.test`.

When the argument holds a `*`, add nothing: `WebFetch(domain:*)` already lets the sandbox reach every host that is
not this machine's own, and a wildcard here would only widen what a host on this machine may serve. Say so and stop.

### 3. Add the host

Run the command on its own, never after `cd` or before a pipe: `uskn-harness` runs outside the sandbox only when it
comes first.

```bash
uskn-harness sandbox-allow-host gl.example.test
```

Exit 2 means the value was refused (empty, a `*`, or a URL): report the message.

### 4. Report

Run `uskn-harness sandbox-allow-host --list` and show the lines marked `machine`. Say that the change applies to new
sessions.

## Example

`curl -sI https://gl.example.test` failed in the sandbox with `resolved to one of this host's addresses`, and you
suggested `/sandbox-allow-host gl.example.test`. The user types `/sandbox-allow-host https://gl.example.test/api/v4`.
The host name is `gl.example.test`. You run `uskn-harness sandbox-allow-host gl.example.test` on its own, then
`--list`, and report: "Sandboxed commands on this machine can now reach `gl.example.test` (machine). New sessions use
it."
