"use client";

import React, { useEffect, useMemo, useState } from "react";
import {
  Activity,
  ArrowRight,
  Blocks,
  Box,
  CheckCircle2,
  ChevronDown,
  CircleAlert,
  Clock3,
  Code2,
  Cpu,
  Download,
  ExternalLink,
  Factory,
  Glasses,
  Layers3,
  Loader2,
  MessageSquare,
  PanelRightOpen,
  Play,
  RotateCcw,
  Search,
  Send,
  ShieldCheck,
  Sparkles,
  SquareDashedMousePointer,
  Zap
} from "lucide-react";

type BomLine = {
  designators: string;
  description: string;
  mpn: string;
  manufacturer: string;
  qty: number;
  footprint: string;
  notes: string;
  supplier: string;
  unit_price: number;
  availability: string;
};

type BoardTemplate = {
  id: string;
  category: string;
  accent: string;
  title: string;
  tagline: string;
  description: string;
  bullets: string[];
  prompt: string;
};

type WorkspaceSnapshot = {
  project_id: string;
  name: string;
  prompt: string;
  active_version: string;
  cad_source: string;
  cad_document: {
    features: unknown[];
    openscad: { parameters: { name: string; display_name: string; value: string }[] };
    presentation: { open_face: string };
  };
  pcb_plan: string;
  circuitron: {
    pcb_source: string;
    width_mm: number;
    height_mm: number;
    layer_count: number;
    pcb_warnings: string[];
    design_validation: { summary: string };
  };
  schematic: string;
  firmware: string;
  bom_document: { lines: BomLine[] };
  validation: { name: string; status: string; score: string; notes: string }[];
  messages: { role: string; content: string; created_at: string }[];
  versions: { id: string; label: string; summary: string }[];
  templates: BoardTemplate[];
  tool_progress: { tool: string; status: string; message: string }[];
  fab_quote: { total_cents: number; lines: { key: string; name: string; unit_amount_cents: number; description: string }[] };
  ar_payload: { cad_summary: string; preferred_mode: string; byte_length: number };
  readiness_score: number;
  ar_ready: boolean;
  order_status: string;
};

type JacResponse<T> = { ok: boolean; data?: { result: T }; error?: { message: string } };
type ToolId = "cad" | "pcb" | "firmware" | "bom" | "validation" | "ar" | "order";
type RequestState = "idle" | "loading" | "error";
type CommandItem = {
  id: string;
  group: "Build" | "Navigate" | "Template" | "Inspect";
  label: string;
  detail: string;
  action: () => void;
};

const API_URL = process.env.NEXT_PUBLIC_HELIX_API_URL ?? "";

