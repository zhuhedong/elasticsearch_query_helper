# Windows 打包指南

## 📦 Flutter Elasticsearch Query Helper Windows 打包完整指南

### 🔧 前置要求

#### 1. 安装Flutter SDK
```bash
# 下载Flutter SDK for Windows
# 访问: https://docs.flutter.dev/get-started/install/windows
# 解压到: C:\flutter

# 添加到系统PATH环境变量
# C:\flutter\bin
```

#### 2. 安装Visual Studio 2022
```bash
# 下载并安装 Visual Studio 2022 Community
# 必须包含以下组件:
# - Desktop development with C++
# - Windows 10/11 SDK
# - CMake tools for Visual Studio
```

#### 3. 验证环境
```bash
flutter doctor -v
# 确保Windows toolchain显示为已安装
```

### 🏗️ 项目配置

#### 1. 启用Windows支持
```bash
cd elasticsearch_query_helper
flutter config --enable-windows-desktop
flutter create --platforms=windows .
```

#### 2. 检查项目结构
确保项目包含以下目录:
```
elasticsearch_query_helper/
├── windows/
│   ├── CMakeLists.txt
│   ├── runner/
│   └── flutter/
├── lib/
├── pubspec.yaml
└── ...
```

#### 3. 更新pubspec.yaml (如需要)
```yaml
name: elasticsearch_query_helper
description: A Flutter application for Elasticsearch query assistance

version: 1.0.0+1

environment:
  sdk: '>=3.1.0 <4.0.0'
  flutter: ">=3.13.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  json_annotation: ^4.8.1
  provider: ^6.0.5
  shared_preferences: ^2.2.2
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  json_serializable: ^6.7.1
  build_runner: ^2.4.7

flutter:
  uses-material-design: true
```

### 🚀 构建步骤

#### 1. 清理项目
```bash
flutter clean
flutter pub get
```

#### 2. 构建Windows版本
```bash
# 调试版本 (开发测试用)
flutter build windows --debug

# 发布版本 (最终分发用)
flutter build windows --release
```

#### 3. 构建输出位置
```
elasticsearch_query_helper/
└── build/
    └── windows/
        └── runner/
            ├── Debug/          # 调试版本
            │   └── elasticsearch_query_helper.exe
            └── Release/        # 发布版本
                └── elasticsearch_query_helper.exe
```

### 📦 打包分发

#### 方式1: 简单分发 (推荐)
```bash
# 复制整个Release文件夹
cp -r build/windows/runner/Release/ elasticsearch_query_helper_windows/

# 文件夹内容:
# elasticsearch_query_helper.exe  # 主程序
# data/                          # Flutter资源
# *.dll                          # 运行时库
```

#### 方式2: 使用MSIX打包器 (Windows Store格式)
```bash
# 安装msix包
flutter pub add msix

# 在pubspec.yaml中添加配置
msix_config:
  display_name: Elasticsearch Query Helper
  publisher_display_name: Your Name
  identity_name: com.yourcompany.elasticsearch_query_helper
  msix_version: 1.0.0.0
  description: Elasticsearch Query Helper for Windows
  
# 构建MSIX包
flutter pub run msix:create
```

#### 方式3: 使用Inno Setup创建安装程序
```bash
# 下载安装 Inno Setup: https://jrsoftware.org/isinfo.php
# 创建安装脚本 setup.iss:

[Setup]
AppName=Elasticsearch Query Helper
AppVersion=1.0.0
DefaultDirName={pf}\ElasticsearchQueryHelper
DefaultGroupName=Elasticsearch Query Helper
OutputDir=installer
OutputBaseFilename=elasticsearch_query_helper_setup

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\Elasticsearch Query Helper"; Filename: "{app}\elasticsearch_query_helper.exe"
Name: "{commondesktop}\Elasticsearch Query Helper"; Filename: "{app}\elasticsearch_query_helper.exe"
```

### 🔍 故障排除

#### 常见问题及解决方案

1. **"Visual Studio not found"**
   ```bash
   # 确保安装了Visual Studio 2022 with C++ tools
   # 重新运行: flutter doctor
   ```

2. **"Windows SDK not found"**
   ```bash
   # 在Visual Studio Installer中安装Windows 10/11 SDK
   ```

3. **构建失败**
   ```bash
   flutter clean
   flutter pub get
   flutter build windows --verbose  # 查看详细错误
   ```

4. **缺少DLL文件**
   ```bash
   # 确保复制了整个Release文件夹
   # 或使用 --bundle-skia-path 参数
   ```

### 📋 最终检查清单

- [ ] Flutter环境配置正确
- [ ] Visual Studio 2022已安装
- [ ] Windows支持已启用
- [ ] 项目构建成功
- [ ] 可执行文件能正常运行
- [ ] 所有依赖文件已包含
- [ ] 在目标机器上测试运行

### 🎯 快速命令序列

```bash
# 1. 配置环境
flutter config --enable-windows-desktop
flutter create --platforms=windows .

# 2. 构建项目
flutter clean
flutter pub get
flutter build windows --release

# 3. 打包分发
cp -r build/windows/runner/Release/ elasticsearch_query_helper_windows/
zip -r elasticsearch_query_helper_windows.zip elasticsearch_query_helper_windows/
```

### 📝 注意事项

1. **目标机器要求**: Windows 10 或更高版本
2. **运行时依赖**: Visual C++ Redistributable (通常已预装)
3. **文件大小**: 约50-100MB (包含Flutter引擎)
4. **权限**: 可能需要管理员权限进行首次安装
5. **防火墙**: 如果应用需要网络访问，可能需要防火墙例外

构建成功后，您将获得一个完整的Windows桌面应用程序！