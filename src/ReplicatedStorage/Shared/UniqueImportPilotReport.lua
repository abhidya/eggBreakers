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


UniqueImportPilotReport.Task10Summary = {
    TaskId = "10",
    RecordedAtUtc = "2026-05-27T05:20:00Z",
    SuccessfulPrimaryImports = 16,
    UniquePrimarySourceAssetIds = 16,
    NewPrimaryIdsVersusTrackedReportAndManifest = 15,
    DuplicatePrimaryIdsVersusTrackedReportAndManifest = 1,
    Notes = "Continuation materialization batch run in Studio edit mode. All rows are primary IDs returned by insert_from_creator_store; secondary IDs remain catalog-only because this MCP surface cannot directly insert secondary IDs or set metadata attributes.",
}

UniqueImportPilotReport.Task10PrimaryImports = {
    { Query = "swamp reeds grass", SearchId = "18f20a05-1b50-4520-a8e0-c266d9619299", InsertGuid = "b80ea38e-2df8-4341-927d-8667b1cf8744", SourceAssetId = "78276962664856" },
    { Query = "mangrove roots swamp", SearchId = "66245bac-83ca-4aa7-b945-c926cc5fbfbf", InsertGuid = "64335961-bcae-4b6c-a906-10ae26caf60e", SourceAssetId = "130564329990740" },
    { Query = "canyon arch rocks", SearchId = "f46ab2ca-03dc-4f3b-be37-e1e67614fc7e", InsertGuid = "c12c4bff-d86e-4686-b579-c6cc54785efd", SourceAssetId = "10839876465" },
    { Query = "desert rock formation", SearchId = "1a734ce4-e390-4c6e-ac42-4dc2d4655f5a", InsertGuid = "99acea92-f69f-4a53-a8b2-ecc1d40e57b6", SourceAssetId = "2798025353" },
    { Query = "broken building rubble", SearchId = "3ec3c721-d751-46f7-8983-d49325588c7a", InsertGuid = "0ba68ea0-c60e-4681-8499-47a92852f3d2", SourceAssetId = "117818892065354" },
    { Query = "abandoned vehicle wreck", SearchId = "1cbdbb27-bdf7-4d2e-9ac4-84e9836a84c5", InsertGuid = "a86d8843-ab15-4ac6-9081-a1d1f2d5b352", SourceAssetId = "109905665910630" },
    { Query = "fossil skeleton dinosaur", SearchId = "0a3ddd22-c46a-4648-a378-903a4e767972", InsertGuid = "def2349a-3747-4f49-af11-b04a658a311d", SourceAssetId = "137420276606883", AlreadyInTrackedReportOrManifest = true },
    { Query = "forest vines hanging", SearchId = "9e55fe55-995a-4e00-892a-f1e40f2a1dc1", InsertGuid = "216778c8-6a9e-433c-9e99-770358e3c90a", SourceAssetId = "96041387484629" },
    { Query = "tree stump forest", SearchId = "fc59f98b-ba4b-47e2-9f09-8c5f9fdd4fa1", InsertGuid = "23c78624-a209-4ec0-a558-9feb1d59adf5", SourceAssetId = "117401257092974" },
    { Query = "mossy logs nature", SearchId = "0626662e-41b4-4889-9862-9f3bad9d9215", InsertGuid = "8cae9b40-2fae-4462-bcb3-01bffff73fbd", SourceAssetId = "72429568457235" },
    { Query = "city concrete debris", SearchId = "042380b7-b6ca-4685-abcf-1e7a2e614c10", InsertGuid = "8b0e1106-b377-46d4-bfb9-1e8f725a50f2", SourceAssetId = "14819176862" },
    { Query = "rusty car wreck", SearchId = "975e2519-e858-4eb8-b0e9-223c19af043d", InsertGuid = "0bcf9bd3-7765-4f41-b449-8133474b3154", SourceAssetId = "103158815948907" },
    { Query = "swamp lily pads", SearchId = "02e989d1-cc0d-454d-be71-ffd9fa5400fe", InsertGuid = "eeed6d8f-7749-463a-bdde-b64985bde8e7", SourceAssetId = "11920489445" },
    { Query = "fern bush jungle", SearchId = "038c9518-08eb-4eca-a307-9840312b3afb", InsertGuid = "b0d0afc1-d93f-40db-bf38-8a911c69f492", SourceAssetId = "8311854308" },
    { Query = "mountain cliff rocks", SearchId = "459c051e-abad-4af4-9962-460e4bf30176", InsertGuid = "6390bc86-2b95-4f25-abc5-94dd1909dfa9", SourceAssetId = "85814757483752" },
    { Query = "old stone arch ruins", SearchId = "62550d58-9a8d-4998-81d2-afa3e261be4b", InsertGuid = "25701a2e-6d17-4ed8-936e-cb6b3ff30507", SourceAssetId = "4026534443" },
}


