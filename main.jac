"""Helix native Jac application.

The graph is the product workspace: users, teams, projects, generated artifacts,
versions, validations, AR handoffs, and manufacturing orders are persisted as
reachable nodes connected by typed edges. Public walkers provide the backend API
and the Jac client UI calls those server functions directly.
"""

cl import "./styles.css";

enum ArtifactKind { CAD, PCB, SCHEMATIC, FIRMWARE, BOM, VALIDATION, AR, ORDER }
enum Severity { INFO, WARNING, ERROR }
enum OrderStatus { DRAFT, QUOTED, CHECKOUT_REQUIRED, PAID, CANCELED, FAILED }
enum ChatRole { USER, ASSISTANT, ASSISTANT_STREAMING, TYPING, PROGRESS }
enum CadBooleanOp { UNION, SUBTRACT }
enum CadShapeKind { BOX, CYLINDER, SPHERE, ROUNDED_BOX }
enum CadOpenFaceMode { NONE, FRONT, TOP }
enum PcbSource { CIRCUITRON, MOCK, PCBFLOW }
enum ProjectToolId { CAD, PCB, BOM, CODE, AR, ORDER }
enum ProjectLifecycle { ACTIVE, ARCHIVED }
enum EvidenceState { VERIFIED, WARNING, BLOCKED, NOT_RUN }

obj ChatMsg {
    has role: str,
        text: str;
}

obj BoardTemplate {
    has id: str,
        category: str,
        accent: str,
        title: str,
        tagline: str,
        description: str,
        bullets: list[str],
        prompt: str;
}

obj MockProjectRecord {
    has id: str,
        name: str,
        updated_at: int,
        tagline: str,
        team_id: str = "";
}

obj MockWorkspaceState {
    has projects: list[MockProjectRecord],
        messages: dict[str, list[ChatMsg]];
}

obj BomDocumentLine {
    has id: str,
        designators: str,
        description: str,
        mpn: str,
        manufacturer: str,
        qty: int,
        footprint: str,
        notes: str,
        supplier: str = "",
        unit_price: float = 0.0,
        availability: str = "unknown";
}

obj BomDocument {
    has lines: list[BomDocumentLine];
}

obj Vec3 {
    has x: float,
        y: float,
        z: float;
}

obj CadOpenScadParameter {
    has group: str,
        name: str,
        display_name: str,
        parameter_type: str,
        default_value: str,
        value: str,
        min_value: float = 0.0,
        max_value: float = 0.0,
        step: float = 1.0,
        description: str = "";
}

obj CadFeature {
    has id: str,
        op: str,
        shape: str,
        position_mm: Vec3,
        rotation_deg: Vec3,
        size_mm: Vec3,
        radius_mm: float = 0.0,
        height_mm: float = 0.0,
        corner_radius_mm: float = 0.0,
        label: str = "";
}

obj CadPresentation {
    has open_face: str,
        open_face_reveal: float;
}

obj CadOpenScadPayload {
    has code: str,
        parameters: list[CadOpenScadParameter];
}

obj CadDocument {
    has version: int,
        features: list[CadFeature],
        presentation: CadPresentation,
        openscad: CadOpenScadPayload;
}

obj ShellParams {
    has length_mm: float,
        width_mm: float,
        height_mm: float,
        wall_mm: float,
        corner_radius_mm: float;
}

obj PcbOps {
    has width_mm: float,
        height_mm: float,
        layer_count: int,
        min_trace_mm: float,
        min_clearance_mm: float,
        via_drill_mm: float,
        grid_mm: float;
}

obj CircuitronFileSet {
    has schematic: str = "",
        schematic_kicad: str = "",
        pcb: str = "",
        netlist: str = "",
        skidl: str = "";
}

obj DesignValidationSummary {
    has passed: int,
        warnings: int,
        errors: int,
        summary: str;
}

obj CircuitronResponse {
    has success: bool,
        files: CircuitronFileSet,
        workspace_files: dict[str, str],
        pcb_source: str,
        pcb_warnings: list[str],
        design_validation: DesignValidationSummary,
        logs: list[str],
        error: str = "",
        duration_ms: int = 0,
        width_mm: float = 50.0,
        height_mm: float = 35.0,
        layer_count: int = 2;
}

obj ArPcbScene {
    has layout_svg_key: str,
        stage_keys: list[str],
        component_refs: list[str],
        warning: str = "";
}

obj ArHandoffPayload {
    has cad_summary: str,
        circuitron_files: dict[str, str],
        byte_length: int,
        capped: bool,
        preferred_mode: str;
}

obj FabQuoteLine {
    has key: str,
        unit_amount_cents: int,
        quantity: int,
        name: str,
        description: str;
}

obj FabQuoteResult {
    has lines: list[FabQuoteLine],
        total_cents: int,
        pcb_width_mm: float,
        pcb_height_mm: float,
        pcb_area_cm2: float,
        pcb_used_default_outline: bool,
        cad_volume_dm3: float,
        cad_shell: ShellParams;
}

obj OrderRecord {
    has id: str,
        created_at: str,
        qty: int,
        label: str,
        status: str,
        source: str,
        paid_cents: int = 0,
        currency: str = "usd";
}

obj ToolExecution {
    has tool: str,
        status: str,
        message: str;
}

obj DesignChange {
    has target: str,
        summary: str,
        status: str,
        file_ref: str;
}

obj GenerationResult {
    has ok: bool,
        summary: str,
        cad_source: str,
        cad_document: CadDocument,
        pcb_plan: str,
        pcb_ops: PcbOps,
        circuitron: CircuitronResponse,
        firmware: str,
        bom_document: BomDocument,
        validation: list[str],
        changes: list[DesignChange],
        tool_progress: list[ToolExecution];
}

obj ArCapability {
    has secure_context: bool,
        webxr: bool,
        ios_quicklook: bool,
        android_scene_viewer: bool,
        camera: bool,
        fallback: str,
        message: str;
}

obj WorkspaceSnapshot {
    has project_id: str,
        name: str,
        prompt: str,
        tagline: str,
        active_version: str,
        cad_source: str,
        cad_document: CadDocument,
        pcb_plan: str,
        pcb_ops: PcbOps,
        circuitron: CircuitronResponse,
        schematic: str,
        firmware: str,
        bom_items: list[dict[str, str]],
        bom_document: BomDocument,
        validation: list[dict[str, str]],
        messages: list[dict[str, str]],
        versions: list[dict[str, str]],
        templates: list[BoardTemplate],
        tool_progress: list[ToolExecution],
        fab_quote: FabQuoteResult,
        ar_payload: ArHandoffPayload,
        order_steps: list[dict[str, str]],
        readiness_score: int,
        ar_ready: bool,
        order_status: str;
}

obj ProjectBundle {
    has project_id: str,
        project_name: str,
        version_label: str,
        generated_at: str,
        manifest: dict[str, str],
        files: dict[str, str],
        warnings: list[str];
}

obj VersionComparison {
    has project_id: str,
        from_version_id: str,
        to_version_id: str,
        from_label: str,
        to_label: str,
        cad_feature_delta: int,
        bom_line_delta: int,
        firmware_byte_delta: int,
        pcb_width_delta_mm: float,
        pcb_height_delta_mm: float,
        summary: str;
}

obj ReadinessEvidence {
    has key: str,
        label: str,
        state: str,
        source: str,
        message: str,
        score_impact: int;
}

obj ProjectActivityRow {
    has id: str,
        action: str,
        target: str,
        summary: str,
        status: str,
        created_at: str;
}

node User {
    has email: str,
        display_name: str,
        auth_provider: str = "demo",
        role: str = "engineer";
}

node Team {
    has name: str,
        plan: str = "local",
        created_at: str = "local";
}

node Project {
    has name: str,
        prompt: str,
        tagline: str = "Idea to hardware workspace",
        active_tool: str = "cad",
        active_version_id: str = "",
        status: str = "active",
        created_at: str = "local",
        updated_at: str = "local",
        shared: bool = False;
}

node DesignVersion {
    has label: str,
        summary: str,
        created_at: str = "local",
        committed: bool = True;
}

node CADArtifact {
    has name: str,
        source: str,
        cad_doc: CadDocument,
        format: str = "openscad",
        dimensions: str = "80mm x 52mm x 24mm",
        export_status: str = "OpenSCAD source ready; STL/STEP require configured CAD worker.";
}

node PCBArtifact {
    has name: str,
        plan: str,
        ops: PcbOps,
        circuitron: CircuitronResponse,
        board_size: str = "50mm x 35mm",
        drc_status: str = "Not run; connect KiCad/Circuitron worker.";
}

node SchematicArtifact {
    has name: str,
        netlist: str,
        erc_status: str = "Not run; connect schematic validator.";
}

node FirmwareArtifact {
    has name: str,
        source: str,
        language: str = "python",
        build_status: str = "Untested; connect firmware build worker.";
}

node BOM {
    has name: str,
        bom_doc: BomDocument,
        total_estimate: float = 0.0,
        currency: str = "USD";
}

