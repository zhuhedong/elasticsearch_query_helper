@echo off
echo 🚀 Elasticsearch Query Helper - Windows 构建脚本
echo ================================================

REM 检查Flutter环境
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter未安装或未在PATH中
    echo 请先安装Flutter: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

echo ✅ Flutter环境检查通过

REM 启用Windows支持
echo 🔧 启用Windows桌面支持...
flutter config --enable-windows-desktop

REM 创建Windows平台文件
echo 📁 创建Windows平台文件...
flutter create --platforms=windows .

REM 清理项目
echo 🧹 清理项目...
flutter clean

REM 获取依赖
echo 📦 获取依赖...
flutter pub get

REM 构建发布版本
echo 🏗️ 构建Windows发布版本...
flutter build windows --release

REM 检查构建结果
if exist "build\windows\runner\Release\elasticsearch_query_helper.exe" (
    echo ✅ 构建成功！
    
    REM 创建分发目录
    echo 📦 创建分发包...
    if exist "dist" rmdir /s /q "dist"
    mkdir "dist\elasticsearch_query_helper_windows"
    
    REM 复制文件
    xcopy "build\windows\runner\Release\*" "dist\elasticsearch_query_helper_windows\" /E /I /Y
    
    REM 创建启动脚本
    echo @echo off > "dist\elasticsearch_query_helper_windows\start.bat"
    echo elasticsearch_query_helper.exe >> "dist\elasticsearch_query_helper_windows\start.bat"
    
    REM 创建说明文件
    echo Elasticsearch Query Helper - Windows版本 > "dist\elasticsearch_query_helper_windows\README.txt"
    echo. >> "dist\elasticsearch_query_helper_windows\README.txt"
    echo 运行方式: >> "dist\elasticsearch_query_helper_windows\README.txt"
    echo 1. 双击 elasticsearch_query_helper.exe >> "dist\elasticsearch_query_helper_windows\README.txt"
    echo 2. 或者双击 start.bat >> "dist\elasticsearch_query_helper_windows\README.txt"
    echo. >> "dist\elasticsearch_query_helper_windows\README.txt"
    echo 系统要求: Windows 10 或更高版本 >> "dist\elasticsearch_query_helper_windows\README.txt"
    
    echo ✅ 分发包已创建: dist\elasticsearch_query_helper_windows\
    echo 📁 包含文件:
    dir "dist\elasticsearch_query_helper_windows\" /b
    
    echo.
    echo 🎉 Windows版本构建完成！
    echo 📂 分发目录: %cd%\dist\elasticsearch_query_helper_windows\
    echo 🚀 主程序: elasticsearch_query_helper.exe
    
) else (
    echo ❌ 构建失败！
    echo 请检查错误信息并解决问题后重试
)

echo.
echo 按任意键退出...
pause >nul