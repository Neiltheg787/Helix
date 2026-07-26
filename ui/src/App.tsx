import React, { useMemo, useState } from "react";
import { Activity, Box, Cpu, Download, Glasses, Layers3, ListChecks, MessageSquare, Package, Play, RadioTower, Search, Sparkles, Zap } from "lucide-react";
import { createProject, createQuote, generateDesign, loadWorkspace, runValidation, type BoardTemplate, type WorkspaceSnapshot } from "./api";
import "./styles.css";

const starterTemplates: BoardTemplate[] = [
  { id: "plant-monitor", category: "Plants", accent: "green", title: "Houseplant soil watcher", tagline: "BLE moisture puck", description: "A low-power plant monitor with probe, LED, and BLE path.", bullets: ["Capacitive sensing", "USB-C charging", "Clip-on enclosure"], prompt: "Design a houseplant soil watcher with BLE, USB-C charging, LED status, probe connector, enclosure, firmware, and BOM." },
  { id: "dog-feeder", category: "Home robotics", accent: "amber", title: "Automatic dog feeder", tagline: "Scheduled kibble dispenser", description: "Motorized feeder with clean mechanical path and phone-adjustable schedule.", bullets: ["Servo gate", "RTC schedule", "Food-safe shell"], prompt: "Build a simple automatic dog feeder with a servo dispenser, schedule controls, enclosure, PCB, firmware, and BOM." },
  { id: "night-light", category: "Lighting", accent: "violet", title: "Hallway night light", tagline: "Warm auto-off light", description: "Ambient-aware night light that fades out after a timer.", bullets: ["ALS input", "Warm LED", "USB power"], prompt: "Design a hallway night light with ambient sensing, warm LEDs, auto-off firmware, enclosure, PCB, and BOM." },
  { id: "macro-pad", category: "Desk", accent: "blue", title: "Video-call macro pad", tagline: "Mute, camera, slides", description: "USB HID keypad for meeting controls and slide navigation.", bullets: ["Big switches", "USB HID", "Labelled case"], prompt: "Build a USB macro pad with big buttons for mute, camera, and next slide, including PCB, firmware, enclosure, and BOM." },
  { id: "bike-beacon", category: "Outdoor", accent: "lime", title: "Bike safety beacon", tagline: "Brake light and tracker", description: "Clip-on rear beacon with accelerometer brake detection.", bullets: ["IMU braking", "Weather seal", "Rechargeable"], prompt: "Design a bike safety beacon with accelerometer brake sensing, bright LEDs, USB-C charging, enclosure, firmware, and BOM." },
  { id: "pill-timer", category: "Health", accent: "rose", title: "Medication reminder", tagline: "Pocket reminder puck", description: "Small reminder with buzzer, LED ring, and simple buttons.", bullets: ["Buzzer alert", "RTC", "Pocket enclosure"], prompt: "Design a medication reminder puck with buzzer, LED ring, buttons, battery, enclosure, firmware, PCB, and BOM." },
  { id: "desk-clock", category: "Desk", accent: "slate", title: "Minimal desk clock", tagline: "OLED time and climate", description: "USB desk clock with temperature and humidity readout.", bullets: ["OLED display", "RTC", "Temp sensor"], prompt: "Build a minimal USB desk clock with OLED, RTC, temperature sensor, enclosure, firmware, PCB, and BOM." },
  { id: "mailbox", category: "Home", accent: "cyan", title: "Mailbox notifier", tagline: "Door-open ping", description: "Battery sensor that reports when the mailbox flap opens.", bullets: ["Reed switch", "Low-power radio", "Weatherproof case"], prompt: "Design a mailbox door notifier with reed switch, low-power radio, battery, weatherproof enclosure, PCB, firmware, and BOM." },
  { id: "cat-fountain", category: "Pets", accent: "blue", title: "Cat fountain timer", tagline: "Quiet pump schedule", description: "USB pump controller with dry-run awareness.", bullets: ["Pump MOSFET", "Timed cycles", "Splash-safe shell"], prompt: "Build a cat water fountain timer with USB pump control, timed firmware, splash-resistant enclosure, PCB, and BOM." },
  { id: "coffee-warmer", category: "Desk", accent: "amber", title: "Coffee warmer", tagline: "Safe temperature coaster", description: "Low-watt mug warmer with temperature limit.", bullets: ["NTC feedback", "Heater driver", "Thermal safety"], prompt: "Design a coffee mug warmer coaster with NTC sensing, heater driver, temperature limit firmware, enclosure, PCB, and BOM." },
  { id: "air-quality", category: "Environment", accent: "green", title: "Air quality tile", tagline: "CO2-style desk display", description: "Small desktop sensor tile with traffic-light status.", bullets: ["VOC sensor", "LED status", "Ventilated shell"], prompt: "Build an air quality desk tile with VOC sensor, LED traffic-light status, USB-C, ventilated enclosure, PCB, firmware, and BOM." },
  { id: "badge", category: "Wearable", accent: "violet", title: "Conference badge", tagline: "E-ink identity card", description: "Rechargeable badge with e-ink display and buttons.", bullets: ["E-ink display", "Buttons", "Lanyard case"], prompt: "Design a conference badge with e-ink display, buttons, battery, USB-C, lanyard enclosure, firmware, PCB, and BOM." }
];

