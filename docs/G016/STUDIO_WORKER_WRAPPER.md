# G016 Studio Worker Wrapper

Status: v0 capture wrapper ready, not release credit.

Roblox Studio should be treated as a controlled render-and-validation worker,
not as the only build engine. The fast loop remains headless with Rojo, Lune,
rbx-dom-style file parsing/writing, manifests, and gate audits. Studio enters
only when the skills require viewport evidence: asset-family clean-spot
screenshots, live player-height screenshots, playtest state checks, UI review,
and final save/reopen validation.

## Headless Boundary

There is no reliable pure-headless Studio renderer in the current workflow.
Roblox's documented command line launches Studio with special startup behavior
such as opening a place or script, and the documented external-tools workflow
expects Rojo to sync through the Studio plugin. That gives us automation hooks,
but screenshots still require a renderable Studio session.

The practical design is:

1. Build and mutate files outside Studio whenever possible.
2. Launch or attach to exactly one intended Studio DataModel.
3. Move worker-owned Studio into a full-screen macOS Space before screenshot/OCR.
4. Gate every MCP action on `game.Name`.
5. Gate Rojo prompt clicks on the worker-owned `localhost:<port>`.
6. Clear or record startup/UI blockers before asset-family screenshots.
7. Batch scripted camera moves and screenshot captures.
8. Save screenshots plus a machine-readable report.
9. Audit temporary validation names before ending the pass.
10. Save/reopen and run the offline place gate before claiming release credit.

References:

- Roblox Studio command line: <https://create.roblox.com/docs/studio/command-line-interface>
- Roblox external tools and Rojo: <https://create.roblox.com/docs/projects/external-tools>
- Roblox place file formats: <https://create.roblox.com/docs/projects/place-files>

## Wrapper

`tools/studio_worker_capture_batch.mjs` wraps StudioMCP tools into a single
capture batch. It supports the built-in Studio MCP tools
(`execute_luau`/`screen_capture`) and the older Rust MCP names
(`run_code`/`capture_screenshot`). It queries the active DataModel and refuses
to capture if the MCP command lands in the wrong place.

Current capabilities:

- active-place gate with `game.Name`;
- MCP adapter report naming the Luau and screenshot tools used;
- per-screenshot OCR audit for UI overlays such as Auto-Recovery and Rojo
  connect prompts;
- local Studio process summary for stale-target diagnosis;
- optional scripted camera pose per capture;
- optional `beforeLuau` and `afterLuau` per capture for clean-spot setup and
  teardown;
- sequential `screen_capture` or `capture_screenshot` calls written as JPEG/PNG
  files;
- `capture-report.json` with hashes, byte counts, camera poses, Studio state,
  process summary, screenshot UI blockers, and temp artifact count;
- temp-prefix audit for names such as `G016CleanSpot_`, `Preview_`, and
  `StudioWorkerTemp_`.

It does not launch, save, close, kill, or publish Studio yet. Those actions need
a session-owned Studio worker with unique MCP identity so we do not repeat the
stale DataModel problem found in `STUDIO_BATCH_IMPORT_QUEUE.md`.

`tools/studio_controller_prototype.mjs` is the companion lifecycle prototype. It
can build a scratch place, start worker-owned Rojo, launch Studio, move Studio
into a full-screen macOS Space, classify startup blockers from OCR, and close
only manifest-owned processes.

The capture wrapper now imports `StudioControllerPrototype` and uses its shared
MCP adapter instead of duplicating the MCP subprocess transport. This is the
first absorption step toward one host-side `StudioWorkerController` surface for
lifecycle, target selection, Rojo, capture, profiling, and cleanup.

The controller now has a `session` command for the full one-owner prototype
loop. `session --dry-run` prints the planned build, Rojo, Studio launch,
desktop isolation, startup-blocker pass, MCP probe, profile, capture batch, and
cleanup sequence. A live scratch session passed on
`.omx/studio-controller-live-smoke-20260606T014640`: it reached the expected
`prototype-place.rbxl` DataModel, cleared startup UI, captured one viewport
image with `uiBlockerCount: 0`, found zero temp artifacts, and closed the
manifest-owned Studio and Rojo pids.

The controller now also has a strict `rojo-sync-probe`. It creates a temporary
Rojo-mapped ModuleScript after Studio is open, polls the active DataModel for
that exact token through MCP, removes the file, and expects the deletion to sync
back out of Studio. The first live strict probe
`.omx/studio-controller-rojo-sync-live-20260606T015748` failed honestly:
Studio was targeted correctly, but only the stale `localhost:34872` Rojo prompt
appeared; the worker-owned `34915` server never synced the sentinel. This is the
remaining acceptance gap before Rojo can be treated as connected.

Follow-up live testing on
`.omx/studio-controller-live-test-20260606T060708Z` proved the launch and
visual path again: Studio opened in a full-screen macOS Space, Auto-Recovery was
ignored, the stale `localhost:34872` prompt was dismissed, MCP reached
`prototype-place.rbxl`, the capture report had `uiBlockerCount: 0`, and the
manifest-owned Studio/Rojo children were closed. The only failed step was strict
Rojo sentinel sync.

`tools/studio_controller_prototype.mjs rojo-port-diagnostics` now explains that
failure before and during the sentinel probe. Live diagnostic run
`.omx/studio-controller-live-diagnostics-20260606T061307Z` found worker Rojo on
`34879` healthy and owned by the worker, but Rojo's plugin default port `34872`
was already occupied by pre-existing pid `9660`. The next worker layer therefore
needs coded Rojo plugin host/port control or a clean default-port lease; it
should not simply click any visible Rojo prompt.