node BOMItem {
    has component_name: str,
        reference: str,
        manufacturer: str,
        manufacturer_part_number: str,
        quantity: int,
        unit_price: float,
        availability: str,
        supplier: str,
        substitutions: str = "";
}

node ValidationRun {
    has name: str,
        score: int,
        status: str,
        notes: list[str];
}

node ARHandoff {
    has token: str,
        model_format: str,
        expires_at: str,
        status: str,
        dimensions: str,
        fallback: str;
}

node Conversation {
    has title: str,
        status: str = "open";
}

node Message {
    has role: str,
        content: str,
        created_at: str = "local";
}

node ManufacturingQuote {
    has status: OrderStatus = OrderStatus.DRAFT,
        quantity: int = 1,
        amount_cents: int = 0,
        currency: str = "usd",
        details: str = "Quote not generated.";
}

node Order {
    has status: OrderStatus = OrderStatus.DRAFT,
        provider: str = "stripe",
        checkout_url: str = "",
        details: str = "Stripe is not configured.";
}

node ProjectActivity {
    has action: str,
        target: str,
        summary: str,
        status: str = "complete",
        created_at: str = "local";
}

node ExportRecord {
    has format: str,
        filename: str,
        version_label: str,
        byte_length: int,
        created_at: str = "local";
}

edge Owns: User --> Project {}
edge MemberOf: User --> Team { has access: str = "owner"; }
edge TeamProject: Team --> Project {}
edge ProjectVersion: Project --> DesignVersion {}
edge VersionCad: DesignVersion --> CADArtifact {}
edge VersionPcb: DesignVersion --> PCBArtifact {}
edge VersionSchematic: DesignVersion --> SchematicArtifact {}
edge VersionFirmware: DesignVersion --> FirmwareArtifact {}
edge VersionBom: DesignVersion --> BOM {}
edge BomLine: BOM --> BOMItem {}
edge ProjectValidation: Project --> ValidationRun {}
edge ProjectAr: Project --> ARHandoff {}
edge ProjectConversation: Project --> Conversation {}
edge ConversationMessage: Conversation --> Message {}
edge ProjectQuote: Project --> ManufacturingQuote {}
edge QuoteOrder: ManufacturingQuote --> Order {}
edge ProjectActivityLog: Project --> ProjectActivity {}
edge ProjectExport: Project --> ExportRecord {}

sem synthesize_hardware_design = "Return concrete CAD, PCB, firmware, BOM, validation, and change summaries for a described physical electronics product. Never claim validations passed without evidence.";
sv def synthesize_hardware_design(product_prompt: str, project_context: str) -> GenerationResult by llm();

sv def clamp_float(n: float, lo: float, hi: float) -> float {
    if n < lo { return lo; }
    if n > hi { return hi; }
    return n;
}

sv def default_cad_parameters -> list[CadOpenScadParameter] {
    return [
        CadOpenScadParameter(group="Shell", name="width", display_name="Width", parameter_type="number", default_value="80", value="80", min_value=20, max_value=220, step=1, description="Outer enclosure width in mm."),
        CadOpenScadParameter(group="Shell", name="depth", display_name="Depth", parameter_type="number", default_value="52", value="52", min_value=20, max_value=180, step=1, description="Outer enclosure depth in mm."),
        CadOpenScadParameter(group="Shell", name="height", display_name="Height", parameter_type="number", default_value="24", value="24", min_value=8, max_value=90, step=1, description="Outer enclosure height in mm."),
        CadOpenScadParameter(group="Shell", name="wall", display_name="Wall thickness", parameter_type="number", default_value="2", value="2", min_value=1.2, max_value=6, step=0.1, description="3D print wall thickness.")
    ];
}

sv def default_cad_document(source: str) -> CadDocument {
    return CadDocument(
        version=2,
        features=[
            CadFeature(id="outer-shell", op="union", shape="roundedBox", position_mm=Vec3(x=0, y=0, z=0), rotation_deg=Vec3(x=0, y=0, z=0), size_mm=Vec3(x=80, y=52, z=24), corner_radius_mm=3, label="outer enclosure"),
            CadFeature(id="inner-cavity", op="subtract", shape="box", position_mm=Vec3(x=0, y=0, z=2), rotation_deg=Vec3(x=0, y=0, z=0), size_mm=Vec3(x=76, y=48, z=22), label="electronics cavity"),
            CadFeature(id="usb-c-port", op="subtract", shape="box", position_mm=Vec3(x=0, y=27, z=0), rotation_deg=Vec3(x=0, y=0, z=0), size_mm=Vec3(x=12, y=4, z=6), label="USB-C cutout"),
            CadFeature(id="boss-a", op="union", shape="cylinder", position_mm=Vec3(x=-25, y=-14, z=-7), rotation_deg=Vec3(x=0, y=0, z=0), size_mm=Vec3(x=0, y=0, z=0), radius_mm=2.8, height_mm=8, label="mounting boss"),
            CadFeature(id="boss-b", op="union", shape="cylinder", position_mm=Vec3(x=25, y=-14, z=-7), rotation_deg=Vec3(x=0, y=0, z=0), size_mm=Vec3(x=0, y=0, z=0), radius_mm=2.8, height_mm=8, label="mounting boss")
        ],
        presentation=CadPresentation(open_face="front", open_face_reveal=0.52),
        openscad=CadOpenScadPayload(code=source, parameters=default_cad_parameters())
    );
}

sv def default_pcb_ops -> PcbOps {
    return PcbOps(width_mm=50, height_mm=35, layer_count=2, min_trace_mm=0.2, min_clearance_mm=0.2, via_drill_mm=0.3, grid_mm=0.5);
}

sv def default_circuitron -> CircuitronResponse {
    return CircuitronResponse(
        success=False,
        files=CircuitronFileSet(schematic="schematic.svg", pcb="layout.kicad_pcb", netlist="netlist.net", skidl="design.py"),
        workspace_files={
            "schematic.svg": "<svg role='img' aria-label='logical schematic'></svg>",
            "netlist.net": "(export (components U1 J1 D1) (nets power signal ground))",
            "layout_board.svg": "<svg role='img' aria-label='pcb layout'></svg>",
            "pcbflow_assembly_stages.json": "{\"stages\":[{\"label\":\"Power\",\"refs\":[\"J1\"]},{\"label\":\"Controller\",\"refs\":[\"U1\",\"D1\"]}]}"
        },
        pcb_source="mock",
        pcb_warnings=["Circuitron/KiCad worker is not configured; generated files are planning artifacts."],
        design_validation=DesignValidationSummary(passed=0, warnings=2, errors=0, summary="ERC/DRC not run."),
        logs=["planned schematic", "prepared local workspace file map", "waiting for external Circuitron worker"],
        error="external Circuitron worker missing",
        duration_ms=0,
        width_mm=50,
        height_mm=35,
        layer_count=2
    );
}

sv def bom_line(id: str, designators: str, description: str, mpn: str, manufacturer: str, qty: int, footprint: str, notes: str, supplier: str, unit_price: float, availability: str) -> BomDocumentLine {
    return BomDocumentLine(id=id, designators=designators, description=description, mpn=mpn, manufacturer=manufacturer, qty=qty, footprint=footprint, notes=notes, supplier=supplier, unit_price=unit_price, availability=availability);
}

sv def default_bom_document(prompt: str) -> BomDocument {
    lower = prompt.lower();
    lines = [
        bom_line("bom-u1", "U1", "BLE MCU / SoC module", "ESP32-S3-MINI-1", "Espressif", 1, "Module", "Main controller, BLE and USB serial", "Digi-Key", 4.20, "check supplier"),
        bom_line("bom-j1", "J1", "USB Type-C receptacle", "USB4105", "GCT", 1, "USB-C-16Pin", "Power and programming", "Mouser", 0.68, "in stock typical"),
        bom_line("bom-d1", "D1", "Status LED, green", "APT1608", "Kingbright", 1, "0603", "User feedback", "LCSC", 0.08, "in stock typical"),
        bom_line("bom-cbulk", "C1-C3", "Bulk and decoupling capacitors", "CL21A106KAYNNNE", "Samsung", 3, "0805/0603", "Power rail stability", "Digi-Key", 0.11, "in stock typical")
    ];
    if "plant" in lower or "soil" in lower {
        lines.append(bom_line("bom-s1", "S1", "Capacitive soil moisture probe", "SEN0193", "DFRobot", 1, "Cable module", "Corrosion-aware soil sensing", "DFRobot", 6.90, "check supplier"));
    }
    if "dog" in lower or "feeder" in lower or "motor" in lower {
        lines.append(bom_line("bom-m1", "M1", "Micro gearmotor / servo", "SG90", "TowerPro", 1, "Servo header", "Dispense actuator", "Adafruit", 2.95, "in stock typical"));
    }
    if "light" in lower or "lamp" in lower {
        lines.append(bom_line("bom-leds", "LED1-LED8", "Warm white LED strip segment", "LTST-C191KFKT", "Lite-On", 8, "0603", "Soft night lighting", "Mouser", 0.09, "in stock typical"));
    }
    return BomDocument(lines=lines);
}

