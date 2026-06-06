# G016 Studio Controller Prototype

Status: prototype, not production worker.

Question: can a host-side controller own Studio lifecycle, MCP targeting, Rojo
serving, screenshots, and profiling without relying on agentic UI clicking?

## Research Summary

The strongest pattern is a hybrid:

1. Asset/search MCP remains the asset brain: finding, ranking, inventorying, and
   reusing Creator Store assets.
2. `run-in-roblox` style coded worker for lifecycle: copy/build a place, write a
   temporary plugin or session bridge, launch Studio, stream output, then close
   only the worker-owned process.
3. Built-in Roblox Studio MCP for target selection and richer tool access:
   `list_roblox_studios` and `set_active_studio` solve the stale DataModel
   problem better than the older shared-port Rust Studio bridge.
4. Rojo as a worker-owned subprocess: start `rojo serve` on a known port and
   make the Studio-side plugin/session bridge connect to that port.
5. rbx-dom/Lune/Rojo build for file creation and mutation outside Studio.
   Studio remains the renderer/playtest verifier, not the primary serializer.

Sources:

- Roblox Studio MCP docs: <https://create.roblox.com/docs/studio/mcp>
- Studio CLI docs: <https://create.roblox.com/docs/studio/command-line-interface>
- Roblox external tools / Rojo docs: <https://create.roblox.com/docs/projects/external-tools>
- Place files docs: <https://create.roblox.com/docs/projects/place-files>
- `rojo-rbx/run-in-roblox`: <https://github.com/rojo-rbx/run-in-roblox>
- `Roblox/studio-rust-mcp-server`: <https://github.com/Roblox/studio-rust-mcp-server>
- `rojo-rbx/rojo`: <https://github.com/rojo-rbx/rojo>
- `rojo-rbx/rbx-dom`: <https://github.com/rojo-rbx/rbx-dom>

## Prototype Command

`tools/studio_controller_prototype.mjs` is intentionally disposable. It exposes
one importable `StudioControllerPrototype` class and a small CLI:

```sh
node tools/studio_controller_prototype.mjs research
node tools/studio_controller_prototype.mjs env
node tools/studio_controller_prototype.mjs build-place
node tools/studio_controller_prototype.mjs start-rojo
node tools/studio_controller_prototype.mjs start-studio
node tools/studio_controller_prototype.mjs select-studio
node tools/studio_controller_prototype.mjs isolate-desktop
node tools/studio_controller_prototype.mjs mcp-probe
node tools/studio_controller_prototype.mjs rojo-sync-probe
node tools/studio_controller_prototype.mjs profile
node tools/studio_controller_prototype.mjs close-studio
node tools/studio_controller_prototype.mjs session --dry-run
```

Full smoke:

```sh
node tools/studio_controller_prototype.mjs session \
  --isolate-desktop \
  --dismiss-startup-blockers \
  --connect-rojo \
  --dismiss-stale-rojo \
  --startup-passes 5 \
  --wait-ms 12000 \
  --profile-ms 8000
```

The demo writes:

- `.omx/studio-controller-prototype/manifest.json`
- `.omx/studio-controller-prototype/profile.json`
- `.omx/studio-controller-prototype/demo-report.json`
- `.omx/studio-controller-prototype/rojo.log`
- `.omx/studio-controller-prototype/studio.log`

Other prototype scripts should import this class instead of creating their own
MCP transport. `studio_worker_capture_batch.mjs` now uses the same controller
for `tools/list`, Luau execution, and screenshot calls, so MCP target selection,
timeouts, command fallback, and future persistent-client work have one place to
land.

## What It Measures

- startup command latency;
- Rojo port readiness;
- MCP tool-list latency;
- MCP `list_roblox_studios` / `set_active_studio` target selection;
- MCP `execute_luau` or `run_code` round-trip and reached `game.Name`;
- worker-owned Studio pid, CPU, memory RSS, and MCP process count;
- macOS Accessibility/System Events window visibility.
- macOS full-screen Space isolation before screenshot/OCR capture.

## Desktop Isolation

The worker should not capture the shared desktop. A shared-desktop screenshot can
read Codex text, browser panes, or other windows and produce false startup
blockers. The prototype supports:

```sh
node tools/studio_controller_prototype.mjs demo --isolate-desktop
```

On macOS this is implemented by activating the worker-owned Studio process and
toggling `control-command-f`, which moves Studio into a full-screen Space.
macOS does not expose a stable public command-line API for creating and
assigning Spaces, so full-screen Studio is the least-brittle isolation path. OCR
and click actions activate Studio again immediately before capture/action.

The Rojo connect prompt is also port-gated. The worker extracts
`localhost:<port>` from OCR and only clicks `Connect` when that port matches the
worker-owned Rojo port in the manifest. A stale Rojo prompt from another server
is reported as `rojo_connect_skipped`.

## MCP Target Selection

Before any Luau execution, the prototype now lists Studio instances and sets the
active target explicitly:

```sh
node tools/studio_controller_prototype.mjs select-studio \
  --expected-place prototype-place.rbxl
```

Selection priority is:

1. `--studio-id`, when provided;
2. exact expected place basename, such as `prototype-place.rbxl`;
3. the only open Studio instance;
4. an already-active Studio instance as a last fallback.

`mcp-probe` uses the same path before calling `execute_luau`, then records
`targetMatch` from the returned `game.Name`.

