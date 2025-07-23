import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'elasticsearch_config.g.dart';

@JsonSerializable()
class ElasticsearchConfig {
  final String name;
  final String host;
  final int port;
  final String scheme;
  final String? username;
  final String? password;
  final String? apiKey;
  final String version; // v6, v7, v8
  final String? indexPattern;

  const ElasticsearchConfig({
    this.name = '',
    required this.host,
    this.port = 9200,
    this.scheme = 'http',
    this.username,
    this.password,
    this.apiKey,
    required this.version,
    this.indexPattern,
  });

  String get baseUrl => '$scheme://$host:$port';

  Map<String, String> get headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (apiKey != null) {
      headers['Authorization'] = 'ApiKey $apiKey';
    } else if (username != null && password != null) {
      final credentials = '$username:$password';
      final encoded = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encoded';
    }

    return headers;
  }

  factory ElasticsearchConfig.fromJson(Map<String, dynamic> json) =>
      _$ElasticsearchConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ElasticsearchConfigToJson(this);

  ElasticsearchConfig copyWith({
    String? name,
    String? host,
    int? port,
    String? scheme,
    String? username,
    String? password,
    String? apiKey,
    String? version,
    String? indexPattern,
  }) {
    return ElasticsearchConfig(
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      scheme: scheme ?? this.scheme,
      username: username ?? this.username,
      password: password ?? this.password,
      apiKey: apiKey ?? this.apiKey,
      version: version ?? this.version,
      indexPattern: indexPattern ?? this.indexPattern,
    );
  }
}