sv def board_templates -> list[BoardTemplate] {
    return [
        BoardTemplate(id="dog-feeder", category="Pets & home", accent="amber", title="Automatic dog feeder", tagline="Dispense kibble on a schedule you set", description="A small gadget that drops dry food at meal times with a simple actuator and cleanable food path.", bullets=["Motor or servo to release a measured portion", "RTC or phone schedule", "Food-safe path and jam awareness"], prompt="Build me a simple automatic dog feeder that dispenses dry kibble on a schedule I can change from my phone. USB or battery is fine."),
        BoardTemplate(id="plant-monitor", category="Plants & garden", accent="emerald", title="Houseplant soil watcher", tagline="Know when your plant is thirsty", description="Stick a probe in the dirt and get a clear signal before leaves droop.", bullets=["Soil moisture sense", "Too dry vs fine calibration", "Low power near a pot"], prompt="I want a tiny board that tells me when my houseplant's soil is too dry. LED or gentle buzzer is enough, bonus if it can notify my phone later."),
        BoardTemplate(id="night-light", category="Lights & rooms", accent="violet", title="Hallway night light", tagline="Soft light when it is dark", description="Warm light that fades out so it does not run all night.", bullets=["Ambient light sensor", "Warm LED", "Auto-off timer"], prompt="Design a simple hallway night light: turns on when the room is dark, warm white, and turns off automatically after maybe 30-60 minutes."),
        BoardTemplate(id="cat-fountain", category="Pets & home", accent="sky", title="Cat water fountain timer", tagline="Run a small pump on a gentle schedule", description="Short pump runs a few times an hour instead of constant noise.", bullets=["Low-voltage pump control", "USB friendly", "Optional dry-run fault"], prompt="Small pump controller for a cat water fountain: run the pump a few minutes every hour instead of always on, USB powered, simple and quiet."),
        BoardTemplate(id="key-finder", category="Portable", accent="cyan", title="Key finder tag", tagline="Make your keys beep from your phone", description="House-scale BLE tag with a buzzer in a keychain case.", bullets=["BLE beacon and buzzer", "Coin cell idle", "Simple pairing"], prompt="Build a simple BLE key finder: I tap find on my phone and the tag on my keys beeps."),
        BoardTemplate(id="macro-pad", category="Desk & work", accent="sky", title="Big shortcut buttons", tagline="Mute, camera, next slide", description="USB HID macro pad for calls and slides.", bullets=["Big tactile switches", "USB HID firmware", "Labels or RGB optional"], prompt="Macro keypad with big buttons for mute, camera on/off, and next slide during video calls.")
    ];
}

sv def bom_rows_from_document(doc: BomDocument) -> list[dict[str, str]] {
    rows: list[dict[str, str]] = [];
    for line in doc.lines {
        rows.append({
            "component_name": line.description,
            "reference": line.designators,
            "manufacturer": line.manufacturer,
            "manufacturer_part_number": line.mpn,
            "quantity": str(line.qty),
            "unit_price": f"{line.unit_price:.2f}",
            "availability": line.availability,
            "supplier": line.supplier,
            "substitutions": line.notes,
            "footprint": line.footprint
        });
    }
    return rows;
}

sv def compute_bom_total(doc: BomDocument) -> float {
    total = 0.0;
    for line in doc.lines {
        total = total + line.unit_price * line.qty;
    }
    return total;
}

sv def document_to_shell(doc: CadDocument) -> ShellParams {
    if doc.features {
        outer = doc.features[0];
        return ShellParams(length_mm=outer.size_mm.x, width_mm=outer.size_mm.y, height_mm=outer.size_mm.z, wall_mm=2.0, corner_radius_mm=outer.corner_radius_mm);
    }
    return ShellParams(length_mm=80, width_mm=52, height_mm=24, wall_mm=2, corner_radius_mm=3);
}

sv def compute_fab_quote_from_parts(pcb: PcbOps, cad: CadDocument, qty: int) -> FabQuoteResult {
    safe_qty = qty if qty > 0 else 1;
    area_cm2 = (pcb.width_mm * pcb.height_mm) / 100.0;
    pcb_line = int(clamp_float(area_cm2 * 14.0 * safe_qty, 2200.0, 250000.0));
    shell = document_to_shell(cad);
    volume_dm3 = (shell.length_mm * shell.width_mm * shell.height_mm) / 1000000.0;
    cad_line = int(clamp_float(volume_dm3 * 1400.0 * safe_qty, 900.0, 80000.0));
    platform = 500;
    return FabQuoteResult(
        lines=[
            FabQuoteLine(key="pcb", unit_amount_cents=pcb_line, quantity=1, name="PCB fabrication (per run)", description=f"{pcb.width_mm:.0f}x{pcb.height_mm:.0f} mm, {area_cm2:.1f} cm2 per board x {safe_qty} pcs."),
            FabQuoteLine(key="cad", unit_amount_cents=cad_line, quantity=1, name="CAD / enclosure file prep", description=f"{shell.length_mm:.0f}x{shell.width_mm:.0f}x{shell.height_mm:.0f} mm enclosure, {volume_dm3:.2f} dm3 x {safe_qty} pcs."),
            FabQuoteLine(key="platform", unit_amount_cents=platform, quantity=1, name="Helix platform & handling", description="Order routing, design package intake, and support coordination.")
        ],
        total_cents=pcb_line + cad_line + platform,
        pcb_width_mm=pcb.width_mm,
        pcb_height_mm=pcb.height_mm,
        pcb_area_cm2=area_cm2,
        pcb_used_default_outline=False,
        cad_volume_dm3=volume_dm3,
        cad_shell=shell
    );
}

sv def default_order_steps -> list[dict[str, str]] {
    return [
        {"id": "waiting", "label": "Waiting", "blurb": "Waiting for checkout or team approval."},
        {"id": "placed", "label": "Placed", "blurb": "Order placed with vendor."},
        {"id": "shipped", "label": "Shipped", "blurb": "Box left the factory."},
        {"id": "delivered", "label": "Delivered", "blurb": "On your bench."}
    ];
}

sv def ar_payload_from(cad: CadDocument, circuitron: CircuitronResponse) -> ArHandoffPayload {
    size = len(cad.openscad.code) + len(str(circuitron.workspace_files));
    return ArHandoffPayload(cad_summary=f"{len(cad.features)} CAD features, {circuitron.layer_count} PCB layers", circuitron_files=circuitron.workspace_files, byte_length=size, capped=size < 48000000, preferred_mode="WebXR -> Quick Look/Scene Viewer -> camera preview -> 3D fallback");
}

sv def fallback_generation(prompt: str) -> GenerationResult {
    scad = "module enclosure(width=80, depth=52, height=24, wall=2) { difference() { cube([width, depth, height], center=true); translate([0,0,2]) cube([width-wall*2, depth-wall*2, height], center=true); } } enclosure();";
    cad_doc = default_cad_document(scad);
    pcb = default_pcb_ops();
    circuitron = default_circuitron();
    bom_doc = default_bom_document(prompt);
    return GenerationResult(
        ok=False,
        summary=f"AI provider is not configured; Helix created a deterministic local starter design for: {prompt}.",
        cad_source=scad,
        cad_document=cad_doc,
        pcb_plan="Two-layer controller board, 50mm x 35mm, USB-C power/input, MCU, status LED, sensor header, programming pads. DRC not run.",
        pcb_ops=pcb,
        circuitron=circuitron,
        firmware="import time\nimport board\nimport digitalio\n\nstatus = digitalio.DigitalInOut(board.LED)\nstatus.direction = digitalio.Direction.OUTPUT\n\nwhile True:\n    status.value = not status.value\n    time.sleep(0.5)\n",
        bom_document=bom_doc,
        validation=[
            "CAD generated as OpenSCAD source only; STL/STEP worker not configured.",
            "PCB plan exists but KiCad DRC/ERC has not run.",
            "Firmware is starter CircuitPython code and is untested on hardware."
        ],
        changes=[
            DesignChange(target="CAD", summary="Created parameterized enclosure OpenSCAD source.", status="proposed", file_ref="cad/enclosure.scad"),
            DesignChange(target="PCB", summary="Created two-layer board plan and dependencies disclosure.", status="proposed", file_ref="pcb/board.plan"),
            DesignChange(target="Firmware", summary="Created starter CircuitPython firmware with a status heartbeat.", status="proposed", file_ref="firmware/code.py"),
            DesignChange(target="BOM", summary="Created prototype BOM with supplier and substitution fields.", status="proposed", file_ref="bom/items.json")
        ],
        tool_progress=[
            ToolExecution(tool="update_cad", status="fallback", message="Generated OpenSCAD and CadDocument locally."),
            ToolExecution(tool="update_pcb", status="blocked", message="Circuitron/KiCad worker missing; stored planning artifact."),
            ToolExecution(tool="replace_bom", status="complete", message="Built BOMDocument from Helix seed rules.")
        ]
    );
}

