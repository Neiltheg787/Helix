"""Helix native Jac application.

The graph is the product workspace: users, teams, projects, generated artifacts,
versions, validations, AR handoffs, and manufacturing orders are persisted as
reachable nodes connected by typed edges. Public walkers provide the backend API
and the Jac client UI calls those server functions directly.
"""

import "./styles.css";

enum ArtifactKind { CAD, PCB, SCHEMATIC, FIRMWARE, BOM, VALIDATION, AR, ORDER }
enum Severity { INFO, WARNING, ERROR }
enum OrderStatus { DRAFT, QUOTED, CHECKOUT_REQUIRED, PAID, CANCELED, FAILED }

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
        pcb_plan: str,
        firmware: str,
        bom_items: list[dict[str, str]],
        validation: list[str],
        changes: list[DesignChange];
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
        active_version: str,
        cad_source: str,
        pcb_plan: str,
        schematic: str,
        firmware: str,
        bom_items: list[dict[str, str]],
        validation: list[dict[str, str]],
        messages: list[dict[str, str]],
        versions: list[dict[str, str]],
        readiness_score: int,
        ar_ready: bool,
        order_status: str;
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
        format: str = "openscad",
        dimensions: str = "80mm x 52mm x 24mm",
        export_status: str = "OpenSCAD source ready; STL/STEP require configured CAD worker.";
}

node PCBArtifact {
    has name: str,
        plan: str,
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
        language: str = "cpp",
        build_status: str = "Untested; connect firmware build worker.";
}

