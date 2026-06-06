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
node tools/studio_controller_prototype.mjs demo \
  --isolate-desktop \
  --dismiss-startup-blockers \
  --connect-rojo
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
5. connect Rojo only when the prompt port matches the worker manifest;
6. fail or quarantine the capture pass if startup/UI blockers remain visible;
7. run import/capture/playtest batches;
8. save, close, reopen, and audit;
9. kill only the Studio pid recorded in the worker manifest.

The asset/search MCP remains the asset discovery and inventory brain. The
Studio MCP path here is only the controlled render, edit, screenshot, and
playtest surface.