sv def get_or_create_demo_user -> User {
    users = [root-->][?:User];
    if users { return users[0]; }
    user = root ++> User(email="demo@helix.local", display_name="Helix Demo");
    team = root ++> Team(name="Local Hardware Lab");
    user +>: MemberOf(access="owner") :+> team;
    return user;
}

sv def project_by_id(project_id: str) -> Project | None {
    for project in [root-->][?:Project] {
        if jid(project) == project_id { return project; }
    }
    return None;
}

sv def normalized_project_name(name: str) -> str {
    clean = name.strip();
    if not clean { return "Untitled Helix project"; }
    if len(clean) > 96 { return clean[:96]; }
    return clean;
}

sv def normalized_project_prompt(prompt: str) -> str {
    clean = prompt.strip();
    if not clean { return "Design a compact electronics product with an enclosure, PCB, firmware, BOM, and validation notes."; }
    if len(clean) > 12000 { return clean[:12000]; }
    return clean;
}

sv def record_project_activity(project: Project, action: str, target: str, summary: str, status: str = "complete") -> ProjectActivity {
    activity = ProjectActivity(action=action, target=target, summary=summary, status=status);
    project +>: ProjectActivityLog() :+> activity;
    return activity;
}

sv def project_activity_rows(project: Project) -> list[dict[str, str]] {
    rows: list[dict[str, str]] = [];
    for activity in [project ->:ProjectActivityLog:->] {
        rows.append({
            "id": jid(activity),
            "action": activity.action,
            "target": activity.target,
            "summary": activity.summary,
            "status": activity.status,
            "created_at": activity.created_at
        });
    }
    return rows;
}

sv def version_by_id(project: Project, version_id: str) -> DesignVersion | None {
    for version in [project ->:ProjectVersion:->] {
        if jid(version) == version_id { return version; }
    }
    return None;
}

sv def active_version_for(project: Project) -> DesignVersion | None {
    versions = [project ->:ProjectVersion:->];
    if not versions { return None; }
    if project.active_version_id {
        found = version_by_id(project, project.active_version_id);
        if found is not None { return found; }
    }
    return versions[-1];
}

sv def version_generation(version: DesignVersion, prompt: str) -> GenerationResult {
    cads = [version ->:VersionCad:->];
    pcbs = [version ->:VersionPcb:->];
    firmwares = [version ->:VersionFirmware:->];
    boms = [version ->:VersionBom:->];
    if not cads or not pcbs or not firmwares or not boms {
        return fallback_generation(prompt);
    }
    pcb = pcbs[0];
    bom = boms[0];
    return GenerationResult(
        ok=True,
        summary=f"Duplicated {version.label} without claiming new AI generation.",
        cad_source=cads[0].source,
        cad_document=cads[0].cad_doc,
        pcb_plan=pcb.plan,
        pcb_ops=pcb.ops,
        circuitron=pcb.circuitron,
        firmware=firmwares[0].source,
        bom_document=bom.bom_doc,
        validation=["Copied artifact graph; external checks must be rerun for the duplicate."],
        changes=[
            DesignChange(target="Project", summary=f"Copied artifact graph from {version.label}.", status="accepted", file_ref="manifest.json")
        ],
        tool_progress=[
            ToolExecution(tool="copy_graph", status="complete", message="Copied CAD, PCB, firmware, and BOM artifacts in JaC."),
            ToolExecution(tool="invalidate_checks", status="complete", message="Marked external validation evidence for rerun.")
        ]
    );
}

sv def compute_total(items: list[dict[str, str]]) -> float {
    total = 0.0;
    for item in items {
        try {
            total = total + float(item["unit_price"]) * int(item["quantity"]);
        } except Exception {
            total = total + 0.0;
        }
    }
    return total;
}

sv def score_validation(notes: list[str]) -> int {
    score = 82;
    for note in notes {
        lowered = note.lower();
        if "not run" in lowered or "untested" in lowered {
            score = score - 16;
        }
        if "missing" in lowered or "not configured" in lowered {
            score = score - 10;
        }
    }
    if score < 0 { return 0; }
    return score;
}

sv def attach_version(project: Project, result: GenerationResult, label: str) -> DesignVersion {
    version = DesignVersion(label=label, summary=result.summary);
    project +>: ProjectVersion() :+> version;
    cad = CADArtifact(name="enclosure.scad", source=result.cad_source, cad_doc=result.cad_document);
    pcb = PCBArtifact(name="board.plan", plan=result.pcb_plan, ops=result.pcb_ops, circuitron=result.circuitron);
    schematic = SchematicArtifact(name="schematic.net", netlist="USB-C -> regulator -> MCU; MCU GPIO -> sensor header; MCU GPIO -> LED.");
    firmware = FirmwareArtifact(name="code.py", source=result.firmware);
    bom = BOM(name="prototype-bom", bom_doc=result.bom_document, total_estimate=compute_bom_total(result.bom_document));
    version +>: VersionCad() :+> cad;
    version +>: VersionPcb() :+> pcb;
    version +>: VersionSchematic() :+> schematic;
    version +>: VersionFirmware() :+> firmware;
    version +>: VersionBom() :+> bom;
    for line in result.bom_document.lines {
        bom +>: BomLine() :+> BOMItem(
            component_name=line.description,
            reference=line.designators,
            manufacturer=line.manufacturer,
            manufacturer_part_number=line.mpn,
            quantity=line.qty,
            unit_price=line.unit_price,
            availability=line.availability,
            supplier=line.supplier,
            substitutions=line.notes
        );
    }
    validation = ValidationRun(name="Manufacturing readiness", score=score_validation(result.validation), status="warnings", notes=result.validation);
    project +>: ProjectValidation() :+> validation;
    project.active_version_id = jid(version);
    return version;
}

sv def snapshot_project(project: Project) -> WorkspaceSnapshot {
    versions = [project ->:ProjectVersion:->];
    active = versions[-1] if versions else attach_version(project, fallback_generation(project.prompt), "v1");
    if project.active_version_id {
        for version in versions {
            if jid(version) == project.active_version_id {
                active = version;
            }
        }
    }
    cads = [active ->:VersionCad:->];
    pcbs = [active ->:VersionPcb:->];
    schematics = [active ->:VersionSchematic:->];
    firmwares = [active ->:VersionFirmware:->];
    boms = [active ->:VersionBom:->];
    vals = [project ->:ProjectValidation:->];
    convs = [project ->:ProjectConversation:->];
    quotes = [project ->:ProjectQuote:->];
    msgs: list[dict[str, str]] = [];
    if convs {
        for msg in [convs[0] ->:ConversationMessage:->] {
            msgs.append({"role": msg.role, "content": msg.content, "created_at": msg.created_at});
        }
    }
    bom_rows: list[dict[str, str]] = [];
    bom_doc = BomDocument(lines=[]);
    if boms {
        bom_doc = boms[0].bom_doc;
        for item in [boms[0] ->:BomLine:->] {
            bom_rows.append({
                "component_name": item.component_name,
                "reference": item.reference,
                "manufacturer": item.manufacturer,
                "manufacturer_part_number": item.manufacturer_part_number,
                "quantity": str(item.quantity),
                "unit_price": f"{item.unit_price:.2f}",
                "availability": item.availability,
                "supplier": item.supplier,
                "substitutions": item.substitutions
            });
        }
    }
    val_rows: list[dict[str, str]] = [];
    readiness = 0;
    if vals {
        readiness = vals[-1].score;
        for val in vals {
            val_rows.append({"name": val.name, "status": val.status, "score": str(val.score), "notes": " | ".join(val.notes)});
        }
    }
    version_rows: list[dict[str, str]] = [];
    for version in versions {
        version_rows.append({"id": jid(version), "label": version.label, "summary": version.summary});
    }
    cad_doc = cads[0].cad_doc if cads else default_cad_document("");
    pcb_ops = pcbs[0].ops if pcbs else default_pcb_ops();
    circuitron = pcbs[0].circuitron if pcbs else default_circuitron();
    quote_quantity = quotes[-1].quantity if quotes else 10;
    quote = compute_fab_quote_from_parts(pcb_ops, cad_doc, quote_quantity);
    payload = ar_payload_from(cad_doc, circuitron);
    return WorkspaceSnapshot(
        project_id=jid(project),
        name=project.name,
        prompt=project.prompt,
        tagline=project.tagline,
        active_version=active.label,
        cad_source=cads[0].source if cads else "",
        cad_document=cad_doc,
        pcb_plan=pcbs[0].plan if pcbs else "",
        pcb_ops=pcb_ops,
        circuitron=circuitron,
        schematic=schematics[0].netlist if schematics else "",
        firmware=firmwares[0].source if firmwares else "",
        bom_items=bom_rows,
        bom_document=bom_doc,
        validation=val_rows,
        messages=msgs,
        versions=version_rows,
        templates=board_templates(),
        tool_progress=[
            ToolExecution(tool="cad", status="ready", message="CADDocument v2 and OpenSCAD source are stored in JaC."),
            ToolExecution(tool="pcb", status=circuitron.pcb_source, message="CircuitronResponse workspace files are stored in JaC."),
            ToolExecution(tool="bom", status="ready", message=f"{len(bom_doc.lines)} BOM lines normalized in JaC.")
        ],
        fab_quote=quote,
        ar_payload=payload,
        order_steps=default_order_steps(),
        readiness_score=readiness,
        ar_ready=bool([project ->:ProjectAr:->]),
        order_status=str(quotes[-1].status).split(".")[-1] if quotes else "DRAFT"
    );
}

