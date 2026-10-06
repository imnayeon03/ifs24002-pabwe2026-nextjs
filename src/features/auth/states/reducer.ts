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