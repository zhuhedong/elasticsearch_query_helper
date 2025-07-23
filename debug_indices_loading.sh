#!/bin/bash

echo "🔍 调试 View All Indices 界面数据加载问题"
echo "=============================================="

# 检查相关文件
echo "📁 检查关键文件:"
echo "  - index_list_screen.dart: $([ -f elasticsearch_query_helper/lib/screens/index_list_screen.dart ] && echo "✅ 存在" || echo "❌ 缺失")"
echo "  - elasticsearch_provider.dart: $([ -f elasticsearch_query_helper/lib/providers/elasticsearch_provider.dart ] && echo "✅ 存在" || echo "❌ 缺失")"
echo "  - elasticsearch_service.dart: $([ -f elasticsearch_query_helper/lib/services/elasticsearch_service.dart ] && echo "✅ 存在" || echo "❌ 缺失")"
echo "  - version_adapter.dart: $([ -f elasticsearch_query_helper/lib/services/version_adapter.dart ] && echo "✅ 存在" || echo "❌ 缺失")"

echo ""
echo "🔧 检查数据加载逻辑:"

# 检查initState中的数据加载
echo "  initState数据加载:"
if grep -q "provider.loadIndices()" elasticsearch_query_helper/lib/screens/index_list_screen.dart; then
    echo "  ✅ initState中有loadIndices调用"
else
    echo "  ❌ initState中缺少loadIndices调用"
fi

# 检查刷新按钮
echo "  刷新按钮功能:"
if grep -q "onPressed.*loadIndices" elasticsearch_query_helper/lib/screens/index_list_screen.dart; then
    echo "  ✅ 刷新按钮有loadIndices调用"
else
    echo "  ❌ 刷新按钮缺少loadIndices调用"
fi

# 检查连接状态检查
echo "  连接状态检查:"
if grep -q "provider.isConnected" elasticsearch_query_helper/lib/screens/index_list_screen.dart; then
    echo "  ✅ 有连接状态检查"
else
    echo "  ❌ 缺少连接状态检查"
fi

echo ""
echo "🌐 检查API端点配置:"

# 检查endpoints配置
echo "  /_cat/indices端点:"
if grep -q "'indices': '/_cat/indices'" elasticsearch_query_helper/lib/services/version_adapter.dart; then
    echo "  ✅ 所有版本都配置了正确的indices端点"
else
    echo "  ❌ indices端点配置有问题"
fi

echo ""
echo "📊 检查数据处理:"

# 检查数据解析
echo "  JSON数据解析:"
if grep -q "_safeJsonDecode" elasticsearch_query_helper/lib/services/elasticsearch_service.dart; then
    echo "  ✅ 使用安全JSON解析"
else
    echo "  ❌ 缺少安全JSON解析"
fi

# 检查错误处理
echo "  错误处理:"
if grep -q "catch.*Exception" elasticsearch_query_helper/lib/services/elasticsearch_service.dart; then
    echo "  ✅ 有错误处理机制"
else
    echo "  ❌ 缺少错误处理"
fi

echo ""
echo "🎯 可能的问题原因:"
echo "  1. Elasticsearch连接问题 - 检查连接配置"
echo "  2. API端点访问权限问题 - 检查Elasticsearch配置"
echo "  3. 数据格式解析问题 - 检查响应格式"
echo "  4. 网络连接问题 - 检查网络状态"
echo "  5. 版本兼容性问题 - 检查Elasticsearch版本"

echo ""
echo "🔧 建议的调试步骤:"
echo "  1. 检查Elasticsearch服务是否正常运行"
echo "  2. 验证连接配置（主机、端口、认证）"
echo "  3. 测试/_cat/indices端点是否可访问"
echo "  4. 查看应用日志中的错误信息"
echo "  5. 添加调试日志到loadIndices方法"

echo ""
echo "📝 需要检查的具体问题:"
echo "  - provider.indices 是否为空列表"
echo "  - provider.isLoading 状态是否正确"
echo "  - provider.error 是否有错误信息"
echo "  - 连接状态 provider.isConnected 是否为true"