sv def:pub list_projects -> list[dict[str, str]] {
    get_or_create_demo_user();
    rows: list[dict[str, str]] = [];
    for project in [root-->][?:Project] {
        versions = [project ->:ProjectVersion:->];
        rows.append({
            "id": jid(project),
            "name": project.name,
            "prompt": project.prompt,
            "tagline": project.tagline,
            "status": project.status,
            "active_version_id": project.active_version_id,
            "version_count": str(len(versions)),
            "updated_at": project.updated_at,
            "shared": str(project.shared)
        });
    }
    return rows;
}

sv def:pub create_project(name: str, prompt: str) -> WorkspaceSnapshot {
    user = get_or_create_demo_user();
    clean_name = normalized_project_name(name);
    clean_prompt = normalized_project_prompt(prompt);
    project = root ++> Project(name=clean_name, prompt=clean_prompt, tagline="Generated by the Helix native JaC graph model");
    user +>: Owns() :+> project;
    teams = [user ->:MemberOf:->];
    if teams { teams[0] +>: TeamProject() :+> project; }
    result = fallback_generation(clean_prompt);
    attach_version(project, result, "v1 local draft");
    conv = Conversation(title=f"{name} copilot");
    project +>: ProjectConversation() :+> conv;
    conv +>: ConversationMessage() :+> Message(role="assistant", content=result.summary);
    record_project_activity(project, "create", "project", "Created the project and deterministic starter artifact graph.");
    return snapshot_project(project);
}

sv def:pub load_workspace(project_id: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    return snapshot_project(project);
}

sv def:pub generate_hardware_design(project_id: str, prompt: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    clean_prompt = normalized_project_prompt(prompt);
    try {
        result = synthesize_hardware_design(clean_prompt, snapshot_project(project).cad_source);
    } except Exception {
        result = fallback_generation(clean_prompt);
    }
    current_versions = [project ->:ProjectVersion:->];
    label = f"v{len(current_versions) + 1} generated";
    attach_version(project, result, label);
    convs = [project ->:ProjectConversation:->];
    if not convs {
        conv = Conversation(title=f"{project.name} copilot");
        project +>: ProjectConversation() :+> conv;
    } else {
        conv = convs[0];
    }
    conv +>: ConversationMessage() :+> Message(role="user", content=clean_prompt);
    conv +>: ConversationMessage() :+> Message(role="assistant", content=result.summary);
    project.prompt = clean_prompt;
    project.updated_at = "local";
    record_project_activity(project, "generate", "version", f"Created {label} with CAD, PCB, firmware, and BOM artifacts.");
    return snapshot_project(project);
}

sv def:pub restore_project_version(project_id: str, version_id: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    for version in [project ->:ProjectVersion:->] {
        if jid(version) == version_id {
            project.active_version_id = version_id;
            project.updated_at = "local";
            record_project_activity(project, "restore", "version", f"Restored {version.label} as the active artifact graph.");
            return snapshot_project(project);
        }
    }
    return None;
}

sv def:pub run_validations(project_id: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    notes = [
        "Geometry source exists and exposes dimensions.",
        "PCB DRC not run; configure KiCad/Circuitron worker before manufacturing.",
        "Firmware build not run; configure toolchain before flashing.",
        "BOM includes supplier and substitution fields."
    ];
    project +>: ProjectValidation() :+> ValidationRun(name="Readiness audit", score=score_validation(notes), status="warnings", notes=notes);
    record_project_activity(project, "validate", "project", "Recorded a warning-based manufacturing readiness audit.");
    return snapshot_project(project);
}

sv def:pub create_ar_handoff(project_id: str, capability: ArCapability) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    token = "ar-" + project_id[:8];
    handoff = ARHandoff(token=token, model_format="glb/usdz/open-scad-source", expires_at="24h", status="ready-with-fallback", dimensions=snapshot_project(project).cad_source[:80], fallback=capability.fallback);
    project +>: ProjectAr() :+> handoff;
    record_project_activity(project, "create", "ar_handoff", f"Recorded AR fallback mode: {capability.fallback}.");
    return {"ok": "true", "token": token, "fallback": capability.fallback, "message": capability.message};
}

sv def:pub create_fabrication_quote(project_id: str, quantity: int) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    qty = quantity if quantity > 0 else 1;
    workspace = snapshot_project(project);
    priced = compute_fab_quote_from_parts(workspace.pcb_ops, workspace.cad_document, qty);
    amount = priced.total_cents;
    quote = ManufacturingQuote(status=OrderStatus.QUOTED, quantity=qty, amount_cents=amount, details="Server-priced prototype quote. Stripe checkout requires STRIPE_SECRET_KEY.");
    order = Order(status=OrderStatus.CHECKOUT_REQUIRED, details="Stripe not configured in local Jac deployment.");
    project +>: ProjectQuote() :+> quote;
    quote +>: QuoteOrder() :+> order;
    record_project_activity(project, "quote", "manufacturing", f"Created authoritative quantity-{qty} prototype quote.");
    return {"ok": "true", "amount_cents": str(amount), "currency": "usd", "status": "CHECKOUT_REQUIRED", "details": quote.details};
}

sv def:pub share_project(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    project.shared = True;
    record_project_activity(project, "share", "project", "Enabled read-only project sharing metadata.");
    return {"ok": "true", "share_url": f"/share/{project_id}"};
}

sv def:pub rename_project(project_id: str, name: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    previous = project.name;
    project.name = normalized_project_name(name);
    project.updated_at = "local";
    record_project_activity(project, "rename", "project", f"Renamed {previous} to {project.name}.");
    return snapshot_project(project);
}

sv def:pub duplicate_project(project_id: str, name: str = "") -> WorkspaceSnapshot | None {
    source = project_by_id(project_id);
    if source is None { return None; }
    source_version = active_version_for(source);
    if source_version is None { return None; }
    user = get_or_create_demo_user();
    duplicate_name = normalized_project_name(name if name.strip() else source.name + " copy");
    duplicate = root ++> Project(
        name=duplicate_name,
        prompt=source.prompt,
        tagline=f"Duplicate of {source.name}"
    );
    user +>: Owns() :+> duplicate;
    teams = [user ->:MemberOf:->];
    if teams { teams[0] +>: TeamProject() :+> duplicate; }
    generation = version_generation(source_version, source.prompt);
    attach_version(duplicate, generation, "v1 copied graph");
    conv = Conversation(title=f"{duplicate_name} copilot");
    duplicate +>: ProjectConversation() :+> conv;
    conv +>: ConversationMessage() :+> Message(role="assistant", content=generation.summary);
    record_project_activity(duplicate, "duplicate", "project", f"Copied active artifact graph from {source.name}.");
    return snapshot_project(duplicate);
}

sv def:pub archive_project(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    project.status = "archived";
    project.updated_at = "local";
    record_project_activity(project, "archive", "project", "Archived project without deleting graph history.");
    return {"ok": "true", "project_id": project_id, "status": project.status};
}

sv def:pub reactivate_project(project_id: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    project.status = "active";
    project.updated_at = "local";
    record_project_activity(project, "reactivate", "project", "Restored archived project to the active workspace.");
    return snapshot_project(project);
}

sv def:pub get_project_activity(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    return project_activity_rows(project);
}

sv def:pub compare_project_versions(project_id: str, from_version_id: str, to_version_id: str) -> VersionComparison | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    from_version = version_by_id(project, from_version_id);
    to_version = version_by_id(project, to_version_id);
    if from_version is None or to_version is None { return None; }
    from_cads = [from_version ->:VersionCad:->];
    to_cads = [to_version ->:VersionCad:->];
    from_pcbs = [from_version ->:VersionPcb:->];
    to_pcbs = [to_version ->:VersionPcb:->];
    from_firmwares = [from_version ->:VersionFirmware:->];
    to_firmwares = [to_version ->:VersionFirmware:->];
    from_boms = [from_version ->:VersionBom:->];
    to_boms = [to_version ->:VersionBom:->];
    if not from_cads or not to_cads or not from_pcbs or not to_pcbs or not from_firmwares or not to_firmwares or not from_boms or not to_boms {
        return None;
    }
    feature_delta = len(to_cads[0].cad_doc.features) - len(from_cads[0].cad_doc.features);
    bom_delta = len(to_boms[0].bom_doc.lines) - len(from_boms[0].bom_doc.lines);
    firmware_delta = len(to_firmwares[0].source) - len(from_firmwares[0].source);
    width_delta = to_pcbs[0].ops.width_mm - from_pcbs[0].ops.width_mm;
    height_delta = to_pcbs[0].ops.height_mm - from_pcbs[0].ops.height_mm;
    return VersionComparison(
        project_id=project_id,
        from_version_id=from_version_id,
        to_version_id=to_version_id,
        from_label=from_version.label,
        to_label=to_version.label,
        cad_feature_delta=feature_delta,
        bom_line_delta=bom_delta,
        firmware_byte_delta=firmware_delta,
        pcb_width_delta_mm=width_delta,
        pcb_height_delta_mm=height_delta,
        summary=f"CAD features {feature_delta:+d}; BOM lines {bom_delta:+d}; firmware bytes {firmware_delta:+d}; PCB {width_delta:+.1f} x {height_delta:+.1f} mm."
    );
}

