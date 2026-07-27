"""Helix native Jac application.

The graph is the product workspace: users, teams, projects, generated artifacts,
versions, validations, AR handoffs, and manufacturing orders are persisted as
reachable nodes connected by typed edges. Public walkers provide the backend API
and the Jac client UI calls those server functions directly.
"""

cl import "./styles.css";
import from "./helix_ui.tsx" { HelixApp }

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

obj ProjectSearchResult {
    has project_id: str,
        name: str,
        tagline: str,
        status: str,
        match: str,
        version_count: int,
        readiness_score: int,
        updated_at: str;
}

obj ArtifactManifestRow {
    has project_id: str,
        version_id: str,
        version_label: str,
        artifact_type: str,
        filename: str,
        format: str,
        status: str,
        source: str,
        byte_length: int;
}

obj CollaborationSnapshot {
    has project_id: str,
        shared: bool,
        team_name: str,
        member_count: int,
        activity_count: int,
        access_mode: str,
        last_activity: str;
}

obj OrderHistoryRow {
    has order_id: str,
        quote_id: str,
        status: str,
        quantity: int,
        amount_cents: int,
        currency: str,
        provider: str,
        created_at: str,
        detail: str;
}

obj DependencyDisclosure {
    has key: str,
        feature: str,
        available: bool,
        required: bool,
        owner: str,
        message: str;
}

obj ProjectHealthReport {
    has project_id: str,
        project_name: str,
        status: str,
        score: int,
        active_version: str,
        artifact_count: int,
        blockers: list[str],
        checks: list[dict[str, str]];
}

