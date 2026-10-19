#!/usr/bin/env bash
# 把 GitHub Release 里的安装包同步到 Gitee 同名 Release。
#
# 用法：sync-to-gitee.sh [tag]
#   tag 省略时用当前仓库最新 release 的 tag。
# 环境变量：
#   GITEE_TOKEN  必填（Gitee 私人令牌，权限 projects）
#   DRY_RUN      true 时只检查账号/资产/发布计划，不做任何写入（默认 false）
#   GH_OWNER/GH_REPO/GITEE_OWNER/GITEE_REPO 可选，默认都是 songoao25 / wenyin-downloads
#
# 只同步安装产物（dmg/zip），不传源码、不传清单。
set -euo pipefail

GH_OWNER="${GH_OWNER:-songoao25}"
GH_REPO="${GH_REPO:-wenyin-downloads}"
GITEE_OWNER="${GITEE_OWNER:-songoao25}"
GITEE_REPO="${GITEE_REPO:-wenyin-downloads}"
API="https://gitee.com/api/v5"
TAG="${1:-}"
DRY_RUN="${DRY_RUN:-false}"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -n "${GITEE_TOKEN:-}" ] || die "缺少 GITEE_TOKEN：请在 GitHub 仓库 Settings → Secrets and variables → Actions 里配置后重试。"

if [ -z "$TAG" ]; then
  TAG="$(gh release view --repo "$GH_OWNER/$GH_REPO" --json tagName --jq .tagName)"
fi
[ -n "$TAG" ] || die "拿不到 tag。"

echo "== 同步 $GH_OWNER/$GH_REPO 的 release $TAG → Gitee $GITEE_OWNER/$GITEE_REPO =="

# 0) 令牌自检（不打印令牌本身）
ME="$(curl -sS --max-time 30 "$API/user?access_token=$GITEE_TOKEN")"
python3 - "$ME" <<'PY'
import json, sys
try:
    data = json.loads(sys.argv[1])
except Exception:
    sys.exit("Gitee 令牌自检失败：返回不是 JSON，令牌可能无效。")
login = data.get("login")
if not login:
    sys.exit("Gitee 令牌自检失败：没有返回账号信息，令牌可能无效或权限不足。")
print("Gitee 账号自检通过：", login)
PY

# 1) GitHub release 资产
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
gh release view "$TAG" --repo "$GH_OWNER/$GH_REPO" --json name,body,isPrerelease,assets > "$TMP/release.json"
python3 - "$TMP/release.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
assets = [a for a in data.get("assets", []) if a["name"].lower().endswith((".dmg", ".zip"))]
if not assets:
    sys.exit("GitHub release 里没有 dmg/zip 资产，停止。")
print("GitHub 资产：")
for a in assets:
    print(f"  - {a['name']} ({a['size']} bytes)")
PY

# 2) Gitee 现状
RELEASE_JSON="$(curl -sS --max-time 30 "$API/repos/$GITEE_OWNER/$GITEE_REPO/releases/tags/$TAG?access_token=$GITEE_TOKEN" || true)"
python3 - "$TMP/release.json" "$RELEASE_JSON" <<'PY'
import json, sys
assets = [a["name"] for a in json.load(open(sys.argv[1])).get("assets", []) if a["name"].lower().endswith((".dmg", ".zip"))]
try:
    existing = json.loads(sys.argv[2])
except Exception:
    existing = None
if isinstance(existing, dict) and existing.get("id"):
    have = {a.get("name") for a in existing.get("assets", [])}
    print(f"Gitee 已有 release id={existing['id']}，已有附件：{sorted(n for n in have if n)}")
    print("待上传：", [n for n in assets if n not in have])
else:
    print("Gitee 还没有这个 release，将创建；待上传：", assets)
PY

if [ "$DRY_RUN" = "true" ]; then
  echo "== DRY RUN：以上只是检查，未做任何写入 =="
  exit 0
fi

# 3) 确保 tag 存在（Gitee 空仓库/新 tag 时）
if ! curl -sS --max-time 30 "$API/repos/$GITEE_OWNER/$GITEE_REPO/tags/$TAG?access_token=$GITEE_TOKEN" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if isinstance(d,dict) and d.get("name") else 1)' 2>/dev/null; then
  echo "Gitee 上没有 tag $TAG，先创建（指向 main）。"
  curl -sS --max-time 30 -X POST "$API/repos/$GITEE_OWNER/$GITEE_REPO/tags" \
    --data-urlencode "access_token=$GITEE_TOKEN" \
    --data-urlencode "tag_name=$TAG" \
    --data-urlencode "refs=main" \
    --data-urlencode "tag_message=$TAG" >/dev/null
fi

# 4) 创建 / 复用 release
RELEASE_JSON="$(curl -sS --max-time 30 "$API/repos/$GITEE_OWNER/$GITEE_REPO/releases/tags/$TAG?access_token=$GITEE_TOKEN" || true)"
RELEASE_ID="$(python3 -c 'import json,sys
try: d=json.loads(sys.argv[1])
except Exception: d={}
print(d.get("id","") if isinstance(d,dict) else "")' "$RELEASE_JSON")"
if [ -z "$RELEASE_ID" ]; then
  echo "在 Gitee 创建 release $TAG"
  NAME="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "$TMP/release.json")"
  BODY="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("body") or "")' "$TMP/release.json")"
  PRE="$(python3 -c 'import json,sys; print("true" if json.load(open(sys.argv[1])).get("isPrerelease") else "false")' "$TMP/release.json")"
  CREATE="$(curl -sS --max-time 60 -X POST "$API/repos/$GITEE_OWNER/$GITEE_REPO/releases" \
    --data-urlencode "access_token=$GITEE_TOKEN" \
    --data-urlencode "tag_name=$TAG" \
    --data-urlencode "name=$NAME" \
    --data-urlencode "body=$BODY" \
    --data-urlencode "target_commitish=main" \
    --data-urlencode "prerelease=$PRE")"
  RELEASE_ID="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("id",""))' "$CREATE")"
  [ -n "$RELEASE_ID" ] || die "Gitee 创建 release 失败：$CREATE"
fi
echo "Gitee release id=$RELEASE_ID"

# 5) 上传缺失的附件
for asset in $(python3 -c 'import json,sys; print(" ".join(a["name"] for a in json.load(open(sys.argv[1]))["assets"] if a["name"].lower().endswith((".dmg",".zip"))))' "$TMP/release.json"); do
  if curl -sS --max-time 30 "$API/repos/$GITEE_OWNER/$GITEE_REPO/releases/$RELEASE_ID?access_token=$GITEE_TOKEN" \
      | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if any(a.get("name")==sys.argv[1] for a in d.get("assets",[])) else 1)' "$asset"; then
    echo "已存在，跳过：$asset"
    continue
  fi
  echo "下载并上传：$asset"
  gh release download "$TAG" --repo "$GH_OWNER/$GH_REPO" --pattern "$asset" --dir "$TMP" --clobber
  curl -sS --max-time 600 -X POST "$API/repos/$GITEE_OWNER/$GITEE_REPO/releases/$RELEASE_ID/attach_files" \
    --data-urlencode "access_token=$GITEE_TOKEN" \
    -F "file=@$TMP/$asset" >/dev/null
  echo "上传完成：$asset"
done
echo "== 同步完成：https://gitee.com/$GITEE_OWNER/$GITEE_REPO/releases =="