sv def project_readiness_evidence(project: Project) -> list[ReadinessEvidence] {
    workspace = snapshot_project(project);
    rows: list[ReadinessEvidence] = [];
    rows.append(ReadinessEvidence(
        key="cad-source",
        label="CAD source",
        state=("verified" if workspace.cad_source else "blocked"),
        source="JaC CADArtifact",
        message=("OpenSCAD source and dimensions exist." if workspace.cad_source else "No CAD source exists."),
        score_impact=(0 if workspace.cad_source else -30)
    ));
    drc_ran = workspace.circuitron.design_validation.passed > 0 or workspace.circuitron.design_validation.errors > 0;
    rows.append(ReadinessEvidence(
        key="pcb-drc",
        label="PCB DRC/ERC",
        state=("verified" if drc_ran and workspace.circuitron.design_validation.errors == 0 else "not_run"),
        source="CircuitronResponse.design_validation",
        message=workspace.circuitron.design_validation.summary,
        score_impact=(0 if drc_ran and workspace.circuitron.design_validation.errors == 0 else -20)
    ));
    rows.append(ReadinessEvidence(
        key="firmware-build",
        label="Firmware build",
        state="not_run",
        source="FirmwareArtifact.build_status",
        message="CircuitPython source exists, but no hardware build runner has reported a result.",
        score_impact=-16
    ));
    missing_bom = 0;
    for line in workspace.bom_document.lines {
        if not line.mpn or not line.supplier { missing_bom = missing_bom + 1; }
    }
    rows.append(ReadinessEvidence(
        key="bom-sourcing",
        label="BOM sourcing",
        state=("verified" if missing_bom == 0 and bool(workspace.bom_document.lines) else "warning"),
        source="BOMDocument",
        message=(f"{len(workspace.bom_document.lines)} normalized lines include supplier and MPN fields." if missing_bom == 0 else f"{missing_bom} lines are missing supplier or MPN data."),
        score_impact=(0 if missing_bom == 0 else -12)
    ));
    rows.append(ReadinessEvidence(
        key="checkout",
        label="Manufacturing checkout",
        state=("warning" if workspace.order_status == "CHECKOUT_REQUIRED" else "not_run"),
        source="ManufacturingQuote / Order",
        message=("Server quote exists; Stripe checkout is not configured." if workspace.order_status == "CHECKOUT_REQUIRED" else "No manufacturing order has been requested."),
        score_impact=-6
    ));
    return rows;
}

sv def:pub get_readiness_evidence(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    for evidence in project_readiness_evidence(project) {
        rows.append({
            "key": evidence.key,
            "label": evidence.label,
            "state": evidence.state,
            "source": evidence.source,
            "message": evidence.message,
            "score_impact": str(evidence.score_impact)
        });
    }
    return rows;
}

sv def csv_cell(value: str) -> str {
    return "\"" + value.replace("\"", "\"\"") + "\"";
}

sv def bom_csv(document: BomDocument) -> str {
    csv = "reference,component,manufacturer,mpn,quantity,unit_price,availability,supplier\n";
    for line in document.lines {
        csv = csv
            + csv_cell(line.designators) + ","
            + csv_cell(line.description) + ","
            + csv_cell(line.manufacturer) + ","
            + csv_cell(line.mpn) + ","
            + str(line.qty) + ","
            + f"{line.unit_price:.2f}" + ","
            + csv_cell(line.availability) + ","
            + csv_cell(line.supplier) + "\n";
    }
    return csv;
}

sv def:pub build_project_bundle(project_id: str) -> ProjectBundle | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    workspace = snapshot_project(project);
    safe_name = normalized_project_name(project.name).lower().replace(" ", "-");
    files = {
        f"{safe_name}/cad/enclosure.scad": workspace.cad_source,
        f"{safe_name}/pcb/board.plan.txt": workspace.pcb_plan,
        f"{safe_name}/pcb/schematic.net": workspace.schematic,
        f"{safe_name}/firmware/code.py": workspace.firmware,
        f"{safe_name}/bom/prototype.csv": bom_csv(workspace.bom_document),
        f"{safe_name}/validation/readiness.txt": "\n".join([row["notes"] for row in workspace.validation])
    };
    manifest = {
        "project_id": project_id,
        "project_name": project.name,
        "version": workspace.active_version,
        "cad_format": "openscad",
        "firmware_language": "circuitpython",
        "pcb_source": workspace.circuitron.pcb_source,
        "readiness_score": str(workspace.readiness_score),
        "order_status": workspace.order_status
    };
    warnings = [
        "STL and STEP are not included because no CAD worker is configured.",
        "KiCad DRC/ERC evidence is not included unless Circuitron reports a real run.",
        "Firmware has not been built or flashed by Helix.",
        "Bundle contents are source artifacts, not a manufacturing approval."
    ];
    byte_length = 0;
    for content in files.values() { byte_length = byte_length + len(content); }
    project +>: ProjectExport() :+> ExportRecord(format="source-bundle", filename=f"{safe_name}.json", version_label=workspace.active_version, byte_length=byte_length);
    record_project_activity(project, "export", "project_bundle", f"Built a {byte_length}-byte source bundle manifest.");
    return ProjectBundle(
        project_id=project_id,
        project_name=project.name,
        version_label=workspace.active_version,
        generated_at="local",
        manifest=manifest,
        files=files,
        warnings=warnings
    );
}

sv def:pub project_graph_stats(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    versions = [project ->:ProjectVersion:->];
    validations = [project ->:ProjectValidation:->];
    quotes = [project ->:ProjectQuote:->];
    activities = [project ->:ProjectActivityLog:->];
    exports = [project ->:ProjectExport:->];
    artifact_count = 0;
    for version in versions {
        artifact_count = artifact_count
            + len([version ->:VersionCad:->])
            + len([version ->:VersionPcb:->])
            + len([version ->:VersionSchematic:->])
            + len([version ->:VersionFirmware:->])
            + len([version ->:VersionBom:->]);
    }
    return {
        "ok": "true",
        "project_id": project_id,
        "versions": str(len(versions)),
        "artifacts": str(artifact_count),
        "validations": str(len(validations)),
        "quotes": str(len(quotes)),
        "activities": str(len(activities)),
        "exports": str(len(exports))
    };
}

sv walker:pub CreateProject {
    has name: str,
        prompt: str;
    can run with Root entry { report create_project(self.name, self.prompt); }
}

sv walker:pub LoadWorkspace {
    has project_id: str;
    can run with Root entry { report load_workspace(self.project_id); }
}

sv walker:pub GenerateHardwareDesign {
    has project_id: str,
        prompt: str;
    can run with Root entry { report generate_hardware_design(self.project_id, self.prompt); }
}

sv walker:pub RunValidations {
    has project_id: str;
    can run with Root entry { report run_validations(self.project_id); }
}

sv walker:pub RestoreProjectVersion {
    has project_id: str,
        version_id: str;
    can run with Root entry { report restore_project_version(self.project_id, self.version_id); }
}

sv walker:pub ListProjects {
    can run with Root entry { report list_projects(); }
}

sv walker:pub RenameProject {
    has project_id: str,
        name: str;
    can run with Root entry { report rename_project(self.project_id, self.name); }
}

sv walker:pub DuplicateProject {
    has project_id: str,
        name: str = "";
    can run with Root entry { report duplicate_project(self.project_id, self.name); }
}

sv walker:pub ArchiveProject {
    has project_id: str;
    can run with Root entry { report archive_project(self.project_id); }
}

sv walker:pub ReactivateProject {
    has project_id: str;
    can run with Root entry { report reactivate_project(self.project_id); }
}

sv walker:pub ProjectActivityHistory {
    has project_id: str;
    can run with Root entry { report get_project_activity(self.project_id); }
}

sv walker:pub CompareProjectVersions {
    has project_id: str,
        from_version_id: str,
        to_version_id: str;
    can run with Root entry { report compare_project_versions(self.project_id, self.from_version_id, self.to_version_id); }
}

sv walker:pub ReadinessEvidenceReport {
    has project_id: str;
    can run with Root entry { report get_readiness_evidence(self.project_id); }
}

sv walker:pub BuildProjectBundle {
    has project_id: str;
    can run with Root entry { report build_project_bundle(self.project_id); }
}

