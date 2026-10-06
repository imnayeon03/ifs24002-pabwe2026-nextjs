import { createSlice, isAnyOf } from "@reduxjs/toolkit";
import type { User } from "@/types";
import {
  asyncChangeProfile,
  asyncChangeProfilePassword,
  asyncChangeProfilePhoto,
  asyncGetProfile,
  asyncGetUsers,
} from "./action";

interface UsersState {
  users: User[];
  profile: User | null;
  isUsers: boolean;
  isProfile: boolean;
  isChangeProfile: boolean;
  isChangeProfilePhoto: boolean;
  isChangeProfilePassword: boolean;
}

const initialState: UsersState = {
  users: [],
  profile: null,
  isUsers: false,
  isProfile: false,
  isChangeProfile: false,
  isChangeProfilePhoto: false,
  isChangeProfilePassword: false,
};

const usersSlice = createSlice({
  name: "users",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(asyncGetUsers.pending, (state) => {
        state.isUsers = true;
      })
      .addCase(asyncGetUsers.fulfilled, (state, action) => {
        state.users = action.payload;
        state.isUsers = false;
      })
      .addCase(asyncGetUsers.rejected, (state) => {
        state.isUsers = false;
      })
      .addCase(asyncGetProfile.pending, (state) => {
        state.isProfile = true;
      })
      .addCase(asyncGetProfile.fulfilled, (state, action) => {
        if (action.payload) state.profile = action.payload;
        state.isProfile = false;
      })
      .addCase(asyncGetProfile.rejected, (state) => {
        state.isProfile = false;
      })
      .addCase(asyncChangeProfile.pending, (state) => {
        state.isChangeProfile = true;
      })
      .addCase(asyncChangeProfilePhoto.pending, (state) => {
        state.isChangeProfilePhoto = true;
      })
      .addCase(asyncChangeProfilePassword.pending, (state) => {
        state.isChangeProfilePassword = true;
      })
      .addMatcher(isAnyOf(asyncChangeProfile.fulfilled, asyncChangeProfile.rejected), (state) => {
        state.isChangeProfile = false;
      })
      .addMatcher(isAnyOf(asyncChangeProfilePhoto.fulfilled, asyncChangeProfilePhoto.rejected), (state) => {
        state.isChangeProfilePhoto = false;
      })
      .addMatcher(
        isAnyOf(asyncChangeProfilePassword.fulfilled, asyncChangeProfilePassword.rejected),
        (state) => {
          state.isChangeProfilePassword = false;
        },
      );
  },
});

export default usersSlice.reducer;