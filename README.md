# AplicatieClientServer

Клиент-серверное веб-приложение для хранения и управления файлами.

Целевой стек: ASP.NET Core на .NET 10, PostgreSQL и EF Core, HTML/CSS/JavaScript с Vite, HTTP и WebSocket через SignalR.

## Текущее состояние

Реализован минимальный API с маршрутом `GET /health`, который возвращает состояние процесса, имя сервиса и версию приложения.

## Запуск

Требуется .NET 10 SDK.

```powershell
Set-Location 'D:\AplicatieClientServer'
dotnet build AplicatieClientServer.slnx
dotnet run --project src/AplicatieClientServer.Api
```

Проверка из другого терминала:

```powershell
Invoke-RestMethod 'http://localhost:5050/health'
```

Ожидаемый ответ:

```json
{
  "status": "ok",
  "service": "AplicatieClientServer.Api",
  "version": "0.1.0"
}
```

Адрес можно открыть в браузере. Корневой маршрут `/` пока возвращает HTTP 404. Остановка API — `Ctrl+C` в терминале сервера.

Если порт 5050 занят:

```powershell
dotnet run --project src/AplicatieClientServer.Api --no-launch-profile -- --urls http://localhost:5051
```

## Структура

```text
AplicatieClientServer.slnx      Solution
global.json                    Настройка версии .NET SDK
src/AplicatieClientServer.Api/  ASP.NET Core API
```
