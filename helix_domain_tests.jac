import from main {
    bom_csv,
    compute_fab_quote_from_parts,
    create_project,
    default_bom_document,
    default_cad_document,
    default_pcb_ops,
    fallback_generation,
    get_artifact_manifest,
    get_project_commands,
    get_project_health,
    get_project_order_history,
    project_artifact_counts,
    project_collaboration_snapshot,
    project_dependency_disclosures,
    project_overview,
    project_readiness_score,
    project_version_rows,
    normalized_project_name,
    normalized_project_prompt,
    search_projects,
    score_validation,
    validate_quote_quantity
}

test "fallback artifacts stay concrete and truthful" {
    result = fallback_generation("usb environmental sensor");
    assert not result.ok;
    assert len(result.cad_document.features) >= 5;
    assert len(result.bom_document.lines) >= 3;
    assert result.circuitron.pcb_source == "mock";
    assert result.circuitron.design_validation.passed == 0;
    assert "#include" not in result.firmware;
    assert "import board" in result.firmware;
}

test "validation score penalizes missing external evidence" {
    score = score_validation([
        "PCB DRC not run",
        "Firmware untested",
        "CAD source exists"
    ]);
    assert score < 82;
    assert score > 0;
}

test "fabrication quote uses CAD volume and PCB area" {
    quote = compute_fab_quote_from_parts(
        default_pcb_ops(),
        default_cad_document("cube([1,1,1]);"),
        5
    );
    assert quote.total_cents > 0;
    assert quote.pcb_area_cm2 == 17.5;
    assert not quote.pcb_used_default_outline;
    assert len(quote.lines) == 3;
}

test "project inputs are normalized before graph persistence" {
    assert normalized_project_name("  Spatial sensor  ") == "Spatial sensor";
    assert normalized_project_name(" ") == "Untitled Helix project";
    assert len(normalized_project_name("x" * 140)) == 96;
    assert normalized_project_prompt("  enclosure prompt  ") == "enclosure prompt";
    assert len(normalized_project_prompt("y" * 13000)) == 12000;
}

test "BOM CSV includes source identity and supplier fields" {
    csv = bom_csv(default_bom_document("sensor"));
    assert csv.startswith("reference,component,manufacturer");
    assert "ESP32-S3-MINI-1" in csv;
    assert "Digi-Key" in csv;
}

test "project intelligence exposes typed versions and artifacts" {
    snapshot = create_project("Intelligence fixture", "Design a compact BLE sensor");
    versions = project_version_rows(snapshot.project_id);
    manifest = get_artifact_manifest(snapshot.project_id);
    counts = project_artifact_counts(snapshot.project_id);
    assert len(versions) == 1;
    assert versions[0]["active"] == "True";
    assert len(manifest) == 5;
    assert counts["total"] == "5";
    assert counts["CAD"] == "1";
}

test "project search and overview remain graph-backed" {
    snapshot = create_project("Searchable sensor", "Design a greenhouse sensor");
    matches = search_projects("greenhouse", False);
    overview = project_overview(snapshot.project_id);
    assert any([row["project_id"] == snapshot.project_id for row in matches]);
    assert overview["version_count"] == "1";
    assert overview["artifact_count"] == "5";
    assert overview["health_status"] == "needs-attention";
}

test "dependency disclosures do not claim unavailable workers" {
    snapshot = create_project("Dependency fixture", "Design a board with firmware");
    dependencies = project_dependency_disclosures(snapshot.project_id);
    pcb = [row for row in dependencies if row["key"] == "pcb-worker"];
    firmware = [row for row in dependencies if row["key"] == "firmware-worker"];
    assert pcb[0]["available"] == "False";
    assert firmware[0]["available"] == "False";
    assert firmware[0]["required"] == "True";
}

test "health, collaboration, and commands expose truthful states" {
    snapshot = create_project("Health fixture", "Design a portable logger");
    health = get_project_health(snapshot.project_id);
    collaboration = project_collaboration_snapshot(snapshot.project_id);
    commands = get_project_commands(snapshot.project_id);
    readiness = project_readiness_score(snapshot.project_id);
    assert health["ok"] == "true";
    assert int(health["blocker_count"]) > 0;
    assert collaboration["shared"] == "False";
    assert any([row["key"] == "export" and row["enabled"] == "True" for row in commands]);
    assert readiness["label"] == "needs-review";
}

test "order history starts empty and quote validation is bounded" {
    snapshot = create_project("Order fixture", "Design a prototype node");
    assert len(get_project_order_history(snapshot.project_id)) == 0;
    valid = validate_quote_quantity(25);
    invalid = validate_quote_quantity(0);
    assert valid["ok"] == "True";
    assert invalid["ok"] == "False";
    assert invalid["normalized"] == "1";
}
