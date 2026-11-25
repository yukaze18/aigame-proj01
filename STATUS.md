# 项目状态记录

> 约定：**每次开工先读这份文件，每次收工前更新它。**
> 它本身进 git，所以自带历史，谁在什么时候改了什么都能查到。

最后更新：2026-11-25 18:10（+08:00）
更新者：本机 `G:\AIGame_Proj01`

---

## 一、当前状态

| 项 | 值 |
|---|---|
| 项目名 | AIGame_Proj01 |
| 工程路径 | `G:\AIGame_Proj01`（本机） |
| 引擎 | **未定** |
| 阶段 | 本地仓库就绪，等待推送远端；游戏开发未开始 |
| 分支 | `main` |
| 远端 | **GitHub 私有仓库（待创建、待填地址）** |
| 提交身份 | **占位**：`AIGame_Proj01 <aigame-proj01@users.noreply.local>` ← 待替换 |

---

## 二、已完成

- [x] 建立工程目录 `G:\AIGame_Proj01`
- [x] `.gitignore`（Unity / Godot / 通用 / 构建产物）
- [x] `.gitattributes`（行尾统一 + LFS 规则 + Unity 合并规则）
- [x] `git init` + 首次提交
- [x] Git LFS 启用，15 类二进制资源已挂到 LFS
- [x] `setup-git.ps1`（初始化脚本，幂等，带忽略规则自检）
- [x] 建立本状态记录
- [x] 定下远端方案：**GitHub 私有仓库**，走 `git clone` 接入家里设备

---

## 三、待办（按顺序执行）

- [ ] **1. 替换占位身份**（不替换的话，以后每次提交都会挂这个名字）
- [ ] **2. 在 GitHub 建私有空仓库**，拿到地址
- [ ] **3. 配 remote 并推送**
- [ ] **4. 家里设备 clone 并接入 DSH**
- [ ] 5. 确定引擎后，删掉 `.gitignore` 里不对应的引擎段落
- [ ] 6. 【今晚目标】家里 DSH 能成功访问到本工程
- [ ] 7. 【资源入场前】确认 LFS 额度够不够，不够就换方案（见第五节）

### 第 2 步：GitHub 建仓库的勾选清单

创建时**必须**这样选，否则会踩坑：

| 选项 | 怎么选 | 原因 |
|---|---|---|
| Repository name | `aigame-proj01` | 全小写无空格，跨平台安全 |
| 可见性 | **Private** | 公司比赛项目 |
| **Add a README file** | **不要勾** | 勾了远端会多一个提交，直接 push 会被拒，得先 pull |
| Add .gitignore | **None** | 我们自己已经写好了 |
| Choose a license | **None** | 同上 |

目标状态是**一个完全空的仓库**，这样本地 `git push -u origin main` 一次成功。

### 第 3 步：推送

```
cd /d G:\AIGame_Proj01
git remote add origin <仓库地址>
git push -u origin main
```

首次推送会弹浏览器让你登录 GitHub（Git Credential Manager，Windows 会记住）。
GitHub 不接受账号密码推送，如果弹的是输密码的框，那就要用
Personal Access Token 当密码。

---

## 四、家里设备接入步骤

```
git lfs install                    # 每台机器一次，必须先做
git clone <仓库地址> G:\AIGame_Proj01
cd /d G:\AIGame_Proj01
git config user.name  "你的名字"
git config user.email "你的邮箱"
```

然后把 DSH 的工作区指向 `G:\AIGame_Proj01`。
仓库里自带的 `setup-git.ps1` 可以跑一次做环境自检（幂等，不会重复初始化）。

**换设备日常只有两下**：离开前 `git push`，到岗后 `git pull`。

---

## 五、两个需要提前知道的限制

### 1. GitHub LFS 免费额度很紧 ⚠️

GitHub 免费账号的 Git LFS 是 **1 GiB 存储 + 1 GiB / 月 流量**
（按当前政策，建议你自己再确认一次）。

对代码和配置来说这绰绰有余，但**对游戏美术资源很容易不够**。
包体目标虽然只有 200MB，源工程里的 PSD、FBX、WAV 加起来往往远超 1 GiB。

**资源入场前必须做的事**：先估算一下资源总量。如果超过 1 GiB，有几个选择：
- 买 GitHub 的数据包（按月付费）
- 大资源**不进仓库**，单独放网盘/对象存储，仓库里只放代码和配置
- 代码放 GitHub，LFS 走另一个远端（Gitee 或自建）

现在仓库里一个二进制文件都没有，所以今晚完全不受影响。

### 2. 国内访问 GitHub 可能不稳

`push` / `clone` 慢或超时是有可能的。真遇到了我们再加镜像或代理，
今晚先试，不提前折腾。

---

## 六、已知问题与记录

- 本机原先在 `E:\Project_T6\DSH_WorkSpace` 会话里 **bash 完全无法启动**，
  报错 `Workspace ancestry contains a reparse point`。
  改为以 `G:\AIGame_Proj01` 为工作区后一切正常。
  **结论：工程不要放在 E: 盘那条路径下。**
- `git lfs install` 已在本机全局执行了一次（LFS 的前置条件），
  影响范围仅限匹配 `filter=lfs` 的文件，其他仓库不受影响。

---

## 七、决策记录

| 日期 | 决策 | 理由 |
|---|---|---|
| 2026-11-25 | 用 git 统一管理，不用同步盘 | 同步盘没有历史和回退点；且会把 `Library/` 一起同步导致工程损坏 |
| 2026-11-25 | 单人轮换**不开分支**，直接在 `main` 提交 | 分支解决的是「多人并行改」的问题，单人轮换没有这个需求 |
| 2026-11-25 | 工程目录不放在任何同步盘内 | 防止 `.git` 被同步盘破坏 |
| 2026-11-25 | 二进制资源走 Git LFS | 包体目标 <200MB，资源量可控 |
| 2026-11-25 | git 身份只配仓库级（`--local`），不动全局 | 避免影响其他仓库的提交身份 |
| 2026-11-25 | 远端选 **GitHub 私有仓库**（原定 Gitee，因已有 GitHub 账号而改） | 复用已有账号；走 clone 接入家里设备，不依赖本机开机 |
| 2026-11-25 | 换机前必须 `git status` 干净且已 push | 整个方案里最容易忘、代价最大的一条纪律 |

---

## 八、保命规矩

1. `.git` **绝不**放进任何同步盘（坚果云、OneDrive 都不行）
2. 换设备前 `git status` 必须干净且已 push
3. 不碰 `push --force`、`reset --hard`、`clean -fd`，除非确定要丢东西
