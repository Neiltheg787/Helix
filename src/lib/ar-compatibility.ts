export type ArCapabilityStatus = "supported" | "unsupported" | "unknown";

export type ArCompatibilityReport = {
  secureContext: boolean;
  webXr: ArCapabilityStatus;
  iosQuickLook: ArCapabilityStatus;
  androidSceneViewer: ArCapabilityStatus;
  cameraApi: ArCapabilityStatus;
  cameraPermission: "granted" | "denied" | "prompt" | "unknown";
  preferredMode:
    | "webxr"
    | "ios-quick-look"
    | "android-scene-viewer"
    | "camera-preview"
    | "orbit-preview";
  blockers: string[];
  warnings: string[];
};

type NavigatorLike = Navigator & {
  xr?: {
    isSessionSupported?: (mode: "immersive-ar") => Promise<boolean>;
  };
};

function detectIosQuickLook(userAgent: string, platform: string, maxTouchPoints: number) {
  const isiOS =
    /iPad|iPhone|iPod/i.test(userAgent) ||
    (platform === "MacIntel" && maxTouchPoints > 1);
  const safari = /Safari/i.test(userAgent) && !/CriOS|FxiOS|EdgiOS/i.test(userAgent);
  return isiOS && safari;
}

function detectAndroidSceneViewer(userAgent: string) {
  return /Android/i.test(userAgent) && /Chrome|CriOS/i.test(userAgent);
}

export async function getArCompatibilityReport(
  env: {
    navigator?: NavigatorLike;
    isSecureContext?: boolean;
    userAgent?: string;
    platform?: string;
  } = {},
): Promise<ArCompatibilityReport> {
  const nav = env.navigator;
  const userAgent = env.userAgent ?? nav?.userAgent ?? "";
  const platform = env.platform ?? nav?.platform ?? "";
  const secureContext = env.isSecureContext ?? globalThis.isSecureContext === true;
  const maxTouchPoints = nav?.maxTouchPoints ?? 0;
  const blockers: string[] = [];
  const warnings: string[] = [];

  let webXr: ArCapabilityStatus = "unknown";
  if (!secureContext) {
    webXr = "unsupported";
    blockers.push("WebXR requires HTTPS or localhost.");
  } else if (nav?.xr?.isSessionSupported) {
    try {
      webXr = (await nav.xr.isSessionSupported("immersive-ar"))
        ? "supported"
        : "unsupported";
    } catch {
      webXr = "unsupported";
      warnings.push("The browser exposed WebXR but rejected the immersive-ar probe.");
    }
  } else {
    webXr = "unsupported";
  }

  const iosQuickLook = detectIosQuickLook(userAgent, platform, maxTouchPoints)
    ? "supported"
    : "unsupported";
  const androidSceneViewer = detectAndroidSceneViewer(userAgent)
    ? "supported"
    : "unsupported";
  const cameraApi = nav?.mediaDevices?.getUserMedia ? "supported" : "unsupported";

  let cameraPermission: ArCompatibilityReport["cameraPermission"] = "unknown";
  try {
    const permission = await nav?.permissions?.query?.({
      name: "camera" as PermissionName,
    });
    if (
      permission?.state === "granted" ||
      permission?.state === "denied" ||
      permission?.state === "prompt"
    ) {
      cameraPermission = permission.state;
    }
  } catch {
    cameraPermission = "unknown";
  }
  if (cameraPermission === "denied") {
    blockers.push("Camera permission was denied. Browser preview can still use orbit mode.");
  }
  if (cameraApi === "unsupported") {
    warnings.push("Camera API is unavailable, so Helix will use interactive 3D orbit preview.");
  }

  const preferredMode =
    webXr === "supported"
      ? "webxr"
      : iosQuickLook === "supported"
        ? "ios-quick-look"
        : androidSceneViewer === "supported"
          ? "android-scene-viewer"
          : cameraApi === "supported" && cameraPermission !== "denied" && secureContext
            ? "camera-preview"
            : "orbit-preview";

  return {
    secureContext,
    webXr,
    iosQuickLook,
    androidSceneViewer,
    cameraApi,
    cameraPermission,
    preferredMode,
    blockers,
    warnings,
  };
}
