import { computed, ref, shallowRef, watch } from "vue";
import { getErrorMessage } from "../../shared/api/http";
import { registerAccount } from "./authApi";
import type { AuthFeedback, AuthMode, Credentials } from "./authTypes";
import type { AuthSession } from "./useAuthSession";

export function useAuthForm(session: AuthSession) {
  const mode = ref<AuthMode>("login");
  const email = ref("");
  const submitting = ref(false);
  const resetKey = ref(0);
  const formFeedback = shallowRef<AuthFeedback | null>(null);
  const busy = computed(() => submitting.value || session.busy.value);
  const feedback = computed(() => formFeedback.value ?? session.feedback.value);

  function changeMode(nextMode: AuthMode) {
    if (busy.value) return;
    mode.value = nextMode;
    resetKey.value++;
    formFeedback.value = null;
    session.clearFeedback();
  }

  async function submit(credentials: Credentials): Promise<void> {
    if (busy.value) return;
    submitting.value = true;
    formFeedback.value = null;
    session.clearFeedback();
    try {
      if (mode.value === "register") {
        await registerAccount(credentials);
        mode.value = "login";
        resetKey.value++;
        formFeedback.value = { message: "Аккаунт создан. Войдите с указанным email и паролем.", kind: "success" };
      } else if (await session.login(credentials)) {
        resetKey.value++;
      }
    } catch (error: unknown) {
      formFeedback.value = { message: getErrorMessage(error), kind: "error" };
    } finally {
      submitting.value = false;
    }
  }

  function logout() {
    formFeedback.value = null;
    return session.logout();
  }

  watch(() => session.state.value.status, (status) => {
    if (status !== "anonymous") {
      resetKey.value++;
      formFeedback.value = null;
    }
    if (status === "anonymous") mode.value = "login";
  });

  return { mode, email, busy, resetKey, feedback, changeMode, submit, logout };
}