function money(cents: number) {
  return `$${(cents / 100).toFixed(2)}`;
}

function Logo() {
  return <div className="brand"><div className="brand-mark"><span /><span /><span /></div><strong>Helix</strong></div>;
}

function TemplateGrid({ templates, onPick }: { templates: BoardTemplate[]; onPick: (template: BoardTemplate) => void }) {
  return <section className="template-grid" aria-label="Design starters">
    {templates.map((template) => <button key={template.id} className={`template ${template.accent}`} onClick={() => onPick(template)}>
      <span>{template.category}</span>
      <strong>{template.title}</strong>
      <p>{template.tagline}</p>
    </button>)}
  </section>;
}

function Workspace({ snapshot, onUpdate }: { snapshot: WorkspaceSnapshot; onUpdate: (next: WorkspaceSnapshot) => void }) {
  const [tool, setTool] = useState("cad");
  const quoteTotal = snapshot.fab_quote?.total_cents ?? 0;

  async function validate() {
    const next = await runValidation(snapshot.project_id);
    if (next) onUpdate(next);
  }

  async function quote() {
    await createQuote(snapshot.project_id, 5);
    const next = await loadWorkspace(snapshot.project_id);
    if (next) onUpdate(next);
  }

  const tools = [
    ["cad", Box, "CAD"],
    ["pcb", Layers3, "PCB"],
    ["bom", Package, "BOM"],
    ["code", Cpu, "Firmware"],
    ["validation", ListChecks, "Validation"],
    ["ar", Glasses, "AR"],
    ["order", RadioTower, "Order"]
  ] as const;

  return <main className="workspace">
    <header className="workspace-head">
      <div>
        <p>Active project</p>
        <h1>{snapshot.name}</h1>
        <span>{snapshot.prompt}</span>
      </div>
      <div className="head-actions">
        <button onClick={validate}><ListChecks size={16} />Validate</button>
        <button onClick={quote}><Zap size={16} />Quote</button>
      </div>
    </header>

    <section className="metrics">
      <article><span>Readiness</span><strong>{snapshot.readiness_score}%</strong></article>
      <article><span>Version</span><strong>{snapshot.active_version}</strong></article>
      <article><span>BOM lines</span><strong>{snapshot.bom_document.lines.length}</strong></article>
      <article><span>Quote</span><strong>{money(quoteTotal)}</strong></article>
    </section>

    <nav className="tools">
      {tools.map(([id, Icon, label]) => <button key={id} className={tool === id ? "active" : ""} onClick={() => setTool(id)}><Icon size={16} />{label}</button>)}
    </nav>

    {tool === "cad" && <section className="work-grid">
      <div className="cad-stage"><div className="model" /><p>{snapshot.cad_document.features.length} CAD features · {snapshot.cad_document.presentation.open_face} preview · OpenSCAD source ready</p></div>
      <aside className="panel"><h3>Parameters</h3>{snapshot.cad_document.openscad.parameters.map((p) => <label key={p.name}><span>{p.display_name}</span><input readOnly value={p.value} /></label>)}<pre>{snapshot.cad_source}</pre></aside>
    </section>}

    {tool === "pcb" && <section className="work-grid">
      <div className="pcb-stage"><div className="board"><b>U1</b><b>J1</b><b>D1</b></div><p>{snapshot.pcb_plan}</p></div>
      <aside className="panel"><h3>Circuitron</h3><p>{snapshot.circuitron.design_validation.summary}</p><p>{snapshot.circuitron.width_mm} x {snapshot.circuitron.height_mm} mm · {snapshot.circuitron.layer_count} layers</p>{snapshot.circuitron.pcb_warnings.map((w) => <p key={w} className="warning">{w}</p>)}</aside>
    </section>}

    {tool === "bom" && <section className="panel table-panel"><table><thead><tr><th>Ref</th><th>Part</th><th>MPN</th><th>Qty</th><th>Supplier</th><th>Unit</th></tr></thead><tbody>{snapshot.bom_document.lines.map((line) => <tr key={line.designators}><td>{line.designators}</td><td>{line.description}</td><td>{line.mpn}</td><td>{line.qty}</td><td>{line.supplier}</td><td>{money(Math.round(line.unit_price * 100))}</td></tr>)}</tbody></table></section>}

    {tool === "code" && <section className="work-grid"><pre>{snapshot.firmware}</pre><aside className="panel"><h3>Schematic</h3><pre>{snapshot.schematic}</pre></aside></section>}
    {tool === "validation" && <section className="panel stack">{snapshot.validation.map((v) => <article key={v.name}><strong>{v.name} · {v.score}%</strong><p>{v.notes}</p></article>)}</section>}
    {tool === "ar" && <section className="panel ar-card"><Glasses size={30} /><h3>AR handoff</h3><p>{snapshot.ar_payload.preferred_mode}</p><p>{snapshot.ar_payload.cad_summary} · {snapshot.ar_payload.byte_length} bytes</p></section>}
    {tool === "order" && <section className="panel stack">{snapshot.fab_quote.lines.map((line) => <article key={line.key}><strong>{line.name}<span>{money(line.unit_amount_cents)}</span></strong><p>{line.description}</p></article>)}<h2>Total {money(snapshot.fab_quote.total_cents)}</h2></section>}
  </main>;
}