const starterTemplates: BoardTemplate[] = [
  { id: "plant-monitor", category: "Agritech", accent: "green", title: "Soil intelligence puck", tagline: "BLE moisture and light sensor", description: "A low-power enclosure, PCB, firmware loop, and BOM for plant-health telemetry.", bullets: ["Capacitive probe", "USB-C charging", "Snap-fit lid"], prompt: "Design a soil intelligence puck with BLE, capacitive moisture sensing, USB-C charging, LED status, enclosure, PCB, firmware, and BOM." },
  { id: "dog-feeder", category: "Home robotics", accent: "amber", title: "Servo dog feeder", tagline: "Scheduled kibble dispenser", description: "A compact motorized dispenser with safe actuation, serviceable shell, and server-priced prototype quote.", bullets: ["Servo gate", "RTC schedule", "Food-safe chute"], prompt: "Build a simple automatic dog feeder with a servo dispenser, schedule controls, enclosure, PCB, firmware, and BOM." },
  { id: "night-light", category: "Lighting", accent: "violet", title: "Adaptive night light", tagline: "Ambient-aware hallway light", description: "A dimming LED product with light sensing, soft firmware states, and manufacturable enclosure layers.", bullets: ["ALS input", "Warm LED rail", "USB power"], prompt: "Design an adaptive hallway night light with ambient sensing, warm LEDs, auto-off firmware, enclosure, PCB, and BOM." },
  { id: "macro-pad", category: "Desk hardware", accent: "blue", title: "Meeting macro pad", tagline: "Mute, camera, slides", description: "A USB HID accessory with labeled switches, firmware mapping, enclosure, PCB, and quote artifacts.", bullets: ["USB HID", "Tactile switches", "Label plate"], prompt: "Build a USB macro pad with buttons for mute, camera, and next slide, including PCB, firmware, enclosure, and BOM." },
  { id: "bike-beacon", category: "Outdoor", accent: "lime", title: "Brake-sensing bike beacon", tagline: "IMU-triggered rear light", description: "A weather-sealed rechargeable beacon with accelerometer braking and AR handoff metadata.", bullets: ["IMU braking", "Weather seal", "Rechargeable"], prompt: "Design a bike safety beacon with accelerometer brake sensing, bright LEDs, USB-C charging, enclosure, firmware, and BOM." },
  { id: "pill-timer", category: "Care", accent: "rose", title: "Medication reminder", tagline: "Pocket alert puck", description: "A small buzzer and LED-ring reminder with a conservative readiness audit and BOM substitutions.", bullets: ["Buzzer alert", "RTC", "Pocket shell"], prompt: "Design a medication reminder puck with buzzer, LED ring, buttons, battery, enclosure, firmware, PCB, and BOM." },
  { id: "desk-clock", category: "Desktop", accent: "slate", title: "Climate desk clock", tagline: "OLED time and humidity", description: "A minimal desk clock with sensor module, enclosure geometry, firmware loop, and manufacturing notes.", bullets: ["OLED", "RTC", "Temp sensor"], prompt: "Build a minimal USB desk clock with OLED, RTC, temperature sensor, enclosure, firmware, PCB, and BOM." },
  { id: "mailbox", category: "Home sensing", accent: "cyan", title: "Mailbox notifier", tagline: "Door-open telemetry", description: "A low-power reed-switch sensor with weatherproofing, radio notes, and fallback AR preview.", bullets: ["Reed switch", "Low-power radio", "Gasketed case"], prompt: "Design a mailbox door notifier with reed switch, low-power radio, battery, weatherproof enclosure, PCB, firmware, and BOM." },
  { id: "cat-fountain", category: "Pets", accent: "blue", title: "Pump cycle controller", tagline: "Quiet fountain schedule", description: "A MOSFET-driven pump controller with dry-run warnings, splash-aware enclosure, and firmware states.", bullets: ["Pump MOSFET", "Timed cycles", "Splash shell"], prompt: "Build a cat water fountain timer with USB pump control, timed firmware, splash-resistant enclosure, PCB, and BOM." },
  { id: "coffee-warmer", category: "Thermal", accent: "amber", title: "Safe coffee warmer", tagline: "Temperature-limited coaster", description: "A thermal product brief with NTC sensing, bounded heater logic, and explicit validation warnings.", bullets: ["NTC feedback", "Heater driver", "Thermal limit"], prompt: "Design a coffee mug warmer coaster with NTC sensing, heater driver, temperature limit firmware, enclosure, PCB, and BOM." },
  { id: "air-quality", category: "Environment", accent: "green", title: "Air quality tile", tagline: "Traffic-light desk sensor", description: "A compact sensor tile with ventilation geometry, status LEDs, PCB, firmware, and BOM availability.", bullets: ["VOC sensor", "LED status", "Vented shell"], prompt: "Build an air quality desk tile with VOC sensor, LED traffic-light status, USB-C, ventilated enclosure, PCB, firmware, and BOM." },
  { id: "badge", category: "Wearable", accent: "violet", title: "Conference e-ink badge", tagline: "Rechargeable identity display", description: "A lanyard-ready badge with e-ink module, buttons, enclosure, firmware, PCB, and prototype quote.", bullets: ["E-ink", "Buttons", "Lanyard case"], prompt: "Design a conference badge with e-ink display, buttons, battery, USB-C, lanyard enclosure, firmware, PCB, and BOM." }
];

const toolTabs: { id: ToolId; label: string; icon: React.ComponentType<{ size?: number }> }[] = [
  { id: "cad", label: "CAD", icon: Box },
  { id: "pcb", label: "PCB", icon: Layers3 },
  { id: "firmware", label: "Firmware", icon: Code2 },
  { id: "bom", label: "BOM", icon: Blocks },
  { id: "validation", label: "Validation", icon: ShieldCheck },
  { id: "ar", label: "AR", icon: Glasses },
  { id: "order", label: "Order", icon: Factory }
];

