export async function getHealth() {
  let response;

  try {
    response = await fetch("/api/health", {
      headers: { Accept: "application/json" },
      cache: "no-store",
      signal: AbortSignal.timeout(8000),
    });
  } catch (error) {
    if (error.name === "TimeoutError") {
      throw new Error("Сервер не ответил за 8 секунд. Повторите проверку.");
    }

    throw new Error("Не удалось связаться с сервером. Проверьте подключение и повторите попытку.");
  }

  // fetch resolves for HTTP errors too; inspect the response before reading JSON.
  if (!response.ok) {
    throw new Error(`Сервер вернул HTTP ${response.status}. Убедитесь, что API запущен, и повторите проверку.`);
  }

  let health;

  try {
    health = await response.json();
  } catch {
    throw new Error("Сервер вернул некорректный JSON. Проверьте адрес API.");
  }

  if (
    health?.status !== "ok" ||
    typeof health.service !== "string" || !health.service.trim() ||
    typeof health.version !== "string" || !health.version.trim()
  ) {
    throw new Error("Ответ сервера не соответствует ожидаемому формату проверки.");
  }

  return health;
}
