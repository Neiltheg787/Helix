import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "api.qrserver.com",
        pathname: "/v1/create-qr-code/**",
      },
    ],
  },
  // For API routes that need longer execution time
  async headers() {
    return [
      {
        source: "/api/circuitron/:path*",
        headers: [
          {
            key: "X-Timeout",
            value: "300000", // 5 minutes in milliseconds (Vercel Hobby maximum)
          },
        ],
      },
    ];
  },
};

export default nextConfig;
