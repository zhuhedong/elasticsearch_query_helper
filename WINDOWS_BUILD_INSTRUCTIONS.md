# 🐧➡️🪟 Linux 下构建 Windows 包说明

## 🎯 推荐方案: GitHub Actions

### 1. 提交代码到 GitHub
```bash
# 初始化 Git 仓库 (如果还没有)
git init
git add .
git commit -m "Add Windows build workflow"

# 推送到 GitHub
git remote add origin https://github.com/yourusername/elasticsearch-query-helper.git
git push -u origin main
```

### 2. 触发构建
- 进入 GitHub 仓库页面
- 点击 "Actions" 标签
- 选择 "Build Windows Release" 工作流
- 点击 "Run workflow" 按钮

### 3. 下载构建产物
- 构建完成后，在 Actions 页面下载 artifacts
- 解压获得 Windows 可执行文件

## 🔄 自动发布

### 创建版本标签自动发布
```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0

# 这将自动触发构建并创建 GitHub Release
```

## 🧪 本地测试 (可选)

```bash
# 使用 act 本地测试 GitHub Actions
./test_github_actions_locally.sh

# 或尝试 Docker 实验性构建
./docker_windows_build_experimental.sh
```

## 📋 文件说明

- `.github/workflows/build-windows.yml` - GitHub Actions 工作流
- `test_github_actions_locally.sh` - 本地测试脚本
- `docker_windows_build_experimental.sh` - Docker 实验性构建
- `WINDOWS_BUILD_INSTRUCTIONS.md` - 本说明文件

## ✅ 成功标志

构建成功后，您将获得：
- `elasticsearch_query_helper.exe` - Windows 可执行文件
- `data/` 目录 - 应用资源文件
- 运行时 DLL 文件
- README.txt - 使用说明

文件大小约 50-100MB，可在 Windows 10/11 上直接运行。