node BOM {
    has name: str,
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

sem synthesize_hardware_design = "Return concrete CAD, PCB, firmware, BOM, validation, and change summaries for a described physical electronics product. Never claim validations passed without evidence.";
def synthesize_hardware_design(product_prompt: str, project_context: str) -> GenerationResult by llm();

def fallback_generation(prompt: str) -> GenerationResult {
    return GenerationResult(
        ok=False,
        summary=f"AI provider is not configured; Helix created a deterministic local starter design for: {prompt}.",
        cad_source="module enclosure(width=80, depth=52, height=24, wall=2) { difference() { cube([width, depth, height], center=true); translate([0,0,2]) cube([width-wall*2, depth-wall*2, height], center=true); } } enclosure();",
        pcb_plan="Two-layer controller board, 50mm x 35mm, USB-C power/input, MCU, status LED, sensor header, programming pads. DRC not run.",
        firmware="#include <Arduino.h>\nvoid setup(){ Serial.begin(115200); pinMode(13, OUTPUT); }\nvoid loop(){ digitalWrite(13, millis() / 500 % 2); }",
        bom_items=[
            {"component_name": "MCU module", "reference": "U1", "manufacturer": "Espressif", "manufacturer_part_number": "ESP32-S3-MINI-1", "quantity": "1", "unit_price": "4.20", "availability": "check supplier", "supplier": "Digi-Key", "substitutions": "ESP32-C3-MINI"},
            {"component_name": "USB-C connector", "reference": "J1", "manufacturer": "GCT", "manufacturer_part_number": "USB4105", "quantity": "1", "unit_price": "0.68", "availability": "in stock typical", "supplier": "Mouser", "substitutions": "HRO TYPE-C-31-M-12"},
            {"component_name": "Status LED", "reference": "D1", "manufacturer": "Kingbright", "manufacturer_part_number": "APT1608", "quantity": "1", "unit_price": "0.08", "availability": "in stock typical", "supplier": "LCSC", "substitutions": "Any 0603 green LED"}
        ],
        validation=[
            "CAD generated as OpenSCAD source only; STL/STEP worker not configured.",
            "PCB plan exists but KiCad DRC/ERC has not run.",
            "Firmware is starter Arduino code and is untested on hardware."
        ],
        changes=[
            DesignChange(target="CAD", summary="Created parameterized enclosure OpenSCAD source.", status="proposed", file_ref="cad/enclosure.scad"),
            DesignChange(target="PCB", summary="Created two-layer board plan and dependencies disclosure.", status="proposed", file_ref="pcb/board.plan"),
            DesignChange(target="Firmware", summary="Created starter firmware with serial and status LED.", status="proposed", file_ref="firmware/main.cpp"),
            DesignChange(target="BOM", summary="Created prototype BOM with supplier and substitution fields.", status="proposed", file_ref="bom/items.json")
        ]
    );
}

def get_or_create_demo_user -> User {
    users = [root-->][?:User];
    if users { return users[0]; }
    user = root ++> User(email="demo@helix.local", display_name="Helix Demo");
    team = root ++> Team(name="Local Hardware Lab");
    user +>: MemberOf(access="owner") :+> team;
    return user;
}

def project_by_id(project_id: str) -> Project | None {
    for project in [root-->][?:Project] {
        if jid(project) == project_id { return project; }
    }
    return None;
}

def compute_total(items: list[dict[str, str]]) -> float {
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

def score_validation(notes: list[str]) -> int {
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

def attach_version(project: Project, result: GenerationResult, label: str) -> DesignVersion {
    version = DesignVersion(label=label, summary=result.summary);
    project +>: ProjectVersion() :+> version;
    cad = CADArtifact(name="enclosure.scad", source=result.cad_source);
    pcb = PCBArtifact(name="board.plan", plan=result.pcb_plan);
    schematic = SchematicArtifact(name="schematic.net", netlist="USB-C -> regulator -> MCU; MCU GPIO -> sensor header; MCU GPIO -> LED.");
    firmware = FirmwareArtifact(name="main.cpp", source=result.firmware);
    bom = BOM(name="prototype-bom", total_estimate=compute_total(result.bom_items));
    version +>: VersionCad() :+> cad;
    version +>: VersionPcb() :+> pcb;
    version +>: VersionSchematic() :+> schematic;
    version +>: VersionFirmware() :+> firmware;
    version +>: VersionBom() :+> bom;
    for item in result.bom_items {
        bom +>: BomLine() :+> BOMItem(
            component_name=item["component_name"],
            reference=item["reference"],
            manufacturer=item["manufacturer"],
            manufacturer_part_number=item["manufacturer_part_number"],
            quantity=int(item["quantity"]),
            unit_price=float(item["unit_price"]),
            availability=item["availability"],
            supplier=item["supplier"],
            substitutions=item["substitutions"]
        );
    }
    validation = ValidationRun(name="Manufacturing readiness", score=score_validation(result.validation), status="warnings", notes=result.validation);
    project +>: ProjectValidation() :+> validation;
    return version;
}

def snapshot_project(project: Project) -> WorkspaceSnapshot {
    versions = [project ->:ProjectVersion:->];
    active = versions[-1] if versions else attach_version(project, fallback_generation(project.prompt), "v1");
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
    if boms {
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
    return WorkspaceSnapshot(
        project_id=jid(project),
        name=project.name,
        prompt=project.prompt,
        active_version=active.label,
        cad_source=cads[0].source if cads else "",
        pcb_plan=pcbs[0].plan if pcbs else "",
        schematic=schematics[0].netlist if schematics else "",
        firmware=firmwares[0].source if firmwares else "",
        bom_items=bom_rows,
        validation=val_rows,
        messages=msgs,
        versions=version_rows,
        readiness_score=readiness,
        ar_ready=bool([project ->:ProjectAr:->]),
        order_status=str(quotes[-1].status).split(".")[-1] if quotes else "DRAFT"
    );
}

def:pub list_projects -> list[dict[str, str]] {
    get_or_create_demo_user();
    rows: list[dict[str, str]] = [];
    for project in [root-->][?:Project] {
        rows.append({"id": jid(project), "name": project.name, "prompt": project.prompt, "status": project.status});
    }
    return rows;
}

def:pub create_project(name: str, prompt: str) -> WorkspaceSnapshot {
    user = get_or_create_demo_user();
    project = root ++> Project(name=name, prompt=prompt);
    user +>: Owns() :+> project;
    teams = [user ->:MemberOf:->];
    if teams { teams[0] +>: TeamProject() :+> project; }
    result = fallback_generation(prompt);
    attach_version(project, result, "v1 local draft");
    conv = Conversation(title=f"{name} copilot");
    project +>: ProjectConversation() :+> conv;
    conv +>: ConversationMessage() :+> Message(role="assistant", content=result.summary);
    return snapshot_project(project);
}

def:pub load_workspace(project_id: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    return snapshot_project(project);
}

def:pub generate_hardware_design(project_id: str, prompt: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    try {
        result = synthesize_hardware_design(prompt, snapshot_project(project).cad_source);
    } except Exception {
        result = fallback_generation(prompt);
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
    conv +>: ConversationMessage() :+> Message(role="user", content=prompt);
    conv +>: ConversationMessage() :+> Message(role="assistant", content=result.summary);
    project.updated_at = "local";
    return snapshot_project(project);
}

def:pub run_validations(project_id: str) -> WorkspaceSnapshot | None {
    project = project_by_id(project_id);
    if project is None { return None; }
    notes = [
        "Geometry source exists and exposes dimensions.",
        "PCB DRC not run; configure KiCad/Circuitron worker before manufacturing.",
        "Firmware build not run; configure toolchain before flashing.",
        "BOM includes supplier and substitution fields."
    ];
    project +>: ProjectValidation() :+> ValidationRun(name="Readiness audit", score=score_validation(notes), status="warnings", notes=notes);
    return snapshot_project(project);
}

def:pub create_ar_handoff(project_id: str, capability: ArCapability) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    token = "ar-" + project_id[:8];
    handoff = ARHandoff(token=token, model_format="glb/usdz/open-scad-source", expires_at="24h", status="ready-with-fallback", dimensions=snapshot_project(project).cad_source[:80], fallback=capability.fallback);
    project +>: ProjectAr() :+> handoff;
    return {"ok": "true", "token": token, "fallback": capability.fallback, "message": capability.message};
}

def:pub create_fabrication_quote(project_id: str, quantity: int) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    qty = quantity if quantity > 0 else 1;
    amount = 4200 + qty * 1850;
    quote = ManufacturingQuote(status=OrderStatus.QUOTED, quantity=qty, amount_cents=amount, details="Server-priced prototype quote. Stripe checkout requires STRIPE_SECRET_KEY.");
    order = Order(status=OrderStatus.CHECKOUT_REQUIRED, details="Stripe not configured in local Jac deployment.");
    project +>: ProjectQuote() :+> quote;
    quote +>: QuoteOrder() :+> order;
    return {"ok": "true", "amount_cents": str(amount), "currency": "usd", "status": "CHECKOUT_REQUIRED", "details": quote.details};
}

def:pub share_project(project_id: str) -> dict[str, str] {
    project = project_by_id(project_id);
    if project is None { return {"ok": "false", "error": "project not found"}; }
    project.shared = True;
    return {"ok": "true", "share_url": f"/share/{project_id}"};
}

walker:pub CreateProject {
    has name: str,
        prompt: str;
    can run with Root entry { report create_project(self.name, self.prompt); }
}

walker:pub LoadWorkspace {
    has project_id: str;
    can run with Root entry { report load_workspace(self.project_id); }
}

walker:pub GenerateHardwareDesign {
    has project_id: str,
        prompt: str;
    can run with Root entry { report generate_hardware_design(self.project_id, self.prompt); }
}

walker:pub RunValidations {
    has project_id: str;
    can run with Root entry { report run_validations(self.project_id); }
}

walker:pub Health {
    can run with Root entry {
        report {"ok": True, "service": "helix-jac", "architecture": "native-jac", "version": "1.0.0"};
    }
}

def button_class(kind: str) -> str {
    return "button primary" if kind == "primary" else "button";
}

def:pub Logo -> JsxElement {
    return <div className="logo-wrap" aria-label="Helix">
        <div className="helix-mark"><span></span><span></span><span></span></div>
        <strong>Helix</strong>
    </div>;
}

def:pub Metric(label: str, value: str, tone: str = "neutral") -> JsxElement {
    return <div className={"metric " + tone}>
        <span>{label}</span>
        <strong>{value}</strong>
    </div>;
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
    return <aside className="copilot">
        <div className="panel-head">
            <h2>AI Copilot</h2>
            <span>{("running" if loading else "ready")}</span>
        </div>
        <div className="messages">
            {[<div key={m["role"] + m["content"]} className={"message " + m["role"]}>
                <strong>{m["role"]}</strong>
                <p>{m["content"]}</p>
            </div> for m in messages]}
            {error and <div className="message error"><strong>Error</strong><p>{error}</p></div>}
        </div>
        <textarea value={prompt} onChange={lambda (e: ChangeEvent) { prompt = e.target.value; }} />
        <div className="row">
            <button className={button_class("primary")} disabled={loading} onClick={lambda { send(); }}>{("Stop unavailable" if loading else "Generate")}</button>
            <button className="button" onClick={lambda { prompt = "Revise the enclosure for snap-fit tabs and expose mounting bosses."; }}>Suggest</button>
        </div>
    </aside>;
}

def:pub Workspace(snapshot: WorkspaceSnapshot | None, onUpdate: Callable[[WorkspaceSnapshot], None]) -> JsxElement {
    has tab: str = "Design",
        ar_status: str = "Not launched";
    if snapshot is None {
        return <main className="empty">
            <h1>Describe hardware. Get an engineering workspace.</h1>
            <p>Create a first project to generate CAD, PCB, firmware, BOM, validation state, AR handoff, and manufacturing quote records in Jac.</p>
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
                <p className="eyebrow">Project</p>
                <h1>{snapshot.name}</h1>
                <p>{snapshot.prompt}</p>
            </div>
            <div className="actions">
                <button className="button" onClick={validate}>Validate</button>
                <button className="button" onClick={ar}>AR</button>
                <button className={button_class("primary")} onClick={quote}>Quote</button>
            </div>
        </header>
        <section className="metrics">
            <Metric label="Readiness" value={str(snapshot.readiness_score) + "%"} tone="green" />
            <Metric label="Version" value={snapshot.active_version} />
            <Metric label="Order" value={snapshot.order_status} />
            <Metric label="AR" value={("Ready" if snapshot.ar_ready else "Fallback")} tone="lime" />
        </section>
        <nav className="tabs">
            {[<button key={name} className={("active" if tab == name else "")} onClick={lambda { tab = name; }}>{name}</button> for name in ["Design", "PCB", "Schematic", "Firmware", "BOM", "Validation", "AR"]]}
        </nav>
        <section className="canvas">
            {tab == "Design" and <div className="split">
                <pre>{snapshot.cad_source}</pre>
                <div className="viewer"><div className="model-box"></div><p>OpenSCAD source viewer. STL/STEP export requires configured CAD worker.</p></div>
            </div>}
            {tab == "PCB" and <div className="viewer"><h3>PCB plan</h3><p>{snapshot.pcb_plan}</p><p>Layer visibility and DRC require KiCad/Circuitron service.</p></div>}
            {tab == "Schematic" and <pre>{snapshot.schematic}</pre>}
            {tab == "Firmware" and <pre>{snapshot.firmware}</pre>}
            {tab == "BOM" and <table>
                <thead><tr><th>Ref</th><th>Name</th><th>MPN</th><th>Qty</th><th>Unit</th><th>Supplier</th><th>Availability</th></tr></thead>
                <tbody>{[<tr key={item["reference"]}><td>{item["reference"]}</td><td>{item["component_name"]}</td><td>{item["manufacturer_part_number"]}</td><td>{item["quantity"]}</td><td>${item["unit_price"]}</td><td>{item["supplier"]}</td><td>{item["availability"]}</td></tr> for item in snapshot.bom_items]}</tbody>
            </table>}
            {tab == "Validation" and <div>{[<div key={v["name"]} className="validation"><strong>{v["name"]} - {v["score"]}%</strong><p>{v["notes"]}</p></div> for v in snapshot.validation]}</div>}
            {tab == "AR" and <div className="viewer ar"><h3>AR preview</h3><p>{ar_status}</p><p>Progressive enhancement: WebXR, Quick Look, Scene Viewer, camera preview, then interactive 3D fallback.</p><div className="model-box"></div></div>}
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
                <input value={new_name} onChange={lambda (e: ChangeEvent) { new_name = e.target.value; }} />
                <textarea value={new_prompt} onChange={lambda (e: ChangeEvent) { new_prompt = e.target.value; }} />
                <button className={button_class("primary")} disabled={busy} onClick={create}>{("Creating..." if busy else "Create project")}</button>
            </div>
            <div className="project-list">
                {[<button key={p["id"]} onClick={lambda { open_project(p["id"]); }}>{p["name"]}</button> for p in projects]}
            </div>
        </aside>
        <Copilot snapshot={active} project_id={(active.project_id if active is not None else "")} onUpdate={lambda (s: WorkspaceSnapshot) { active = s; }} />
        <Workspace snapshot={active} onUpdate={lambda (s: WorkspaceSnapshot) { active = s; }} />
    </div>;
}

test "fallback generation has concrete artifacts" {
    result = fallback_generation("usb sensor");
    assert not result.ok;
    assert "OpenSCAD" in result.summary or "starter" in result.summary;
    assert len(result.bom_items) >= 3;
}

test "validation score penalizes unrun checks" {
    score = score_validation(["DRC not run", "Firmware untested", "BOM ok"]);
    assert score < 82;
    assert score > 0;
}