obj ProjectCommand {
    has key: str,
        label: str,
        category: str,
        enabled: bool,
        reason: str;
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

sv def project_version_row(project: Project, version: DesignVersion) -> dict[str, str] {
    cads = [version ->:VersionCad:->];
    pcbs = [version ->:VersionPcb:->];
    schematics = [version ->:VersionSchematic:->];
    firmwares = [version ->:VersionFirmware:->];
    boms = [version ->:VersionBom:->];
    artifact_count = len(cads) + len(pcbs) + len(schematics) + len(firmwares) + len(boms);
    active = project.active_version_id == jid(version);
    return {
        "id": jid(version),
        "project_id": jid(project),
        "label": version.label,
        "summary": version.summary,
        "created_at": version.created_at,
        "committed": str(version.committed),
        "active": str(active),
        "artifact_count": str(artifact_count),
        "cad_features": str(len(cads[0].cad_doc.features) if cads else 0),
        "bom_lines": str(len(boms[0].bom_doc.lines) if boms else 0)
    };
}

sv def:pub project_version_rows(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    for version in [project ->:ProjectVersion:->] {
        rows.append(project_version_row(project, version));
    }
    return rows;
}

sv def search_match(project: Project, query: str) -> str {
    lowered = query.lower();
    if not lowered { return "all projects"; }
    if lowered in project.name.lower() { return "name"; }
    if lowered in project.tagline.lower() { return "tagline"; }
    if lowered in project.prompt.lower() { return "brief"; }
    return "";
}

sv def:pub search_projects(query: str = "", include_archived: bool = False) -> list[dict[str, str]] {
    lowered = query.strip().lower();
    rows: list[dict[str, str]] = [];
    for project in [root-->][?:Project] {
        match_kind: str = search_match(project, lowered);
        visible = include_archived or project.status != "archived";
        if visible and match_kind {
            versions = [project ->:ProjectVersion:->];
            validations = [project ->:ProjectValidation:->];
            score = validations[-1].score if validations else 0;
            rows.append({
                "project_id": jid(project),
                "name": project.name,
                "tagline": project.tagline,
                "status": project.status,
                "match": match_kind,
                "version_count": str(len(versions)),
                "readiness_score": str(score),
                "updated_at": project.updated_at
            });
        }
    }
    return rows;
}

sv def artifact_manifest_object(project_id: str, version: DesignVersion, artifact_type: str, filename: str, file_format: str, status: str, source: str) -> ArtifactManifestRow {
    return ArtifactManifestRow(
        project_id=project_id,
        version_id=jid(version),
        version_label=version.label,
        artifact_type=artifact_type,
        filename=filename,
        format=file_format,
        status=status,
        source=source,
        byte_length=len(source)
    );
}

sv def artifact_manifest_dict(row: ArtifactManifestRow) -> dict[str, str] {
    return {
        "project_id": row.project_id,
        "version_id": row.version_id,
        "version_label": row.version_label,
        "artifact_type": row.artifact_type,
        "filename": row.filename,
        "format": row.format,
        "status": row.status,
        "source": row.source,
        "byte_length": str(row.byte_length)
    };
}

sv def project_artifact_manifest_rows(project: Project) -> list[ArtifactManifestRow] {
    rows: list[ArtifactManifestRow] = [];
    for version in [project ->:ProjectVersion:->] {
        cads = [version ->:VersionCad:->];
        pcbs = [version ->:VersionPcb:->];
        schematics = [version ->:VersionSchematic:->];
        firmwares = [version ->:VersionFirmware:->];
        boms = [version ->:VersionBom:->];
        if cads {
            rows.append(artifact_manifest_object(jid(project), version, "CAD", cads[0].name, cads[0].format, cads[0].export_status, cads[0].source));
        }
        if pcbs {
            rows.append(artifact_manifest_object(jid(project), version, "PCB", pcbs[0].name, "circuitron-plan", pcbs[0].drc_status, pcbs[0].plan));
        }
        if schematics {
            rows.append(artifact_manifest_object(jid(project), version, "SCHEMATIC", schematics[0].name, "netlist", schematics[0].erc_status, schematics[0].netlist));
        }
        if firmwares {
            rows.append(artifact_manifest_object(jid(project), version, "FIRMWARE", firmwares[0].name, firmwares[0].language, firmwares[0].build_status, firmwares[0].source));
        }
        if boms {
            rows.append(artifact_manifest_object(jid(project), version, "BOM", boms[0].name, "csv/json", "source-ready", bom_csv(boms[0].bom_doc)));
        }
    }
    return rows;
}

sv def:pub get_artifact_manifest(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    for item in project_artifact_manifest_rows(project) {
        rows.append(artifact_manifest_dict(item));
    }
    return rows;
}

sv def:pub bom_availability_summary(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    workspace = snapshot_project(project);
    total = len(workspace.bom_document.lines);
    known = 0;
    missing_supplier = 0;
    needs_review = 0;
    estimated_cents = 0;
    for line in workspace.bom_document.lines {
        estimated_cents = estimated_cents + int(line.unit_price * 100.0) * line.qty;
        if line.supplier and line.mpn { known = known + 1; }
        if not line.supplier { missing_supplier = missing_supplier + 1; }
        if "check" in line.availability.lower() or "unknown" in line.availability.lower() { needs_review = needs_review + 1; }
    }
    return {
        "ok": "true",
        "project_id": project_id,
        "line_count": str(total),
        "sourced_lines": str(known),
        "missing_supplier": str(missing_supplier),
        "needs_availability_review": str(needs_review),
        "estimated_component_cents": str(estimated_cents),
        "currency": "usd",
        "status": ("ready" if total > 0 and needs_review == 0 else "needs-review")
    };
}

sv def:pub cad_dimension_summary(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    workspace = snapshot_project(project);
    shell = document_to_shell(workspace.cad_document);
    return {
        "ok": "true",
        "project_id": project_id,
        "active_version": workspace.active_version,
        "width_mm": f"{shell.length_mm:.1f}",
        "depth_mm": f"{shell.width_mm:.1f}",
        "height_mm": f"{shell.height_mm:.1f}",
        "wall_mm": f"{shell.wall_mm:.1f}",
        "corner_radius_mm": f"{shell.corner_radius_mm:.1f}",
        "feature_count": str(len(workspace.cad_document.features)),
        "parameter_count": str(len(workspace.cad_document.openscad.parameters)),
        "source_format": "openscad",
        "export_status": "source-ready; STL and STEP require a CAD worker"
    };
}

sv def:pub pcb_dependency_summary(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    workspace = snapshot_project(project);
    validation = workspace.circuitron.design_validation;
    real_result = workspace.circuitron.success and workspace.circuitron.pcb_source != "mock";
    return {
        "ok": "true",
        "project_id": project_id,
        "source": workspace.circuitron.pcb_source,
        "worker_available": str(real_result),
        "drc_status": ("verified" if real_result and validation.errors == 0 else "not-run"),
        "erc_status": ("verified" if real_result and validation.errors == 0 else "not-run"),
        "passed": str(validation.passed),
        "warnings": str(validation.warnings),
        "errors": str(validation.errors),
        "width_mm": f"{workspace.pcb_ops.width_mm:.1f}",
        "height_mm": f"{workspace.pcb_ops.height_mm:.1f}",
        "layers": str(workspace.pcb_ops.layer_count),
        "message": (validation.summary if real_result else "Circuitron/KiCad worker is not configured; no DRC/ERC claim is made.")
    };
}

sv def:pub firmware_dependency_summary(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    workspace = snapshot_project(project);
    return {
        "ok": "true",
        "project_id": project_id,
        "language": "circuitpython",
        "source_bytes": str(len(workspace.firmware)),
        "build_status": "not-run",
        "flash_status": "not-run",
        "worker_available": "false",
        "message": "CircuitPython starter source is available, but no hardware build or flash runner is configured."
    };
}

sv def:pub ar_capability_summary(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    handoffs = [project ->:ProjectAr:->];
    workspace = snapshot_project(project);
    return {
        "ok": "true",
        "project_id": project_id,
        "handoff_recorded": str(bool(handoffs)),
        "preferred_mode": workspace.ar_payload.preferred_mode,
        "model_formats": "glb/usdz/open-scad-source",
        "webxr": "browser-detected",
        "quicklook": "requires-valid-usdz",
        "scene_viewer": "requires-valid-glb",
        "camera_preview": "browser-permission",
        "plane_detection": "not-claimed",
        "message": "AR is progressive enhancement; the fallback is an interactive camera or 3D preview, not guaranteed plane tracking."
    };
}

sv def project_dependency_objects(project: Project) -> list[DependencyDisclosure] {
    workspace = snapshot_project(project);
    pcb_ready = workspace.circuitron.success and workspace.circuitron.pcb_source != "mock";
    has_ar = bool([project ->:ProjectAr:->]);
    return [
        DependencyDisclosure(key="cad-worker", feature="STL / STEP export", available=False, required=False, owner="CAD worker", message="OpenSCAD source is available; mesh and STEP conversion needs a configured CAD worker."),
        DependencyDisclosure(key="pcb-worker", feature="PCB DRC / ERC", available=pcb_ready, required=True, owner="Circuitron / KiCad", message=("A real Circuitron result is attached." if pcb_ready else "No Circuitron or KiCad validation result is attached.")),
        DependencyDisclosure(key="firmware-worker", feature="Firmware build / flash", available=False, required=True, owner="CircuitPython toolchain", message="Generated CircuitPython is untested until a board-specific runner is configured."),
        DependencyDisclosure(key="stripe", feature="Fabrication checkout", available=False, required=False, owner="Stripe", message="Server quotes are available; payment requires verified Stripe configuration and webhook delivery."),
        DependencyDisclosure(key="ar-models", feature="Native AR handoff", available=has_ar, required=False, owner="AR exporter", message=("A project AR handoff is recorded." if has_ar else "Create a handoff after browser capability detection; native GLB/USDZ exports are not assumed."))
    ];
}

sv def:pub project_dependency_disclosures(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    for item in project_dependency_objects(project) {
        rows.append({
            "key": item.key,
            "feature": item.feature,
            "available": str(item.available),
            "required": str(item.required),
            "owner": item.owner,
            "message": item.message
        });
    }
    return rows;
}

sv def project_order_history_objects(project: Project) -> list[OrderHistoryRow] {
    rows: list[OrderHistoryRow] = [];
    for quote in [project ->:ProjectQuote:->] {
        orders = [quote ->:QuoteOrder:->];
        for order in orders {
            rows.append(OrderHistoryRow(
                order_id=jid(order),
                quote_id=jid(quote),
                status=str(order.status).split(".")[-1],
                quantity=quote.quantity,
                amount_cents=quote.amount_cents,
                currency=quote.currency,
                provider=order.provider,
                created_at="local",
                detail=order.details
            ));
        }
    }
    return rows;
}

sv def:pub get_project_order_history(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    for item in project_order_history_objects(project) {
        rows.append({
            "order_id": item.order_id,
            "quote_id": item.quote_id,
            "status": item.status,
            "quantity": str(item.quantity),
            "amount_cents": str(item.amount_cents),
            "currency": item.currency,
            "provider": item.provider,
            "created_at": item.created_at,
            "detail": item.detail
        });
    }
    return rows;
}

sv def:pub project_collaboration_snapshot(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    users = [project <-:Owns:<-];
    teams = [project <-:TeamProject:<-];
    activities = [project ->:ProjectActivityLog:->];
    last_activity = activities[-1].summary if activities else "No activity recorded yet.";
    team_name = teams[0].name if teams else "Local Hardware Lab";
    return {
        "ok": "true",
        "project_id": project_id,
        "shared": str(project.shared),
        "access_mode": ("read-only link" if project.shared else "private workspace"),
        "team_name": team_name,
        "member_count": str(len(users) if users else 1),
        "activity_count": str(len(activities)),
        "last_activity": last_activity,
        "auth_mode": "demo/local" if users else "unresolved"
    };
}

sv def project_health_object(project: Project) -> ProjectHealthReport {
    workspace = snapshot_project(project);
    evidence = project_readiness_evidence(project);
    blockers: list[str] = [];
    checks: list[dict[str, str]] = [];
    for item in evidence {
        checks.append({"key": item.key, "label": item.label, "state": item.state, "message": item.message, "source": item.source});
        if item.state != "verified" { blockers.append(item.message); }
    }
    for dependency in project_dependency_objects(project) {
        if dependency.required and not dependency.available { blockers.append(dependency.message); }
    }
    artifact_count = len(project_artifact_manifest_rows(project));
    status = "ready" if not blockers else "needs-attention";
    return ProjectHealthReport(
        project_id=jid(project),
        project_name=project.name,
        status=status,
        score=workspace.readiness_score,
        active_version=workspace.active_version,
        artifact_count=artifact_count,
        blockers=blockers,
        checks=checks
    );
}

sv def:pub get_project_health(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    health_result = project_health_object(project);
    return {
        "ok": "true",
        "project_id": health_result.project_id,
        "project_name": health_result.project_name,
        "status": health_result.status,
        "score": str(health_result.score),
        "active_version": health_result.active_version,
        "artifact_count": str(health_result.artifact_count),
        "blocker_count": str(len(health_result.blockers)),
        "blockers": " | ".join(health_result.blockers)
    };
}

sv def project_command_objects(project: Project) -> list[ProjectCommand] {
    workspace = snapshot_project(project);
    quote_exists = bool([project ->:ProjectQuote:->]);
    active_version = bool(active_version_for(project));
    return [
        ProjectCommand(key="generate", label="Generate revision", category="design", enabled=project.status == "active", reason=("Project is archived." if project.status != "active" else "Creates a new typed artifact version.")),
        ProjectCommand(key="restore", label="Restore version", category="versioning", enabled=active_version, reason=("No version graph exists." if not active_version else "An active version can be selected.")),
        ProjectCommand(key="validate", label="Run readiness audit", category="validation", enabled=active_version, reason=("Create a design version first." if not active_version else "Records evidence-backed readiness results.")),
        ProjectCommand(key="export", label="Build source bundle", category="export", enabled=active_version, reason=("No source artifacts exist." if not active_version else "Exports source files with dependency warnings.")),
        ProjectCommand(key="quote", label="Create prototype quote", category="manufacturing", enabled=active_version, reason=("A CAD and PCB graph is required." if not active_version else "Pricing is calculated server-side.")),
        ProjectCommand(key="checkout", label="Open checkout", category="manufacturing", enabled=False, reason=("Stripe checkout is not configured." if not quote_exists else "Verified payment configuration is required.")),
        ProjectCommand(key="share", label="Share read-only view", category="collaboration", enabled=project.status == "active", reason=("Archived projects cannot be shared." if project.status != "active" else "Creates project share metadata.")),
        ProjectCommand(key="ar", label="Create AR handoff", category="preview", enabled=active_version, reason=("A CAD version is required." if not active_version else workspace.ar_payload.preferred_mode))
    ];
}

sv def:pub get_project_commands(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    for command in project_command_objects(project) {
        rows.append({
            "key": command.key,
            "label": command.label,
            "category": command.category,
            "enabled": str(command.enabled),
            "reason": command.reason
        });
    }
    return rows;
}

sv def:pub get_project_export_records(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    for export in [project ->:ProjectExport:->] {
        rows.append({
            "id": jid(export),
            "format": export.format,
            "filename": export.filename,
            "version": export.version_label,
            "byte_length": str(export.byte_length),
            "created_at": export.created_at
        });
    }
    return rows;
}

sv def:pub validate_project_input(name: str, prompt: str) -> dict[str, str] {
    clean_name = normalized_project_name(name);
    clean_prompt = normalized_project_prompt(prompt);
    return {
        "ok": ("false" if not name.strip() or not prompt.strip() else "true"),
        "name": clean_name,
        "prompt": clean_prompt,
        "name_changed": str(clean_name != name),
        "prompt_changed": str(clean_prompt != prompt),
        "name_limit": "96",
        "prompt_limit": "12000",
        "message": ("A name and product brief are required." if not name.strip() or not prompt.strip() else "Project input is valid and normalized.")
    };
}

sv def:pub validate_quote_quantity(quantity: int) -> dict[str, str] {
    valid = quantity > 0 and quantity <= 10000;
    normalized = quantity if quantity > 0 else 1;
    if normalized > 10000 { normalized = 10000; }
    return {
        "ok": str(valid),
        "requested": str(quantity),
        "normalized": str(normalized),
        "minimum": "1",
        "maximum": "10000",
        "message": ("Quantity is within the server quote limits." if valid else "Quantity must be between 1 and 10000.")
    };
}

sv def:pub project_readiness_score(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    workspace = snapshot_project(project);
    evidence = project_readiness_evidence(project);
    verified = 0;
    warnings = 0;
    blocked = 0;
    for item in evidence {
        if item.state == "verified" { verified = verified + 1; }
        if item.state == "warning" or item.state == "not_run" { warnings = warnings + 1; }
        if item.state == "blocked" { blocked = blocked + 1; }
    }
    return {
        "ok": "true",
        "project_id": project_id,
        "score": str(workspace.readiness_score),
        "checks": str(len(evidence)),
        "verified": str(verified),
        "warnings": str(warnings),
        "blocked": str(blocked),
        "label": ("manufacturing-ready" if workspace.readiness_score >= 90 else "needs-review")
    };
}

sv def:pub readiness_blockers(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    for item in project_readiness_evidence(project) {
        if item.state != "verified" {
            rows.append({"key": item.key, "label": item.label, "state": item.state, "source": item.source, "message": item.message, "score_impact": str(item.score_impact)});
        }
    }
    return rows;
}

sv def:pub project_overview(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    versions = [project ->:ProjectVersion:->];
    activities = [project ->:ProjectActivityLog:->];
    health = project_health_object(project);
    deps = project_dependency_objects(project);
    unavailable = 0;
    for dependency in deps {
        if dependency.required and not dependency.available { unavailable = unavailable + 1; }
    }
    return {
        "ok": "true",
        "project_id": project_id,
        "name": project.name,
        "status": project.status,
        "shared": str(project.shared),
        "active_version": health.active_version,
        "version_count": str(len(versions)),
        "artifact_count": str(health.artifact_count),
        "activity_count": str(len(activities)),
        "readiness_score": str(health.score),
        "health_status": health.status,
        "dependency_blockers": str(unavailable),
        "last_updated": project.updated_at
    };
}

sv def:pub create_save_checkpoint(project_id: str, label: str = "manual checkpoint") -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    clean_label = label.strip() if label.strip() else "manual checkpoint";
    record_project_activity(project, "save", "checkpoint", f"Saved {clean_label} for {project.name}.");
    project.updated_at = "local";
    versions = [project ->:ProjectVersion:->];
    return {"ok": "true", "project_id": project_id, "label": clean_label, "active_version": (versions[-1].label if versions else "none"), "activity_count": str(len([project ->:ProjectActivityLog:->]))};
}

