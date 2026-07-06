# Builds the Flutter web bundle for the live preview.
# - Bakes SUPABASE_URL / SUPABASE_ANON_KEY from ../backend-nest/.env (a plain
#   `flutter build web` drops them and breaks login).
# - --pwa-strategy=none: do NOT generate a caching service worker. The Flutter SW
#   aggressively caches and strands testers on old builds (esp. iOS Safari).
# - After building, writes a self-destroying flutter_service_worker.js "kill switch"
#   so any device that already installed the old caching SW clears it and reloads.
# API_BASE_URL stays empty -> the app uses same-origin (static server proxies /v1).
# NOTE: don't set ErrorActionPreference='Stop' — flutter prints deprecation warnings to
# stderr which would otherwise abort the script before the kill switch is written.
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
Write-Host "Building web (pwa=none) with SUPABASE_URL=$supaUrl and anon key (len $($anon.Length))..."
$flutter = 'C:\Users\Aviv Avisar\tools\flutter\bin\flutter.bat'
& $flutter build web --release --pwa-strategy=none `
  --dart-define="SUPABASE_URL=$supaUrl" `
  --dart-define="SUPABASE_ANON_KEY=$anon"

# Kill switch: replaces the old caching service worker on already-infected devices.
$sw = @'
// Self-destroying service worker: clears all caches, unregisters itself, reloads
// open tabs. Ensures testers never get stranded on a stale cached build.
self.addEventListener('install', function (e) { self.skipWaiting(); });
self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) { return Promise.all(keys.map(function (k) { return caches.delete(k); })); })
      .then(function () { return self.registration.unregister(); })
      .then(function () { return self.clients.matchAll(); })
      .then(function (clients) { clients.forEach(function (c) { try { c.navigate(c.url); } catch (e) {} }); })
  );
});
'@
$swPath = Join-Path $root 'build\web\flutter_service_worker.js'
Set-Content -Path $swPath -Value $sw -Encoding utf8 -NoNewline

# Sync the fresh bundle into the backend's public/ dir. The NestJS service serves this
# in production (Render), so the deployed site always matches the local build.
$pub = Join-Path $root '..\backend-nest\public'
if (Test-Path $pub) { Remove-Item $pub -Recurse -Force }
New-Item -ItemType Directory -Force $pub | Out-Null
Copy-Item (Join-Path $root 'build\web\*') $pub -Recurse -Force
Write-Host "Done -> build\web + backend-nest\public (kill switch written, backend synced)"