The prototype now includes the safe lease half of that decision. `start-rojo`
requires the spawned child pid to own the requested port, and
`--use-rojo-default-port` selects Rojo's plugin default `34872` without taking
over an existing server. If another process owns `34872`, the session records
the port diagnostic and stops before opening Studio. That keeps the worker
non-destructive while still giving us a direct live test path once the default
port is clean.

Lease verification:

- `.omx/studio-controller-port-lease-smoke` started worker Rojo on `34931`,
  proved the listener belonged to the worker pid, and closed it.
- `.omx/studio-controller-default-port-lease-fail` tried the plugin default
  `34872`, detected pre-existing pid `9660`, and stopped before Studio launch.
- `.omx/studio-controller-live-lease-regression` proved the stricter
  ownership check still supports the live launch/profile/cleanup path on the
  non-default worker port.

Rojo source review closed one tempting dead end: the plugin stores
`priorEndpoints`, but local file places have `PlaceId == 0`, and Rojo's
`ignorePlaceIds` table skips `0`. Pre-seeding prior endpoint metadata therefore
does not help scratch `.rbxl` workers. The controller now has
`rojo-ui-probe` to inventory native Studio menu/window surfaces for
`Rojo: Connect` plugin actions before a guarded coded trigger is attempted.
Live probe `.omx/studio-controller-rojo-ui-live-fast` exposed only the native
plugin menu item `Plugins > Rojo 7.6.1 > Rojo`; it did not expose a native
`Rojo: Connect` plugin action. The probe is now bounded to the Plugins menu with
a 15s timeout because broad native menu enumeration can hang.

The next viable branch is a worker-specific Rojo plugin build. The prototype can
now copy a local `rojo-rbx/rojo` checkout, patch the plugin default port and
label, inject edit-mode auto-connect, and build `CodexRojoWorker-<port>.rbxm`.
It can also install and remove only that manifest-owned local plugin path. Smoke
evidence in `.omx/studio-controller-rojo-worker-plugin-build` and
`.omx/studio-controller-rojo-worker-plugin-install-smoke` proves the artifact
builds and the install side effect is reversible without launching Studio.

Important capture finding: built-in `screen_capture` captures the Studio
viewport surface, but visible Studio overlays can still appear in the image. The
controller's startup-blocker pass must run before the asset-family capture pass,
and any remaining stale prompt is a blocker in the capture report. The wrapper's
top-level `ok` field is false when `uiBlockerCount > 0`, even if the screenshot
file was written successfully.

## Commands

Capture the current viewport once:

```sh
node tools/studio_worker_capture_batch.mjs \
  --expected-place eggBreakers7.rbxl \
  --capture-current \
  --out .omx/studio-worker-captures/smoke
```

Dry-run a plan without screenshots:

```sh
node tools/studio_worker_capture_batch.mjs \
  --expected-place eggBreakers7.rbxl \
  --plan docs/G016/studio-worker-capture-plan.example.json \
  --dry-run
```

Run a planned batch:

```sh
node tools/studio_worker_capture_batch.mjs \
  --expected-place eggBreakers7.rbxl \
  --plan docs/G016/studio-worker-capture-plan.example.json \
  --out .omx/studio-worker-captures/family-pass-001
```

Launch and isolate a scratch Studio worker:

```sh
node tools/studio_controller_prototype.mjs session \
  --isolate-desktop \
  --dismiss-startup-blockers \
  --connect-rojo \
  --dismiss-stale-rojo \
  --startup-passes 5
```

## Skill Gate Mapping

For `roblox-asset-inspection-lab`, one asset-family pass should generate a plan
with clean-spot front, back, left, right, overhead, and player-height captures.
The family fix Luau can live in `beforeLuau`, and the temp clone removal can
live in `afterLuau`. The report's temp audit must be zero before the family can
move toward signoff.

For `roblox-playable-space-review`, a map or quadrant pass should use planned
player-height camera positions and at least one reverse view from the player
path. The wrapper only captures evidence; the reviewer still decides pass,
fix, or blocker from the images.

For G016, screenshots are evidence but not release credit. After imports or
placement fixes, the place still needs:

1. saved local `.rbxl`;
2. closed and reopened candidate;
3. `lune run tools/g016_clean_place_candidate.luau`;
4. `lune run tools/g016_place_gate_audit.luau`;
5. a passing persisted gate before proof attributes are set.

## Next Worker Layer

The next script should own Studio lifecycle:

1. copy the target `.rbxl` into a worker sandbox;
2. launch `/Applications/RobloxStudio.app/Contents/MacOS/RobloxStudio` for that
   exact copy;
3. move Studio into a full-screen macOS Space before visual evidence capture;
4. wait for a unique MCP session token or port;
5. connect Rojo only when the prompt port/default-port diagnostic matches the
   worker manifest;
6. prove Rojo sync with a temporary source sentinel add/delete;
7. fail or quarantine the capture pass if startup/UI blockers remain visible;
8. run import/capture/playtest batches;
9. save, close, reopen, and audit;
10. kill only the Studio pid recorded in the worker manifest.

The asset/search MCP remains the asset discovery and inventory brain. The
Studio MCP path here is only the controlled render, edit, screenshot, and
playtest surface.
