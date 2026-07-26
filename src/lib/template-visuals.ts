import { cn } from "@/lib/utils";
import type { LucideIcon } from "lucide-react";
import {
  Gamepad2,
  Heart,
  KeyRound,
  LampDesk,
  Laptop,
  Leaf,
  Sprout,
} from "lucide-react";

/** Muted tint + dark base — no stock photography. */
export type TemplateAccent =
  | "zinc"
  | "slate"
  | "amber"
  | "sky"
  | "violet"
  | "emerald"
  | "rose"
  | "cyan";

export function templateAccentClass(accent: TemplateAccent): string {
  const map: Record<TemplateAccent, string> = {
    zinc: "from-zinc-600/35 via-zinc-900/72 to-[#0b0a08]",
    slate: "from-slate-600/28 via-zinc-900/72 to-[#0b0a08]",
    amber: "from-amber-500/14 via-zinc-900/68 to-[#0b0a08]",
    sky: "from-amber-500/12 via-zinc-900/68 to-[#0b0a08]",
    violet: "from-teal-500/11 via-zinc-900/68 to-[#0b0a08]",
    emerald: "from-emerald-500/10 via-zinc-900/68 to-[#0b0a08]",
    rose: "from-rose-500/9 via-zinc-900/68 to-[#0b0a08]",
    cyan: "from-cyan-500/10 via-zinc-900/68 to-[#0b0a08]",
  };
  return cn("bg-gradient-to-br", map[accent]);
}

/** Stable icon lookup — avoids creating component types during render. */
export const TEMPLATE_CATEGORY_ICONS: Record<string, LucideIcon> = {
  "Pets & home": Heart,
  "Plants & garden": Sprout,
  "Lights & rooms": LampDesk,
  "Kids & play": Gamepad2,
  "Desk & work": Laptop,
  Portable: KeyRound,
};

export const DEFAULT_TEMPLATE_ICON: LucideIcon = Leaf;

export function templateCategoryIcon(category: string): LucideIcon {
  return TEMPLATE_CATEGORY_ICONS[category] ?? DEFAULT_TEMPLATE_ICON;
}
