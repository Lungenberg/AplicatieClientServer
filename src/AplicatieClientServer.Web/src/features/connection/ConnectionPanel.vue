<script setup lang="ts">
import { useConnection } from "./useConnection";

const emit = defineEmits<{ retry: [] }>();
const { status, health, checkedAt, title, description, check } = useConnection();
function retry() { void check(); emit("retry"); }
</script>

<template>
  <section id="connection" class="connection-panel" aria-labelledby="connection-title">
    <div class="connection-heading">
      <div>
        <p class="eyebrow">Соединение</p>
        <h2 id="connection-title">Связь с сервером</h2>
      </div>
      <button id="check-connection" type="button" :disabled="status === 'loading'" @click="retry">{{ status === "loading" ? "Проверяем…" : "Повторить проверку" }}</button>
    </div>
    <div id="connection-status" class="connection-status" :data-state="status" role="status" aria-live="polite" aria-atomic="true">
      <span class="status-dot" aria-hidden="true"></span>
      <div>
        <h3 id="status-title">{{ title }}</h3>
        <p id="status-description">{{ description }}</p>
      </div>
    </div>
    <dl class="connection-details">
      <div><dt>Сервис</dt><dd id="service-name">{{ health?.service ?? "—" }}</dd></div>
      <div><dt>Версия API</dt><dd id="service-version">{{ health?.version ?? "—" }}</dd></div>
      <div><dt>Последняя проверка</dt><dd id="checked-at">{{ checkedAt }}</dd></div>
    </dl>
    <p class="connection-footnote">Проверка подтверждает доступность API. Готовность файлового хранилища проверяется отдельно.</p>
  </section>
</template>
