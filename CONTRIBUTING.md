# 贡献与维护

本仓库是**发布产物托管仓库**：只放文隐（macOS）的 DMG 安装包下载入口与说明，不放源码。
源码在私有的 `songoao25/wenyin` 仓库；本仓库不接受外部贡献。

## 职责

| 路径 | 职责 |
| --- | --- |
| `README.md` / `README.zh-CN.md` | 下载入口、当前版本、安装与放行说明，中英互链 |
| Releases | 每个版本的 DMG 与校验信息；已发布版本**不覆盖、不重传**，修复发新版本 |

## 发布流程

1. 在私有源码仓库 `wenyin` 完成构建、签名与验收（本仓库不放源码、构建脚本与签名材料）；
2. 把 DMG 上传到本仓库的 Releases，写清版本号与构建号；
3. 更新两份 README 的版本号与下载链接。

## 隐私边界

- 只放**可公开的安装产物与说明**：不放源码、构建日志、签名私钥、公证凭据、用户数据、
  本机路径、内网地址。
- 已发布的安装包**不得在同一版本号下静默替换**（见个人规范 `tasks/development-delivery.md`）。

## Repository framework status

本仓库按个人 GitHub 项目通用框架（`~/code/agent-norms/public-repo/project-standard.md`）
逐项核对，2026-10-14 结果如下。

**已经具备**：`README.md` + `README.zh-CN.md`（中英互链）、`CONTRIBUTING.md`（本文件）、
`SECURITY.md`、`SUPPORT.md`、`.github/pull_request_template.md`、GitHub Releases 作为分发渠道；
根目录只有标准文件。

**已知差异**（每条带理由）：

- **没有源码与 `tests/`**：本仓库只托管发布产物，源码在私有仓库 `wenyin`；
  测试与构建在那边跑，这里没有可测对象。
- **没有 CI / CodeQL**：同上 —— 仓库里没有代码，扫描与测试无从谈起。
- **没有发布链**（`release-please.yml`、`publish-npm.yml`、`verify-npm-release.yml`、
  `auto-merge-own.yml`）：发布是把 DMG 人工上传到 Releases，版本号跟随私有源码仓库的
  `VERSION` / `BUILD_NUMBER`；本仓库不发 npm。
- **没有 `LICENSE`**：分发的是闭源商业软件的安装包，权利保留（All Rights Reserved）；
  标准要求 LICENSE 一条在这里豁免。
- **没有 `CHANGELOG.md`**：版本变化写在 Releases 说明里，读者从下载页看。
- **没有 `docs/`**：仓库只有两份 README，尚不需要单独的用户文档目录。

任何偏离标准的做法都登记在本节，写明理由与日期。
