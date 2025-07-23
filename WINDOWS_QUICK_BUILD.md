# 🚀 Windows 打包快速指南

## 📦 一键打包 Windows 版本

### 🎯 最简单的方法

**在 Windows 系统上执行以下步骤：**

#### 1. 运行自动构建脚本
```cmd
# 双击运行
build_windows.bat
```

#### 2. 手动构建 (如果脚本失败)
```cmd
# 在项目根目录打开命令提示符
flutter config --enable-windows-desktop
flutter create --platforms=windows .
flutter clean
flutter pub get
flutter build windows --release
```

#### 3. 分发文件位置
```
build/windows/runner/Release/
├── elasticsearch_query_helper.exe  ← 主程序
├── data/                          ← 应用资源
└── *.dll                          ← 运行时库
```

### 📋 系统要求

**开发环境：**
- Windows 10/11
- Flutter SDK 3.13+
- Visual Studio 2022 (含 C++ 工具)
- Windows 10/11 SDK

**运行环境：**
- Windows 10/11
- Visual C++ Redistributable (通常已预装)

### 🎁 分发方式

#### 方式1: 文件夹分发
```cmd
# 复制整个Release文件夹
copy build\windows\runner\Release elasticsearch_query_helper_windows
# 压缩成ZIP文件分发
```

#### 方式2: 便携版
```cmd
# 将Release文件夹重命名
ren build\windows\runner\Release elasticsearch_query_helper_portable
# 用户解压后直接运行.exe文件
```

### ⚡ 快速命令

```cmd
# 一键构建命令
flutter build windows --release && echo "构建完成！文件位置: build\windows\runner\Release\"
```

### 🔧 故障排除

**常见问题：**

1. **Flutter命令不存在**
   - 下载安装 Flutter SDK
   - 添加到系统 PATH 环境变量

2. **Visual Studio 错误**
   - 安装 Visual Studio 2022 Community
   - 确保包含 "Desktop development with C++" 工作负载

3. **构建失败**
   - 运行 `flutter doctor -v` 检查环境
   - 确保所有检查项都是绿色 ✓

### 📁 最终文件结构

```
elasticsearch_query_helper_windows/
├── elasticsearch_query_helper.exe  ← 双击运行
├── data/
│   └── flutter_assets/             ← 应用资源
├── msvcp140.dll                    ← 运行时库
├── vcruntime140.dll
├── vcruntime140_1.dll
└── flutter_windows.dll
```

### 🎉 完成！

构建成功后，您将得到一个完整的 Windows 桌面应用程序，可以在任何 Windows 10/11 系统上运行！

**文件大小：** 约 50-100MB  
**启动时间：** 2-5秒  
**内存占用：** 约 100-200MB