UniqueImportPilotReport.Task19Summary = {
    TaskId = "19",
    RecordedAtUtc = "2026-05-27T05:39:00Z",
    SuccessfulPrimaryImports = 14,
    UniquePrimarySourceAssetIds = 14,
    NewPrimaryIdsVersusTrackedReport = 14,
    CumulativeTrackedUniquePrimaryIds = 44,
    RemainingGapTo500 = 456,
    Notes = "Live Studio MCP materialization batch. Initial parallel insert attempt failed because Studio reported play mode; after start_stop_play(false), retry inserted primary assets. Manifest-only rows are not counted here.",
}

UniqueImportPilotReport.Task19PrimaryImports = {
    { Query = "jungle bush pack", SearchId = "8f969051-6d50-4edf-a417-0236ba423fda", InsertGuid = "79214e2f-f57c-4179-8c0c-b8299c5127f6", SourceAssetId = "4775476638" },
    { Query = "tropical plant pack", SearchId = "e03c0058-ef02-40da-8ecf-69273705122a", InsertGuid = "3a2ef23a-623c-4d91-aa58-cdeafe38d025", SourceAssetId = "71660046955277" },
    { Query = "swamp cypress tree", SearchId = "fe5e2aae-aee7-4a6a-b206-ac869577e8a9", InsertGuid = "3ec63e07-47ae-4f35-8d9f-d0159c0cde58", SourceAssetId = "91090488957679" },
    { Query = "marsh grass reeds", SearchId = "746fa3fe-122d-48c0-965f-a866ae884fe6", InsertGuid = "919cc2af-6523-4176-9001-60357c3962e6", SourceAssetId = "134302502719859" },
    { Query = "canyon boulder set", SearchId = "42290ee0-9298-4921-9235-c12b9f623071", InsertGuid = "12798abb-d069-49c5-9c16-4b3d55445277", SourceAssetId = "9142161166" },
    { Query = "red rock cliff", SearchId = "477a19da-756e-4179-ada6-89459c462482", InsertGuid = "fbb188d3-2b0b-434a-a364-7452624a8053", SourceAssetId = "155403152" },
    { Query = "post apocalyptic building", SearchId = "fa20ffcf-e99d-4bab-be29-77e051c792a5", InsertGuid = "38ac445a-e38e-43c8-abda-a06d0b6213d6", SourceAssetId = "98072256581142" },
    { Query = "rubble pile debris", SearchId = "99bc268d-850c-4fb7-b1d6-045e59ac181f", InsertGuid = "cbcefc47-286d-48e7-947f-c88e38fc702f", SourceAssetId = "126869748953266" },
    { Query = "dinosaur egg nest model", SearchId = "83e5c557-1096-42bc-86be-7b878f03add5", InsertGuid = "9185bd0d-2609-43bd-a775-fe473b9754ea", SourceAssetId = "73903179158629" },
    { Query = "hanging vines plant", SearchId = "c378b866-91af-46ca-9e7d-88c45706d359", InsertGuid = "41e95edf-37de-43dc-b3cf-29e1200c38bb", SourceAssetId = "134425530937434" },
    { Query = "moss rock set", SearchId = "427e06d7-467c-404e-bff0-44eebff0e3d0", InsertGuid = "0a2b43a3-f9f7-47bc-9e1c-599443ec9507", SourceAssetId = "837559003" },
    { Query = "swamp water plants", SearchId = "aba83d25-ed15-45de-9f77-1305236e4b55", InsertGuid = "f3d1cb44-df90-4786-beb6-69719e1d4f02", SourceAssetId = "102184221548239" },
    { Query = "ruined wall building", SearchId = "09837054-402d-4bbc-8483-3751c779dd60", InsertGuid = "f5e70ab3-8307-4d48-8622-c72e39e9292a", SourceAssetId = "99017233137282" },
    { Query = "crashed car prop", SearchId = "58d5af1f-5fb5-4a49-b25e-bc62b27f9903", InsertGuid = "e8090207-d71d-4fb5-b36b-4f6d6a08c695", SourceAssetId = "5708963888" },
}

UniqueImportPilotReport.Task19Failures = {
    { Query = "large fossil bones", SearchId = "714b6585-26bf-4cbf-8e4f-873d268089bb", Error = "Target is not reachable (CreatorStoreInsertTool_insertFromMarketplaceAsync)" },
    { Query = "fallen tree log", SearchId = "9375ee91-671a-41a6-b25e-ca8b8c6774d6", Error = "Target is not reachable (CreatorStoreInsertTool_insertFromMarketplaceAsync)" },
    { Query = "first insert attempt for 8 searchIds", Error = "Studio reported play mode; fixed with start_stop_play(false) and retried successful candidates" },
}

return UniqueImportPilotReport
