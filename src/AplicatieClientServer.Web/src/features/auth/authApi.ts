import { ApiError, isRecord, postJson, requestJson } from "../../shared/api/http";
import type { Credentials, CurrentUser } from "./authTypes";

const identityMessages: Record<string, string> = {
  DuplicateEmail: "Аккаунт с таким email уже существует.",
  DuplicateUserName: "Аккаунт с таким email уже существует.",
  InvalidEmail: "Укажите корректный email.",
  InvalidUserName: "Проверьте написание email.",
  PasswordTooShort: "Пароль должен содержать не менее 8 символов.",
  PasswordRequiresLower: "Добавьте в пароль строчную букву.",
  PasswordRequiresUpper: "Добавьте в пароль прописную букву.",
  PasswordRequiresDigit: "Добавьте в пароль цифру.",
  PasswordRequiresNonAlphanumeric: "Добавьте в пароль специальный символ.",
  PasswordRequiresUniqueChars: "Используйте разные символы в пароле.",
};

function authErrorMessage(error: ApiError): string {
  const payload = isRecord(error.payload) ? error.payload : {};
  if (payload.code === "csrf_validation_failed") return "Состояние входа изменилось. Повторите действие.";
  if (error.status === 401) return "Неверный email или пароль. Проверьте данные и повторите вход.";
  if (error.status === 403) return "Действие недоступно для этого аккаунта.";
  if (error.status === 429) return "Слишком много попыток. Подождите и попробуйте снова.";
  if (error.status === 400) {
    const messages = Object.keys(isRecord(payload.errors) ? payload.errors : {})
      .map((key) => identityMessages[key]).filter((message) => message !== undefined);
    return [...new Set(messages)].join("\n") || "Проверьте введённые данные и повторите действие.";
  }
  return "Сервис аккаунтов временно недоступен. Попробуйте ещё раз позже.";
}

async function authRequest(path: string, body?: unknown): Promise<unknown> {
  try {
    return await (body === undefined ? requestJson(`/auth${path}`) : postJson(`/auth${path}`, body));
  } catch (error: unknown) {
    if (error instanceof ApiError && error.status !== 0) {
      throw new ApiError(authErrorMessage(error), error.status, error.payload);
    }
    throw error;
  }
}

export async function getCurrentUser(): Promise<CurrentUser | null> {
  try {
    const user = await authRequest("/me");
    if (!isRecord(user) || typeof user.id !== "string" || !user.id ||
        (user.email !== null && typeof user.email !== "string")) {
      throw new ApiError("Ответ сервера не содержит данные аккаунта. Повторите проверку.");
    }
    return { id: user.id, email: user.email };
  } catch (error: unknown) {
    if (error instanceof ApiError && error.status === 401) return null;
    throw error;
  }
}

export async function registerAccount(credentials: Credentials): Promise<void> {
  await authRequest("/register", credentials);
}

export async function login(credentials: Credentials): Promise<void> {
  await authRequest("/login?useSessionCookies=true", credentials);
}

export async function logout(): Promise<void> {
  await authRequest("/logout", {});
}
