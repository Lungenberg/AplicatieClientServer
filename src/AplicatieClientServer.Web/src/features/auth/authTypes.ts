export interface CurrentUser {
  id: string;
  email: string | null;
}

export interface Credentials {
  email: string;
  password: string;
}

export type AuthMode = "login" | "register";

export type AuthState =
  | { status: "loading" | "anonymous" | "unavailable"; user: null }
  | { status: "authenticated"; user: CurrentUser };

export interface AuthFeedback {
  message: string;
  kind: "success" | "error";
}
