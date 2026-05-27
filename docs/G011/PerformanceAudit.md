# G011 Performance Audit

- Decorative/foliage assets remain non-gameplay by default: no imported touch/query/collision behavior is enabled by manifest classification.
- `PerformanceAuditService` continues to cap decorative collision, imported touch, particle emitters, and NPC counts.
- Manifest entries record `PerformanceNotes` for collision/query/touch audit at import.
- Full-map terrain underlay is a single terrain fill operation plus route/biome overlays, avoiding many collidable baseplate parts.
