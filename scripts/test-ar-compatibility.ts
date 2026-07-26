import assert from "node:assert/strict";
import { getArCompatibilityReport } from "../src/lib/ar-compatibility";

async function run() {
  const insecure = await getArCompatibilityReport({
    isSecureContext: false,
    navigator: {
      userAgent: "Mozilla/5.0",
      platform: "Linux",
      maxTouchPoints: 0,
    } as unknown as Navigator,
  });
  assert.equal(insecure.webXr, "unsupported");
  assert.equal(insecure.preferredMode, "orbit-preview");
  assert.ok(insecure.blockers.some((line) => line.includes("HTTPS")));

  const webxr = await getArCompatibilityReport({
    isSecureContext: true,
    navigator: {
      userAgent: "Mozilla/5.0 Android Chrome",
      platform: "Linux armv8",
      maxTouchPoints: 5,
      xr: { isSessionSupported: async () => true },
      mediaDevices: { getUserMedia: async () => ({}) as MediaStream },
    } as unknown as Navigator,
  });
  assert.equal(webxr.webXr, "supported");
  assert.equal(webxr.preferredMode, "webxr");

  const ios = await getArCompatibilityReport({
    isSecureContext: true,
    navigator: {
      userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit Safari",
      platform: "iPhone",
      maxTouchPoints: 5,
      mediaDevices: { getUserMedia: async () => ({}) as MediaStream },
    } as unknown as Navigator,
  });
  assert.equal(ios.iosQuickLook, "supported");
  assert.equal(ios.preferredMode, "ios-quick-look");

  const denied = await getArCompatibilityReport({
    isSecureContext: true,
    navigator: {
      userAgent: "Mozilla/5.0",
      platform: "MacIntel",
      maxTouchPoints: 0,
      mediaDevices: { getUserMedia: async () => ({}) as MediaStream },
      permissions: { query: async () => ({ state: "denied" }) as PermissionStatus },
    } as unknown as Navigator,
  });
  assert.equal(denied.cameraPermission, "denied");
  assert.equal(denied.preferredMode, "orbit-preview");
}

run().then(
  () => console.log("AR compatibility tests passed."),
  (error) => {
    console.error(error);
    process.exit(1);
  },
);
