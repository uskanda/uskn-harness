---
name: cleanup
description: Stop the Claude Code processes started more than 2 hours ago, other than this session's, to free memory.
disable-model-invocation: true
allowed-tools: Bash
---

# cleanup: stop stale Claude Code processes

Linux only: memory comes from `free -h`, start times from the `lstart` column of `ps -eo pid,lstart,args`.

1. Show memory with `free -h`.
2. Note this session's own process, `$PPID`. It is never a target.
3. List the processes whose command line contains `anthropic.claude-code` and whose `lstart` is more than 2 hours
   ago, leaving out `$PPID`.
4. Send each listed process SIGTERM with `kill`. Two seconds later, send `kill -9` to any still running.
5. Show memory with `free -h` again.

Done when the report gives the number of processes stopped and the memory in use before and after.
