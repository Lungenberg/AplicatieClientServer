<script setup lang="ts">
import { onMounted, useTemplateRef } from "vue";
import type { CurrentUser } from "../authTypes";

defineProps<{ user: CurrentUser; busy: boolean }>();
defineEmits<{ logout: [] }>();
const logoutButton = useTemplateRef<HTMLButtonElement>("logoutButton");
onMounted(() => { logoutButton.value?.focus(); });
</script>

<template>
  <div id="signed-in" class="signed-in">
    <span class="account-avatar" aria-hidden="true">✓</span>
    <div>
      <p class="field-hint">Вы вошли как</p>
      <p id="account-email" class="account-email">{{ user.email || "Личный аккаунт" }}</p>
    </div>
    <button id="auth-logout" ref="logoutButton" type="button" :disabled="busy" @click="$emit('logout')">{{ busy ? "Выходим…" : "Выйти" }}</button>
  </div>
</template>
