---
name: set-workspace-theme
description: Give this VS Code workspace a window.title with an icon and a color theme far in hue from the other open windows. Use when the user wants VS Code windows told apart or a workspace color-coded.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, AskUserQuestion
---

# set-workspace-theme

With several VS Code windows open, the user loses track of which is which. This skill sets two values on the current
workspace: `window.title`, led by an icon, and `workbench.colorTheme`, a theme whose hue sits far from the other open
windows. The order is always **propose, hear the user, write**. A value the user answers in place of the proposal is
the value written.

## Where the values go

The workspace settings, never the user settings. The workspace's shape decides the file:

| Workspace | File | Where in the file |
| --- | --- | --- |
| Single folder | `<workspace>/.vscode/settings.json` | top level |
| Multi-root | `<name>.code-workspace` | inside the `settings` object |

- Multi-root: a folder's `.vscode/settings.json` is ignored for these two keys. Both are window-scoped, and only the
  user settings and the `.code-workspace` file accept window-scoped keys. Write them to the `.code-workspace` file.
- `workbench.colorTheme` takes the theme's `id`, not its label. A language pack translates labels
  (`Dark Modern` becomes `ダーク モダン`), and a label written as the value is silently ignored. Use the `settingsId`
  the script in step 1 reports.

A save applies at once, without a reload. In Restricted Mode, VS Code does not apply `workbench.colorTheme`.

## Steps

### 1. Collect the facts

```bash
python3 ~/.claude/skills/set-workspace-theme/scripts/vscode-workspace-env.py
```

Pass a workspace path to aim it elsewhere; the default is the current directory. It prints JSON:

| Key | Content |
| --- | --- |
| `target` | where to write: `kind` (`folder` / `workspaceFile`), `settingsFile`, `settingsKeyPath`, and the current `currentWindowTitle` / `currentColorTheme` |
| `otherWindows` | the other open windows and the theme each one shows |
| `takenColors` | background colors the other windows already use (`hue` / `neutral`) |
| `suggestions` | candidate themes, farthest hue first, with themes unfit for a background already removed |
| `themes` | every installed theme (`settingsId` / `bg` / `hue` / `chroma` / `luma` / `unsuitable`) |

A `note` on `target` means no open window matched, which happens right after a window opens, before VS Code's state
file catches up. Treat the workspace as a single folder, and confirm the target path with the user before writing.

A window whose `remote` is `ssh-remote+<host>` has a `settingsFile` of `null`: this machine cannot read its settings,
so its color is missing from the overlap check. Mention that when the top candidates are close.

### 2. Learn what the workspace is for

The icon and the name rest on it. Skim the README, `CLAUDE.md` or `AGENTS.md`, `package.json`, and `git remote -v`
until you can say in a few words what the workspace is for. When `window.title` already has a value, build on it:
adding an icon to the user's title lands better than replacing it.

### 3. Draft the window.title

- One icon (an emoji) first, a space, then the name. The point is telling windows apart in the tab bar and the
  window switcher, so pick an emoji that suggests the content: `⚙️ dotfiles`, `📦 <library>`, `🧪 sandbox`,
  `🚀 production`, `📝 docs`.
- The default shape is `<icon> <name>${separator}${activeEditorShort}`: the edited file shows and the icon stays.
- When the user asked for no icon, leave the icon out of every draft.
- Useful variables: `${activeEditorShort}`, `${activeEditorMedium}`, `${rootName}`, `${folderName}`, `${separator}`,
  `${dirty}`, `${remoteName}`, `${appName}`. An empty variable takes its neighboring `${separator}` with it, so a
  row of them never leaves a dangling separator.

### 4. Draft the colorTheme

The first entry of `suggestions` is the first candidate. Weigh:

- `hueDistance`: the angle to the nearest hue in use; larger means less overlap. `-1` means the other windows already
  use a neutral theme, so this neutral one overlaps them.
- `unsuitable`: why a theme fails as a background (too saturated, too bright, too dark). Propose only themes where it
  is empty. `suggestions` is already filtered; check it when picking from `themes` directly.
- `uiTheme`: `vs-dark`, `vs` (light), or `hc-*` (high contrast). Match the brightness family of the theme in use, so
  someone working in a dark theme is offered a dark one.

The background, title bar, and activity bar tell windows apart; syntax colors do not. A theme with a low `chroma`
(Monokai and One Dark have a near-gray background) does nothing for this even with vivid syntax colors. Treat
`neutral: true` as unfit for telling windows apart by color.

An empty `takenColors` means nobody set a theme and every window shows the VS Code default. Any colored theme then
stands apart, so choose one that fits the workspace.

When the hues are used up because many windows are open, say plainly that the N open windows cannot all be kept
apart, and offer the best available candidate.

### 5. Propose both at once

Call `AskUserQuestion` once, with two questions: `window.title` and `workbench.colorTheme`.

- Put the recommended draft first in each question and end its label with `(Recommended)`.
- For the theme options, use the `settingsId` as the label. In the `description`, give the background color, the hue,
  and which open windows it stays apart from, so the user can picture it.
- When the user answers Other with a theme name, look for the same `settingsId` in `themes`. With no match, list the
  closest ones and ask again: VS Code ignores a theme that is not installed without a word.

### 6. Write

Edit the file in `settingsFile` under `target`, creating `.vscode/` when the file does not exist. Change an existing file with `Edit` and
the smallest diff, so its comments and formatting survive.

`kind: "folder"`: two keys at the top level.

```json
{
  "window.title": "⚙️ dotfiles${separator}${activeEditorShort}",
  "workbench.colorTheme": "Solarized Dark"
}
```

`kind: "workspaceFile"`: two keys inside `settings` (add `settings` after `folders` when it is missing).

```json
{
  "folders": [{ "path": "." }],
  "settings": {
    "window.title": "⚙️ dotfiles${separator}${activeEditorShort}",
    "workbench.colorTheme": "Solarized Dark"
  }
}
```

The values come from steps 3 and 4; the blocks above show the shape.

### 7. Check and report

- Run the step 1 script again and confirm that `currentWindowTitle` and `currentColorTheme` under `target` hold the
  new values.
- Ask the user whether the title bar and the colors changed. When they did not, suspect in this order: Restricted
  Mode, the spelling of the `settingsId`, a multi-root workspace written on the folder side.
- A `.vscode/settings.json` inside a repository shows up in its git diff. Ask the user whether to commit it; the commit
  is theirs to decide.

Done when the script reports both values and the user has seen the change, or has the next thing to check.
