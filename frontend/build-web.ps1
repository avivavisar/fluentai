# Builds the Flutter web bundle WITH the Supabase defines baked in.
# Reads SUPABASE_URL / SUPABASE_ANON_KEY from ../backend-nest/.env so they are never
# forgotten (a plain `flutter build web` drops them and breaks login).
# API_BASE_URL stays empty on purpose -> the app uses same-origin (static server proxies /v1).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $root '..\backend-nest\.env'
$vals = @{}
foreach ($line in Get-Content $envFile) {
  if ($line -match '^\s*([A-Z0-9_]+)=(.*)$') {
    $vals[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
  }
}
$supaUrl = $vals['SUPABASE_URL']
$anon    = $vals['SUPABASE_ANON_KEY']
if (-not $supaUrl -or -not $anon) { throw "SUPABASE_URL / SUPABASE_ANON_KEY missing from $envFile" }
Write-Host "Building web with SUPABASE_URL=$supaUrl and anon key (len $($anon.Length))..."
$flutter = 'C:\Users\Aviv Avisar\tools\flutter\bin\flutter.bat'
& $flutter build web --release `
  --dart-define="SUPABASE_URL=$supaUrl" `
  --dart-define="SUPABASE_ANON_KEY=$anon"
Write-Host "Done -> build\web"
