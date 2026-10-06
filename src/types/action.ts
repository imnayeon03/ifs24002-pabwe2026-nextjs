export interface LoginPayload {
  email: string;
  password: string;
}

export interface RegisterPayload extends LoginPayload {
  name: string;
}

export interface ProfilePayload {
  name: string;
  email: string;
}

export interface ChangePasswordPayload {
  password: string;
  new_password: string;
  new_password_confirmation: string;
}

export interface ChangePostPayload {
  postId: number;
  description: string;
}

export interface ChangeCoverPayload {
  postId: number;
  cover: File;
}

export interface LikePayload {
  postId: number;
  like: 0 | 1;
}

export interface AddCommentPayload {
  postId: number;
  comment: string;
}