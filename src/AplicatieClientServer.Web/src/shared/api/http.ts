export class ApiError extends Error {
  constructor(message: string, public readonly status = 0, public readonly payload: unknown = null) {
    super(message);
    this.name = "ApiError";
  }
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Не удалось выполнить действие. Повторите попытку.";
}

interface RequestOptions {
  method?: "GET" | "POST";
  body?: unknown;
  csrfToken?: string;
}

export async function requestJson(path: string, options: RequestOptions = {}): Promise<unknown> {
  const headers = new Headers({ Accept: "application/json" });
  if (options.body !== undefined) headers.set("Content-Type", "application/json");
  if (options.csrfToken) headers.set("X-CSRF-TOKEN", options.csrfToken);

  try {
    const response = await fetch(`/api${path}`, {
      method: options.method ?? "GET",
      headers,
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      credentials: "same-origin",
      cache: "no-store",
      signal: AbortSignal.timeout(8000),
    });
    const text = await response.text();
    let payload: unknown = null;
    if (text && response.headers.get("Content-Type")?.includes("json")) {
      try {
        payload = JSON.parse(text);
      } catch {
        if (response.ok) throw new ApiError("Не удалось прочитать ответ сервера. Повторите попытку.");
      }
    }
    if (!response.ok) throw new ApiError(`Сервер вернул HTTP ${response.status}.`, response.status, payload);
    return payload;
  } catch (error: unknown) {
    if (error instanceof ApiError) throw error;
    if (error instanceof Error && (error.name === "TimeoutError" || error.name === "AbortError")) {
      throw new ApiError("Сервер не ответил за 8 секунд. Повторите попытку.");
    }
    throw new ApiError("Не удалось связаться с сервером. Проверьте подключение и повторите попытку.");
  }
}
