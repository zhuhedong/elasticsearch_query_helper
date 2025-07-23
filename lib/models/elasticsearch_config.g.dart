// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'elasticsearch_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ElasticsearchConfig _$ElasticsearchConfigFromJson(Map<String, dynamic> json) =>
    ElasticsearchConfig(
      name: json['name'] as String? ?? '',
      host: json['host'] as String,
      port: (json['port'] as num?)?.toInt() ?? 9200,
      scheme: json['scheme'] as String? ?? 'http',
      username: json['username'] as String?,
      password: json['password'] as String?,
      apiKey: json['apiKey'] as String?,
      version: json['version'] as String,
      indexPattern: json['indexPattern'] as String?,
    );

Map<String, dynamic> _$ElasticsearchConfigToJson(
        ElasticsearchConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'host': instance.host,
      'port': instance.port,
      'scheme': instance.scheme,
      'username': instance.username,
      'password': instance.password,
      'apiKey': instance.apiKey,
      'version': instance.version,
      'indexPattern': instance.indexPattern,
    };
