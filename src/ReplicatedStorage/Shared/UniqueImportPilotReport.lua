local UniqueImportPilotReport = {}

UniqueImportPilotReport.TaskId = "7"
UniqueImportPilotReport.Worker = "worker-2"
UniqueImportPilotReport.RecordedAtUtc = "2026-05-27T05:13:00Z"
UniqueImportPilotReport.Scope = "Studio MCP write-enabled pilot for real unique Creator Store source asset IDs."

UniqueImportPilotReport.Summary = {
    SuccessfulPrimaryImports = 15,
    UniquePrimarySourceAssetIds = 15,
    NewPrimaryIdsVersusExistingManifestSourceSets = 12,
    FailedInsertions = 1,
    MetadataSetterAvailable = false,
    ScriptInspectionAvailable = false,
    Notes = "Studio MCP insert_from_creator_store returned real numeric asset IDs and inserted primary assets into the open Studio session. The exposed MCP surface does not provide a setter for SourceAssetId/CreatorStoreOnly attributes or a model tree/script inspector for imported asset contents.",
}

UniqueImportPilotReport.PrimaryImports = {
    { Query = "jungle tree pack", SearchId = "0f94192e-5ddf-4239-b1c3-47dd3e67a5ac", InsertGuid = "a978d4eb-7064-431c-af91-acc6a0328d62", SourceAssetId = "107692847452014" },
    { Query = "swamp tree pack", SearchId = "23af4396-9823-4426-bfeb-608d7c1a4e6c", InsertGuid = "2dc1afb3-b4c2-4b93-a0f3-dfc1973764d0", SourceAssetId = "12598461005" },
    { Query = "rock cliff canyon", SearchId = "c60d10b2-b1a0-482a-b65c-00b43526240c", InsertGuid = "7956e8db-5866-4e69-b952-a37cb98dc20d", SourceAssetId = "80786476505187" },
    { Query = "city ruins debris", SearchId = "66390829-9fe6-4d4d-a2b0-f3380586950c", InsertGuid = "0f1ae037-a177-4445-8040-46969d5d6afe", SourceAssetId = "74103818945018" },
    { Query = "wrecked car apocalypse", SearchId = "ba192ebf-b39d-4840-9ae6-dd2083d14513", InsertGuid = "2645466b-fa02-4e87-af9c-de9362f1112a", SourceAssetId = "111614048167471" },
    { Query = "dinosaur bones fossil", SearchId = "55495c0e-9f48-4343-90f4-3006490ed295", InsertGuid = "1ad122f7-09c8-4c27-8925-c9601318755a", SourceAssetId = "137420276606883", AlreadyInManifest = true },
    { Query = "prehistoric plants fern", SearchId = "f31504ab-aaac-4810-9405-733d6e803db1", InsertGuid = "9c31571b-2146-4c67-b5d8-fa05bbba8464", SourceAssetId = "4536575513", AlreadyInManifest = true },
    { Query = "mushroom forest pack", SearchId = "b48e850c-2d2e-4775-b8ec-70988b7ad632", InsertGuid = "943f13fa-3e84-493d-b53b-20ede6279433", SourceAssetId = "5845551036" },
    { Query = "fallen log forest", SearchId = "561e3096-758f-4ee8-b898-9ed6cd71da10", InsertGuid = "ed706731-5036-4c44-bd21-cad99d6930a8", SourceAssetId = "16201102729", AlreadyInManifest = true },
    { Query = "dinosaur nest", SearchId = "186f0917-80c7-474d-acc9-96b1b558918f", InsertGuid = "a39fc156-e3b4-439c-bd54-6d2f6064761e", SourceAssetId = "8895193" },
    { Query = "volcano rocks lava", SearchId = "3493a011-fe8c-4e83-a110-651a97f9c3a4", InsertGuid = "84489585-ac29-487e-a529-d8bf4321e7fd", SourceAssetId = "110082641596723" },
    { Query = "jungle vines", SearchId = "fd20783f-8d78-42ef-8d02-c1925f26cf40", InsertGuid = "b6e727a4-94b1-4cab-b7bf-fc0a0d0dc31d", SourceAssetId = "75686678415376" },
    { Query = "boulder rock pack", SearchId = "961c290e-108b-482c-85cb-5c93db235818", InsertGuid = "e699ba0b-0acb-451b-bfaa-c4f601a84697", SourceAssetId = "97115138298077" },
    { Query = "ancient ruins jungle", SearchId = "6398e7f1-0b36-470a-8319-b01538df1e90", InsertGuid = "18383fd8-6bfe-40fc-8c43-f3ea30aeecbe", SourceAssetId = "138397836874560" },
    { Query = "tropical flowers pack", SearchId = "98f5cd8a-e120-4b72-9cce-c8244adbf6ae", InsertGuid = "3a0482c3-2861-46ef-9efc-ca299dff6f91", SourceAssetId = "16574480849" },
}

UniqueImportPilotReport.FailedInsertions = {
    { Query = "pond water nature", SearchId = "d9741f47-805c-4244-9892-a53e6ad8253c", Error = "Target is not reachable (CreatorStoreInsertTool_insertFromMarketplaceAsync)" },
}

UniqueImportPilotReport.ToolLimits = {
    "insert_from_creator_store mutates Studio by inserting only the primary result; secondary IDs are returned as strings but cannot be directly inserted by this MCP surface.",
    "No exposed Studio MCP method can set SourceAssetId or CreatorStoreOnly attributes on inserted instances after insertion.",
    "No exposed Studio MCP method can enumerate the inserted model tree or inspect/remove imported scripts; script preservation/audit requires Studio-side explorer/script tooling beyond this MCP surface.",
    "Parallel insertion can race with play/edit mode; several attempted calls failed with 'Unable to insert models from the marketplace in play mode' until play was stopped and calls were retried.",
}

return UniqueImportPilotReport
