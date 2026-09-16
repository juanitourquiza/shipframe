# ShipFrame Workflow for Herdr

Local MVP Herdr plugin for opening a ShipFrame-ready workflow pane without replacing ShipFrame.

## What it does

- Adds **Start ShipFrame workflow** to Herdr plugin actions.
- Detects the current git repository from Herdr context when available.
- Runs the read-only ShipFrame source-tree doctor (`./install.sh --doctor --repo-only`) when the active repo is the ShipFrame checkout.
- Opens a Herdr plugin pane with paste-ready ShipFrame instructions for Codex, Claude Code, or OpenCode.
- Adds **Open ShipFrame checklist** as a lightweight process checklist pane.

## What it does not do

- It does not merge, deploy, approve, or run destructive git commands.
- It does not modify global config.
- It does not replace ShipFrame skills, profiles, or installer behavior.

## Local development

From the ShipFrame repository root:

```bash
herdr plugin link ./herdr-plugin
herdr plugin action list --plugin shipframe.workflow
herdr plugin action invoke shipframe.workflow.start-workflow
```

If you only want the checklist:

```bash
herdr plugin action invoke shipframe.workflow.open-checklist
```

For future GitHub distribution, publish this plugin directory in a public repository or subdirectory with the `herdr-plugin` topic, then install with:

```bash
herdr plugin install owner/repo[/subdir]
```
