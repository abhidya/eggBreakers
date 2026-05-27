# G011 Security Audit

- Imported runtime scripts are denied by default through manifest metadata: `ImportedScriptsPresent=false`, `ScriptsAudited=true`.
- Creator Store sources with script counts are marked `ScriptsRemoved` unless a future audited sandbox explicitly sets `Sandboxed`.
- Studio MCP probe `G011Probe_Tree` reported 14 embedded LuaSourceContainer instances; all 14 were removed before cataloging.
- `AssetAuditService:ValidateManifestReference` now rejects visible imported instances whose `SourceAssetId` disagrees with the manifest or whose imported scripts remain present.
