if (-not (Test-Path ".\package.json")) {
  Write-Host "Jalankan dari root proyek (folder yang berisi package.json)." -ForegroundColor Red
  exit 1
}

$utf8 = New-Object System.Text.UTF8Encoding $false
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = ".\backup-lama\src-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null

# Simpan favicon
if (Test-Path ".\src\app\favicon.ico") {
  Copy-Item ".\src\app\favicon.ico" ".\favicon.tmp.ico"
}

# Pindahkan seluruh isi src lama ke backup
Get-ChildItem ".\src" -Force | ForEach-Object {
  Move-Item $_.FullName $backup
}
Write-Host "Isi src lama dipindah ke $backup" -ForegroundColor Yellow

# Kembalikan favicon
New-Item -ItemType Directory -Force -Path ".\src\app" | Out-Null
if (Test-Path ".\favicon.tmp.ico") {
  Move-Item ".\favicon.tmp.ico" ".\src\app\favicon.ico"
}

# Amankan file konfigurasi dari kumpulan kode lain
if (Test-Path ".\tsconfig.json") { Copy-Item ".\tsconfig.json" ".\backup-lama\tsconfig.json.lama" -Force }
if (Test-Path ".\vitest.config.mts") { Move-Item ".\vitest.config.mts" ".\backup-lama\vitest.config.mts.lama" -Force }

# Hapus cache build (dibuat ulang otomatis oleh Next)
if (Test-Path ".\.next") { Remove-Item ".\.next" -Recurse -Force }

# tsconfig bersih, backup-lama diabaikan
$tsconfig = @'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "react-jsx",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", "**/*.mts", ".next/types/**/*.ts", ".next/dev/types/**/*.ts"],
  "exclude": ["node_modules", "backup-lama"]
}
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location) "tsconfig.json"), $tsconfig, $utf8)
Write-Host "Dibuat: tsconfig.json (backup-lama diabaikan)" -ForegroundColor Green

# Jangan ikut di-commit
if (Test-Path ".gitignore") {
  $gi = Get-Content ".gitignore" -Raw
  if ($gi -notmatch "backup-lama") { Add-Content ".gitignore" "`nbackup-lama/" }
}

Write-Host ""
Write-Host "Reset selesai. Lanjut jalankan setup.ps1." -ForegroundColor Cyan