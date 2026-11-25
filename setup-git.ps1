# ============================================================
# setup-git.ps1 —— 在 G:\AIGame_Proj01 初始化 git 仓库
#
# 用法（二选一）：
#   1. 在本目录右键 -> 使用 PowerShell 运行
#   2. cd G:\AIGame_Proj01
#      powershell -ExecutionPolicy Bypass -File .\setup-git.ps1
#
# 这个脚本只做本地动作，不碰远端、不上传任何东西。
# ============================================================

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

Write-Host "== 1/5 检查环境 ==" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "找不到 git。请先安装 Git for Windows，并确保它在 PATH 里。"
}
Write-Host ("git 版本: " + (git --version))

$userName  = (git config --global user.name)
$userEmail = (git config --global user.email)
if (-not $userName -or -not $userEmail) {
    Write-Host "还没配置提交身份，请先执行这两条：" -ForegroundColor Yellow
    Write-Host '  git config --global user.name  "你的名字"'
    Write-Host '  git config --global user.email "你的邮箱"'
    throw "缺少 user.name / user.email"
}
Write-Host "提交身份: $userName <$userEmail>"

# Windows 上必须关掉行尾自动转换，否则每次提交都会产生满屏噪音 diff
git config --global core.autocrlf false
git config --global core.quotepath false
git config --global init.defaultBranch main

Write-Host "`n== 2/5 初始化仓库 ==" -ForegroundColor Cyan

$hasRepo = Test-Path -LiteralPath (Join-Path $PWD '.git')
if ($hasRepo) {
    Write-Host "已经是 git 仓库，跳过 init。"
} else {
    git init -b main 2>$null
    if ($LASTEXITCODE -ne 0) {
        # 老版本 git 不支持 -b
        git init | Out-Null
        git branch -M main
    }
    Write-Host "已初始化，分支 main。"
}

$hasCommit = $false
if (Test-Path -LiteralPath (Join-Path $PWD '.git')) {
    git rev-parse --verify HEAD 2>$null | Out-Null
    $hasCommit = ($LASTEXITCODE -eq 0)
}
if ($hasCommit) {
    Write-Host "已有提交历史，本次只做检查。"
}

Write-Host "`n== 3/5 Git LFS ==" -ForegroundColor Cyan

if (Get-Command git-lfs -ErrorAction SilentlyContinue) {
    git lfs install
    Write-Host "LFS 已就绪，.gitattributes 里的 filter=lfs 规则会生效。"
} else {
    Write-Host "没装 git-lfs。" -ForegroundColor Yellow
    Write-Host "直接提交会导致 .png/.psd 等文件入库异常。两个选择：" -ForegroundColor Yellow
    Write-Host "  A) 装好 git-lfs 后重新运行本脚本（推荐）"
    Write-Host "  B) 把 .gitattributes 里「二进制资源 -> 交给 Git LFS」那一段整段删掉"
    throw "未安装 git-lfs，已停止，未做任何提交。"
}

Write-Host "`n== 4/5 检查忽略规则 ==" -ForegroundColor Cyan

git add -A
$tracked = @(git diff --cached --name-only)

if ($tracked.Count -eq 0) {
    Write-Host "没有待提交的内容。" -ForegroundColor Yellow
} else {
    Write-Host "将要提交 $($tracked.Count) 个文件："
    $tracked | ForEach-Object { Write-Host "  $_" }
}

# 安全闸：本该被忽略的缓存目录一旦混进来，立刻中止
$bad = $tracked | Where-Object { $_ -match '(?i)(^|/)(Library|Temp|obj|Build|Builds|Logs)(/|$)' }
if ($bad) {
    Write-Host "`n!! 发现本该被忽略的目录：" -ForegroundColor Red
    $bad | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    throw "忽略规则没生效，已中止（暂存区内容未提交）。请先修 .gitignore。"
}

Write-Host "`n== 5/5 首次提交 ==" -ForegroundColor Cyan

if ($hasCommit) {
    Write-Host "已有历史，跳过首次提交动作。"
} elseif ($tracked.Count -gt 0) {
    git commit -m "chore: 初始化 AIGame_Proj01 仓库，加入忽略规则、LFS 规则与状态记录"
}

Write-Host "`n== 完成 ==" -ForegroundColor Green
git log --oneline
Write-Host "`n下一步（等远端定好后执行）："
Write-Host '  git remote add origin <远端地址>'
Write-Host '  git push -u origin main'
