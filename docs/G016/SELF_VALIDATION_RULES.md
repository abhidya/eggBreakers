# G016 Self Validation Rules

- No PASS from docs alone.
- No PASS from source-only tests for client-visible behavior.
- A story PASS needs required source test categories plus fresh Studio/live proof when behavior is visible.
- Every FAIL maps to `ACTIVE_WORK_QUEUE.md`.
- `G016FinalGate` must fail until US01-US15 are PASS at the same time.
- `ReplicatedStorage.G016FinalGateProof` is the only final proof attachment point for server gate claims.
- `ReplicatedStorage.G016ClientProof` is the only client/mobile proof attachment point for client-visible control claims.
- Required proof attributes must be produced by a fresh Studio/live run, not static source defaults:
  - `US01LiveProofPassed` ... `US15LiveProofPassed` are all `true`.
  - `US01Status` ... `US15Status` are all `PASS`.
  - every story has concrete `US##Evidence`, `US##ObservedAt`, `US##ProofSource`, and `US##Milestone=G016FinalGate` metadata.
  - `FreshAllCategoryTestRunnerPassed=true`, milestone `G016FinalGate`, zero failures, and non-empty Client category.
  - `MobileControllerProofPassed=true` and `LiveE2EProofPassed=true`.
  - `RBXLPersistencePassed=true` with reopen audit timestamp.
  - `releaseReadyVisibleAssets >= 500` via `AssetImportAuditService:ValidateReleaseCounts(500)`.
- G015 evidence remains historical input only; G016 cannot inherit a G015 PASS.
