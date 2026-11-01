<script setup lang="ts">
defineProps<{ id?: string; message: string; kind: "success" | "error" }>();
</script>

<template>
  <p :id="id" class="auth-feedback" :data-kind="kind" role="status" aria-live="polite" aria-atomic="true">{{ message }}</p>
</template>
