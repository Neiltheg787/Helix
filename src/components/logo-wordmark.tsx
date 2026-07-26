import { cn } from "@/lib/utils";

type LogoWordmarkProps = {
  className?: string;
  /** Prefer true for above-the-fold brand marks (e.g. main nav). */
  priority?: boolean;
};

/** Compact Helix wordmark used across the app shell. */
export function LogoWordmark({ className, priority }: LogoWordmarkProps) {
  void priority;

  return (
    <span
      className={cn(
        "inline-flex items-center gap-2.5 font-sans font-semibold tracking-normal text-inherit",
        className,
      )}
    >
      <span
        aria-hidden
        className="relative size-7 shrink-0 overflow-hidden rounded-[10px] border border-emerald-950/15 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.08),inset_0_0_0_1px_rgba(255,255,255,0.8)] sm:size-8"
      >
        <span className="absolute left-[6px] top-[5px] h-[18px] w-[4px] rotate-[25deg] rounded-full bg-[#0b3d2e]" />
        <span className="absolute right-[6px] top-[5px] h-[18px] w-[4px] rotate-[25deg] rounded-full bg-[#0b3d2e]" />
        <span className="absolute left-[9px] top-[8px] h-[3px] w-[11px] -rotate-[25deg] rounded-full bg-[#b7e75d]" />
        <span className="absolute left-[8px] top-[15px] h-[3px] w-[12px] -rotate-[25deg] rounded-full bg-[#b7e75d]" />
      </span>
      <span className="font-heading text-[1.03em] font-semibold">Helix</span>
    </span>
  );
}
