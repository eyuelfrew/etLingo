# Full Android rebuild for flutter_facebook_auth
# Run from D:\etlingo\etlingo in PowerShell

Write-Host "==> Uninstalling old app from device (if connected)..."
flutter devices
# Optional: flutter uninstall  (or: adb uninstall com.virallinkdigital.etlingo)

Write-Host "==> Cleaning Flutter + Gradle caches..."
flutter clean
if (Test-Path "android\build") { Remove-Item -Recurse -Force "android\build" }
if (Test-Path "android\app\build") { Remove-Item -Recurse -Force "android\app\build" }
if (Test-Path "android\.gradle") { Remove-Item -Recurse -Force "android\.gradle" }
if (Test-Path "build") { Remove-Item -Recurse -Force "build" }

Write-Host "==> pub get..."
flutter pub get

Write-Host "==> Start app (full compile)..."
flutter run