function cents(value: number) {
  return `$${(value / 100).toFixed(2)}`;
}

async function callJac<T>(path: string, body?: unknown): Promise<T> {
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 20000);
  try {
    const res = await fetch(`${API_URL}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body ?? {}),
      signal: controller.signal
    });
    const data = (await res.json()) as JacResponse<T>;
    if (!res.ok || !data.ok || !data.data) {
      throw new Error(data.error?.message ?? `Helix API failed at ${path}`);
    }
    return data.data.result;
  } finally {
    window.clearTimeout(timeout);
  }
}

function createProject(name: string, prompt: string) {
  return callJac<WorkspaceSnapshot>("/function/create_project", { name, prompt });
}

function loadWorkspace(project_id: string) {
  return callJac<WorkspaceSnapshot | null>("/function/load_workspace", { project_id });
}

function generateDesign(project_id: string, prompt: string) {
  return callJac<WorkspaceSnapshot | null>("/function/generate_hardware_design", { project_id, prompt });
}

function runValidation(project_id: string) {
  return callJac<WorkspaceSnapshot | null>("/function/run_validations", { project_id });
}

async function createQuote(project_id: string, quantity: number) {
  await callJac<Record<string, string>>("/function/create_fabrication_quote", { project_id, quantity });
  return loadWorkspace(project_id);
}

function HelixMark() {
  return (
    <div className="brand" aria-label="Helix">
      <span className="mark"><i /><i /><i /></span>
      <span>Helix</span>
    </div>
  );
}

function StatusPill({ state, label }: { state: RequestState; label: string }) {
  const Icon = state === "loading" ? Loader2 : state === "error" ? CircleAlert : CheckCircle2;
  return (
    <span className={`status ${state}`}>
      <Icon size={14} />
      {label}
    </span>
  );
}

function DesignStarter({ template, active, onSelect }: { template: BoardTemplate; active: boolean; onSelect: () => void }) {
  return (
    <button className={`starter ${active ? "selected" : ""}`} onClick={onSelect} type="button">
      <span className={`starter-dot ${template.accent}`} />
      <span className="starter-copy">
        <b>{template.title}</b>
        <small>{template.tagline}</small>
      </span>
      <ArrowRight size={15} />
    </button>
  );
}

function CommandPalette({ open, commands, onClose }: { open: boolean; commands: CommandItem[]; onClose: () => void }) {
  const [query, setQuery] = useState("");
  const visibleCommands = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    if (!normalized) return commands.slice(0, 12);
    return commands.filter((command) => `${command.group} ${command.label} ${command.detail}`.toLowerCase().includes(normalized)).slice(0, 12);
  }, [commands, query]);

  useEffect(() => {
    if (!open) {
      setQuery("");
      return;
    }
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") onClose();
    }
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [onClose, open]);

  if (!open) return null;

  return (
    <div className="palette-backdrop" role="presentation" onMouseDown={onClose}>
      <section className="command-palette" role="dialog" aria-modal="true" aria-label="Command palette" onMouseDown={(event) => event.stopPropagation()}>
        <div className="palette-input">
          <Search size={16} />
          <input autoFocus value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Run a command or choose a design" />
        </div>
        <div className="palette-list">
          {visibleCommands.length ? visibleCommands.map((command) => (
            <button
              key={command.id}
              type="button"
              onClick={() => {
                command.action();
                onClose();
              }}
            >
              <span>{command.group}</span>
              <b>{command.label}</b>
              <small>{command.detail}</small>
            </button>
          )) : (
            <div className="palette-empty">
              <CircleAlert size={18} />
              <p>No command matches that search.</p>
            </div>
          )}
        </div>
      </section>
    </div>
  );
}

function EmptyWorkspace({ onCreate, state }: { onCreate: () => void; state: RequestState }) {
  return (
    <section className="empty-workspace" aria-label="Empty workspace">
      <Sparkles size={28} />
      <h2>Generate the first engineering packet.</h2>
      <p>Helix will ask the JaC backend for CAD source, PCB intent, firmware, BOM rows, readiness checks, AR payload metadata, and a prototype quote state.</p>
      <button className="primary-action" onClick={onCreate} disabled={state === "loading"} type="button">
        {state === "loading" ? <Loader2 size={16} /> : <Play size={16} />}
        Start build
      </button>
    </section>
  );
}

function CopilotPanel({ snapshot, busy, onSend }: { snapshot: WorkspaceSnapshot | null; busy: boolean; onSend: (text: string) => Promise<void> }) {
  const [text, setText] = useState("Reduce the enclosure height, expose the sensor port, and update the validation summary.");
  const history = snapshot?.messages ?? [];
  const progress = snapshot?.tool_progress ?? [];

  return (
    <aside className="copilot-panel">
      <div className="panel-title">
        <span>Copilot</span>
        <b>Engineering thread</b>
      </div>
      <div className="thread-log" aria-live="polite">
        {!snapshot ? <p className="muted">Create a design to start a real JaC-backed conversation.</p> : null}
        {history.map((message, index) => (
          <article key={`${message.role}-${index}`} className="thread-message">
            <span>{message.role}</span>
            <p>{message.content}</p>
          </article>
        ))}
        {progress.map((item, index) => (
          <article key={`${item.tool}-${index}`} className="tool-progress">
            <span>{item.tool} · {item.status}</span>
            <p>{item.message}</p>
          </article>
        ))}
      </div>
      <form
        className="copilot-form"
        onSubmit={(event) => {
          event.preventDefault();
          void onSend(text);
        }}
      >
        <textarea value={text} onChange={(event) => setText(event.target.value)} disabled={!snapshot || busy} aria-label="Copilot instruction" />
        <button disabled={!snapshot || busy || !text.trim()} type="submit">
          {busy ? <Loader2 size={15} /> : <Send size={15} />}
          Send
        </button>
      </form>
    </aside>
  );
}

function CadViewport({ snapshot }: { snapshot: WorkspaceSnapshot }) {
  return (
    <section className="viewport-shell">
      <div className="viewport-toolbar" aria-label="CAD controls">
        <button type="button"><SquareDashedMousePointer size={15} />Fit</button>
        <button type="button"><RotateCcw size={15} />Reset</button>
        <button type="button"><PanelRightOpen size={15} />Inspect</button>
      </div>
      <div className="cad-scene" role="img" aria-label="Generated CAD model preview">
        <div className="axis x" />
        <div className="axis y" />
        <div className="cad-object">
          <span />
          <span />
          <span />
        </div>
      </div>
      <div className="viewport-caption">
        <b>{snapshot.cad_document.features.length} modeled features</b>
        <span>{snapshot.cad_document.presentation.open_face} assembly preview</span>
      </div>
    </section>
  );
}

function PcbViewport({ snapshot }: { snapshot: WorkspaceSnapshot }) {
  return (
    <section className="viewport-shell">
      <div className="viewport-toolbar">
        <button type="button"><Layers3 size={15} />Layers</button>
        <button type="button"><Activity size={15} />Nets</button>
        <button type="button"><Download size={15} />Export</button>
      </div>
      <div className="pcb-canvas" role="img" aria-label="Generated PCB layout preview">
        <span className="chip u1">U1</span>
        <span className="chip j1">J1</span>
        <span className="chip d1">D1</span>
        <i className="trace t1" />
        <i className="trace t2" />
        <i className="trace t3" />
      </div>
      <div className="viewport-caption">
        <b>{snapshot.circuitron.width_mm} x {snapshot.circuitron.height_mm} mm</b>
        <span>{snapshot.circuitron.layer_count} layers · DRC requires configured worker</span>
      </div>
    </section>
  );
}

function ArtifactPanel({ snapshot, tool }: { snapshot: WorkspaceSnapshot; tool: ToolId }) {
  if (tool === "cad") {
    return (
      <aside className="artifact-panel">
        <h3>CAD parameters</h3>
        {snapshot.cad_document.openscad.parameters.map((param) => (
          <label key={param.name}>
            <span>{param.display_name}</span>
            <input readOnly value={param.value} />
          </label>
        ))}
        <pre>{snapshot.cad_source}</pre>
      </aside>
    );
  }
  if (tool === "pcb") {
    return (
      <aside className="artifact-panel">
        <h3>PCB intelligence</h3>
        <p>{snapshot.circuitron.design_validation.summary}</p>
        {snapshot.circuitron.pcb_warnings.map((warning) => <p className="warning" key={warning}>{warning}</p>)}
        <pre>{snapshot.circuitron.pcb_source}</pre>
      </aside>
    );
  }
  if (tool === "firmware") {
    return <pre className="code-block">{snapshot.firmware}</pre>;
  }
  if (tool === "bom") {
    return (
      <section className="bom-table">
        <table>
          <thead>
            <tr><th>Ref</th><th>Component</th><th>MPN</th><th>Qty</th><th>Supplier</th><th>Unit</th><th>Availability</th></tr>
          </thead>
          <tbody>
            {snapshot.bom_document.lines.map((line) => (
              <tr key={line.designators}>
                <td>{line.designators}</td>
                <td>{line.description}</td>
                <td>{line.mpn}</td>
                <td>{line.qty}</td>
                <td>{line.supplier}</td>
                <td>{cents(Math.round(line.unit_price * 100))}</td>
                <td>{line.availability}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    );
  }
  if (tool === "validation") {
    return (
      <section className="result-stack">
        {snapshot.validation.map((check) => (
          <article key={check.name}>
            <b>{check.name}<span>{check.score}%</span></b>
            <p>{check.notes}</p>
          </article>
        ))}
      </section>
    );
  }
  if (tool === "ar") {
    return (
      <section className="handoff-card">
        <Glasses size={28} />
        <h3>Progressive AR handoff</h3>
        <p>{snapshot.ar_payload.preferred_mode}</p>
        <span>{snapshot.ar_payload.cad_summary} · {snapshot.ar_payload.byte_length} bytes · fallback never opens blank</span>
      </section>
    );
  }
  return (
    <section className="result-stack">
      {snapshot.fab_quote.lines.map((line) => (
        <article key={line.key}>
          <b>{line.name}<span>{cents(line.unit_amount_cents)}</span></b>
          <p>{line.description}</p>
        </article>
      ))}
      <h3>Total {cents(snapshot.fab_quote.total_cents)}</h3>
    </section>
  );
}

function Workspace({ snapshot, busy, onUpdate, setBusy, setError }: { snapshot: WorkspaceSnapshot; busy: boolean; onUpdate: (snapshot: WorkspaceSnapshot) => void; setBusy: (busy: boolean) => void; setError: (message: string) => void }) {
  const [tool, setTool] = useState<ToolId>("cad");
  const warnings = snapshot.circuitron.pcb_warnings.length + snapshot.validation.filter((check) => check.status !== "passed").length;

  async function validate() {
    setBusy(true);
    setError("");
    try {
      const next = await runValidation(snapshot.project_id);
      if (next) onUpdate(next);
    } catch (error) {
      setError(error instanceof Error ? error.message : "Validation failed.");
    } finally {
      setBusy(false);
    }
  }

  async function quote() {
    setBusy(true);
    setError("");
    try {
      const next = await createQuote(snapshot.project_id, 5);
      if (next) onUpdate(next);
    } catch (error) {
      setError(error instanceof Error ? error.message : "Quote creation failed.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="workspace" id="workspace">
      <div className="workspace-header">
        <div>
          <span className="eyebrow">Active JaC workspace</span>
          <h2>{snapshot.name}</h2>
          <p>{snapshot.prompt}</p>
        </div>
        <div className="workspace-actions">
          <button onClick={validate} disabled={busy} type="button"><ShieldCheck size={15} />Validate</button>
          <button onClick={quote} disabled={busy} type="button"><Factory size={15} />Quote</button>
        </div>
      </div>
      <div className="metric-row">
        <article><span>Readiness</span><b>{snapshot.readiness_score}%</b></article>
        <article><span>Version</span><b>{snapshot.active_version}</b></article>
        <article><span>BOM</span><b>{snapshot.bom_document.lines.length} lines</b></article>
        <article><span>Warnings</span><b>{warnings}</b></article>
      </div>
      <nav className="tool-tabs" aria-label="Workspace tools">
        {toolTabs.map(({ id, label, icon: Icon }) => (
          <button className={tool === id ? "active" : ""} key={id} onClick={() => setTool(id)} type="button">
            <Icon size={15} />
            {label}
          </button>
        ))}
      </nav>
      <div className="artifact-grid">
        {tool === "cad" ? <CadViewport snapshot={snapshot} /> : null}
        {tool === "pcb" ? <PcbViewport snapshot={snapshot} /> : null}
        {tool !== "cad" && tool !== "pcb" ? <div className="artifact-stage"><ArtifactPanel snapshot={snapshot} tool={tool} /></div> : null}
        {(tool === "cad" || tool === "pcb") ? <ArtifactPanel snapshot={snapshot} tool={tool} /> : null}
      </div>
    </section>
  );
}

export default function Page() {
  const [selectedId, setSelectedId] = useState(starterTemplates[0].id);
  const [name, setName] = useState(starterTemplates[0].title);
  const [prompt, setPrompt] = useState(starterTemplates[0].prompt);
  const [snapshot, setSnapshot] = useState<WorkspaceSnapshot | null>(null);
  const [requestState, setRequestState] = useState<RequestState>("idle");
  const [error, setError] = useState("");
  const [paletteOpen, setPaletteOpen] = useState(false);
  const selectedTemplate = useMemo(() => starterTemplates.find((template) => template.id === selectedId) ?? starterTemplates[0], [selectedId]);
  const generatedTemplates = useMemo(() => snapshot?.templates?.length ? [...snapshot.templates, ...starterTemplates].slice(0, 16) : starterTemplates, [snapshot]);

  async function build() {
    setRequestState("loading");
    setError("");
    try {
      setSnapshot(await createProject(name.trim() || selectedTemplate.title, prompt.trim() || selectedTemplate.prompt));
      setRequestState("idle");
      window.setTimeout(() => document.getElementById("workspace")?.scrollIntoView({ block: "start" }), 60);
    } catch (buildError) {
      setRequestState("error");
      setError(buildError instanceof Error ? buildError.message : "Could not reach the JaC backend. Start it on port 8000.");
    }
  }

  async function sendCopilot(text: string) {
    if (!snapshot) return;
    setRequestState("loading");
    setError("");
    try {
      const next = await generateDesign(snapshot.project_id, text);
      if (next) setSnapshot(next);
      setRequestState("idle");
    } catch (sendError) {
      setRequestState("error");
      setError(sendError instanceof Error ? sendError.message : "The copilot request failed.");
    }
  }

  function chooseTemplate(template: BoardTemplate) {
    setSelectedId(template.id);
    setName(template.title);
    setPrompt(template.prompt);
  }

  const commands = useMemo<CommandItem[]>(() => {
    const navigation: CommandItem[] = [
      { id: "nav-why", group: "Navigate", label: "Go to product brief", detail: "Return to the prompt and value proposition", action: () => window.scrollTo({ top: 0, behavior: "smooth" }) },
      { id: "nav-how", group: "Navigate", label: "Go to pipeline context", detail: "Show how the JaC snapshot feeds the UI", action: () => document.getElementById("operations")?.scrollIntoView({ block: "start" }) },
      { id: "nav-workspace", group: "Navigate", label: "Go to workspace", detail: "Jump to CAD, PCB, firmware, BOM, validation, AR, and order panels", action: () => document.getElementById("workspace")?.scrollIntoView({ block: "start" }) }
    ];
    const buildCommands: CommandItem[] = [
      { id: "build-current", group: "Build", label: "Build current prompt", detail: "Create a JaC-backed engineering packet", action: () => void build() },
      { id: "build-validate", group: "Build", label: "Review validation warning policy", detail: "Helix never shows fake DRC/ERC pass states", action: () => document.getElementById("operations")?.scrollIntoView({ block: "start" }) }
    ];
    const templateCommands = generatedTemplates.map<CommandItem>((template) => ({
      id: `template-${template.id}`,
      group: "Template",
      label: template.title,
      detail: template.description,
      action: () => chooseTemplate(template)
    }));
    const inspectCommands: CommandItem[] = toolTabs.map((tool) => ({
      id: `inspect-${tool.id}`,
      group: "Inspect",
      label: `Inspect ${tool.label}`,
      detail: snapshot ? `Open the ${tool.label} workspace after generation` : "Create a design first to inspect this artifact",
      action: () => document.getElementById("workspace")?.scrollIntoView({ block: "start" })
    }));
    return [...buildCommands, ...navigation, ...inspectCommands, ...templateCommands];
  }, [generatedTemplates, snapshot]);

  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setPaletteOpen(true);
      }
    }
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  return (
    <main className="shell">
      <CommandPalette open={paletteOpen} commands={commands} onClose={() => setPaletteOpen(false)} />
      <header className="topbar">
        <HelixMark />
        <button className="command-search" type="button" onClick={() => setPaletteOpen(true)}>
          <Search size={15} />
          <span>Search projects, commands, artifacts</span>
          <kbd>⌘K</kbd>
        </button>
        <a href="#workspace">Workspace <ChevronDown size={14} /></a>
      </header>

      <section className="hero narrative-panel">
        <div className="hero-copy">
          <span className="eyebrow">AI-native hardware engineering</span>
          <h1>Describe the product. Helix drafts the engineering system.</h1>
          <p>Generate CAD, PCB intent, firmware, BOM, validation notes, AR handoff metadata, and prototype quote state from the JaC backend without pretending unsupported manufacturing checks passed.</p>
          <div className="hero-actions">
            <button className="primary-action" onClick={build} disabled={requestState === "loading"} type="button">
              {requestState === "loading" ? <Loader2 size={16} /> : <Zap size={16} />}
              Build with JaC
            </button>
            <a className="secondary-action" href="#operations">View pipeline <ArrowRight size={15} /></a>
          </div>
          <div className="trust-row">
            <StatusPill state={requestState} label={requestState === "loading" ? "Generating" : requestState === "error" ? "Needs backend" : "JaC API ready"} />
            <span>60/40 target: JaC backend, Next.js TypeScript UI</span>
          </div>
        </div>
        <div className="build-card">
          <label>
            Product name
            <input value={name} onChange={(event) => setName(event.target.value)} />
          </label>
          <label>
            Engineering prompt
            <textarea value={prompt} onChange={(event) => setPrompt(event.target.value)} />
          </label>
          {error ? <p className="error-message"><CircleAlert size={15} />{error}</p> : null}
          <div className="packet-summary" aria-label="Generated packet summary">
            <span>Generated packet</span>
            <b>CAD · PCB · Firmware · BOM · AR · Quote</b>
            <p>JaC returns the source artifact graph; Next renders inspection, command, and handoff states.</p>
          </div>
        </div>
      </section>

      <section className="template-section" aria-label="Design options">
        <div className="section-heading">
          <span className="eyebrow">Design options</span>
          <h2>Choose a real product path, then edit the spec.</h2>
        </div>
        <div className="starter-list">
          {generatedTemplates.map((template) => (
            <DesignStarter key={template.id} template={template} active={template.id === selectedId} onSelect={() => chooseTemplate(template)} />
          ))}
        </div>
      </section>

      <section className="operations" id="operations">
        <div className="section-heading">
          <span className="eyebrow">Operational context</span>
          <h2>Every panel is tied to a JaC snapshot.</h2>
        </div>
        <div className="operations-grid">
          <article><Cpu size={18} /><b>Backend graph</b><p>Projects, versions, artifacts, conversations, validations, AR handoffs, and orders live in JaC structures.</p></article>
          <article><Clock3 size={18} /><b>Version state</b><p>Generation creates a new design version instead of mutating invisible mock state.</p></article>
          <article><ShieldCheck size={18} /><b>Honest checks</b><p>Validation calls return warnings when KiCad, Circuitron, firmware builds, or Stripe are not configured.</p></article>
        </div>
      </section>

      <div className="product-grid">
        <CopilotPanel snapshot={snapshot} busy={requestState === "loading"} onSend={sendCopilot} />
        {snapshot ? (
          <Workspace snapshot={snapshot} busy={requestState === "loading"} onUpdate={setSnapshot} setBusy={(busy) => setRequestState(busy ? "loading" : "idle")} setError={setError} />
        ) : (
          <EmptyWorkspace onCreate={build} state={requestState} />
        )}
      </div>

      <section className="next-step">
        <div>
          <span className="eyebrow">What next</span>
          <h2>Move from generated packet to prototype decision.</h2>
          <p>Run validation, inspect CAD and PCB assumptions, export source artifacts, then request a server-priced prototype quote when the backend is configured for checkout.</p>
        </div>
        <button className="secondary-action button-like" type="button" onClick={() => document.getElementById("workspace")?.scrollIntoView({ block: "start" })}>
          Continue in workspace <ExternalLink size={15} />
        </button>
      </section>

    </main>
  );
}