sv walker:pub ProjectGraphStats {
    has project_id: str;
    can run with Root entry { report project_graph_stats(self.project_id); }
}

sv walker:pub Health {
    can run with Root entry {
        report {"ok": True, "service": "helix-jac", "architecture": "native-jac", "version": "1.0.0"};
    }
}

def button_class(kind: str) -> str {
    return "hx-button hx-primary" if kind == "primary" else "hx-button";
}

def:pub Logo -> JsxElement {
    return <div className="logo-wrap" aria-label="Helix">
        <div className="helix-mark"><span></span><span></span><span></span></div>
        <strong>Helix</strong>
    </div>;
}

def:pub Metric(label: str, value: str, tone: str = "neutral") -> JsxElement {
    return <div className={"hx-metric " + tone}>
        <span>{label}</span>
        <strong>{value}</strong>
    </div>;
}

def cents(c: int) -> str {
    return "$" + f"{float(c) / 100.0:.2f}";
}

def:pub TemplateRail(templates: list[BoardTemplate], onPick: Callable[[str, str], None]) -> JsxElement {
    return <section className="template-rail" aria-label="Project templates">
        {[<button key={t.id} className={"template-card " + t.accent} onClick={lambda { onPick(t.title, t.prompt); }}>
            <span>{t.category}</span>
            <strong>{t.title}</strong>
            <p>{t.tagline}</p>
            <ul>{[<li key={b}>{b}</li> for b in t.bullets]}</ul>
        </button> for t in templates]}
    </section>;
}

def:pub ToolDock(active: str, onPick: Callable[[str], None]) -> JsxElement {
    tools = [
        {"id": "cad", "label": "CAD"},
        {"id": "pcb", "label": "PCB"},
        {"id": "bom", "label": "BOM"},
        {"id": "code", "label": "Code"},
        {"id": "ar", "label": "AR guide"},
        {"id": "order", "label": "Order"}
    ];
    return <nav className="tool-dock" aria-label="Project tools">
        {[<button key={t["id"]} className={("active" if active == t["id"] else "")} onClick={lambda { onPick(t["id"]); }}>{t["label"]}</button> for t in tools]}
    </nav>;
}

def:pub Copilot(snapshot: WorkspaceSnapshot | None, project_id: str, onUpdate: Callable[[WorkspaceSnapshot], None]) -> JsxElement {
    has prompt: str = "Generate a compact environmental sensor with USB-C, BLE, battery, enclosure, and firmware.",
        loading: bool = False,
        error: str = "";

    async def send {
        if not project_id or not prompt.strip() { return; }
        loading = True;
        error = "";
        result = await generate_hardware_design(project_id, prompt.strip());
        loading = False;
        if result is None {
            error = "Project not found.";
        } else {
            onUpdate(result);
            prompt = "";
        }
    }

    messages = snapshot.messages if snapshot is not None else [];
    progress = snapshot.tool_progress if snapshot is not None else [];
    return <aside className="copilot">
        <div className="panel-head">
            <div>
                <span>Helix copilot</span>
                <h2>Build thread</h2>
            </div>
            <span className={("status-live" if loading else "status-idle")}>{("running" if loading else "ready")}</span>
        </div>
        <div className="messages">
            {[<div key={m["role"] + m["content"]} className={"message " + m["role"]}>
                <strong>{m["role"]}</strong>
                <p>{m["content"]}</p>
            </div> for m in messages]}
            {[<div key={p.tool + p.message} className="message progress">
                <strong>{p.tool} · {p.status}</strong>
                <p>{p.message}</p>
            </div> for p in progress]}
            {error and <div className="message error"><strong>Error</strong><p>{error}</p></div>}
        </div>
        <textarea aria-label="Prompt Helix" value={prompt} onChange={lambda (e: ChangeEvent) { prompt = e.target.value; }} />
        <div className="row">
            <button className={button_class("primary")} disabled={loading} onClick={lambda { send(); }}>{("Stop unavailable" if loading else "Generate")}</button>
            <button className="hx-button" onClick={lambda { prompt = "Revise the enclosure for snap-fit tabs and expose mounting bosses."; }}>Suggest</button>
        </div>
    </aside>;
}

def:pub Workspace(snapshot: WorkspaceSnapshot | None, onUpdate: Callable[[WorkspaceSnapshot], None]) -> JsxElement {
    has tool: str = "cad",
        ar_status: str = "Not launched";
    if snapshot is None {
        return <main className="empty hero-home">
            <div className="hero-orb"></div>
            <p className="eyebrow">Helix</p>
            <h1>Go from idea to hardware, fast.</h1>
            <p>Helix runs as a native JaC graph app: prompt, chat, CAD, PCB, BOM, firmware, AR, and prototype orders in one workspace.</p>
        </main>;
    }

    async def validate {
        result = await run_validations(snapshot.project_id);
        if result is not None { onUpdate(result); }
    }

    async def quote {
        await create_fabrication_quote(snapshot.project_id, 3);
        result = await load_workspace(snapshot.project_id);
        if result is not None { onUpdate(result); }
    }

    async def ar {
        cap = ArCapability(secure_context=True, webxr=False, ios_quicklook=False, android_scene_viewer=False, camera=False, fallback="interactive-3d", message="Browser capability detection is handled by the Jac client fallback.");
        res = await create_ar_handoff(snapshot.project_id, cap);
        ar_status = res["message"];
    }

    return <main className="workspace">
        <header className="workspace-top">
            <div>
                <p className="eyebrow">Project workspace</p>
                <h1>{snapshot.name}</h1>
                <p>{snapshot.tagline} · {snapshot.prompt}</p>
            </div>
            <div className="actions">
                <button className="hx-button" onClick={validate}>Validate</button>
                <button className="hx-button" onClick={ar}>AR</button>
                <button className={button_class("primary")} onClick={quote}>Quote</button>
            </div>
        </header>
        <section className="metrics">
            <Metric label="Readiness" value={str(snapshot.readiness_score) + "%"} tone="green" />
            <Metric label="Version" value={snapshot.active_version} />
            <Metric label="Order" value={snapshot.order_status} />
            <Metric label="AR" value={("Ready" if snapshot.ar_ready else "Fallback")} tone="lime" />
        </section>
        <ToolDock active={tool} onPick={lambda (id: str) { tool = id; }} />
        <section className="canvas">
            {tool == "cad" and <div className="split cad-panel">
                <div className="viewer dark-grid">
                    <div className="viewer-toolbar"><span>Viewport</span><button className="ghost">Reset camera</button></div>
                    <div className="model-box"></div>
                    <p>{str(len(snapshot.cad_document.features))} CSG features · {snapshot.cad_document.presentation.open_face} cutaway · OpenSCAD export ready</p>
                </div>
                <aside className="inspector">
                    <h3>Inspector</h3>
                    {[<label key={p.name}><span>{p.display_name}</span><input value={p.value} readOnly={True} /></label> for p in snapshot.cad_document.openscad.parameters]}
                    <pre>{snapshot.cad_source}</pre>
                </aside>
            </div>}
            {tool == "pcb" and <div className="split">
                <div className="viewer pcb-board"><h3>PCB layout</h3><div className="board-shape"><span>U1</span><span>J1</span><span>D1</span></div><p>{snapshot.pcb_plan}</p></div>
                <aside className="inspector"><h3>Circuitron</h3><p>{snapshot.circuitron.design_validation.summary}</p><p>{snapshot.circuitron.width_mm} x {snapshot.circuitron.height_mm} mm · {snapshot.circuitron.layer_count} layers</p><ul>{[<li key={w}>{w}</li> for w in snapshot.circuitron.pcb_warnings]}</ul></aside>
            </div>}
            {tool == "bom" and <table>
                <thead><tr><th>Ref</th><th>Name</th><th>MPN</th><th>Qty</th><th>Footprint</th><th>Unit</th><th>Supplier</th><th>Availability</th></tr></thead>
                <tbody>{[<tr key={item["reference"]}><td>{item["reference"]}</td><td>{item["component_name"]}</td><td>{item["manufacturer_part_number"]}</td><td>{item["quantity"]}</td><td>{item["footprint"]}</td><td>${item["unit_price"]}</td><td>{item["supplier"]}</td><td>{item["availability"]}</td></tr> for item in snapshot.bom_items]}</tbody>
            </table>}
            {tool == "code" and <div className="split"><pre>{snapshot.firmware}</pre><aside className="inspector"><h3>Schematic</h3><pre>{snapshot.schematic}</pre><h3>Validation</h3>{[<p key={v["name"]}>{v["name"]}: {v["score"]}% · {v["notes"]}</p> for v in snapshot.validation]}</aside></div>}
            {tool == "ar" and <div className="viewer ar"><h3>AR guide</h3><p>{ar_status}</p><p>{snapshot.ar_payload.preferred_mode}</p><p>{snapshot.ar_payload.cad_summary} · payload {str(snapshot.ar_payload.byte_length)} bytes</p><div className="model-box"></div></div>}
            {tool == "order" and <div className="split"><div className="viewer"><h3>Prototype quote</h3>{[<div key={line.key} className="quote-line"><strong>{line.name}</strong><span>{cents(line.unit_amount_cents)}</span><p>{line.description}</p></div> for line in snapshot.fab_quote.lines]}<div className="quote-total">Total {cents(snapshot.fab_quote.total_cents)}</div></div><aside className="inspector"><h3>Status</h3>{[<p key={s["id"]}><strong>{s["label"]}</strong><br />{s["blurb"]}</p> for s in snapshot.order_steps]}</aside></div>}
        </section>
    </main>;
}

