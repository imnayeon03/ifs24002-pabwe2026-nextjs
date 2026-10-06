import { resolveMediaUrl } from "@/helpers/toolsHelper";

interface AvatarProps {
  name: string;
  photo?: string | null;
  size?: number;
}

export default function Avatar({ name, photo, size = 44 }: AvatarProps) {
  const url = resolveMediaUrl(photo);
  const initial = name.trim().charAt(0).toUpperCase() || "?";

  if (url) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={url}
        alt={`Foto ${name}`}
        width={size}
        height={size}
        className="rounded-full bg-stone-200 object-cover"
        style={{ width: size, height: size }}
      />
    );
  }

  return (
    <span
      aria-hidden="true"
      className="grid place-items-center rounded-full bg-indigo-950 font-extrabold text-amber-300"
      style={{ width: size, height: size }}
    >
      {initial}
    </span>
  );
}