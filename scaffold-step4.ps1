if (-not (Test-Path ".\package.json")) {
  Write-Host "Jalankan script ini dari root proyek (folder yang berisi package.json)." -ForegroundColor Red
  exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding $false

function Write-SourceFile($relativePath, $content) {
  $fullPath = Join-Path (Get-Location) $relativePath
  $dir = Split-Path $fullPath -Parent
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  [System.IO.File]::WriteAllText($fullPath, $content.Replace("`r`n", "`n"), $utf8)
  Write-Host "Dibuat: $relativePath" -ForegroundColor Green
}

Write-SourceFile "src\features\auth\api\authApi.ts" @'
import { apiFetch } from "@/helpers/apiHelper";
import type { LoginPayload, RegisterPayload } from "@/types/action";
import type { User } from "@/types";

export const login = (payload: LoginPayload) =>
  apiFetch<{ user: User; token: string }>("/auth/login", {
    method: "POST",
    body: payload,
    auth: false,
  });

export const register = (payload: RegisterPayload) =>
  apiFetch("/auth/register", { method: "POST", body: payload, auth: false });

export const logout = () => apiFetch("/auth/logout", { method: "POST" });
'@

Write-SourceFile "src\features\auth\states\action.ts" @'
import { createAsyncThunk } from "@reduxjs/toolkit";
import { putAccessToken, removeAccessToken } from "@/helpers/apiHelper";
import { showErrorDialog, showSuccessDialog } from "@/helpers/toolsHelper";
import type { LoginPayload, RegisterPayload } from "@/types/action";
import * as authApi from "../api/authApi";

export const asyncLogin = createAsyncThunk("auth/login", async (payload: LoginPayload) => {
  const result = await authApi.login(payload);
  if (result.status !== "success" || !result.data) {
    void showErrorDialog(result.message);
    return false;
  }
  putAccessToken(result.data.token);
  return true;
});

export const asyncRegister = createAsyncThunk("auth/register", async (payload: RegisterPayload) => {
  const result = await authApi.register(payload);
  if (result.status !== "success") {
    void showErrorDialog(result.message);
    return false;
  }
  void showSuccessDialog(result.message);
  return true;
});

export const asyncLogout = createAsyncThunk("auth/logout", async () => {
  await authApi.logout();
  removeAccessToken();
  return true;
});
'@

Write-SourceFile "src\features\auth\states\reducer.ts" @'
import { createSlice, isAnyOf } from "@reduxjs/toolkit";
import { asyncLogin, asyncLogout, asyncRegister } from "./action";

const initialState = {
  isAuthLogin: false,
  isAuthRegister: false,
  isAuthLogout: false,
};

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(asyncLogin.pending, (state) => {
        state.isAuthLogin = true;
      })
      .addCase(asyncRegister.pending, (state) => {
        state.isAuthRegister = true;
      })
      .addCase(asyncLogout.pending, (state) => {
        state.isAuthLogout = true;
      })
      .addMatcher(isAnyOf(asyncLogin.fulfilled, asyncLogin.rejected), (state) => {
        state.isAuthLogin = false;
      })
      .addMatcher(isAnyOf(asyncRegister.fulfilled, asyncRegister.rejected), (state) => {
        state.isAuthRegister = false;
      })
      .addMatcher(isAnyOf(asyncLogout.fulfilled, asyncLogout.rejected), (state) => {
        state.isAuthLogout = false;
      });
  },
});

export default authSlice.reducer;
'@

Write-SourceFile "src\store.ts" @'
import { configureStore } from "@reduxjs/toolkit";
import authReducer from "@/features/auth/states/reducer";

const store = configureStore({
  reducer: {
    auth: authReducer,
  },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export default store;
'@

Write-SourceFile "src\components\Providers.tsx" @'
"use client";

import type { ReactNode } from "react";
import { Provider } from "react-redux";
import store from "@/store";

export default function Providers({ children }: { children: ReactNode }) {
  return <Provider store={store}>{children}</Provider>;
}
'@

Write-Host ""
Write-Host "Langkah 4 selesai." -ForegroundColor Cyan