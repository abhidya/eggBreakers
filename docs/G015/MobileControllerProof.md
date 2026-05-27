# G015 Mobile Controller Proof

Status: BLOCKED

| Requirement | Status | Evidence |
|---|---|---|
| touch hatch | BLOCKED | MCP keyboard/controller input exists, but no physical mobile/touch emulator run was completed. |
| mobile eat/drink/interact button | BLOCKED | Source/UI tests exist; runtime touch proof missing. |
| mobile attack button | BLOCKED | Source/UI tests exist; runtime touch proof missing. |
| mobile sprint button | BLOCKED | Source/UI tests exists; runtime touch proof missing. |
| mobile call button | BLOCKED | Source/UI tests exist; runtime touch proof missing. |
| controller hatch/interact/attack | BLOCKED | No attached controller/device proof completed. |
| UI readable on small screen | BLOCKED | No screenshot/device viewport proof completed. |

Simulated/source coverage only: `MobileControlsController.lua`, `ClientBootstrap.client.lua`, `InputController.lua`, `MobileControlsTests.client.lua`, and `ClientInputTests.client.lua` exist. This is not sufficient for PASS under G015.
