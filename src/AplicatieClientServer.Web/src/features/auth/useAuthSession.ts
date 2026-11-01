import { computed, onMounted, onUnmounted, ref, shallowRef } from "vue";
import { ApiError, getErrorMessage } from "../../shared/api/http";
import * as authApi from "./authApi";
import type { AuthFeedback, AuthState, Credentials, CurrentUser } from "./authTypes";

export function useAuthSession() {
  const state = shallowRef<AuthState>({ status: "loading", user: null });
  const busy = ref(false);
  const feedback = shallowRef<AuthFeedback | null>(null);
  let requestVersion = 0;
  let active = true;
  let refreshQueued = false;
  let channel: BroadcastChannel | null = null;

  async function refresh(): Promise<void> {
    if (busy.value) {
      refreshQueued = true;
      return;
    }
    const version = ++requestVersion;
    const previousStatus = state.value.status;
    try {
      const user = await authApi.getCurrentUser();
      if (!active || version !== requestVersion) return;
      state.value = user ? { status: "authenticated", user } : { status: "anonymous", user: null };
      if (previousStatus === "unavailable") feedback.value = null;
      if (previousStatus === "authenticated" && !user) {
        feedback.value = { message: "Сеанс завершён. Войдите снова.", kind: "success" };
      }
    } catch (error: unknown) {
      if (!active || version !== requestVersion) return;
      state.value = { status: "unavailable", user: null };
      feedback.value = { message: getErrorMessage(error), kind: "error" };
    }
  }

  async function changeSession(action: () => Promise<CurrentUser | null>, message: string): Promise<boolean> {
    if (busy.value) return false;
    busy.value = true;
    requestVersion++;
    feedback.value = null;
    try {
      const user = await action();
      if (!active) return false;
      state.value = user ? { status: "authenticated", user } : { status: "anonymous", user: null };
      feedback.value = { message, kind: "success" };
      channel?.postMessage("session-changed");
      return true;
    } catch (error: unknown) {
      if (active) feedback.value = { message: getErrorMessage(error), kind: "error" };
      return false;
    } finally {
      busy.value = false;
      if (active && refreshQueued) {
        refreshQueued = false;
        void refresh();
      }
    }
  }

  function login(credentials: Credentials): Promise<boolean> {
    return changeSession(async () => {
      await authApi.login(credentials);
      const user = await authApi.getCurrentUser();
      if (!user) throw new ApiError("Не удалось подтвердить вход. Повторите попытку.");
      return user;
    }, "Вход выполнен.");
  }

  function logout(): Promise<boolean> {
    return changeSession(async () => {
      try {
        await authApi.logout();
      } catch (error: unknown) {
        if (!(error instanceof ApiError) || error.status !== 401) throw error;
      }
      return null;
    }, "Вы вышли из аккаунта.");
  }

  function refreshOnFocus() {
    void refresh();
  }

  function refreshOnVisibility() {
    if (document.visibilityState === "visible") void refresh();
  }

  onMounted(() => {
    if (typeof BroadcastChannel === "function") {
      channel = new BroadcastChannel("acs-drive-auth");
      // Announce invalidation only; the receiving tab reads the account from the API.
      channel.addEventListener("message", refreshOnFocus);
    }
    window.addEventListener("focus", refreshOnFocus);
    document.addEventListener("visibilitychange", refreshOnVisibility);
    void refresh();
  });

  onUnmounted(() => {
    active = false;
    requestVersion++;
    window.removeEventListener("focus", refreshOnFocus);
    document.removeEventListener("visibilitychange", refreshOnVisibility);
    channel?.close();
  });

  return {
    state: computed(() => state.value),
    busy: computed(() => busy.value),
    feedback: computed(() => feedback.value),
    refresh, login, logout,
    clearFeedback: () => { feedback.value = null; },
  };
}

export type AuthSession = ReturnType<typeof useAuthSession>;
