# AplicatieClientServer

Клиент-серверное веб-приложение для хранения и управления файлами. Веб-клиент отображается как ACS Drive.

Целевой стек: ASP.NET Core на .NET 10, PostgreSQL и EF Core, Vue 3 и TypeScript с Vite, HTTP и WebSocket через SignalR.

## Текущее состояние

Подготовлены отдельные компоненты:

- ASP.NET Core API: проверка процесса `/health`, проверка подключения к PostgreSQL `/health/db`, регистрация, вход через cookie, текущий пользователь и выход через ASP.NET Core Identity.
- Веб-клиент на Vue 3 и TypeScript: регистрация с подтверждением пароля, вход, отображение аккаунта, выход, восстановление состояния по cookie и проверка связи с API.
- PostgreSQL: отдельное локальное окружение с постоянным томом и проверкой сохранности данных.

PostgreSQL запускается отдельно через Docker Compose и хранит данные в постоянном томе. EF Core содержит модель файлового дерева и таблицы Identity. Работа с файлами и WebSocket ещё предстоят. Успешный `/health` подтверждает доступность процесса; `/health/db` проверяет соединение, но не полноту схемы.

## Требования

- .NET 10 SDK.
- Node.js 22.12+ (проверено с 24.21.0) и npm.
- Docker Desktop с Linux-контейнерами и Docker Compose для PostgreSQL.

## Запуск API

При первом запуске подготовьте PostgreSQL по инструкции ниже и задайте `ConnectionStrings:DefaultConnection` через User Secrets проекта API. Строка должна указывать на локальную БД; пароль берётся из локального `.env`. ASP.NET Core не загружает этот файл автоматически. User Secrets не входят в исходный код.

Пример команды с заполнителем вместо пароля:

```powershell
dotnet user-secrets set 'ConnectionStrings:DefaultConnection' 'Host=127.0.0.1;Port=55432;Database=acs_drive;Username=acs_dev;Password=<пароль из локального .env>' --project src/AplicatieClientServer.Api
```

После настройки подключения примените миграции из корня проекта:

```powershell
dotnet tool restore
dotnet ef database update --project src/AplicatieClientServer.Api --startup-project src/AplicatieClientServer.Api --context AppDbContext -- --environment Development
```

Запуск API в первом терминале:

```powershell
Set-Location 'D:\AplicatieClientServer'
dotnet build AplicatieClientServer.slnx
dotnet run --project src/AplicatieClientServer.Api
```

API: <http://localhost:5050/health>. Ожидаемый ответ:

```json
{
  "status": "ok",
  "service": "AplicatieClientServer.Api",
  "version": "0.1.0"
}
```

Корневой маршрут API `/` возвращает HTTP 404. Интерфейс приложения открывается по адресу веб-клиента.

## Swagger UI

