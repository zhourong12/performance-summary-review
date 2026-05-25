# 唤起飞书登录页（Windows）
# 用法: .\scripts\open-feishu-login.ps1 [-FrontendUrl "http://172.25.1.43:8081"]
param(
  [string]$FrontendUrl = "http://172.25.1.43:8081"
)
$loginUrl = ($FrontendUrl.TrimEnd('/')) + "/login"
Write-Host "Opening Feishu login: $loginUrl"
Start-Process $loginUrl
