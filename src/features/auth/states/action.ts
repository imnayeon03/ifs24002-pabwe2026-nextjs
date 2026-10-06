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