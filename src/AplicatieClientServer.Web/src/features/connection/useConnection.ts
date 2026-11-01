import { computed, onMounted, onUnmounted, ref, shallowRef } from "vue";
import { getErrorMessage } from "../../shared/api/http";
import { getHealth } from "./connectionApi";
import type { HealthResponse } from "./connectionApi";

export function useConnection() {
  const status = ref<"loading" | "success" | "error">("loading");
  const health = shallowRef<HealthResponse | null>(null);
  const errorMessage = ref("");
  const checkedAt = ref("—");
  const timeFormat = new Intl.DateTimeFormat("ru-RU", { timeStyle: "medium" });
  let active = true;
  let checking = false;

  async function check(): Promise<void> {
    if (checking) return;
    checking = true;
    status.value = "loading";
    health.value = null;
    checkedAt.value = "—";
    try {
      const response = await getHealth();
      if (!active) return;
      health.value = response;
      status.value = "success";
    } catch (error: unknown) {
      if (!active) return;
      errorMessage.value = getErrorMessage(error);
      status.value = "error";
    } finally {
      checking = false;
      if (active) checkedAt.value = timeFormat.format(new Date());
    }
  }

  const title = computed(() => status.value === "loading" ? "Проверяем подключение"
    : status.value === "success" ? "Сервер доступен" : "Не удалось подключиться");
  const description = computed(() => status.value === "loading" ? "Ожидаем ответ сервера."
    : status.value === "success" ? "Соединение установлено. API отвечает на запросы." : errorMessage.value);

  onMounted(() => { void check(); });
  onUnmounted(() => { active = false; });
  return { status, health, checkedAt, title, description, check };
}
