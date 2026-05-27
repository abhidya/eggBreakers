# G015 Fix Until Pass Log

## 2026-05-27 — Visible dinosaur after hatch
- Gate: US01/US02 live hatch visual.
- Red evidence: live Play probe found `_EggBreakersCharacterVisual.DinosaurVisual` existed but imported visual BaseParts had `Transparency=1`, so the player could not see the dino.
- Fix: avatar-hiding now skips descendants of `_EggBreakersCharacterVisual` and imported/game visual descendants.
- Live green evidence: Studio Play hotfix probe reported 104/104 visual BaseParts visible and 16 default avatar parts hidden.
- Source checks: `luac -p`, `rojo build`, `git diff --check` passed.
- Next failing gate: full live user-story E2E matrix.
