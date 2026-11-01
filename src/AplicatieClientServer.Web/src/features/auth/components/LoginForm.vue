<script setup lang="ts">
import { onMounted, ref, useTemplateRef, watch } from "vue";
import type { Credentials } from "../authTypes";

const props = defineProps<{ busy: boolean; resetKey: number }>();
const emit = defineEmits<{ submit: [credentials: Credentials] }>();
const email = defineModel<string>("email", { required: true });
const password = ref("");
const passwordInput = useTemplateRef<HTMLInputElement>("passwordInput");

watch(() => props.resetKey, () => { password.value = ""; });
onMounted(() => { if (email.value) passwordInput.value?.focus(); });

function submit() {
  if (!props.busy) emit("submit", { email: email.value.trim(), password: password.value });
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
      <input id="auth-password" ref="passwordInput" v-model="password" name="password" type="password" autocomplete="current-password" minlength="1" :disabled="busy" required />
    </div>
    <button id="auth-submit" class="primary-button" type="submit" :disabled="busy">{{ busy ? "Входим…" : "Войти" }}</button>
  </form>
</template>
