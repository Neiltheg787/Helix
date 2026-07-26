import from main { create_project, create_fabrication_quote, generate_hardware_design }

test "manufacturing quote uses server price" {
    snap = create_project("Quote test", "small BLE sensor");
    quote = create_fabrication_quote(snap.project_id, 2);
    assert quote["ok"] == "true";
    assert int(quote["amount_cents"]) == 7900;
}

test "workspace persists versions through graph edges" {
    snap = create_project("Version test", "USB powered sensor");
    updated = generate_hardware_design(snap.project_id, "Add snap-fit enclosure tabs");
    assert updated is not None;
    assert len(updated.versions) >= 2;
    assert updated.readiness_score > 0;
}
