# ============================================================
# checkin.ps1 —— 收工脚本：提交 + 推送 + 资源自检
#
# 用法（二选一）：
#   cd G:\AIGame_Proj01
#   powershell -ExecutionPolicy Bypass -File .\Tools\checkin.ps1
#   powershell -ExecutionPolicy Bypass -File .\Tools\checkin.ps1 -Message "feat: 加了角色移动"
#
# 参数：
#   -Message <文本>   直接给定提交信息，不提问
#   -NoPush           只提交，不推送
#
# 为什么要有这个脚本：
#   工作流改成「全部走远程桌面」之后，仓库只有一份工作副本。
#   push 不再是「同步到另一台机器」，而是「备份」——忘了 push，
#   硬盘坏了项目就没了。把这件事交给脚本，别交给记性。
#
# 安全边界：只用 add / commit / push / fetch。
#           不碰 push --force、reset --hard、clean -fd。
# ============================================================

[CmdletBinding()]
param(
    [string]$Message,
    [switch]$NoPush
)

$ErrorActionPreference = 'Stop'

# 坚果云里放美术资源的真实目录（按实际路径改）
$ArtSyncDir = 'G:\坚果云\AIGame_Art'

# ---------- 定位仓库根（本脚本在 <仓库>\Tools\ 下）----------
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot '.git'))) {
    Write-Host "找不到 git 仓库。本脚本应放在仓库的 Tools\ 目录下。" -ForegroundColor Red
    Write-Host "推断出的仓库根：$repoRoot" -ForegroundColor Red
    exit 1
}
Set-Location -LiteralPath $repoRoot

function Step([string]$text) { Write-Host "`n===== $text =====" -ForegroundColor Cyan }
function Die([string]$text)  { Write-Host "`n!! $text" -ForegroundColor Red; exit 1 }

# ============================================================
Step '1/6 环境检查'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Die '找不到 git，请确认它在 PATH 里。'
}
Write-Host ('git: ' + (git --version))

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -eq 'HEAD') { Die '当前处于游离 HEAD 状态，请先切回分支。' }
Write-Host "当前分支: $branch"

$remotes = @(git remote)
if ($remotes -notcontains 'origin') { Die '没有配置 origin 远端。' }
Write-Host "远端: $(git remote get-url origin)"

$uname  = (git config user.name)
$uemail = (git config user.email)
if (-not $uname -or -not $uemail) {
    Write-Host '警告：没配提交身份，提交可能挂错名字。' -ForegroundColor Yellow
} else {
    Write-Host "提交身份: $uname <$uemail>"
}

# ============================================================
Step '2/6 检查改动'

$statusLines = @(git status --porcelain)
$hasChanges  = ($statusLines.Count -gt 0)

if (-not $hasChanges) {
    Write-Host '工作树干净，没有要提交的内容。'
} else {
    Write-Host "有 $($statusLines.Count) 项改动："
    $statusLines | ForEach-Object { Write-Host "  $_" }
}

# ============================================================
Step '3/6 提交'

if (-not $hasChanges) {
    Write-Host '跳过。'
} else {
    git add -A
    $staged = @(git diff --cached --name-only)

    if ($staged.Count -eq 0) {
        Write-Host '暂存区为空，跳过。'
    } else {
        # 安全闸：本该被忽略的目录一旦混进来，立刻取消暂存，什么都不提交
        $bad = $staged | Where-Object {
            $_ -match '(?i)(^|/)(Library|Temp|obj|Build|Builds|Logs|UserSettings|MemoryCaptures|node_modules)(/|$)'
        }
        if ($bad) {
            Write-Host "`n!! 发现本该被忽略的内容：" -ForegroundColor Red
            $bad | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
            git reset --quiet          # 只取消暂存，不动工作区文件
            Die '忽略规则没生效，已取消暂存（什么都没有提交）。请先修 .gitignore。'
        }

        Write-Host "将提交 $($staged.Count) 个文件。"

        if (-not $Message) {
            $suggest = "wip: 收工提交 $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            $typed   = Read-Host "提交信息（直接回车用：$suggest）"
            if ([string]::IsNullOrWhiteSpace($typed)) { $Message = $suggest }
            else { $Message = $typed.Trim() }
        }

        git commit -m $Message
        if ($LASTEXITCODE -ne 0) { Die '提交失败。' }
        Write-Host "已提交：$Message" -ForegroundColor Green
    }
}

