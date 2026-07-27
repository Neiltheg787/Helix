import from main {
    bom_csv,
    compute_fab_quote_from_parts,
    default_bom_document,
    default_cad_document,
    default_pcb_ops,
    fallback_generation,
    normalized_project_name,
    normalized_project_prompt,
    score_validation
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
