$env:PORT = '5199'
$env:CAMPAIGN_WORKER_INTERVAL_MS = '3000'
$base = 'http://localhost:5199/api/v1'
$p = Start-Process node -ArgumentList 'src/server.js' -RedirectStandardOutput 'smoke_out.log' -RedirectStandardError 'smoke_err.log' -PassThru
Start-Sleep -Seconds 3

$stamp = Get-Date -Format 'HHmmss'
try {
  $login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body (@{ email = 'admin@etlang.app'; password = 'admin123' } | ConvertTo-Json)
  $h = @{ Authorization = "Bearer $($login.token)" }
  Write-Host "1. admin login OK"

  $u = Invoke-RestMethod -Method Post -Uri "$base/admin/app-users" -Headers $h -ContentType 'application/json' -Body (@{ email = "smoke.$stamp@test.et"; display_name = 'Smoke Learner'; password = 'password123' } | ConvertTo-Json)
  Write-Host ("2. created learner #" + $u.id + " provider=" + $u.provider)

  $d = Invoke-RestMethod -Uri "$base/admin/app-users/$($u.id)" -Headers $h
  Write-Host ("3. detail ok xp=" + $d.xp + " lessonsDone=" + $d.lessonsDone)

  $up = Invoke-RestMethod -Method Put -Uri "$base/admin/app-users/$($u.id)" -Headers $h -ContentType 'application/json' -Body (@{ xp = 120; streak = 4; display_name = 'Renamed Learner'; email = "renamed.$stamp@test.et" } | ConvertTo-Json)
  Write-Host ("4. updated xp=" + $up.xp + " streak=" + $up.streak + " name=" + $up.displayName + " email=" + $up.email)

  try {
    Invoke-RestMethod -Method Post -Uri "$base/admin/app-users" -Headers $h -ContentType 'application/json' -Body (@{ email = "renamed.$stamp@test.et" } | ConvertTo-Json) | Out-Null
    Write-Host "5. FAIL duplicate email accepted"
  } catch { Write-Host "5. duplicate email rejected OK" }

  $n = Invoke-RestMethod -Method Post -Uri "$base/admin/notifications" -Headers $h -ContentType 'application/json' -Body (@{ title = 'Just for you'; body = 'direct msg'; userId = $u.id } | ConvertTo-Json)
  Write-Host ("6. direct notif id=" + $n.id + " broadcast=" + $n.broadcast)

  $c = Invoke-RestMethod -Method Post -Uri "$base/admin/campaigns" -Headers $h -ContentType 'application/json' -Body (@{ title = 'Round-based hello'; body = 'campaign body'; audience = 'all'; batchSize = 1; intervalMinutes = 0.1 } | ConvertTo-Json)
  Write-Host ("7. campaign #" + $c.id + " status=" + $c.status + " batchSize=" + $c.batchSize)

  Start-Sleep -Seconds 8
  $cs = Invoke-RestMethod -Uri "$base/admin/campaigns" -Headers $h
  $mine = $cs | Where-Object { $_.id -eq $c.id }
  Write-Host ("8. after rounds status=" + $mine.status + " totalSent=" + $mine.totalSent)

  $cc = Invoke-RestMethod -Method Post -Uri "$base/admin/campaigns/$($c.id)/cancel" -Headers $h
  Write-Host ("9. cancelled status=" + $cc.status)
} catch {
  Write-Host ("SMOKE ERROR: " + $_.Exception.Message)
}

Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
Write-Host "--- worker console lines ---"
Get-Content 'smoke_out.log' | Select-String -Pattern 'campaign|users' | ForEach-Object { $_.Line }
Write-Host "--- stderr ---"
Get-Content 'smoke_err.log' -ErrorAction SilentlyContinue