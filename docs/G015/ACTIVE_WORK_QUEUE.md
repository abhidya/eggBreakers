# G015 Active Work Queue

Status values: TODO / IN_PROGRESS / FIXED / RETRYING.

Task ID: G015-US01-VISIBLE-DINO
User Story: US01 Hatch from egg / US02 Dinosaur visual + diet identity
Failure: Player can hatch, but cannot see the dinosaur after hatching.
Root Cause: `CharacterVisualBootstrap.client.lua` hid every non-root BasePart in the character, including server-attached imported dinosaur parts under `_EggBreakersCharacterVisual`. Server avatar hiding had the same unsafe behavior if called after visual attachment.
Fix Strategy: Make avatar-hiding skip imported game visual descendants and add regression coverage that visible imported dinosaur parts remain visible.
Files/Studio Objects To Change: `src/StarterPlayer/StarterPlayerScripts/CharacterVisualBootstrap.client.lua`, `src/ServerScriptService/Services/CharacterVisualService.lua`, `src/ServerScriptService/Tests/Integration/CharacterVisualServiceTests.lua`, active Studio character visual parts.
Test To Run First: Live Play mode hatch visual probe: count visible BaseParts under `_EggBreakersCharacterVisual` after hatch.
Broader Gate To Run After: Source syntax, Rojo build, live E2E user-story matrix.
Status: FIXED
Owner Agent: leader

Task ID: G015-LIVE-E2E-MATRIX
User Story: All user stories
Failure: No complete live Play-mode E2E matrix proving game playability.
Root Cause: Prior reports relied on source/edit-mode tests and partial smoke evidence.
Fix Strategy: Build and run live Studio probes for hatch, visible dino, movement, eat, drink, combat, death/respawn, group/call, nesting, city/fossil, mobile controls.
Files/Studio Objects To Change: TBD per failing probe.
Test To Run First: Live Play-mode hatch + visible dino + movement probe.
Broader Gate To Run After: Full live matrix and fresh TestRunner.
Status: TODO
Owner Agent: unassigned

Task ID: G015-UI-BUTTONS
User Story: US13 Client UI/mobile controls
Failure: UI/buttons are ugly and not proven usable.
Root Cause: Current UI uses raw default rectangular buttons with weak layout/touch affordance and limited E2E assertions.
Fix Strategy: Refresh DESIGN.md, style/rebuild controls with clear large buttons, labels, focus/touch states, and add client/live probes.
Files/Studio Objects To Change: `DESIGN.md`, `UIFactory.lua`, `HatchUIController.lua`, `MobileControlsController.lua`, client tests.
Test To Run First: Client UI structure/readability probe.
Broader Gate To Run After: Live mobile/control proof.
Status: TODO
Owner Agent: unassigned
