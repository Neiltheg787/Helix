"use client";

import React, {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState
} from "react";
import {
  Activity,
  Aperture,
  ArrowDownToLine,
  Box,
  Boxes,
  Braces,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  CircleAlert,
  CircuitBoard,
  Code2,
  Command,
  Cpu,
  Download,
  Expand,
  Factory,
  FileCode2,
  Focus,
  Gauge,
  GitBranch,
  Glasses,
  Grid3X3,
  Layers3,
  Loader2,
  Maximize2,
  Menu,
  Mic,
  MousePointer2,
  Package,
  Paperclip,
  PanelRight,
  Play,
  Redo2,
  Rotate3D,
  ScanLine,
  Search,
  Send,
  Settings2,
  ShieldCheck,
  Sparkles,
  Square,
  StopCircle,
  Undo2,
  WandSparkles,
  X,
  Zap
} from "lucide-react";

type Vec3 = { x: number; y: number; z: number };
type CadParameter = {
  name: string;
  display_name: string;
  value: string;
  min_value?: number;
  max_value?: number;
  step?: number;
};
type CadFeature = {
  id: string;
  op: string;
  shape: string;
  position_mm: Vec3;
  rotation_deg: Vec3;
  size_mm: Vec3;
  radius_mm: number;
  height_mm: number;
  label: string;
};
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
  tagline: string;
  active_version: string;
  cad_source: string;
  cad_document: {
    features: CadFeature[];
    openscad: { parameters: CadParameter[] };
    presentation: { open_face: string };
  };
  pcb_plan: string;
  pcb_ops: {
    width_mm: number;
    height_mm: number;
    layer_count: number;
    min_trace_mm: number;
    min_clearance_mm: number;
  };
  circuitron: {
    pcb_source: string;
    width_mm: number;
    height_mm: number;
    layer_count: number;
    pcb_warnings: string[];
    design_validation: {
      passed: number;
      warnings: number;
      errors: number;
      summary: string;
    };
  };
  schematic: string;
  firmware: string;
  bom_document: { lines: BomLine[] };
  validation: { name: string; status: string; score: string; notes: string }[];
  messages: { role: string; content: string; created_at: string }[];
  versions: { id: string; label: string; summary: string }[];
  templates: BoardTemplate[];
  tool_progress: { tool: string; status: string; message: string }[];
  fab_quote: {
    total_cents: number;
    lines: { key: string; name: string; unit_amount_cents: number; description: string }[];
  };
  ar_payload: { cad_summary: string; preferred_mode: string; byte_length: number };
  readiness_score: number;
  ar_ready: boolean;
  order_status: string;
};
type JacResponse<T> = { ok: boolean; data?: { result: T }; error?: { message: string } };
type ToolId = "design" | "pcb" | "schematic" | "firmware" | "bom" | "validation" | "ar" | "manufacturing";
type DockTab = "core" | "inspect" | "thread";
type RequestState = "idle" | "loading" | "error" | "cancelled";
type Dimensions = { width: number; depth: number; height: number; wall: number };
type ThreeHandle = { fit: () => void; reset: () => void };
type LayerVisibility = { shell: boolean; lid: boolean; pcb: boolean; hardware: boolean };
type Telemetry = { load: number; tokens: number; confidence: number };
type ArSupport = {
  secure: boolean;
  camera: boolean;
  webxr: boolean;
  quickLook: boolean;
  sceneViewer: boolean;
};
type SpeechRecognitionResultEventLike = Event & {
  results: { item(index: number): { item(index: number): { transcript: string } } };
};
type SpeechRecognitionLike = {
  continuous: boolean;
  interimResults: boolean;
  lang: string;
  start: () => void;
  stop: () => void;
  onresult: ((event: SpeechRecognitionResultEventLike) => void) | null;
  onend: (() => void) | null;
  onerror: (() => void) | null;
};
type SpeechRecognitionConstructor = new () => SpeechRecognitionLike;

declare global {
  interface Window {
    SpeechRecognition?: SpeechRecognitionConstructor;
    webkitSpeechRecognition?: SpeechRecognitionConstructor;
  }
}

const API_URL = process.env.NEXT_PUBLIC_HELIX_API_URL ?? "";
const DEFAULT_DIMENSIONS: Dimensions = { width: 80, depth: 52, height: 24, wall: 2 };
const DEFAULT_LAYERS: LayerVisibility = { shell: true, lid: true, pcb: true, hardware: true };

const starterTemplates: BoardTemplate[] = [
  { id: "sensor-node", category: "Sensing", accent: "cyan", title: "Environmental sensor node", tagline: "BLE, USB-C, vented enclosure", description: "A compact monitor with environmental sensing, power management, status light, and serviceable shell.", bullets: ["BLE MCU", "VOC + temperature", "Vented shell"], prompt: "Design a palm-sized environmental sensor node with BLE, USB-C, VOC and temperature sensing, a status light, vented enclosure, PCB, CircuitPython firmware, BOM, and validation notes." },
  { id: "robot-gripper", category: "Robotics", accent: "orange", title: "Adaptive robot gripper", tagline: "Force-aware parallel jaws", description: "A compact actuator assembly with force sensing, replaceable jaw inserts, and cable management.", bullets: ["Force feedback", "Servo actuation", "Replaceable jaws"], prompt: "Design an adaptive two-finger robot gripper with servo actuation, force sensing, replaceable jaws, controller PCB, CircuitPython firmware, BOM, and enclosure." },
  { id: "bike-beacon", category: "Mobility", accent: "cyan", title: "Brake-sensing bike beacon", tagline: "IMU-triggered rear light", description: "A weather-sealed rechargeable beacon with motion-triggered braking and real mounting geometry.", bullets: ["IMU braking", "IP-rated shell", "USB-C charging"], prompt: "Design a bike safety beacon with accelerometer brake sensing, bright LEDs, USB-C charging, weather-sealed enclosure, PCB, CircuitPython firmware, and BOM." },
  { id: "macro-deck", category: "Desktop", accent: "violet", title: "Spatial macro deck", tagline: "Six keys and rotary input", description: "A premium USB control surface with tactile switches, encoder, OLED, and a low-profile enclosure.", bullets: ["USB HID", "Rotary encoder", "OLED status"], prompt: "Design a six-key USB macro deck with a rotary encoder, OLED, low-profile enclosure, PCB, CircuitPython firmware, BOM, and validation notes." },
  { id: "air-sampler", category: "Field", accent: "orange", title: "Portable air sampler", tagline: "Pump, filter, flow sensing", description: "A battery-powered sampling instrument with replaceable media and calibrated airflow control.", bullets: ["Micro pump", "Flow feedback", "Filter cassette"], prompt: "Design a portable air sampler with a micro pump, flow sensing, replaceable filter cassette, battery, enclosure, PCB, CircuitPython firmware, and BOM." },
  { id: "plant-probe", category: "Agritech", accent: "green", title: "Soil intelligence probe", tagline: "Moisture, light, temperature", description: "A low-power probe and base station for plant-health telemetry and local status feedback.", bullets: ["Capacitive probe", "BLE telemetry", "Snap-fit base"], prompt: "Design a soil intelligence probe with capacitive moisture, light and temperature sensing, BLE, battery, snap-fit enclosure, PCB, CircuitPython firmware, and BOM." },
  { id: "camera-slider", category: "Motion", accent: "violet", title: "Precision camera slider", tagline: "Quiet stepper motion", description: "A compact motion-control carriage with limit sensing, belt tensioning, and repeatable moves.", bullets: ["Stepper drive", "Limit sensors", "Belt tensioner"], prompt: "Design a tabletop camera slider controller with quiet stepper motion, limit sensors, belt tensioner, enclosure, PCB, CircuitPython firmware, and BOM." },
  { id: "thermal-logger", category: "Lab", accent: "cyan", title: "Eight-channel thermal logger", tagline: "Bench thermocouple recorder", description: "A desktop measurement instrument with isolated channels, display, removable storage, and robust connectors.", bullets: ["8 thermocouples", "Local display", "SD logging"], prompt: "Design an eight-channel thermocouple data logger with display, SD storage, USB-C, bench enclosure, PCB, CircuitPython firmware, BOM, and validation notes." },
  { id: "water-valve", category: "Home", accent: "orange", title: "Smart water shutoff", tagline: "Leak-triggered ball valve", description: "A retrofit valve actuator with torque margin, position feedback, and conservative safety behavior.", bullets: ["Valve actuator", "Position feedback", "Leak input"], prompt: "Design a retrofit smart water shutoff with motorized ball valve, position feedback, leak sensor input, backup power, enclosure, PCB, CircuitPython firmware, and BOM." },
  { id: "wearable-badge", category: "Wearable", accent: "violet", title: "E-ink identity badge", tagline: "Rechargeable event display", description: "A lanyard-ready e-ink badge with navigation buttons, USB-C, and a thin serviceable case.", bullets: ["E-ink display", "Navigation keys", "Lanyard shell"], prompt: "Design a conference e-ink identity badge with navigation buttons, USB-C charging, lanyard enclosure, PCB, CircuitPython firmware, and BOM." },
  { id: "audio-meter", category: "Audio", accent: "green", title: "Studio level meter", tagline: "Stereo LED metering", description: "A precise desktop audio meter with balanced input, peak hold, and high-visibility light bars.", bullets: ["Balanced input", "Peak hold", "LED bars"], prompt: "Design a stereo studio level meter with balanced audio input, peak hold, LED bars, desktop enclosure, PCB, CircuitPython firmware, BOM, and validation notes." },
  { id: "drone-dock", category: "Autonomy", accent: "orange", title: "Micro-drone charging dock", tagline: "Guided landing and contact charge", description: "A desktop landing target with magnetic alignment, charge contacts, and docking telemetry.", bullets: ["Charge contacts", "Magnetic alignment", "Dock sensing"], prompt: "Design a charging dock for a micro drone with guided landing target, magnetic alignment, charge contacts, sensing, enclosure, PCB, CircuitPython firmware, and BOM." }
];

