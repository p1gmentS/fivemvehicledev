# Reality Vehicle Lab Dev Repo

This repository is designed for Reality Vehicle Lab v0.2.0 Developer Sync.

## Branch

Use `chatgpt-dev` for changes that should flow into the local test server.

## Update manifest

`.rvl-update.json` is the only deployment manifest the Lab reads. Each entry may deploy one FiveM resource from `resources/<name>` to the local Lab's `data/resources/<name>` folder.

The Lab intentionally does **not** allow this updater to replace the launcher EXE, FXServer binaries, `server.cfg`, or `secrets.cfg`.

## Current built-in diagnostics

Inside FiveM:

- `/checkhydro` prints the current model hash, modkit, hydraulic mod count (type 38), and current hydraulic mod.
- `/sethydro` runs the same diagnostic and attempts hydraulic mod type 38 index 0 when available.
- `/moddump` prints populated mod slots 0-49 to F8, always including slot 38.

## Workflow

1. Commit a resource change to `chatgpt-dev`.
2. Open Reality Vehicle Lab's local dashboard.
3. Under **Developer Sync**, click **Pull & Apply**.
4. The Lab stages the resource, backs up the old copy, swaps it, then restarts only that resource.
5. On an apply failure, already-changed resources are rolled back automatically.