После запуска API в Development откройте [Swagger UI](http://localhost:5050/swagger). JSON-описание API доступно по адресу [OpenAPI v1](http://localhost:5050/openapi/v1.json). В Production оба инструмента отключены.

Используется встроенная генерация OpenAPI ASP.NET Core 10 и Swashbuckle Swagger UI. Кнопка `Execute` доступна после раскрытия операции: режим Try it out уже включён.

Swagger автоматически получает свежий CSRF-токен перед POST-запросами `/auth/*` и добавляет `X-CSRF-TOKEN`. Вручную заполнять этот заголовок в Swagger не требуется.

Проверка аккаунта через Swagger:

1. Раскройте `POST /auth/register`, замените тело своим учебным email и паролем по требованиям ниже, нажмите `Execute`. Успех — 200; аккаунт сохраняется в локальной БД.
2. В `POST /auth/login` установите query-параметр `useSessionCookies` в `true`, в теле передайте те же email/password. Успех — 200. Браузер сохранит HttpOnly-cookie и будет отправлять её автоматически на том же адресе.
3. Выполните `GET /auth/me`: ожидаются 200, ваш id и email.
4. В `POST /auth/logout` замените предложенное Swagger тело на пустой JSON-объект `{}` и выполните запрос: ожидается 204.
5. Повторите `GET /auth/me`: ожидается 401.

Пример тела регистрации и входа (для нового аккаунта выберите ещё не занятый email):

```json
{
  "email": "swagger.student@example.test",
  "password": "DriveDemo!2026"
}
```

Swagger UI следует открывать на адресе API. Cookie PowerShell-проверки и cookie браузера хранятся в разных клиентах. Дополнительные маршруты Identity также видны в списке; проверяемый основной цикл описан выше.

## Аккаунты и вход

API использует ASP.NET Core Identity с ключом `Guid` и cookie `AcsDrive.Auth`. Для локального прототипа подтверждение email не требуется. Пароль должен содержать не менее 8 символов, строчную и прописную буквы, цифру и специальный символ.

| Метод и путь | Тело JSON | Результат |
| --- | --- | --- |
| `POST /auth/register` | `email`, `password` | 200; неверные данные и дубликат — 400; автоматического входа нет |
| `POST /auth/login?useSessionCookies=true` | `email`, `password` | 200 и session cookie; неверные данные — 401 |
| `GET /auth/me` | Нет | 200 с `id` и `email`; без cookie — 401 |
| `POST /auth/logout` | `{}` | 204; без cookie — 401 |
| `GET /auth/csrf` | Нет | 200 с `requestToken` и antiforgery-cookie |

Все POST используют `Content-Type: application/json`. `/auth/me` и `/auth/logout` требуют application-cookie; встроенный Identity bearer-токен её не заменяет. Вход с `useSessionCookies=true` выбирает cookie-режим. Cookie — HttpOnly и SameSite=Lax; вне Development требует HTTPS. Срок ticket — 8 часов со скользящим продлением.

Все POST `/auth/*` проверяют пару antiforgery-cookie и заголовка `X-CSRF-TOKEN`. Получите токен через `GET /auth/csrf` в той же cookie-сессии; после изменения аккаунта нужен новый request token. Отсутствующий или неверный токен даёт 400 с кодом `csrf_validation_failed`. Веб-клиент, Swagger и проверочный скрипт выполняют этот обмен автоматически. Ответы аккаунтов не кешируются.

Повторяемая HTTP-проверка на запущенном локальном API:

```powershell
.\scripts\Test-Authentication.ps1
```

Скрипт создаёт один аккаунт со случайным email в выбранной БД, проверяет регистрацию, вход, DTO, CSRF, ошибки и выход. Можно указать другой локальный адрес через `-BaseUri`. Параметры `-ExistingAccount -Email <email> -ExpectedUserId <guid>` позволяют проверить тот же учебный аккаунт после перезапуска API. В текущем наборе 47 HTTP-проверок для нового аккаунта и 34 для существующего, включая получение CSRF-токенов.

## Запуск веб-клиента

Во втором терминале:

```powershell
Set-Location 'D:\AplicatieClientServer\src\AplicatieClientServer.Web'
npm ci
npm run dev
```

Веб-клиент: <http://localhost:5173/>. Команда `npm ci` нужна при первой установке или изменении файла зависимостей. Остановка каждого компонента — `Ctrl+C` в его терминале.

В блоке «Ваш аккаунт» выберите регистрацию, заполните email, пароль и его подтверждение. После создания аккаунта форма переключится на вход. Успешный вход показывает email и кнопку «Выйти». Обновление страницы восстанавливает состояние через `/auth/me`. Пароли и токены входа не записываются в localStorage или sessionStorage; auth-cookie недоступна JavaScript. Вкладки одного origin синхронизируют состояние через уведомление BroadcastChannel и повторный запрос к серверу; также выполняется проверка при возврате к странице.

Клиент запускается и при выключенном API: страница остаётся доступной и показывает ошибку проверки. После запуска API нажмите «Повторить проверку».

## PostgreSQL

Из корня проекта:

```powershell
Set-Location 'D:\AplicatieClientServer'
.\scripts\Initialize-LocalEnvironment.ps1
docker compose up -d --wait postgres
docker compose ps
```

Скрипт создаёт корневой `.env` со случайным паролем и не перезаписывает существующий файл. `.env` исключён из Git. `.env.example` содержит только названия настроек; пароль в нём пустой.

Локальное подключение при настройках по умолчанию:

| Параметр | Значение |
| --- | --- |
| Host | `127.0.0.1` |
| Port | `55432` |
| Database | `acs_drive` |
| User | `acs_dev` |
| Password | `POSTGRES_PASSWORD` из корневого `.env` |

Официальный образ — `postgres:18.6-bookworm`; данные хранятся в именованном томе `acs-drive_postgres-data`, подключённом к `/var/lib/postgresql`. Порт опубликован только на loopback. Формат каталога соответствует [официальному образу PostgreSQL 18](https://hub.docker.com/_/postgres).

Проверка SQL, отката транзакции и сохранности данных при замене контейнера:

```powershell
.\scripts\Test-Database.ps1 -RecreateContainer
```

Проверка использует отдельную временную БД, сохраняет запись, пересоздаёт только контейнер `postgres` проекта и читает запись из прежнего тома. В конце временная БД удаляется. Без `-RecreateContainer` выполняются проверки подключения, записи и отката без пересоздания контейнера.

Для SQL-консоли с настройками по умолчанию:

```powershell
docker compose exec postgres psql -U acs_dev -d acs_drive
```

```sql
SELECT current_database(), current_user;
```

Выход из psql — `\q`. Остановка БД — `docker compose stop postgres`; повторный запуск — `docker compose up -d --wait postgres`. Том сохраняется.

Если `55432` занят, измените `POSTGRES_PORT` в корневом `.env` и повторите запуск. Параметры создания БД и пароль применяются при первой инициализации пустого тома; изменение `POSTGRES_PASSWORD` в `.env` само по себе не меняет пароль уже созданной БД.

Корневой `.env` предназначен для Compose; ASP.NET Core автоматически его не читает. API получает `ConnectionStrings:DefaultConnection` через стандартные настройки .NET; в Development используются User Secrets.

## Адрес API

По умолчанию Vite пересылает запросы `/api/*` в `http://localhost:5050`, убирая префикс `/api`:

```text
Браузер → http://localhost:5173/api/health
Vite    → http://localhost:5050/health
```

Это локальный прокси, позволяющий браузеру обращаться к своему адресу без дополнительной настройки CORS на API. При выключенном API прокси может вернуть HTTP 502; такой ответ создаёт Vite.

Если API использует другой порт, создайте локальный файл конфигурации:

```powershell
Set-Location 'D:\AplicatieClientServer\src\AplicatieClientServer.Web'
Copy-Item '.env.example' '.env'
```

Укажите в `.env`, например, `API_PROXY_TARGET=http://localhost:5051`, затем перезапустите веб-клиент. API на этом порту запускается командой:

```powershell
Set-Location 'D:\AplicatieClientServer'
dotnet run --project src/AplicatieClientServer.Api --no-launch-profile -- --urls http://localhost:5051
```

Порт клиента фиксирован: если 5173 занят, Vite завершится с сообщением об ошибке.

## Сборка клиента

```powershell
Set-Location 'D:\AplicatieClientServer\src\AplicatieClientServer.Web'
npm run typecheck
npm run build
npm run preview
```

`typecheck` проверяет TypeScript и Vue-шаблоны. `build` также запускает эту проверку перед сборкой. Версии инструментов зафиксированы в package-lock.json; используется TypeScript 6.0.3, совместимый с текущим vue-tsc.

Собранные файлы находятся в `dist/`; локальная проверка сборки доступна на <http://localhost:4173/> и использует тот же прокси к API. `preview` предназначен для локальной проверки. При развёртывании статических файлов веб-серверу потребуется отдельное правило пересылки `/api/*` к API.

Компоненты используют Composition API и `<script setup lang="ts">`. Модули `features/auth` и `features/connection` содержат API-функции, состояние и интерфейс своих сценариев. Общий HTTP-клиент находится в `src/shared/api/http.ts`; состояние аккаунта создаётся один раз в App.vue. Глобальные стили — в `src/styles/main.css`.

## Структура

```text
AplicatieClientServer.slnx      Solution для .NET
global.json                    Настройка версии .NET SDK
compose.yaml                   Локальный PostgreSQL
.env.example                   Шаблон локальных настроек БД
scripts/                       Инициализация окружения и проверка БД
src/AplicatieClientServer.Api/  ASP.NET Core API
src/AplicatieClientServer.Web/  Vue 3 / TypeScript-клиент с Vite
```