sv def:pub project_version_timeline(project_id: str) -> list[dict[str, str]] {
    project = project_by_id(project_id);
    if project is None { return []; }
    rows: list[dict[str, str]] = [];
    index = 0;
    for version in [project ->:ProjectVersion:->] {
        index = index + 1;
        row = project_version_row(project, version);
        row["sequence"] = str(index);
        row["state"] = ("active" if project.active_version_id == jid(version) else "available");
        rows.append(row);
    }
    return rows;
}

sv def:pub project_artifact_counts(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    counts = {"CAD": "0", "PCB": "0", "SCHEMATIC": "0", "FIRMWARE": "0", "BOM": "0"};
    for item in project_artifact_manifest_rows(project) {
        counts[item.artifact_type] = str(int(counts[item.artifact_type]) + 1);
    }
    counts["ok"] = "true";
    counts["project_id"] = project_id;
    counts["total"] = str(len(project_artifact_manifest_rows(project)));
    return counts;
}

sv def:pub transition_order(project_id: str, order_id: str, target_status: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    target = target_status.strip().upper();
    if target == "PAID" { return {"ok": "false", "error": "paid status requires a verified Stripe webhook"}; }
    for quote in [project ->:ProjectQuote:->] {
        for order in [quote ->:QuoteOrder:->] {
            if jid(order) == order_id {
                current = str(order.status).split(".")[-1];
                if target == "CANCELED" and current == "CHECKOUT_REQUIRED" {
                    order.status = OrderStatus.CANCELED;
                    order.details = "Canceled before payment; no fabrication order was created.";
                    record_project_activity(project, "cancel", "order", f"Canceled order {order_id} before payment.");
                    return {"ok": "true", "order_id": order_id, "status": "CANCELED", "message": order.details};
                }
                if target == "FAILED" and current == "CHECKOUT_REQUIRED" {
                    order.status = OrderStatus.FAILED;
                    order.details = "Checkout failed or was unavailable; no fabrication order was created.";
                    record_project_activity(project, "fail", "order", f"Recorded failed checkout for {order_id}.", "error");
                    return {"ok": "true", "order_id": order_id, "status": "FAILED", "message": order.details};
                }
                return {"ok": "false", "order_id": order_id, "status": current, "error": f"transition from {current} to {target} is not allowed"};
            }
        }
    }
    return {"ok": "false", "error": "order not found"};
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

sv walker:pub ProjectVersions {
    has project_id: str;
    can run with Root entry { report project_version_rows(self.project_id); }
}

sv walker:pub SearchProjects {
    has query: str = "",
        include_archived: bool = False;
    can run with Root entry { report search_projects(self.query, self.include_archived); }
}

sv walker:pub ArtifactManifest {
    has project_id: str;
    can run with Root entry { report get_artifact_manifest(self.project_id); }
}

sv walker:pub BOMAvailability {
    has project_id: str;
    can run with Root entry { report bom_availability_summary(self.project_id); }
}

sv walker:pub CADDimensions {
    has project_id: str;
    can run with Root entry { report cad_dimension_summary(self.project_id); }
}

sv walker:pub PCBDependencies {
    has project_id: str;
    can run with Root entry { report pcb_dependency_summary(self.project_id); }
}

sv walker:pub FirmwareDependencies {
    has project_id: str;
    can run with Root entry { report firmware_dependency_summary(self.project_id); }
}

sv walker:pub ARCapabilities {
    has project_id: str;
    can run with Root entry { report ar_capability_summary(self.project_id); }
}

sv walker:pub ProjectDependencies {
    has project_id: str;
    can run with Root entry { report project_dependency_disclosures(self.project_id); }
}

sv walker:pub ProjectCollaboration {
    has project_id: str;
    can run with Root entry { report project_collaboration_snapshot(self.project_id); }
}

sv walker:pub ProjectOrderHistory {
    has project_id: str;
    can run with Root entry { report get_project_order_history(self.project_id); }
}

sv walker:pub ProjectHealth {
    has project_id: str;
    can run with Root entry { report get_project_health(self.project_id); }
}

sv walker:pub ProjectCommands {
    has project_id: str;
    can run with Root entry { report get_project_commands(self.project_id); }
}

sv walker:pub ProjectExports {
    has project_id: str;
    can run with Root entry { report get_project_export_records(self.project_id); }
}

sv walker:pub ProjectOverview {
    has project_id: str;
    can run with Root entry { report project_overview(self.project_id); }
}

sv walker:pub ProjectReadinessScore {
    has project_id: str;
    can run with Root entry { report project_readiness_score(self.project_id); }
}

sv walker:pub ProjectReadinessBlockers {
    has project_id: str;
    can run with Root entry { report readiness_blockers(self.project_id); }
}

sv walker:pub ProjectVersionTimeline {
    has project_id: str;
    can run with Root entry { report project_version_timeline(self.project_id); }
}

sv walker:pub ProjectArtifactCounts {
    has project_id: str;
    can run with Root entry { report project_artifact_counts(self.project_id); }
}

sv walker:pub SaveCheckpoint {
    has project_id: str,
        label: str = "manual checkpoint";
    can run with Root entry { report create_save_checkpoint(self.project_id, self.label); }
}

sv walker:pub ValidateProjectInput {
    has name: str,
        prompt: str;
    can run with Root entry { report validate_project_input(self.name, self.prompt); }
}

sv walker:pub ValidateQuoteQuantity {
    has quantity: int;
    can run with Root entry { report validate_quote_quantity(self.quantity); }
}

sv walker:pub TransitionOrder {
    has project_id: str,
        order_id: str,
        target_status: str;
    can run with Root entry { report transition_order(self.project_id, self.order_id, self.target_status); }
}

sv walker:pub Health {
    can run with Root entry {
        report {"ok": True, "service": "helix-jac", "architecture": "native-jac", "version": "1.0.0"};
    }
}

def:pub app() -> JsxElement {
    return <HelixApp />;
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