export default function App() {
  const [name, setName] = useState("Helix design");
  const [prompt, setPrompt] = useState(starterTemplates[0].prompt);
  const [snapshot, setSnapshot] = useState<WorkspaceSnapshot | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const templates = useMemo(() => snapshot?.templates?.length ? [...snapshot.templates, ...starterTemplates].slice(0, 18) : starterTemplates, [snapshot]);

  async function create() {
    setBusy(true);
    setMessage("");
    try {
      setSnapshot(await createProject(name, prompt));
    } catch (err) {
      setMessage(err instanceof Error ? err.message : "Could not create project. Start the JaC backend on port 8000.");
    } finally {
      setBusy(false);
    }
  }

  async function sendCopilot(text: string) {
    if (!snapshot || !text.trim()) return;
    setBusy(true);
    try {
      const next = await generateDesign(snapshot.project_id, text.trim());
      if (next) setSnapshot(next);
    } finally {
      setBusy(false);
    }
  }

  return <div className="app">
    <header className="topbar">
      <Logo />
      <div className="search"><Search size={16} /><input aria-label="Search Helix" placeholder="Search designs, parts, commands" /></div>
      <button className="primary" onClick={create} disabled={busy}><Play size={16} />{busy ? "Working" : "Build"}</button>
    </header>

    <section className="launcher">
      <div className="prompt-card">
        <p>Describe a product</p>
        <input value={name} onChange={(e) => setName(e.target.value)} />
        <textarea value={prompt} onChange={(e) => setPrompt(e.target.value)} />
        {message ? <small>{message}</small> : null}
      </div>
      <TemplateGrid templates={templates} onPick={(template) => { setName(template.title); setPrompt(template.prompt); }} />
    </section>

    <div className="main-grid">
      <aside className="copilot">
        <div><p>AI engineering copilot</p><h2>Build thread</h2></div>
        <div className="thread">
          {(snapshot?.messages ?? []).map((m) => <article key={`${m.role}-${m.content}`}><strong>{m.role}</strong><p>{m.content}</p></article>)}
          {(snapshot?.tool_progress ?? []).map((p) => <article key={`${p.tool}-${p.message}`}><strong>{p.tool} · {p.status}</strong><p>{p.message}</p></article>)}
        </div>
        <CopilotBox disabled={!snapshot || busy} onSend={sendCopilot} />
      </aside>
      {snapshot ? <Workspace snapshot={snapshot} onUpdate={setSnapshot} /> : <section className="empty-state"><Sparkles size={34} /><h1>Pick a design starter or write your own.</h1><p>Helix will ask the JaC backend to generate CAD, PCB, firmware, BOM, validation, AR, and quote data.</p></section>}
    </div>
  </div>;
}

function CopilotBox({ disabled, onSend }: { disabled: boolean; onSend: (text: string) => void }) {
  const [text, setText] = useState("Make it smaller, add snap-fit tabs, and prepare a prototype quote.");
  return <div className="copilot-box"><textarea value={text} onChange={(e) => setText(e.target.value)} /><button disabled={disabled} onClick={() => onSend(text)}><MessageSquare size={16} />Send</button></div>;
}
