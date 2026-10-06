import { createAsyncThunk } from "@reduxjs/toolkit";
import { showErrorDialog, showSuccessDialog } from "@/helpers/toolsHelper";
import type { ChangePasswordPayload, ProfilePayload } from "@/types/action";
import type { User } from "@/types";
import * as userApi from "../api/userApi";

export const asyncGetUsers = createAsyncThunk("users/getUsers", async (): Promise<User[]> => {
  const result = await userApi.getUsers();
  if (result.status !== "success" || !result.data) {
    void showErrorDialog(result.message);
    return [];
  }
  return result.data.users;
});

export const asyncGetProfile = createAsyncThunk("users/getProfile", async (): Promise<User | null> => {
  const result = await userApi.getProfile();
  if (result.status !== "success" || !result.data) return null;
  return result.data.user;
});

export const asyncChangeProfile = createAsyncThunk(
  "users/changeProfile",
  async (payload: ProfilePayload, { dispatch }) => {
    const result = await userApi.changeProfile(payload);
    if (result.status !== "success") {
      void showErrorDialog(result.message);
      return false;
    }
    void showSuccessDialog(result.message);
    await dispatch(asyncGetProfile());
    return true;
  },
);

export const asyncChangeProfilePhoto = createAsyncThunk(
  "users/changeProfilePhoto",
  async (photo: File, { dispatch }) => {
    const result = await userApi.changeProfilePhoto(photo);
    if (result.status !== "success") {
      void showErrorDialog(result.message);
      return false;
    }
    void showSuccessDialog(result.message);
    await dispatch(asyncGetProfile());
    return true;
  },
);

export const asyncChangeProfilePassword = createAsyncThunk(
  "users/changeProfilePassword",
  async (payload: ChangePasswordPayload) => {
    const result = await userApi.changePassword(payload);
    if (result.status !== "success") {
      void showErrorDialog(result.message);
      return false;
    }
    void showSuccessDialog(result.message);
    return true;
  },
);