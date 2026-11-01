<script setup lang="ts">
defineProps<{ sessionLabel: string }>();
</script>

<template>
  <a class="skip-link" href="#main">К содержимому</a>
  <div class="app-shell">
    <aside class="sidebar" aria-label="Панель приложения">
      <a class="brand" href="/" aria-label="ACS Drive — главная">
        <span class="brand-mark" aria-hidden="true">
          <svg viewBox="0 0 32 32" fill="none"><path d="M7 23h18a5 5 0 0 0 0-10h-1a8 8 0 0 0-15-1 5.5 5.5 0 0 0-2 11Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></svg>
        </span>
        <span>ACS<span class="brand-light"> Drive</span></span>
      </a>
      <p class="sidebar-label">Личное пространство</p>
      <nav aria-label="Основная навигация">
        <a class="nav-link active" href="#main" aria-current="page">
          <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M3 7a2 2 0 0 1 2-2h5l2 2h7a2 2 0 0 1 2 2v10H3V7Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/></svg>
          Мои файлы
        </a>
        <a class="nav-link" href="#account">
          <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="1.7"/><path d="M4 21v-2a8 8 0 0 1 16 0v2" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/></svg>
          Аккаунт
        </a>
        <a class="nav-link" href="#connection">
          <svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M5 15a10 10 0 0 1 14 0M8 18a6 6 0 0 1 8 0M2 11a15 15 0 0 1 20 0" stroke="currentColor" stroke-width="1.7" stroke-linecap="round"/><circle cx="12" cy="21" r="1" fill="currentColor"/></svg>
          Подключение
        </a>
      </nav>
      <div class="sidebar-note">
        <span class="note-line" aria-hidden="true"></span>
        <p>Всё важное.<br />В одном пространстве.</p>
      </div>
    </aside>

    <main id="main" class="workspace" tabindex="-1">
      <header class="page-header">
        <div>
          <p class="eyebrow">Ваше пространство</p>
          <h1>Мои файлы</h1>
          <p class="page-description">Личное место для документов, идей и всего важного.</p>
        </div>
        <span id="session-label" class="prototype-label">{{ sessionLabel }}</span>
      </header>
      <slot />
      <footer class="page-footer"><span>ACS Drive</span><span>Пространство для ваших файлов</span></footer>
    </main>
  </div>
</template>
