const jacOrigin = process.env.HELIX_JAC_ORIGIN ?? "http://127.0.0.1:8000";

/** @type {import('next').NextConfig} */
const nextConfig = {
  devIndicators: false,
  async rewrites() {
    return [
      { source: "/function/:path*", destination: `${jacOrigin}/function/:path*` },
      { source: "/walker/:path*", destination: `${jacOrigin}/walker/:path*` }
    ];
  }
};

export default nextConfig;