## Current Design Decision

Do not click Studio UI as the main control path. The production worker should
use a coded session bridge:

1. build/copy a scratch `.rbxl`;
2. launch Studio with the scratch place;
3. connect via built-in MCP and select the intended Studio instance;
4. isolate Studio into a full-screen macOS Space before visual capture;
5. start a local Rojo server;
6. use a Studio plugin or `run_code` bootstrap to connect Rojo;
7. run import/camera/screenshot/playtest batches;
8. save/close/reopen/audit;
9. kill only pids recorded in the worker manifest.

MCP enablement itself is still a Studio setting according to the official docs:
Assistant -> Manage MCP Servers -> Enable Studio as MCP server. The coded bot
can verify and use MCP once enabled, but it should not depend on visual clicking
to toggle that setting for every run.

## Latest Prototype Evidence

The built-in MCP path is now the default for `tools/studio_mcp_call.js`; the old
Rust Studio MCP server remains available through `STUDIO_MCP_COMMAND`. This does
not deprecate the asset/search MCP; asset search remains the upstream asset
brain, while StudioMCP is the viewport/control worker.

Live scratch run on `prototype-place.rbxl`:

- `list_roblox_studios` found one Studio id,
  `4d224f07-1169-4567-9bb7-966820384d60`.
- `set_active_studio` selected that id by expected place name.
- `execute_luau` returned `game.Name == "prototype-place.rbxl"`.
- `mcp-probe` recorded `targetMatch: true`.
- clearing the JSON-RPC response timer dropped per-call latency from the
  artificial timeout cliff (`~45s`) to roughly `160-235ms` for tool list,
  Studio list, active selection, state, and Luau readback.
- `studio_worker_capture_batch.mjs` used the built-in adapter
  `execute_luau` / `screen_capture` and produced one viewport screenshot with
  zero temp artifacts.
- `startup-blockers --startup-passes 5 --dismiss-startup-blockers
  --dismiss-stale-rojo` cleared Auto-Recovery in two passes using an
  Accessibility click on the `Ignore` button.
- `studio_worker_capture_batch.mjs` now OCR-audits the actual saved screenshot
  and reports `uiBlockers`; a visible stale Rojo prompt produced
  `uiBlockerCount: 1` with `kind: "rojo_connect"` and `port: 34872`.
- `StudioControllerPrototype` is now import-safe and provides the shared MCP
  adapter used by `studio_worker_capture_batch.mjs`; importing it does not run
  the CLI.
- `session --dry-run` emits the whole build/Rojo/Studio/isolation/blocker/MCP/
  profile/capture/cleanup plan without launching Studio.
- Live `session` run on scratch `prototype-place.rbxl` passed end-to-end:
  build, worker Rojo on `34913`, Studio launch, full-screen Space isolation,
  Auto-Recovery ignore, stale Rojo dismiss, `targetMatch: true`, profile,
  one `screen_capture`, `uiBlockerCount: 0`, `tempArtifactCount: 0`, and
  manifest-owned Studio/Rojo cleanup. Evidence:
  `.omx/studio-controller-live-smoke-20260606T014640/session-report.json`.
- `tools/studio_mcp_call.js` now waits for its `StudioMCP --stdio` child to
  exit; one-shot `tools/list` smoke returned 26 tools without increasing the
  StudioMCP process count.
- `rojo-sync-probe` now writes a temporary ModuleScript under
  `src/ReplicatedStorage/Shared`, polls Studio through MCP for that exact token,
  removes the file, and records whether both add and delete synced.
- Live strict Rojo sync run on scratch `prototype-place.rbxl` did **not** pass:
  `.omx/studio-controller-rojo-sync-live-20260606T015748/rojo-sync-probe.json`
  reached the correct DataModel, but the sentinel stayed absent for all six
  polls. Startup OCR only saw the stale `localhost:34872` Rojo prompt, dismissed
  it, and never observed a worker-owned `localhost:34915` prompt. This proves
  the current controller can launch, target, clear UI, profile, capture, and
  clean up, but cannot yet honestly claim worker-owned Rojo acceptance.

Known capture gate: built-in `screen_capture` can still include Studio UI
overlays such as Rojo connection prompts. Startup/UI blockers must be cleared or
explicitly accepted as evidence blockers before asset-family screenshots count.
The capture wrapper is the final authority because it audits the image that will
be used as evidence, not just the desktop preflight screenshot.

Known Rojo gate: Rojo's Studio plugin starts a session from the plugin UI
`Connect` action or from plugin auto-reconnect settings. Current live evidence
shows the reminder can be stale and tied to the old default `34872` server. The
worker must either control the Rojo plugin state directly or launch in a clean
Studio/plugin state where the worker-owned port prompt appears and the sentinel
sync probe passes.

## Next Absorb Step

If the prototype is accepted, absorb it into a non-prototype
`StudioWorkerController` with:

- persistent JSON-RPC MCP client instead of one-shot subprocess calls;
- explicit `list_roblox_studios` / `set_active_studio` target selection;
- Mac full-screen Space isolation as a first-class capture precondition;
- a worker session plugin for Rojo connect and scripted save;
- strict Rojo sentinel add/delete sync proof after any claimed Connect action;
- screenshot batch integration with `studio_worker_capture_batch.mjs`;
- hard fail when accessibility, MCP target, or resource budget checks fail.
