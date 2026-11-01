import { ApiError, isRecord, requestJson } from "../../shared/api/http";

export interface HealthResponse {
  status: "ok";
  service: string;
  version: string;
}

export async function getHealth(): Promise<HealthResponse> {
  const health = await requestJson("/health");
  if (!isRecord(health) || health.status !== "ok" ||
      typeof health.service !== "string" || typeof health.version !== "string") {
    throw new ApiError("Ответ сервера не соответствует ожидаемому формату проверки.");
  }
  return { status: "ok", service: health.service, version: health.version };
}
