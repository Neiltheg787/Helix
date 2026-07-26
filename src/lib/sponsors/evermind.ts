type EvermindMessage = {
  role: "user" | "assistant" | "system";
  content: string;
};

const EVERMIND_BASE_URL =
  process.env.EVERMIND_BASE_URL?.replace(/\/$/, "") ?? "https://api.evermind.ai";

function evermindKey() {
  return process.env.EVERMIND_API_KEY?.trim() || null;
}

function evermindUserId() {
  return process.env.EVERMIND_USER_ID?.trim() || "helix-hackathon-demo";
}

export function isEvermindConfigured() {
  return Boolean(evermindKey());
}

export async function searchEvermindMemories(query: string) {
  const key = evermindKey();
  if (!key || !query.trim()) return "";

  try {
    const res = await fetch(`${EVERMIND_BASE_URL}/api/v1/memories/search`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        query: query.slice(0, 2000),
        filters: { user_id: evermindUserId() },
        method: "hybrid",
        memory_types: ["episodic_memory", "profile", "agent_memory"],
        top_k: 5,
      }),
    });
    if (!res.ok) return "";
    const data = (await res.json()) as unknown;
    return JSON.stringify(data).slice(0, 4000);
  } catch (error) {
    console.warn("[evermind] memory search failed", error);
    return "";
  }
}

export async function rememberWithEvermind(
  sessionId: string,
  messages: EvermindMessage[],
) {
  const key = evermindKey();
  const clean = messages
    .map((message) => ({
      role: message.role,
      timestamp: Date.now(),
      content: message.content.slice(0, 4000),
    }))
    .filter((message) => message.content.trim().length > 0);

  if (!key || clean.length === 0) return false;

  try {
    const res = await fetch(`${EVERMIND_BASE_URL}/api/v1/memories`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        user_id: evermindUserId(),
        session_id: sessionId,
        messages: clean,
        async_mode: true,
      }),
    });
    return res.ok;
  } catch (error) {
    console.warn("[evermind] memory write failed", error);
    return false;
  }
}
