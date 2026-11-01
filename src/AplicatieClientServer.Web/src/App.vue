<script setup lang="ts">
import AppLayout from "./layouts/AppLayout.vue";
import ConnectionPanel from "./features/connection/ConnectionPanel.vue";
</script>

<template>
  <AppLayout session-label="Прототип">
  <section class="files-panel" aria-labelledby="files-title">
    <div class="panel-heading">
      <h2 id="files-title">Файловое пространство</h2>
      <span class="muted-label">Подготовка</span>
    </div>
    <div class="empty-state">
      <div class="folder-art" aria-hidden="true">
        <svg viewBox="0 0 120 100" fill="none"><path d="M17 27a7 7 0 0 1 7-7h24l11 11h37a7 7 0 0 1 7 7v45H17V27Z" fill="#c8d9ce"/><path d="M11 44a6 6 0 0 1 6-6h86a6 6 0 0 1 6 7l-7 34a7 7 0 0 1-7 6H24a7 7 0 0 1-7-6l-6-34Z" fill="#e3ebe2" stroke="#6f8b76" stroke-width="1.5"/><path d="M47 61h26M60 48v26" stroke="#50735b" stroke-width="2" stroke-linecap="round"/></svg>
      </div>
      <h3>Начинаем с подключения</h3>
      <p>Сейчас доступна проверка связи с сервером.<br class="desktop-break" /> Хранение и управление файлами появятся следующим шагом.</p>
      <a class="text-link" href="#connection">Проверить соединение <span aria-hidden="true">↗</span></a>
    </div>
  </section>
    <ConnectionPanel />
  </AppLayout>
</template>
