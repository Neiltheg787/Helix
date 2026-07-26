import type { Metadata, Viewport } from "next";
import "./globals.css";
import { SiteNavbar } from "@/components/site-navbar";

export const metadata: Metadata = {
  title: "Helix",
  description: "The direct path from idea to hardware prototype.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className="min-h-dvh antialiased"
    >
      <body
        className="flex min-h-dvh flex-col font-sans antialiased"
      >
        <SiteNavbar />
        <div className="flex min-h-0 flex-1 flex-col">{children}</div>
      </body>
    </html>
  );
}
