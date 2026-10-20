import "./style.css";
import { getHealth } from "./api.js";

const checkButton = document.querySelector("#check-connection");
const status = document.querySelector("#connection-status");
const title = document.querySelector("#status-title");
const description = document.querySelector("#status-description");
const serviceName = document.querySelector("#service-name");
const serviceVersion = document.querySelector("#service-version");
const checkedAt = document.querySelector("#checked-at");
const timeFormat = new Intl.DateTimeFormat("ru-RU", { timeStyle: "medium" });

async function checkConnection() {
  checkButton.disabled = true;
  checkButton.textContent = "Проверяем…";
  status.dataset.state = "loading";
  title.textContent = "Проверяем подключение";
  description.textContent = "Ожидаем ответ сервера.";
  serviceName.textContent = "—";
  serviceVersion.textContent = "—";
  checkedAt.textContent = "—";

  try {
    const health = await getHealth();
    status.dataset.state = "success";
    title.textContent = "Сервер доступен";
    description.textContent = "Соединение установлено. API отвечает на запросы.";
    serviceName.textContent = health.service;
    serviceVersion.textContent = health.version;
  } catch (error) {
    status.dataset.state = "error";
    title.textContent = "Не удалось подключиться";
    description.textContent = error.message;
  } finally {
    checkedAt.textContent = timeFormat.format(new Date());
    checkButton.disabled = false;
    checkButton.textContent = "Повторить проверку";
  }
}

checkButton.addEventListener("click", checkConnection);
checkConnection();