def:pub app -> JsxElement {
    has projects: list[dict[str, str]] = [],
        active: WorkspaceSnapshot | None = None,
        new_name: str = "Helix reference module",
        new_prompt: str = "A palm-sized BLE environmental monitor with USB-C charging, battery, display, enclosure, firmware, BOM, and prototype quote.",
        busy: bool = False;

    async can with entry {
        loaded_projects = await list_projects();
        projects = loaded_projects;
        if loaded_projects {
            loaded = await load_workspace(loaded_projects[0]["id"]);
            active = loaded;
        }
    }

    async def create {
        busy = True;
        active = await create_project(new_name, new_prompt);
        projects = await list_projects();
        busy = False;
    }

    async def open_project(id: str) {
        loaded = await load_workspace(id);
        if loaded is not None { active = loaded; }
    }

    return <div className="app-shell">
        <aside className="sidebar">
            <Logo />
            <nav>
                {for item in ["Build", "Projects", "Templates", "Component library", "Manufacturing orders", "Team", "Settings"] {
                    <button key={item}>{item}</button>
                }}
            </nav>
            <div className="create-card">
                <span>New board</span>
                <input value={new_name} onChange={lambda (e: ChangeEvent) { new_name = e.target.value; }} />
                <textarea value={new_prompt} onChange={lambda (e: ChangeEvent) { new_prompt = e.target.value; }} />
                <button className={button_class("primary")} disabled={busy} onClick={create}>{("Creating..." if busy else "Create project")}</button>
            </div>
            <div className="project-list">
                {[<button key={p["id"]} onClick={lambda { open_project(p["id"]); }}>{p["name"]}</button> for p in projects]}
            </div>
            <TemplateRail templates={(active.templates if active is not None else [])} onPick={lambda (name: str, prompt: str) { new_name = name; new_prompt = prompt; }} />
        </aside>
        <Copilot snapshot={active} project_id={(active.project_id if active is not None else "")} onUpdate={lambda (s: WorkspaceSnapshot) { active = s; }} />
        <Workspace snapshot={active} onUpdate={lambda (s: WorkspaceSnapshot) { active = s; }} />
    </div>;
}

test "fallback generation has concrete artifacts" {
    result = fallback_generation("usb sensor");
    assert not result.ok;
    assert "OpenSCAD" in result.summary or "starter" in result.summary;
    assert len(result.bom_document.lines) >= 3;
}

test "validation score penalizes unrun checks" {
    score = score_validation(["DRC not run", "Firmware untested", "BOM ok"]);
    assert score < 82;
    assert score > 0;
}

test "original template structures are represented in Jac" {
    templates = board_templates();
    assert len(templates) >= 6;
    assert templates[0].title == "Automatic dog feeder";
    assert templates[1].id == "plant-monitor";
}

test "fallback generation carries migrated CAD PCB BOM data" {
    result = fallback_generation("houseplant soil watcher");
    assert len(result.cad_document.features) >= 5;
    assert len(result.bom_document.lines) >= 3;
    assert result.circuitron.pcb_source == "mock";
}

test "fab quote uses original area and volume style math" {
    quote = compute_fab_quote_from_parts(default_pcb_ops(), default_cad_document("cube([1,1,1]);"), 10);
    assert quote.total_cents > 0;
    assert quote.pcb_area_cm2 == 17.5;
    assert len(quote.lines) == 3;
}

test "project input normalization is bounded and deliberate" {
    assert normalized_project_name("  Spatial sensor  ") == "Spatial sensor";
    assert normalized_project_name("  ") == "Untitled Helix project";
    assert len(normalized_project_name("x" * 140)) == 96;
    assert normalized_project_prompt("  enclosure prompt  ") == "enclosure prompt";
    assert len(normalized_project_prompt("y" * 13000)) == 12000;
}

test "CircuitPython fallback contains no C plus plus artifact path" {
    result = fallback_generation("portable sensor");
    assert "import board" in result.firmware;
    assert "#include" not in result.firmware;
    firmware_changes = [change for change in result.changes if change.target == "Firmware"];
    assert len(firmware_changes) == 1;
    assert firmware_changes[0].file_ref == "firmware/code.py";
}

test "BOM CSV export preserves normalized sourcing fields" {
    document = default_bom_document("sensor");
    csv = bom_csv(document);
    assert csv.startswith("reference,component,manufacturer");
    assert "ESP32-S3-MINI-1" in csv;
    assert "Digi-Key" in csv;
    assert len(csv.split("\n")) > len(document.lines);
}

test "project lifecycle APIs preserve graph history" {
    snapshot = create_project("Lifecycle fixture", "Design a USB sensor");
    project_id = snapshot.project_id;
    renamed = rename_project(project_id, "Lifecycle fixture renamed");
    assert renamed is not None;
    assert renamed.name == "Lifecycle fixture renamed";
    archived = archive_project(project_id);
    assert archived["ok"] == "true";
    assert archived["status"] == "archived";
    restored = reactivate_project(project_id);
    assert restored is not None;
    active_project = project_by_id(project_id);
    assert active_project is not None;
    assert active_project.status == "active";
    assert len(get_project_activity(project_id)) >= 4;
}

test "duplicate project copies typed artifact graph" {
    source = create_project("Duplicate source", "Design a small BLE node");
    duplicate = duplicate_project(source.project_id, "Duplicate target");
    assert duplicate is not None;
    assert duplicate.name == "Duplicate target";
    assert duplicate.project_id != source.project_id;
    assert duplicate.cad_source == source.cad_source;
    assert duplicate.firmware == source.firmware;
    assert len(duplicate.bom_document.lines) == len(source.bom_document.lines);
    assert duplicate.active_version == "v1 copied graph";
}

test "active version restore changes returned artifact graph" {
    snapshot = create_project("Version fixture", "Design a desk sensor");
    project = project_by_id(snapshot.project_id);
    assert project is not None;
    first_id = snapshot.versions[0]["id"];
    attach_version(project, fallback_generation("Design a revised desk sensor"), "v2 deterministic");
    latest = snapshot_project(project);
    assert latest.active_version == "v2 deterministic";
    restored = restore_project_version(snapshot.project_id, first_id);
    assert restored is not None;
    assert restored.active_version == "v1 local draft";
    assert len(restored.versions) == 2;
}

test "version comparison reports concrete artifact deltas" {
    snapshot = create_project("Compare fixture", "Design a compact logger");
    project = project_by_id(snapshot.project_id);
    assert project is not None;
    first_id = snapshot.versions[0]["id"];
    attach_version(project, fallback_generation("Design a revised compact logger"), "v2 deterministic");
    latest = snapshot_project(project);
    second_id = latest.versions[1]["id"];
    comparison = compare_project_versions(snapshot.project_id, first_id, second_id);
    assert comparison is not None;
    assert comparison.from_label == "v1 local draft";
    assert comparison.to_label == "v2 deterministic";
    assert "CAD features" in comparison.summary;
}

test "readiness evidence never invents external validation" {
    snapshot = create_project("Evidence fixture", "Design a field monitor");
    evidence = get_readiness_evidence(snapshot.project_id);
    assert len(evidence) == 5;
    drc = [row for row in evidence if row["key"] == "pcb-drc"];
    firmware = [row for row in evidence if row["key"] == "firmware-build"];
    assert drc[0]["state"] == "not_run";
    assert firmware[0]["state"] == "not_run";
    assert "no hardware build runner" in firmware[0]["message"];
}

test "project bundle contains source artifacts and explicit warnings" {
    snapshot = create_project("Bundle fixture", "Design an environmental logger");
    bundle = build_project_bundle(snapshot.project_id);
    assert bundle is not None;
    assert bundle.manifest["firmware_language"] == "circuitpython";
    assert bundle.manifest["cad_format"] == "openscad";
    assert len(bundle.files) == 6;
    assert any([path.endswith("enclosure.scad") for path in bundle.files.keys()]);
    assert any([path.endswith("code.py") for path in bundle.files.keys()]);
    assert len(bundle.warnings) == 4;
}

test "project graph stats count versions artifacts and activity" {
    snapshot = create_project("Graph stats fixture", "Design a control module");
    stats = project_graph_stats(snapshot.project_id);
    assert stats["ok"] == "true";
    assert int(stats["versions"]) >= 1;
    assert int(stats["artifacts"]) >= 5;
    assert int(stats["validations"]) >= 1;
    assert int(stats["activities"]) >= 1;
}
