# G018 Publish Blocker Scan — Asset ID 9922699889

Scan time: 2026-05-27 worker shell.

## Commands Run

```bash
grep -RIl --exclude-dir=.git --exclude='*.rbxl' '9922699889' . /Users/abdulrehmanbhidya/PycharmProjects/eggBreakers/.omx/context /Users/abdulrehmanbhidya/PycharmProjects/eggBreakers/.omx/ultragoal 2>/dev/null | sort || true
for f in eggBreakers.rbxl eggBreakers2.rbxl; do printf '%s:' "$f"; strings "$f" | grep -F '9922699889' | wc -l; done
grep -RIn '9922699889' src/ReplicatedStorage/Shared/AssetManifest.lua docs .omx/*.md 2>/dev/null || true
```

## Result

| Surface | Result |
| --- | --- |
| Repo/source/docs text scan | Only leader context note mentions `9922699889`; no source/manifest/doc release reference found before this report. |
| `eggBreakers.rbxl` strings scan | 0 matches. |
| `eggBreakers2.rbxl` strings scan | 0 matches. |
| `AssetManifest.lua` scan | 0 matches. |

## Limitation

This is a local byte/string scan, not a Studio instance-tree publish audit. It supports the current blocker-removal evidence but does not replace a fresh Studio/RBXL save-reopen/publish-blocker audit before release.
