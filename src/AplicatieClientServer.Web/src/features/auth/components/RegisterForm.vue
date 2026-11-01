<script setup lang="ts">
import { ref, useTemplateRef, watch } from "vue";
import type { Credentials } from "../authTypes";

const props = defineProps<{ busy: boolean; resetKey: number }>();
const emit = defineEmits<{ submit: [credentials: Credentials] }>();
const email = defineModel<string>("email", { required: true });
const password = ref("");
const confirmation = ref("");
const confirmationInput = useTemplateRef<HTMLInputElement>("confirmationInput");

function clearValidity() { confirmationInput.value?.setCustomValidity(""); }
watch(() => props.resetKey, () => {
  password.value = "";
  confirmation.value = "";
  clearValidity();
});

function submit(event: Event) {
  if (props.busy) return;
  confirmationInput.value?.setCustomValidity(password.value === confirmation.value ? "" : "Пароли должны совпадать.");
  if (event.currentTarget instanceof HTMLFormElement && event.currentTarget.reportValidity()) {
    emit("submit", { email: email.value.trim(), password: password.value });
  }
}
</script>

<template>
  <form id="auth-form" class="auth-form" @submit.prevent="submit">
    <div class="form-field">
      <label for="auth-email">Email</label>
      <input id="auth-email" v-model="email" name="email" type="email" autocomplete="username" maxlength="256" :disabled="busy" required />
    </div>
    <div class="form-field">
      <label for="auth-password">Пароль</label>
      <input id="auth-password" v-model="password" name="password" type="password" autocomplete="new-password" minlength="8" :disabled="busy" aria-describedby="password-hint" required @input="clearValidity" />
      <p id="password-hint" class="field-hint">Не менее 8 символов: строчная и прописная буквы, цифра и специальный символ.</p>
    </div>
    <div class="form-field">
      <label for="auth-password-confirm">Повторите пароль</label>
      <input id="auth-password-confirm" ref="confirmationInput" v-model="confirmation" name="passwordConfirmation" type="password" autocomplete="new-password" :disabled="busy" required @input="clearValidity" />
    </div>
    <button id="auth-submit" class="primary-button" type="submit" :disabled="busy">{{ busy ? "Создаём аккаунт…" : "Создать аккаунт" }}</button>
  </form>
</template>
