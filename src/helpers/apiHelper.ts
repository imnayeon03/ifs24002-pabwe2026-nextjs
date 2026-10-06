import { DELCOM_BASEURL } from "@/lib/config";
import type { ApiResult } from "@/types";

const TOKEN_KEY = "token";

export const getAccessToken = (): string | null =>
  typeof window === "undefined" ? null : localStorage.getItem(TOKEN_KEY);

export const putAccessToken = (token: string): void => localStorage.setItem(TOKEN_KEY, token);

export const removeAccessToken = (): void => localStorage.removeItem(TOKEN_KEY);

type Query = Record<string, string | number | undefined>;

interface RequestOptions {
  method?: "GET" | "POST" | "PUT" | "DELETE";
  query?: Query;
  body?: unknown;
  auth?: boolean;
}

export async function apiFetch<T = unknown>(
  path: string,
  { method = "GET", query, body, auth = true }: RequestOptions = {},
): Promise<ApiResult<T>> {
  const url = new URL(`${DELCOM_BASEURL}${path}`);
  Object.entries(query ?? {}).forEach(([key, value]) => {
    if (value !== undefined) url.searchParams.set(key, String(value));
  });

  const headers: Record<string, string> = { Accept: "application/json" };
  const token = getAccessToken();
  if (auth && token) headers.Authorization = `Bearer ${token}`;

  let payload: BodyInit | undefined;
  if (body instanceof FormData) {
    payload = body;
  } else if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    payload = JSON.stringify(body);
  }

  try {
    const response = await fetch(url, { method, headers, body: payload });
    return (await response.json()) as ApiResult<T>;
  } catch {
    return { status: "fail", message: "Tidak dapat terhubung ke server" };
  }
}