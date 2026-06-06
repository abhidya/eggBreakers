# G016 Studio Preview Inspections

Status: inspection evidence only, not release credit.

Preview inspections use StudioMCP as a clean lab for queued assets when direct
Asset Delivery is unavailable. A previewed asset counts only after it is
delivered/imported as real model geometry, saved into a persisted `.rbxl`,
cleaned, and accepted by `tools/g016_place_gate_audit.luau`.

| Date | Asset ID | Queue slot | Result | Cleanup | Release credit |
| --- | --- | --- | --- | --- | --- |
| 2026-06-06 | `70617428` | `beat6.redstone_canyon.rocks` | StudioMCP `preview_asset` inserted `Preview_70617428`; model summary reported `1` visible `Part`, `2` total descendants, `4 x 4 x 4` studs, and no scripts in the preview summary. Asset-search inspection memory records `basePartCount=1`, `scriptCount=0`, `hasScripts=false`, `anchoredCapable=true`, `screenshotVerdict=not_reviewed`, `visualRiskScore=4`. | `run_code` cleanup removed `1` `Preview_70617428`; follow-up scan reported `G016PreviewRemaining count=0`. | No. Screenshot capture failed because the Studio window was not found, the active Studio place was `eggBreakers4.rbxl`, and the asset was not saved into `eggBreakers7.rbxl` or any new persisted candidate. |

## Current Constraint

StudioMCP is reachable, but the active place reported `name="eggBreakers4.rbxl"`
and `PlaceId=0`. Previous save/reopen probes show `game:SavePlace()` is not
valid for this local place id, so preview inspections cannot satisfy the final
RBXL persistence gate by themselves.
