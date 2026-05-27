# G016 Self Validation Rules

- No PASS from docs alone.
- No PASS from source-only tests for client-visible behavior.
- A story PASS needs required test categories plus fresh Studio/live proof when behavior is visible.
- Every FAIL maps to `ACTIVE_WORK_QUEUE.md`.
- G016FinalGate must fail until US01-US15 are PASS, mobile/controller proof exists, RBXL save/reopen proof exists, and releaseReadyVisibleAssets >= 500.
