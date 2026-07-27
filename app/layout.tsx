import type { Metadata, Viewport } from "next";
import React from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "Helix",
  description: "AI-native hardware engineering workspace powered by a JaC backend."
};

export const viewport: Viewport = {
  themeColor: "#f8faf8",
  width: "device-width",
  initialScale: 1
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
