import { Suspense } from "react";

import { HomeExperience } from "@/components/home-experience";

function HomeFallback() {
  return (
    <div
      className="flex min-h-screen flex-col items-center justify-center bg-[#080706] px-6 pt-24 text-center"
      aria-busy
      aria-label="Loading"
    >
      <p className="font-heading text-lg font-semibold text-zinc-100">Helix</p>
      <p className="mt-2 max-w-sm text-sm text-zinc-500">
        Loading… If this stays blank, refresh once the tunnel connection is ready.
      </p>
    </div>
  );
}

export default function Home() {
  return (
    <Suspense fallback={<HomeFallback />}>
      <HomeExperience />
    </Suspense>
  );
}