const tools: { id: ToolId; label: string; icon: React.ComponentType<{ size?: number }> }[] = [
  { id: "design", label: "Design", icon: Box },
  { id: "pcb", label: "PCB", icon: CircuitBoard },
  { id: "schematic", label: "Schematic", icon: GitBranch },
  { id: "firmware", label: "Firmware", icon: Code2 },
  { id: "bom", label: "BOM", icon: Package },
  { id: "validation", label: "Validation", icon: ShieldCheck },
  { id: "ar", label: "Spatial preview", icon: Glasses },
  { id: "manufacturing", label: "Manufacturing", icon: Factory }
];

function cents(value: number) {
  return `$${(value / 100).toFixed(2)}`;
}

function sanitizedName(value: string) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "helix-project";
}

function downloadText(filename: string, content: string, type = "text/plain") {
  const url = URL.createObjectURL(new Blob([content], { type }));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  window.setTimeout(() => URL.revokeObjectURL(url), 0);
}

async function callJac<T>(path: string, body?: unknown, externalSignal?: AbortSignal): Promise<T> {
  const controller = new AbortController();
  const abort = () => controller.abort();
  externalSignal?.addEventListener("abort", abort, { once: true });
  const timeout = window.setTimeout(abort, 25000);
  try {
    const response = await fetch(`${API_URL}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body ?? {}),
      signal: controller.signal
    });
    const raw = await response.text();
    let payload: JacResponse<T>;
    try {
      payload = JSON.parse(raw) as JacResponse<T>;
    } catch {
      throw new Error(`JaC returned an unreadable ${response.status} response at ${path}.`);
    }
    if (!response.ok || !payload.ok || !payload.data) {
      const validationDetail = (payload as JacResponse<T> & { detail?: { msg?: string }[] }).detail;
      throw new Error(payload.error?.message ?? validationDetail?.[0]?.msg ?? `JaC request failed at ${path}`);
    }
    return payload.data.result;
  } finally {
    window.clearTimeout(timeout);
    externalSignal?.removeEventListener("abort", abort);
  }
}

function createProject(name: string, prompt: string, signal?: AbortSignal) {
  return callJac<WorkspaceSnapshot>("/function/create_project", { name, prompt }, signal);
}

function generateDesign(projectId: string, prompt: string, signal?: AbortSignal) {
  return callJac<WorkspaceSnapshot | null>("/function/generate_hardware_design", { project_id: projectId, prompt }, signal);
}

function runValidation(projectId: string, signal?: AbortSignal) {
  return callJac<WorkspaceSnapshot | null>("/function/run_validations", { project_id: projectId }, signal);
}

async function createQuote(projectId: string, quantity: number, signal?: AbortSignal) {
  await callJac<Record<string, string>>("/function/create_fabrication_quote", { project_id: projectId, quantity }, signal);
  return callJac<WorkspaceSnapshot | null>("/function/load_workspace", { project_id: projectId }, signal);
}

function restoreVersion(projectId: string, versionId: string, signal?: AbortSignal) {
  return callJac<WorkspaceSnapshot | null>("/function/restore_project_version", { project_id: projectId, version_id: versionId }, signal);
}

function createArHandoff(projectId: string, support: ArSupport, fallback: string) {
  return callJac<Record<string, string>>("/function/create_ar_handoff", {
    project_id: projectId,
    capability: {
      secure_context: support.secure,
      webxr: support.webxr,
      ios_quicklook: support.quickLook,
      android_scene_viewer: support.sceneViewer,
      camera: support.camera,
      fallback,
      message: "Browser compatibility was detected by the Helix Next.js spatial preview."
    }
  });
}

function HelixMark() {
  return (
    <span className="helix-brand" aria-label="Helix">
      <span className="helix-symbol" aria-hidden="true">
        <i />
        <i />
        <i />
      </span>
      <strong>HELIX</strong>
    </span>
  );
}

function IconButton({
  label,
  children,
  active = false,
  disabled = false,
  onClick,
  className = ""
}: {
  label: string;
  children: React.ReactNode;
  active?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  className?: string;
}) {
  return (
    <button
      type="button"
      className={`icon-button ${active ? "active" : ""} ${className}`}
      aria-label={label}
      title={label}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
}

function Toggle({ checked, onChange, label }: { checked: boolean; onChange: (checked: boolean) => void; label: string }) {
  return (
    <button
      type="button"
      className={`toggle ${checked ? "on" : ""}`}
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={() => onChange(!checked)}
    >
      <span />
    </button>
  );
}

const ThreeViewport = forwardRef<ThreeHandle, {
  dimensions: Dimensions;
  layers: LayerVisibility;
  exploded: boolean;
  transparent?: boolean;
}>(({ dimensions, layers, exploded, transparent = false }, ref) => {
  const hostRef = useRef<HTMLDivElement>(null);
  const actionsRef = useRef<ThreeHandle>({ fit: () => undefined, reset: () => undefined });

  useImperativeHandle(ref, () => ({
    fit: () => actionsRef.current.fit(),
    reset: () => actionsRef.current.reset()
  }), []);

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;
    let disposed = false;
    let animationFrame = 0;
    let resizeObserver: ResizeObserver | undefined;

    void Promise.all([
      import("three"),
      import("three/examples/jsm/controls/OrbitControls.js")
    ]).then(([THREE, controlsModule]) => {
      if (disposed) return;
      const scene = new THREE.Scene();
      scene.background = transparent ? null : new THREE.Color(0x050507);
      scene.fog = transparent ? null : new THREE.FogExp2(0x050507, 0.0035);

      const camera = new THREE.PerspectiveCamera(32, 1, 0.1, 1200);
      const initialCamera = new THREE.Vector3(112, 76, 126);
      camera.position.copy(initialCamera);

      const renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: transparent,
        preserveDrawingBuffer: true,
        powerPreference: "high-performance"
      });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.8));
      renderer.outputColorSpace = THREE.SRGBColorSpace;
      renderer.toneMapping = THREE.ACESFilmicToneMapping;
      renderer.toneMappingExposure = 1.62;
      renderer.setClearColor(0x050507, transparent ? 0 : 1);
      renderer.domElement.setAttribute("aria-label", "Interactive generated enclosure model");
      renderer.domElement.setAttribute("role", "img");
      host.appendChild(renderer.domElement);

      const controls = new controlsModule.OrbitControls(camera, renderer.domElement);
      controls.enableDamping = true;
      controls.dampingFactor = 0.06;
      controls.screenSpacePanning = true;
      controls.minDistance = 48;
      controls.maxDistance = 360;
      controls.target.set(0, 0, 0);

      scene.add(new THREE.HemisphereLight(0xc8f9ff, 0x081018, 1.55));
      const keyLight = new THREE.DirectionalLight(0xeffeff, 4.4);
      keyLight.position.set(70, 100, 60);
      scene.add(keyLight);
      const cyanLight = new THREE.PointLight(0x00f0ff, 42, 190, 2);
      cyanLight.position.set(-70, 16, 52);
      scene.add(cyanLight);
      const orangeLight = new THREE.PointLight(0xff5a00, 24, 170, 2);
      orangeLight.position.set(62, -10, -46);
      scene.add(orangeLight);

      const grid = new THREE.GridHelper(520, 52, 0x143b42, 0x101317);
      grid.position.y = -dimensions.height / 2 - 10;
      const gridMaterials = Array.isArray(grid.material) ? grid.material : [grid.material];
      gridMaterials.forEach((material) => {
        material.transparent = true;
        material.opacity = 0.58;
      });
      scene.add(grid);

      const model = new THREE.Group();
      model.rotation.y = -0.42;
      scene.add(model);

      const shellMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x36434d,
        metalness: 0.48,
        roughness: 0.3,
        clearcoat: 0.9,
        clearcoatRoughness: 0.18
      });
      const lidMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x56646d,
        metalness: 0.44,
        roughness: 0.28,
        clearcoat: 1
      });
      const boardMaterial = new THREE.MeshPhysicalMaterial({
        color: 0x062f33,
        metalness: 0.25,
        roughness: 0.42,
        emissive: 0x003b42,
        emissiveIntensity: 0.55
      });
      const cyanMaterial = new THREE.MeshStandardMaterial({
        color: 0x00f0ff,
        emissive: 0x00a5b0,
        emissiveIntensity: 1.25,
        metalness: 0.3,
        roughness: 0.25
      });
      const orangeMaterial = new THREE.MeshStandardMaterial({
        color: 0xff5a00,
        emissive: 0x8a2700,
        emissiveIntensity: 0.8,
        metalness: 0.2,
        roughness: 0.35
      });
      const darkMaterial = new THREE.MeshStandardMaterial({
        color: 0x080a0d,
        metalness: 0.72,
        roughness: 0.3
      });

      const addOutline = (mesh: import("three").Mesh) => {
        const edgeGeometry = new THREE.EdgesGeometry(mesh.geometry, 28);
        const edgeMaterial = new THREE.LineBasicMaterial({ color: 0x3e565e, transparent: true, opacity: 0.68 });
        const edges = new THREE.LineSegments(edgeGeometry, edgeMaterial);
        mesh.add(edges);
      };

      if (layers.shell) {
        const baseGeometry = new THREE.BoxGeometry(dimensions.width, Math.max(5, dimensions.height * 0.72), dimensions.depth);
        const base = new THREE.Mesh(baseGeometry, shellMaterial);
        base.position.y = -dimensions.height * 0.12;
        addOutline(base);
        model.add(base);
      }

      if (layers.lid) {
        const lidGeometry = new THREE.BoxGeometry(dimensions.width + 0.6, Math.max(2.2, dimensions.wall * 1.35), dimensions.depth + 0.6);
        const lid = new THREE.Mesh(lidGeometry, lidMaterial);
        lid.position.y = dimensions.height * 0.39 + (exploded ? 24 : 0);
        addOutline(lid);
        model.add(lid);
      }

      if (layers.pcb) {
        const board = new THREE.Mesh(
          new THREE.BoxGeometry(dimensions.width * 0.72, 1.8, dimensions.depth * 0.68),
          boardMaterial
        );
        board.position.y = exploded ? 9 : 1;
        addOutline(board);
        model.add(board);

        const chip = new THREE.Mesh(
          new THREE.BoxGeometry(dimensions.width * 0.19, 4.2, dimensions.depth * 0.2),
          darkMaterial
        );
        chip.position.set(-dimensions.width * 0.08, board.position.y + 3, 0);
        model.add(chip);

        const usb = new THREE.Mesh(
          new THREE.BoxGeometry(11, 4.8, 7.8),
          cyanMaterial
        );
        usb.position.set(dimensions.width * 0.36, board.position.y + 2.6, 0);
        model.add(usb);

        const sensor = new THREE.Mesh(
          new THREE.CylinderGeometry(5.6, 5.6, 3.2, 28),
          orangeMaterial
        );
        sensor.position.set(-dimensions.width * 0.22, board.position.y + 2.5, -dimensions.depth * 0.16);
        model.add(sensor);
      }

      if (layers.hardware) {
        const fastenerGeometry = new THREE.CylinderGeometry(2.2, 2.2, dimensions.height * 0.46, 24);
        const positions = [
          [-dimensions.width * 0.38, -dimensions.depth * 0.36],
          [dimensions.width * 0.38, -dimensions.depth * 0.36],
          [-dimensions.width * 0.38, dimensions.depth * 0.36],
          [dimensions.width * 0.38, dimensions.depth * 0.36]
        ];
        positions.forEach(([x, z]) => {
          const fastener = new THREE.Mesh(fastenerGeometry, cyanMaterial);
          fastener.position.set(x, exploded ? 4 : -2, z);
          model.add(fastener);
        });
      }

      const fit = () => {
        const box = new THREE.Box3().setFromObject(model);
        const sphere = box.getBoundingSphere(new THREE.Sphere());
        const distance = Math.max(88, sphere.radius / Math.tan(THREE.MathUtils.degToRad(camera.fov / 2)) * 1.15);
        const direction = new THREE.Vector3(0.78, 0.58, 0.92).normalize();
        camera.position.copy(direction.multiplyScalar(distance));
        controls.target.copy(sphere.center);
        controls.update();
      };
      const reset = () => {
        model.rotation.set(0, -0.42, 0);
        camera.position.copy(initialCamera);
        controls.target.set(0, 0, 0);
        controls.update();
      };
      actionsRef.current = { fit, reset };
      fit();

      const resize = () => {
        const width = Math.max(host.clientWidth, 1);
        const height = Math.max(host.clientHeight, 1);
        renderer.setSize(width, height, false);
        camera.aspect = width / height;
        camera.updateProjectionMatrix();
      };
      resizeObserver = new ResizeObserver(resize);
      resizeObserver.observe(host);
      resize();

      const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      const animate = (time: number) => {
        if (disposed) return;
        animationFrame = window.requestAnimationFrame(animate);
        if (!reducedMotion && !controls.enabled) model.rotation.y += 0.0006;
        if (!reducedMotion) model.position.y = Math.sin(time * 0.00055) * 0.75;
        controls.update();
        renderer.render(scene, camera);
      };
      animationFrame = window.requestAnimationFrame(animate);

      const markInteraction = () => {
        controls.enabled = true;
      };
      renderer.domElement.addEventListener("pointerdown", markInteraction);

      actionsRef.current = { fit, reset };
      const cleanup = () => {
        renderer.domElement.removeEventListener("pointerdown", markInteraction);
        resizeObserver?.disconnect();
        window.cancelAnimationFrame(animationFrame);
        controls.dispose();
        scene.traverse((object) => {
          const mesh = object as import("three").Mesh;
          mesh.geometry?.dispose();
          const material = mesh.material;
          if (Array.isArray(material)) material.forEach((item) => item.dispose());
          else material?.dispose();
        });
        renderer.dispose();
        renderer.forceContextLoss();
        renderer.domElement.remove();
      };
      if (disposed) cleanup();
      else (host as HTMLDivElement & { __helixCleanup?: () => void }).__helixCleanup = cleanup;
    });

    return () => {
      disposed = true;
      resizeObserver?.disconnect();
      window.cancelAnimationFrame(animationFrame);
      const cleanupHost = host as HTMLDivElement & { __helixCleanup?: () => void };
      cleanupHost.__helixCleanup?.();
      delete cleanupHost.__helixCleanup;
    };
  }, [dimensions.depth, dimensions.height, dimensions.wall, dimensions.width, exploded, layers.hardware, layers.lid, layers.pcb, layers.shell, transparent]);

  return <div ref={hostRef} className="three-host" />;
});
ThreeViewport.displayName = "ThreeViewport";

function CommandPalette({
  open,
  query,
  setQuery,
  templates,
  activeTool,
  onTool,
  onTemplate,
  onClose
}: {
  open: boolean;
  query: string;
  setQuery: (value: string) => void;
  templates: BoardTemplate[];
  activeTool: ToolId;
  onTool: (tool: ToolId) => void;
  onTemplate: (template: BoardTemplate) => void;
  onClose: () => void;
}) {
  const dialogRef = useRef<HTMLElement>(null);
  const previousFocus = useRef<HTMLElement | null>(null);
  const filtered = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    return templates.filter((template) =>
      `${template.title} ${template.category} ${template.tagline}`.toLowerCase().includes(normalized)
    );
  }, [query, templates]);

  useEffect(() => {
    if (!open) return;
    previousFocus.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
      if (event.key === "Tab" && dialogRef.current) {
        const controls = Array.from(dialogRef.current.querySelectorAll<HTMLElement>("button:not(:disabled), input:not(:disabled)"));
        if (!controls.length) return;
        const first = controls[0];
        const last = controls[controls.length - 1];
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first.focus();
        }
      }
    };
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("keydown", onKey);
      previousFocus.current?.focus();
    };
  }, [onClose, open]);

  if (!open) return null;
  return (
    <div className="dialog-backdrop" role="presentation" onMouseDown={onClose}>
      <section ref={dialogRef} className="command-palette" role="dialog" aria-modal="true" aria-label="Helix command palette" onMouseDown={(event) => event.stopPropagation()}>
        <div className="command-input">
          <Search size={17} />
          <input autoFocus value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search tools or start from a design system..." />
          <kbd>ESC</kbd>
          <IconButton label="Close command palette" onClick={onClose}><X size={15} /></IconButton>
        </div>
        <div className="command-tools" aria-label="Workspace tools">
          {tools.map(({ id, label, icon: Icon }) => (
            <button key={id} className={activeTool === id ? "active" : ""} type="button" onClick={() => { onTool(id); onClose(); }}>
              <Icon size={15} />
              {label}
            </button>
          ))}
        </div>
        <div className="command-section-title">
          <span>Design systems</span>
          <small>{filtered.length} available</small>
        </div>
        <div className="template-grid">
          {filtered.map((template, index) => (
            <button key={`${template.id}-${index}`} type="button" onClick={() => { onTemplate(template); onClose(); }}>
              <i className={`template-accent ${template.accent}`} />
              <span>
                <small>{template.category}</small>
                <b>{template.title}</b>
                <em>{template.tagline}</em>
              </span>
              <ChevronRight size={15} />
            </button>
          ))}
        </div>
      </section>
    </div>
  );
}

function ToolRail({ tool, onChange, onMenu }: { tool: ToolId; onChange: (tool: ToolId) => void; onMenu: () => void }) {
  return (
    <nav className="tool-rail" aria-label="Engineering workspaces">
      <IconButton label="Open command palette" onClick={onMenu} className="rail-menu"><Menu size={18} /></IconButton>
      <div className="rail-tools">
        {tools.map(({ id, label, icon: Icon }) => (
          <IconButton key={id} label={label} active={tool === id} onClick={() => onChange(id)}>
            <Icon size={18} />
          </IconButton>
        ))}
      </div>
      <IconButton label="Workspace settings"><Settings2 size={18} /></IconButton>
    </nav>
  );
}

function PcbStage({ snapshot }: { snapshot: WorkspaceSnapshot | null }) {
  const width = snapshot?.circuitron.width_mm ?? 50;
  const height = snapshot?.circuitron.height_mm ?? 35;
  return (
    <div className="artifact-viewport pcb-stage">
      <div className="board-rulers"><span>{width} mm</span><span>{height} mm</span></div>
      <div className="pcb-board" role="img" aria-label="PCB planning artifact">
        <span className="pcb-part u1">U1</span>
        <span className="pcb-part usb">J1</span>
        <span className="pcb-part sensor">S1</span>
        <span className="pcb-part led">D1</span>
        <i className="pcb-trace trace-a" />
        <i className="pcb-trace trace-b" />
        <i className="pcb-trace trace-c" />
        <i className="pcb-trace trace-d" />
        <div className="mount-hole mh-a" />
        <div className="mount-hole mh-b" />
        <div className="mount-hole mh-c" />
        <div className="mount-hole mh-d" />
      </div>
      <div className="stage-disclosure warning">
        <CircleAlert size={14} />
        {snapshot?.circuitron.design_validation.summary ?? "Planning preview. Create a project to load JaC PCB artifacts."}
      </div>
    </div>
  );
}

function SchematicStage({ snapshot }: { snapshot: WorkspaceSnapshot | null }) {
  return (
    <div className="artifact-viewport schematic-stage">
      <div className="schematic-canvas" role="img" aria-label="Logical schematic planning view">
        <span className="schematic-node power"><small>POWER</small><b>USB-C / 5V</b></span>
        <span className="schematic-node mcu"><small>CONTROL</small><b>ESP32-S3</b></span>
        <span className="schematic-node sensor"><small>SENSOR</small><b>ENV ARRAY</b></span>
        <span className="schematic-node output"><small>OUTPUT</small><b>STATUS LED</b></span>
        <i className="wire wire-a" />
        <i className="wire wire-b" />
        <i className="wire wire-c" />
      </div>
      <div className="artifact-caption">
        <span>Logical net</span>
        <b>{snapshot?.schematic || "USB-C → regulator → MCU → sensor / status output"}</b>
      </div>
    </div>
  );
}

function FirmwareStage({ snapshot }: { snapshot: WorkspaceSnapshot | null }) {
  const code = snapshot?.firmware || "# Create a project to generate CircuitPython firmware.\n# No firmware has been validated or flashed.";
  return (
    <div className="artifact-viewport firmware-stage">
      <div className="editor-tabs"><span className="active"><FileCode2 size={14} />code.py</span></div>
      <div className="code-editor">
        <div className="line-numbers" aria-hidden="true">{code.split("\n").map((_, index) => <span key={index}>{index + 1}</span>)}</div>
        <pre>{code}</pre>
      </div>
      <div className="stage-disclosure warning"><CircleAlert size={14} />CircuitPython source is untested until a configured hardware build runner reports a result.</div>
    </div>
  );
}

function BomStage({ snapshot }: { snapshot: WorkspaceSnapshot | null }) {
  const lines = snapshot?.bom_document.lines ?? [];
  const total = lines.reduce((sum, line) => sum + line.unit_price * line.qty, 0);
  return (
    <div className="artifact-viewport bom-stage">
      <div className="table-summary">
        <span>{lines.length || "No"} normalized components</span>
        <b>{lines.length ? `$${total.toFixed(2)}` : "Awaiting JaC project"}</b>
      </div>
      <div className="table-scroll">
        <table>
          <thead><tr><th>Ref</th><th>Component</th><th>Manufacturer</th><th>MPN</th><th>Qty</th><th>Supplier</th><th>Unit</th><th>Availability</th></tr></thead>
          <tbody>
            {lines.length ? lines.map((line) => (
              <tr key={`${line.designators}-${line.mpn}`}>
                <td><b>{line.designators}</b></td><td>{line.description}</td><td>{line.manufacturer}</td><td><code>{line.mpn}</code></td>
                <td>{line.qty}</td><td>{line.supplier}</td><td>${line.unit_price.toFixed(2)}</td><td><span className="availability">{line.availability}</span></td>
              </tr>
            )) : <tr><td colSpan={8} className="empty-cell">Generate a hardware project to inspect a real BOM.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function ValidationStage({ snapshot, busy, onValidate }: { snapshot: WorkspaceSnapshot | null; busy: boolean; onValidate: () => void }) {
  const checks = snapshot?.validation ?? [];
  return (
    <div className="artifact-viewport validation-stage">
      <div className="readiness-orbit">
        <svg viewBox="0 0 140 140" aria-label={`${snapshot?.readiness_score ?? 0} percent manufacturing readiness`}>
          <circle cx="70" cy="70" r="56" />
          <circle className="progress" cx="70" cy="70" r="56" style={{ strokeDashoffset: 352 - 352 * ((snapshot?.readiness_score ?? 0) / 100) }} />
        </svg>
        <div><b>{snapshot?.readiness_score ?? 0}</b><span>READINESS</span></div>
      </div>
      <div className="validation-list">
        {checks.length ? checks.map((check) => (
          <article key={`${check.name}-${check.notes}`}>
            <CircleAlert size={16} />
            <div><b>{check.name}</b><p>{check.notes}</p></div>
            <span>{check.score}%</span>
          </article>
        )) : <div className="empty-validation"><ShieldCheck size={28} /><b>No evidence yet</b><p>Create a project, then run the JaC readiness audit.</p></div>}
      </div>
      <button className="action-button cyan" type="button" disabled={!snapshot || busy} onClick={onValidate}>
        {busy ? <Loader2 size={15} /> : <ScanLine size={15} />} Run actual checks
      </button>
    </div>
  );
}

function ManufacturingStage({ snapshot, busy, onQuote }: { snapshot: WorkspaceSnapshot | null; busy: boolean; onQuote: () => void }) {
  return (
    <div className="artifact-viewport manufacturing-stage">
      <div className="manufacturing-heading">
        <span><Factory size={18} />SERVER-PRICED PROTOTYPE</span>
        <h2>{snapshot ? cents(snapshot.fab_quote.total_cents) : "No quote"}</h2>
        <p>Quote math is owned by JaC. Checkout remains unavailable until Stripe is configured server-side.</p>
      </div>
      <div className="quote-lines">
        {(snapshot?.fab_quote.lines ?? []).map((line) => (
          <article key={line.key}><span><b>{line.name}</b><small>{line.description}</small></span><strong>{cents(line.unit_amount_cents)}</strong></article>
        ))}
      </div>
      <button className="action-button cyan" disabled={!snapshot || busy} type="button" onClick={onQuote}>
        {busy ? <Loader2 size={15} /> : <Factory size={15} />} Refresh server quote
      </button>
      <div className="stage-disclosure warning"><CircleAlert size={14} />No payment is created in local mode. Stripe configuration is required for checkout.</div>
    </div>
  );
}

function ArStage({
  snapshot,
  dimensions,
  layers,
  exploded,
  support,
  cameraActive,
  videoRef,
  threeRef,
  onCamera,
  onCapture
}: {
  snapshot: WorkspaceSnapshot | null;
  dimensions: Dimensions;
  layers: LayerVisibility;
  exploded: boolean;
  support: ArSupport;
  cameraActive: boolean;
  videoRef: React.RefObject<HTMLVideoElement | null>;
  threeRef: React.RefObject<ThreeHandle | null>;
  onCamera: () => void;
  onCapture: () => void;
}) {
  return (
    <div className={`artifact-viewport ar-stage ${cameraActive ? "camera-active" : ""}`}>
      <video ref={videoRef} autoPlay muted playsInline aria-label="Camera spatial preview" />
      <ThreeViewport ref={threeRef} dimensions={dimensions} layers={layers} exploded={exploded} transparent={cameraActive} />
      <div className="ar-badge"><Glasses size={15} />{cameraActive ? "CAMERA OVERLAY" : "INTERACTIVE 3D FALLBACK"}</div>
      <div className="ar-compatibility">
        <span className={support.webxr ? "supported" : ""}>WEBXR <i /></span>
        <span className={support.quickLook ? "supported" : ""}>QUICK LOOK <i /></span>
        <span className={support.sceneViewer ? "supported" : ""}>SCENE VIEWER <i /></span>
        <span className={support.camera ? "supported" : ""}>CAMERA <i /></span>
      </div>
      <div className="ar-actions">
        <button type="button" onClick={onCamera} disabled={!support.camera}>
          <Aperture size={15} />{cameraActive ? "Close camera" : "Start camera preview"}
        </button>
        <button type="button" onClick={onCapture} disabled={!cameraActive}><Download size={15} />Capture</button>
      </div>
      {!support.secure ? <div className="stage-disclosure warning"><CircleAlert size={14} />Camera and WebXR require HTTPS or localhost.</div> : null}
      {!snapshot ? <div className="stage-disclosure">The model is an uncommitted local preview. Generate a project for a JaC AR handoff record.</div> : null}
    </div>
  );
}

function VersionTimeline({
  snapshot,
  busy,
  onRestore
}: {
  snapshot: WorkspaceSnapshot | null;
  busy: boolean;
  onRestore: (versionId: string) => void;
}) {
  const versions = snapshot?.versions ?? [];
  return (
    <div className="version-timeline" aria-label="Generative version timeline">
      <div className="timeline-title"><GitBranch size={14} /><span>GENERATIVE TREE</span></div>
      <div className="timeline-track">
        {versions.length ? versions.map((version, index) => {
          const active = version.label === snapshot?.active_version;
          return (
            <button
              key={version.id}
              className={active ? "active" : ""}
              type="button"
              title={version.summary}
              disabled={busy}
              onClick={() => onRestore(version.id)}
            >
              <i>{active ? <Check size={10} /> : index + 1}</i>
              <span>{version.label}</span>
            </button>
          );
        }) : (
          <div className="timeline-empty"><i>0</i><span>Uncommitted design</span></div>
        )}
      </div>
      <span className="timeline-scale">LIVE GRAPH</span>
    </div>
  );
}

function PromptTerminal({
  value,
  setValue,
  busy,
  autonomous,
  setAutonomous,
  attachments,
  onFiles,
  onVoice,
  listening,
  onSubmit,
  onStop,
  message
}: {
  value: string;
  setValue: (value: string) => void;
  busy: boolean;
  autonomous: boolean;
  setAutonomous: (value: boolean) => void;
  attachments: File[];
  onFiles: (files: File[]) => void;
  onVoice: () => void;
  listening: boolean;
  onSubmit: () => void;
  onStop: () => void;
  message: string;
}) {
  const fileInput = useRef<HTMLInputElement>(null);
  const tokenEstimate = Math.ceil(value.length / 4);
  return (
    <section className="prompt-terminal" aria-label="Spatial AI prompt terminal">
      {message ? <div className="terminal-message"><CircleAlert size={13} />{message}</div> : null}
      {attachments.length ? (
        <div className="attachment-row">
          {attachments.map((file) => <span key={`${file.name}-${file.size}`}><Paperclip size={11} />{file.name}</span>)}
          <small>Filenames are sent as context; files stay local.</small>
        </div>
      ) : null}
      <div className="prompt-main">
        <div className={`voice-waveform ${listening ? "listening" : ""}`} aria-hidden="true">
          {Array.from({ length: 9 }).map((_, index) => <i key={index} />)}
        </div>
        <textarea
          value={value}
          onChange={(event) => setValue(event.target.value)}
          placeholder="Describe a product or direct the engineering graph..."
          aria-label="Engineering instruction"
          onKeyDown={(event) => {
            if (event.key === "Enter" && !event.shiftKey) {
              event.preventDefault();
              if (!busy && value.trim()) onSubmit();
            }
          }}
        />
        <div className="prompt-actions">
          <input
            ref={fileInput}
            type="file"
            multiple
            hidden
            onChange={(event) => onFiles(Array.from(event.target.files ?? []))}
          />
          <IconButton label="Attach local references" onClick={() => fileInput.current?.click()}><Paperclip size={16} /></IconButton>
          <IconButton label={listening ? "Stop voice input" : "Start voice input"} active={listening} onClick={onVoice}><Mic size={16} /></IconButton>
          {busy ? (
            <IconButton label="Stop waiting for generation" className="stop" onClick={onStop}><StopCircle size={18} /></IconButton>
          ) : (
            <IconButton label="Run engineering instruction" className="send" disabled={!value.trim()} onClick={onSubmit}><Send size={17} /></IconButton>
          )}
        </div>
      </div>
      <div className="prompt-meta">
        <span className="autonomy-control"><Toggle checked={autonomous} onChange={setAutonomous} label="Autonomous iteration mode" />AUTONOMOUS ITERATION</span>
        <span className="token-meter"><i style={{ width: `${Math.min(100, tokenEstimate / 18)}%` }} />~{tokenEstimate} TOKENS</span>
        <kbd>ENTER TO RUN</kbd>
      </div>
    </section>
  );
}

function SolCore({
  tab,
  setTab,
  snapshot,
  tool,
  busy,
  telemetry,
  reasoning,
  setReasoning,
  coordinates,
  dimensions,
  setDimensions,
  layers,
  setLayers,
  exploded,
  setExploded,
  onCommitDimensions,
  onClose
}: {
  tab: DockTab;
  setTab: (tab: DockTab) => void;
  snapshot: WorkspaceSnapshot | null;
  tool: ToolId;
  busy: boolean;
  telemetry: Telemetry;
  reasoning: string;
  setReasoning: (value: string) => void;
  coordinates: Vec3;
  dimensions: Dimensions;
  setDimensions: (value: Dimensions) => void;
  layers: LayerVisibility;
  setLayers: (value: LayerVisibility) => void;
  exploded: boolean;
  setExploded: (value: boolean) => void;
  onCommitDimensions: () => void;
  onClose: () => void;
}) {
  const warnings = (snapshot?.circuitron.pcb_warnings.length ?? 0) +
    (snapshot?.validation.filter((check) => check.status !== "passed").length ?? 0);
  const agentRoles = [
    { name: "Stress Analyst", detail: warnings ? `${warnings} unresolved constraints` : "Awaiting validation evidence", tone: warnings ? "orange" : "cyan" },
    { name: "Material Specialist", detail: snapshot ? `${snapshot.bom_document.lines.length} BOM lines indexed` : "No project graph loaded", tone: "cyan" },
    { name: "Geometry Optimizer", detail: snapshot ? `${snapshot.cad_document.features.length} CSG features observed` : "Seed geometry preview", tone: "cyan" }
  ];

  return (
    <aside className="sol-core">
      <header className="core-header">
        <div><span className="core-pulse" /><b>SOL CORE</b><small>{busy ? "COMPUTING" : "MONITORING"}</small></div>
        <IconButton label="Close telemetry panel" onClick={onClose}><X size={16} /></IconButton>
      </header>
      <nav className="core-tabs" aria-label="Sol Core views">
        {(["core", "inspect", "thread"] as DockTab[]).map((item) => (
          <button key={item} type="button" className={tab === item ? "active" : ""} onClick={() => setTab(item)}>
            {item === "core" ? "Telemetry" : item === "inspect" ? "Inspector" : "Thread"}
          </button>
        ))}
      </nav>

      {tab === "core" ? (
        <div className="core-content">
          <div className="local-simulation-note"><Activity size={13} />Interface telemetry · simulated locally</div>
          <div className="load-visual">
            <div className="load-ring" style={{ "--load": `${telemetry.load * 3.6}deg` } as React.CSSProperties}>
              <span><b>{telemetry.load}</b><small>% LOAD</small></span>
            </div>
            <div className="load-stats">
              <span><small>TOKENS / SEC</small><b>{busy ? telemetry.tokens.toFixed(1) : "0.0"}</b></span>
              <span><small>CONFIDENCE</small><b>{telemetry.confidence}%</b></span>
            </div>
          </div>
          <div className="depth-control">
            <div><span>REASONING DEPTH</span><b>{reasoning.toUpperCase()}</b></div>
            <div>{["low", "med", "high", "ultra"].map((depth) => <button key={depth} type="button" className={reasoning === depth ? "active" : ""} onClick={() => setReasoning(depth)}>{depth}</button>)}</div>
            <small>UI preference only; current JaC endpoint does not accept a depth parameter.</small>
          </div>
          <section className="agent-hub">
            <header><span>MULTI-AGENT HUB</span><small>{busy ? "LOCAL ACTIVITY PREVIEW" : "ROLES READY"}</small></header>
            {agentRoles.map((agent, index) => (
              <article key={agent.name}>
                <i className={`${agent.tone} ${busy ? "active" : ""}`}><span>{index + 1}</span></i>
                <div><b>{agent.name}</b><small>{agent.detail}</small></div>
                <Activity size={14} />
              </article>
            ))}
          </section>
          <section className="spatial-readout">
            <header><span>SPATIAL READOUT</span><small>VIEWPORT COORDINATES</small></header>
            <div><span>X <b>{coordinates.x.toFixed(2)}</b></span><span>Y <b>{coordinates.y.toFixed(2)}</b></span><span>Z <b>{coordinates.z.toFixed(2)}</b></span></div>
          </section>
        </div>
      ) : null}

      {tab === "inspect" ? (
        <div className="core-content inspector-content">
          <div className="selection-title"><MousePointer2 size={15} /><span><small>SELECTED ASSEMBLY</small><b>{snapshot?.name ?? "Uncommitted enclosure"}</b></span></div>
          <section className="dimension-editor">
            <header><span>ENCLOSURE PARAMETERS</span><small>MM</small></header>
            {(["width", "depth", "height", "wall"] as const).map((key) => (
              <label key={key}>
                <span>{key}</span>
                <input
                  type="number"
                  min={key === "wall" ? 1.2 : 8}
                  max={key === "wall" ? 6 : 240}
                  step={key === "wall" ? 0.1 : 1}
                  value={dimensions[key]}
                  onChange={(event) => setDimensions({ ...dimensions, [key]: Number(event.target.value) })}
                />
              </label>
            ))}
            <button type="button" className="commit-parameters" disabled={!snapshot || busy} onClick={onCommitDimensions}>
              <WandSparkles size={14} />Commit through JaC
            </button>
          </section>
          <section className="layer-editor">
            <header><span>ASSEMBLY LAYERS</span><small>{Object.values(layers).filter(Boolean).length}/4</small></header>
            {(Object.keys(layers) as (keyof LayerVisibility)[]).map((key) => (
              <label key={key}><span><i className={key} />{key}</span><Toggle checked={layers[key]} onChange={(checked) => setLayers({ ...layers, [key]: checked })} label={`Toggle ${key}`} /></label>
            ))}
            <label><span><i className="explode" />exploded view</span><Toggle checked={exploded} onChange={setExploded} label="Toggle exploded view" /></label>
          </section>
          <section className="artifact-facts">
            <header><span>{tool.toUpperCase()} ARTIFACT</span><small>JAC SNAPSHOT</small></header>
            <dl>
              <div><dt>Version</dt><dd>{snapshot?.active_version ?? "Draft"}</dd></div>
              <div><dt>Features</dt><dd>{snapshot?.cad_document.features.length ?? 0}</dd></div>
              <div><dt>Readiness</dt><dd>{snapshot?.readiness_score ?? 0}%</dd></div>
              <div><dt>Warnings</dt><dd className={warnings ? "warning-text" : ""}>{warnings}</dd></div>
            </dl>
          </section>
        </div>
      ) : null}

      {tab === "thread" ? (
        <div className="core-content thread-content">
          <div className="thread-status"><Sparkles size={15} /><span><b>JaC engineering thread</b><small>Responses appear after the backend returns a complete snapshot.</small></span></div>
          <div className="message-list" aria-live="polite">
            {(snapshot?.messages ?? []).map((message, index) => (
              <article key={`${message.role}-${index}`} className={message.role}>
                <span>{message.role}</span><p>{message.content}</p>
              </article>
            ))}
            {!snapshot ? <div className="thread-empty"><Braces size={24} /><p>Start a design to create a persisted JaC conversation.</p></div> : null}
            {busy ? <article className="progress-message"><Loader2 size={15} /><p>Waiting for the JaC generation snapshot...</p></article> : null}
          </div>
          <div className="tool-execution">
            {(snapshot?.tool_progress ?? []).map((step) => (
              <span key={`${step.tool}-${step.message}`}><i className={step.status === "blocked" ? "blocked" : ""} />{step.tool}<small>{step.status}</small></span>
            ))}
          </div>
        </div>
      ) : null}
    </aside>
  );
}

export default function Page() {
  const [tool, setTool] = useState<ToolId>("design");
  const [dockTab, setDockTab] = useState<DockTab>("core");
  const [dockOpen, setDockOpen] = useState(false);
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [paletteQuery, setPaletteQuery] = useState("");
  const [selectedTemplate, setSelectedTemplate] = useState(starterTemplates[0]);
  const [prompt, setPrompt] = useState(starterTemplates[0].prompt);
  const [snapshot, setSnapshot] = useState<WorkspaceSnapshot | null>(null);
  const [requestState, setRequestState] = useState<RequestState>("idle");
  const [notice, setNotice] = useState("");
  const [autonomous, setAutonomous] = useState(true);
  const [reasoning, setReasoning] = useState("high");
  const [attachments, setAttachments] = useState<File[]>([]);
  const [listening, setListening] = useState(false);
  const [coordinates, setCoordinates] = useState<Vec3>({ x: 0, y: 0, z: 0 });
  const [dimensions, setDimensions] = useState<Dimensions>(DEFAULT_DIMENSIONS);
  const [layers, setLayers] = useState<LayerVisibility>(DEFAULT_LAYERS);
  const [exploded, setExploded] = useState(false);
  const [telemetry, setTelemetry] = useState<Telemetry>({ load: 12, tokens: 0, confidence: 78 });
  const [arSupport, setArSupport] = useState<ArSupport>({ secure: false, camera: false, webxr: false, quickLook: false, sceneViewer: false });
  const [cameraActive, setCameraActive] = useState(false);

  const requestController = useRef<AbortController | null>(null);
  const speech = useRef<SpeechRecognitionLike | null>(null);
  const threeRef = useRef<ThreeHandle | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const cameraStream = useRef<MediaStream | null>(null);
  const workspaceRef = useRef<HTMLElement | null>(null);
  const isBusy = requestState === "loading";
  const templates = useMemo(() => {
    const backendTemplates = snapshot?.templates ?? [];
    const combined = [...starterTemplates, ...backendTemplates];
    return combined.filter((template, index) => combined.findIndex((candidate) => candidate.id === template.id) === index);
  }, [snapshot]);
  const activeVersionIndex = snapshot?.versions.findIndex((version) => version.label === snapshot.active_version) ?? -1;

  const stopCamera = useCallback(() => {
    cameraStream.current?.getTracks().forEach((track) => track.stop());
    cameraStream.current = null;
    if (videoRef.current) videoRef.current.srcObject = null;
    setCameraActive(false);
  }, []);

  useEffect(() => {
    setDockOpen(window.matchMedia("(min-width: 861px)").matches);
  }, []);

  useEffect(() => {
    let mounted = true;
    const detect = async () => {
      const userAgent = navigator.userAgent;
      const secure = window.isSecureContext;
      let webxr = false;
      try {
        webxr = Boolean(await navigator.xr?.isSessionSupported("immersive-ar"));
      } catch {
        webxr = false;
      }
      if (!mounted) return;
      setArSupport({
        secure,
        camera: secure && Boolean(navigator.mediaDevices?.getUserMedia),
        webxr,
        quickLook: /iPhone|iPad|iPod/.test(userAgent),
        sceneViewer: /Android/.test(userAgent)
      });
    };
    void detect();
    return () => {
      mounted = false;
      stopCamera();
    };
  }, [stopCamera]);

  useEffect(() => {
    if (tool !== "ar") stopCamera();
  }, [stopCamera, tool]);

  useEffect(() => {
    if (!isBusy) {
      setTelemetry((current) => ({ ...current, load: 12, tokens: 0 }));
      return;
    }
    const timer = window.setInterval(() => {
      setTelemetry({
        load: 58 + Math.floor(Math.random() * 34),
        tokens: 18 + Math.random() * 31,
        confidence: 76 + Math.floor(Math.random() * 17)
      });
    }, 780);
    return () => window.clearInterval(timer);
  }, [isBusy]);

  useEffect(() => {
    if (!snapshot) return;
    const parameters = snapshot.cad_document.openscad.parameters;
    const read = (name: string, fallback: number) => Number(parameters.find((parameter) => parameter.name === name)?.value ?? fallback);
    setDimensions({
      width: read("width", DEFAULT_DIMENSIONS.width),
      depth: read("depth", DEFAULT_DIMENSIONS.depth),
      height: read("height", DEFAULT_DIMENSIONS.height),
      wall: read("wall", DEFAULT_DIMENSIONS.wall)
    });
  }, [snapshot]);

  useEffect(() => {
    const onKey = (event: KeyboardEvent) => {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        setPaletteOpen(true);
      }
      if (event.key === "Escape") {
        setPaletteOpen(false);
        stopCamera();
      }
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "z" && snapshot && !isBusy) {
        event.preventDefault();
        const target = snapshot.versions[activeVersionIndex - 1];
        if (target) void handleRestore(target.id);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });

  function beginRequest() {
    requestController.current?.abort();
    const controller = new AbortController();
    requestController.current = controller;
    setRequestState("loading");
    setNotice("");
    return controller;
  }

  function finishRequest() {
    requestController.current = null;
    setRequestState("idle");
  }

  function handleError(error: unknown, fallback: string) {
    requestController.current = null;
    if (error instanceof DOMException && error.name === "AbortError") {
      setRequestState("cancelled");
      setNotice("Stopped waiting for the response. A server-side generation already in progress may still finish.");
      return;
    }
    setRequestState("error");
    setNotice(error instanceof Error ? error.message : fallback);
  }

  async function submitPrompt() {
    if (!prompt.trim()) return;
    const controller = beginRequest();
    const attachmentContext = attachments.length ? `\nLocal reference filenames: ${attachments.map((file) => file.name).join(", ")}. Files were not uploaded.` : "";
    const autonomyContext = autonomous ? "\nAutonomous iteration is enabled: synthesize and self-review one coherent iteration in this response." : "";
    const instruction = `${prompt.trim()}${attachmentContext}${autonomyContext}`;
    try {
      if (!snapshot) {
        setSnapshot(await createProject(selectedTemplate.title, instruction, controller.signal));
      } else {
        const next = await generateDesign(snapshot.project_id, instruction, controller.signal);
        if (!next) throw new Error("The JaC project no longer exists.");
        setSnapshot(next);
      }
      setAttachments([]);
      finishRequest();
      setDockTab("thread");
      setDockOpen(true);
    } catch (error) {
      handleError(error, "The JaC generation request failed.");
    }
  }

  async function handleValidate() {
    if (!snapshot) return;
    const controller = beginRequest();
    try {
      const next = await runValidation(snapshot.project_id, controller.signal);
      if (!next) throw new Error("The JaC project no longer exists.");
      setSnapshot(next);
      finishRequest();
      setTool("validation");
    } catch (error) {
      handleError(error, "Validation failed.");
    }
  }

  async function handleQuote() {
    if (!snapshot) return;
    const controller = beginRequest();
    try {
      const next = await createQuote(snapshot.project_id, 5, controller.signal);
      if (!next) throw new Error("The JaC project no longer exists.");
      setSnapshot(next);
      finishRequest();
      setTool("manufacturing");
    } catch (error) {
      handleError(error, "Quote creation failed.");
    }
  }

  async function handleRestore(versionId: string) {
    if (!snapshot || isBusy) return;
    const controller = beginRequest();
    try {
      const next = await restoreVersion(snapshot.project_id, versionId, controller.signal);
      if (!next) throw new Error("That version is no longer available in the JaC graph.");
      setSnapshot(next);
      finishRequest();
    } catch (error) {
      handleError(error, "Version restore failed.");
    }
  }

  function handleStop() {
    requestController.current?.abort();
  }

  function chooseTemplate(template: BoardTemplate) {
    setSelectedTemplate(template);
    setPrompt(template.prompt);
    setSnapshot(null);
    setDimensions(DEFAULT_DIMENSIONS);
    setNotice(`${template.title} loaded as an uncommitted design brief.`);
    setTool("design");
  }

  function commitDimensions() {
    setPrompt(`Update the enclosure to ${dimensions.width} mm wide, ${dimensions.depth} mm deep, ${dimensions.height} mm high, with ${dimensions.wall} mm walls. Preserve the current electronics intent and refresh validation notes.`);
    setDockTab("thread");
    setNotice("Dimension change staged in the prompt terminal. Press Enter to commit it through JaC.");
  }

  function voiceInput() {
    if (listening) {
      speech.current?.stop();
      return;
    }
    const Recognition = window.SpeechRecognition ?? window.webkitSpeechRecognition;
    if (!Recognition) {
      setNotice("Voice input is not supported by this browser. Use the prompt terminal instead.");
      return;
    }
    const recognition = new Recognition();
    recognition.continuous = false;
    recognition.interimResults = false;
    recognition.lang = "en-US";
    recognition.onresult = (event) => {
      const transcript = event.results.item(0).item(0).transcript;
      setPrompt((current) => `${current}${current ? " " : ""}${transcript}`.trim());
    };
    recognition.onend = () => setListening(false);
    recognition.onerror = () => {
      setListening(false);
      setNotice("Voice capture was denied or interrupted. Check browser microphone permissions.");
    };
    speech.current = recognition;
    setListening(true);
    recognition.start();
  }

  async function toggleCamera() {
    if (cameraActive) {
      stopCamera();
      return;
    }
    if (!arSupport.camera) {
      setNotice("Camera preview requires HTTPS or localhost and a browser with media-device support.");
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: { ideal: "environment" } }, audio: false });
      cameraStream.current = stream;
      if (videoRef.current) videoRef.current.srcObject = stream;
      setCameraActive(true);
      setNotice("");
      if (snapshot) {
        try {
          await createArHandoff(snapshot.project_id, arSupport, "camera-spatial-overlay");
        } catch {
          setNotice("Camera preview is active, but the JaC AR handoff record could not be saved.");
        }
      }
    } catch {
      stopCamera();
      setNotice("Camera access was denied or no camera is available. The interactive 3D fallback remains active.");
    }
  }

  function captureAr() {
    const video = videoRef.current;
    const modelCanvas = workspaceRef.current?.querySelector<HTMLCanvasElement>(".ar-stage .three-host canvas");
    if (!video || !modelCanvas || !cameraActive) return;
    const canvas = document.createElement("canvas");
    canvas.width = Math.max(video.videoWidth, modelCanvas.width);
    canvas.height = Math.max(video.videoHeight, modelCanvas.height);
    const context = canvas.getContext("2d");
    if (!context) return;
    context.drawImage(video, 0, 0, canvas.width, canvas.height);
    context.drawImage(modelCanvas, 0, 0, canvas.width, canvas.height);
    canvas.toBlob((blob) => {
      if (!blob) return;
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = `${sanitizedName(snapshot?.name ?? selectedTemplate.title)}-spatial-preview.png`;
      anchor.click();
      window.setTimeout(() => URL.revokeObjectURL(url), 0);
    }, "image/png");
  }

  function exportArtifact() {
    if (!snapshot) {
      setNotice("Create a JaC project before exporting an artifact.");
      return;
    }
    const rootName = sanitizedName(snapshot.name);
    if (tool === "design") downloadText(`${rootName}.scad`, snapshot.cad_source);
    else if (tool === "firmware") downloadText(`${rootName}-code.py`, snapshot.firmware, "text/x-python");
    else if (tool === "bom") {
      const header = "reference,component,manufacturer,mpn,quantity,unit_price,availability,supplier";
      const rows = snapshot.bom_document.lines.map((line) =>
        [line.designators, line.description, line.manufacturer, line.mpn, line.qty, line.unit_price, line.availability, line.supplier]
          .map((cell) => `"${String(cell).replace(/"/g, "\"\"")}"`).join(",")
      );
      downloadText(`${rootName}-bom.csv`, [header, ...rows].join("\n"), "text/csv");
    } else if (tool === "pcb") downloadText(`${rootName}-pcb-plan.txt`, snapshot.pcb_plan);
    else if (tool === "schematic") downloadText(`${rootName}-schematic.net`, snapshot.schematic);
    else {
      downloadText(`${rootName}-${tool}.json`, JSON.stringify(tool === "validation" ? snapshot.validation : tool === "ar" ? snapshot.ar_payload : snapshot.fab_quote, null, 2), "application/json");
    }
  }

  async function toggleFullscreen() {
    try {
      if (!document.fullscreenElement) await workspaceRef.current?.requestFullscreen();
      else await document.exitFullscreen();
    } catch {
      setNotice("Fullscreen is unavailable in this browser context.");
    }
  }

  function renderStage() {
    if (tool === "pcb") return <PcbStage snapshot={snapshot} />;
    if (tool === "schematic") return <SchematicStage snapshot={snapshot} />;
    if (tool === "firmware") return <FirmwareStage snapshot={snapshot} />;
    if (tool === "bom") return <BomStage snapshot={snapshot} />;
    if (tool === "validation") return <ValidationStage snapshot={snapshot} busy={isBusy} onValidate={() => void handleValidate()} />;
    if (tool === "manufacturing") return <ManufacturingStage snapshot={snapshot} busy={isBusy} onQuote={() => void handleQuote()} />;
    if (tool === "ar") {
      return (
        <ArStage
          snapshot={snapshot}
          dimensions={dimensions}
          layers={layers}
          exploded={exploded}
          support={arSupport}
          cameraActive={cameraActive}
          videoRef={videoRef}
          threeRef={threeRef}
          onCamera={() => void toggleCamera()}
          onCapture={captureAr}
        />
      );
    }
    return <ThreeViewport ref={threeRef} dimensions={dimensions} layers={layers} exploded={exploded} />;
  }

  const activeToolLabel = tools.find((item) => item.id === tool)?.label ?? "Design";
  const warningCount = (snapshot?.circuitron.pcb_warnings.length ?? 0) +
    (snapshot?.validation.filter((check) => check.status !== "passed").length ?? 0);

  return (
    <main className={`helix-app ${dockOpen ? "dock-open" : "dock-closed"}`} ref={workspaceRef}>
      <CommandPalette
        open={paletteOpen}
        query={paletteQuery}
        setQuery={setPaletteQuery}
        templates={templates}
        activeTool={tool}
        onTool={setTool}
        onTemplate={chooseTemplate}
        onClose={() => { setPaletteOpen(false); setPaletteQuery(""); }}
      />

      <header className="global-bar">
        <div className="global-left">
          <HelixMark />
          <span className="bar-divider" />
          <button className="project-switcher" type="button" onClick={() => setPaletteOpen(true)}>
            <span><small>PROJECT / {snapshot?.active_version ?? "DRAFT"}</small><b>{snapshot?.name ?? selectedTemplate.title}</b></span>
            <ChevronDown size={14} />
          </button>
        </div>
        <button className="global-command" type="button" onClick={() => setPaletteOpen(true)}>
          <Search size={14} /><span>Search tools, artifacts, design systems</span><kbd>⌘K</kbd>
        </button>
        <div className="global-actions">
          <span className={`save-state ${requestState}`}>
            {isBusy ? <Loader2 size={13} /> : requestState === "error" ? <CircleAlert size={13} /> : <span className="save-dot" />}
            {isBusy ? "JaC computing" : requestState === "error" ? "Backend issue" : snapshot ? "Graph synced" : "Local draft"}
          </span>
          <div className="history-controls">
            <IconButton label="Restore previous version" disabled={!snapshot || activeVersionIndex <= 0 || isBusy} onClick={() => {
              const target = snapshot?.versions[activeVersionIndex - 1];
              if (target) void handleRestore(target.id);
            }}><Undo2 size={15} /></IconButton>
            <IconButton label="Restore next version" disabled={!snapshot || activeVersionIndex < 0 || activeVersionIndex >= (snapshot?.versions.length ?? 0) - 1 || isBusy} onClick={() => {
              const target = snapshot?.versions[activeVersionIndex + 1];
              if (target) void handleRestore(target.id);
            }}><Redo2 size={15} /></IconButton>
          </div>
          <button className="export-button" type="button" onClick={exportArtifact}><ArrowDownToLine size={14} />Export {activeToolLabel}</button>
          <IconButton label={dockOpen ? "Hide Sol Core" : "Show Sol Core"} active={dockOpen} onClick={() => setDockOpen(!dockOpen)}><PanelRight size={17} /></IconButton>
        </div>
      </header>

      <ToolRail tool={tool} onChange={setTool} onMenu={() => setPaletteOpen(true)} />

      <section
        className="kinetic-canvas"
        onPointerMove={(event) => {
          const bounds = event.currentTarget.getBoundingClientRect();
          setCoordinates({
            x: ((event.clientX - bounds.left) / bounds.width - 0.5) * dimensions.width,
            y: (0.5 - (event.clientY - bounds.top) / bounds.height) * dimensions.height,
            z: dimensions.depth * 0.5
          });
        }}
      >
        {renderStage()}
        <div className="canvas-grain" aria-hidden="true" />

        <div className="canvas-hud top-left">
          <span>{activeToolLabel.toUpperCase()} / {snapshot?.active_version ?? "UNCOMMITTED"}</span>
          <b>{snapshot?.name ?? selectedTemplate.title}</b>
          <small>{dimensions.width} × {dimensions.depth} × {dimensions.height} mm · {snapshot?.cad_document.features.length ?? 5} features</small>
        </div>
        <div className={`canvas-hud evidence-state ${warningCount ? "warning" : ""}`}>
          <span>{warningCount ? `${warningCount} OPEN WARNINGS` : snapshot ? "NO RECORDED FAILURES" : "AWAITING EVIDENCE"}</span>
          <i />
        </div>
        {!snapshot ? (
          <div className="empty-overlay">
            <span><Sparkles size={14} />UNCOMMITTED DESIGN SYSTEM</span>
            <h1>Engineer the object,<br />not the dashboard.</h1>
            <p>{selectedTemplate.description}</p>
            <button type="button" onClick={() => setPaletteOpen(true)}><Grid3X3 size={15} />Explore {templates.length} design systems</button>
          </div>
        ) : null}

        {(tool === "design" || tool === "ar") ? (
          <div className="view-controls" aria-label="3D view controls">
            <IconButton label="Fit model to viewport" onClick={() => threeRef.current?.fit()}><Focus size={16} /></IconButton>
            <IconButton label="Reset camera" onClick={() => threeRef.current?.reset()}><Rotate3D size={16} /></IconButton>
            <IconButton label="Toggle exploded assembly" active={exploded} onClick={() => setExploded(!exploded)}><Boxes size={16} /></IconButton>
            <IconButton label="Toggle fullscreen" onClick={() => void toggleFullscreen()}><Maximize2 size={16} /></IconButton>
          </div>
        ) : null}

        <div className="axis-gizmo" aria-hidden="true"><i className="axis-x">X</i><i className="axis-y">Y</i><i className="axis-z">Z</i></div>
        <VersionTimeline snapshot={snapshot} busy={isBusy} onRestore={(versionId) => void handleRestore(versionId)} />
        <PromptTerminal
          value={prompt}
          setValue={setPrompt}
          busy={isBusy}
          autonomous={autonomous}
          setAutonomous={setAutonomous}
          attachments={attachments}
          onFiles={setAttachments}
          onVoice={voiceInput}
          listening={listening}
          onSubmit={() => void submitPrompt()}
          onStop={handleStop}
          message={notice}
        />
      </section>

      <SolCore
        tab={dockTab}
        setTab={setDockTab}
        snapshot={snapshot}
        tool={tool}
        busy={isBusy}
        telemetry={telemetry}
        reasoning={reasoning}
        setReasoning={setReasoning}
        coordinates={coordinates}
        dimensions={dimensions}
        setDimensions={setDimensions}
        layers={layers}
        setLayers={setLayers}
        exploded={exploded}
        setExploded={setExploded}
        onCommitDimensions={commitDimensions}
        onClose={() => setDockOpen(false)}
      />

      <button className="mobile-core-trigger" type="button" onClick={() => setDockOpen(!dockOpen)}>
        <Cpu size={16} />SOL CORE<span className={isBusy ? "active" : ""} />
      </button>
    </main>
  );
}
