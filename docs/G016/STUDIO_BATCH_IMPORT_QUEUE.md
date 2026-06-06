# G016 Studio Batch Import Queue

Status: automation ready, not release credit.

`tools/g016_studio_batch_import_queue.mjs` turns the acquisition queue into a
guarded StudioMCP import lane. It refuses to run against the wrong active
Studio place, defaults to read-only dry-run, and requires `--apply` before it
loads missing assets with Studio `game:GetObjects`.

## Commands

Compile the generated Studio command without executing it:

```sh
node tools/g016_studio_batch_import_queue.mjs --compile-only --dry-run --start 1 --limit 3 --expected-place eggBreakers7.rbxl
```

Dry-run the first queue rows against the active Studio session:

```sh
node tools/g016_studio_batch_import_queue.mjs --dry-run --start 1 --limit 3 --expected-place eggBreakers7.rbxl
```

Apply a small batch only after StudioMCP reports the active place is
`eggBreakers7.rbxl`:

```sh
node tools/g016_studio_batch_import_queue.mjs --apply --start 1 --limit 5 --expected-place eggBreakers7.rbxl
```

## Release Policy

An apply run imports real Studio-loaded geometry into
`ReplicatedStorage.ImportedAssetLibrary`, strips imported scripts, anchors parts,
stamps queue/source metadata, and records
`WorldAssetVerificationStatus=imported_geometry_needs_clean_spot_screenshots`.

It still does not prove G016 complete. After every applied batch:

1. Save the local `.rbxl` candidate through a Studio control lane.
2. Close/reopen that persisted file.
3. Run `lune run tools/g016_clean_place_candidate.luau`.
4. Run `lune run tools/g016_place_gate_audit.luau`.
5. Do not set `RBXLPersistencePassed`, `US14LiveProofPassed`,
   `US15LiveProofPassed`, or `finalG016Pass` until the reopened file proves the
   full gate.

## Current Observation

On 2026-06-06, compile-only validation passed, but dry-run refused the active
MCP target because StudioMCP was attached to `eggBreakers4.rbxl`, not
`eggBreakers7.rbxl`. The enriched preflight now also reports local Studio
processes, which showed that an `eggBreakers7.rbxl` process existed but was not
the DataModel receiving MCP commands:

```json
{
  "ok": false,
  "placeName": "eggBreakers4.rbxl",
  "expectedPlace": "eggBreakers7.rbxl",
  "schema": "g016-studio-batch-import/v1",
  "placeId": 0,
  "error": "wrong_place",
  "apply": false,
  "mcpTargetMatchesExpectedPlace": false,
  "localStudioProcessSummary": {
    "expectedPlaceProcessCount": 1,
    "robloxStudioProcessCount": 2,
    "studioMcpProcessCount": 5
  }
}
```

No assets were imported by that refused run.

When this happens, do not force `--apply`. First reduce Studio to one intended
candidate process or otherwise reconnect StudioMCP so the dry-run reports
`mcpTargetMatchesExpectedPlace=true`.
