export type BomLine = {
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

export type BoardTemplate = {
  id: string;
  category: string;
  accent: string;
  title: string;
  tagline: string;
  description: string;
  bullets: string[];
  prompt: string;
};

export type WorkspaceSnapshot = {
  project_id: string;
  name: string;
  prompt: string;
  tagline: string;
  active_version: string;
  cad_source: string;
  cad_document: { features: unknown[]; openscad: { parameters: { name: string; display_name: string; value: string }[] }; presentation: { open_face: string } };
  pcb_plan: string;
  circuitron: { pcb_source: string; width_mm: number; height_mm: number; layer_count: number; pcb_warnings: string[]; design_validation: { summary: string } };
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

const API_URL = import.meta.env.VITE_HELIX_API_URL ?? "";

async function callJac<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    method: "POST",
    headers: body ? { "Content-Type": "application/json" } : undefined,
    body: body ? JSON.stringify(body) : undefined
  });
  const data = (await res.json()) as JacResponse<T>;
  if (!res.ok || !data.ok || !data.data) throw new Error(data.error?.message ?? `Helix API failed: ${path}`);
  return data.data.result;
}

export function createProject(name: string, prompt: string) {
  return callJac<WorkspaceSnapshot>("/function/create_project", { name, prompt });
}

export function loadWorkspace(project_id: string) {
  return callJac<WorkspaceSnapshot | null>("/function/load_workspace", { project_id });
}

export function generateDesign(project_id: string, prompt: string) {
  return callJac<WorkspaceSnapshot | null>("/function/generate_hardware_design", { project_id, prompt });
}

export function runValidation(project_id: string) {
  return callJac<WorkspaceSnapshot | null>("/function/run_validations", { project_id });
}

export function createQuote(project_id: string, quantity: number) {
  return callJac<Record<string, string>>("/function/create_fabrication_quote", { project_id, quantity });
}

export function health() {
  return callJac<{ reports: { ok: boolean }[] }>("/walker/Health");
}
