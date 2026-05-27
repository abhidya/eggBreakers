# G016 User Story Test Plan

Acceptance order:
1. Fix live core play loop: hatch -> readable dino -> diet cue -> food/water -> attack -> death -> sprint/call/hide.
2. Encode each failure as source + live E2E assertion.
3. Add G016 final gate that refuses PASS unless each story has required tests and live proof artifacts.
4. Keep US14 asset 500/500 as release blocker after playability is green.

Immediate retest commands:
- `find src -name '*.lua' -print0 | xargs -0 -n1 luac -p`
- `rojo build default.project.json --output /tmp/eggBreakers-g016.rbxl`
- Studio MCP Play-mode probes for UI buttons and server state.