# ============================================================
Step '4/6 推送'

if ($NoPush) {
    Write-Host '指定了 -NoPush，跳过推送。' -ForegroundColor Yellow
} else {
    git fetch origin --quiet
    if ($LASTEXITCODE -ne 0) { Write-Host '警告：fetch 失败（可能断网），下面按本地已知状态判断。' -ForegroundColor Yellow }

    $counts = ((git rev-list --left-right --count "origin/$branch...HEAD") -join ' ').Trim() -split '\s+'
    $behind = [int]$counts[0]
    $ahead  = [int]$counts[1]
    Write-Host "相对 origin/$branch：落后 $behind 个提交，领先 $ahead 个提交"

    if ($behind -gt 0) {
        Write-Host '远端有你本地没有的提交，直接推会被拒。先执行：' -ForegroundColor Yellow
        Write-Host "   git pull --rebase origin $branch" -ForegroundColor Yellow
        Die '已停下，没有推送。'
    }

    if ($ahead -eq 0) {
        Write-Host '没有需要推送的提交。'
    } else {
        git push origin $branch
        if ($LASTEXITCODE -ne 0) { Die '推送失败，看上面的报错。' }
    }

    # 推送后核对：本地 HEAD 必须等于远端分支
    git fetch origin --quiet
    $local  = (git rev-parse HEAD).Trim()
    $remote = (git rev-parse "origin/$branch").Trim()
    if ($local -eq $remote) {
        Write-Host "`n已核对：本地与远端完全一致（$($local.Substring(0,8))）" -ForegroundColor Green
    } else {
        Die "推送后仍不一致：本地 $local / 远端 $remote"
    }
}

# ============================================================
Step '5/6 资源自检'

$artLink = Join-Path $repoRoot 'Assets\Art'
if (-not (Test-Path -LiteralPath $artLink)) {
    Write-Host '尚未建立 Assets\Art（引擎定下来之前属正常）。'
    Write-Host '将来按「资源同步方案.md」第 5 节建 junction 后，这里会自动开始检查。'
} else {
    $item = Get-Item -LiteralPath $artLink -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "Assets\Art 是链接（类型：$($item.LinkType)）"
        $target = @($item.Target)[0]
        Write-Host "  指向：$target"
        if ($target -and -not (Test-Path -LiteralPath $target)) {
            Write-Host '  !! 链接目标不存在 —— 资源没同步过来。' -ForegroundColor Red
        } else {
            $n = @(Get-ChildItem -LiteralPath $artLink -Recurse -File -ErrorAction SilentlyContinue).Count
            Write-Host "  文件数：$n"
            if ($n -eq 0) {
                Write-Host '  !! 链接是空的 —— 坚果云可能还没下载完。' -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host '!! Assets\Art 不是链接，而是一个真实目录。' -ForegroundColor Red
        Write-Host '   说明 junction 没建成，或资源被直接拷进了工程（会出现两份物理副本）。' -ForegroundColor Red
    }
}

if (Test-Path -LiteralPath $ArtSyncDir) {
    Write-Host "`n坚果云资源目录存在：$ArtSyncDir"
} else {
    Write-Host "`n坚果云资源目录还不存在：$ArtSyncDir（尚未启用资源分离时属正常）"
}

# ============================================================
Step '6/6 收工清单'

Write-Host '  [x] 代码已提交'
if (-not $NoPush) {
    Write-Host '  [x] 已推送到 GitHub —— 这就是你的异地备份'
} else {
    Write-Host '  [!] 按要求没有推送 —— 别忘了补一次' -ForegroundColor Yellow
}
Write-Host '  [ ] 等坚果云显示同步完成（资源目录启用后才有这一步）'
Write-Host '  [ ] 确认上面没有红色报错'

Write-Host "`n可以断开远程桌面了。" -ForegroundColor Green
