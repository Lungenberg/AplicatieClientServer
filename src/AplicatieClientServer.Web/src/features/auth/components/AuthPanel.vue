<script setup lang="ts">
import { computed } from "vue";
import FeedbackMessage from "../../../shared/ui/FeedbackMessage.vue";
import { useAuthForm } from "../useAuthForm";
import type { AuthSession } from "../useAuthSession";
import AccountSummary from "./AccountSummary.vue";
import LoginForm from "./LoginForm.vue";
import RegisterForm from "./RegisterForm.vue";

const props = defineProps<{ session: AuthSession }>();
const { state } = props.session;
const { mode, email, busy, resetKey, feedback, changeMode, submit, logout } = useAuthForm(props.session);
const title = computed(() => state.value.status === "authenticated" ? "Вы в своём пространстве"
  : mode.value === "register" ? "Создайте свой аккаунт" : "Войдите в своё пространство");
const description = computed(() => state.value.status === "authenticated"
  ? "Вход выполнен. Здесь можно проверить аккаунт или завершить сеанс."
  : mode.value === "register" ? "Используйте email и надёжный пароль. После регистрации можно будет войти в аккаунт."
  : "Войдите в существующий аккаунт или зарегистрируйтесь, если вы здесь впервые.");
const statusLabel = computed(() => {
  switch (state.value.status) {
    case "loading": return "Проверяем состояние входа…";
    case "authenticated": return "Аккаунт подключён";
    case "anonymous": return "Вход не выполнен";
    case "unavailable": return "Не удалось проверить состояние входа";
  }
});
</script>

<template>
  <section id="account" class="auth-panel" :data-state="state.status" :aria-busy="busy || state.status === 'loading'" aria-labelledby="account-title">
    <div class="auth-intro">
      <p class="eyebrow">Ваш аккаунт</p>
      <h2 id="account-title">{{ title }}</h2>
      <p>{{ description }}</p>
      <p id="auth-status" class="auth-status" role="status" aria-live="polite">{{ statusLabel }}</p>
    </div>
    <div class="auth-controls">
      <template v-if="state.status === 'anonymous'">
        <div class="auth-modes" aria-label="Действие с аккаунтом">
          <button id="auth-login-mode" type="button" :aria-pressed="mode === 'login'" :disabled="busy" @click="changeMode('login')">Вход</button>
          <button id="auth-register-mode" type="button" :aria-pressed="mode === 'register'" :disabled="busy" @click="changeMode('register')">Регистрация</button>
        </div>
        <LoginForm v-if="mode === 'login'" v-model:email="email" :busy="busy" :reset-key="resetKey" @submit="submit" />
        <RegisterForm v-else v-model:email="email" :busy="busy" :reset-key="resetKey" @submit="submit" />
      </template>
      <AccountSummary v-else-if="state.status === 'authenticated'" :user="state.user" :busy="busy" @logout="logout" />
      <FeedbackMessage v-if="feedback" id="auth-feedback" :message="feedback.message" :kind="feedback.kind" />
      <button v-if="state.status === 'unavailable'" id="auth-retry" type="button" :disabled="busy" @click="session.refresh">Повторить проверку входа</button>
    </div>
  </section>
</template>
