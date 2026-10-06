import { useState, type ChangeEvent } from "react";

export default function useInput(initialValue = "") {
  const [value, setValue] = useState(initialValue);

  const onChange = (
    event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>,
  ) => setValue(event.target.value);

  return { value, onChange, setValue };
}