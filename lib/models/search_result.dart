import 'package:json_annotation/json_annotation.dart';

part 'search_result.g.dart';

@JsonSerializable()
class SearchResult {
  final int? took;  // Made nullable in case it's missing in some responses
  @JsonKey(name: 'timed_out')
  final bool? timedOut;  // Made nullable in case it's missing in some responses
  @JsonKey(name: '_shards')
  final Map<String, dynamic>? shards;
  final SearchHits hits;

  const SearchResult({
    this.took,  // Made optional
    this.timedOut,  // Made optional
    this.shards,
    required this.hits,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultToJson(this);
}

@JsonSerializable()
class SearchHits {
  final SearchTotal total;
  @JsonKey(name: 'max_score')
  final double? maxScore;
  final List<SearchHit> hits;

  const SearchHits({
    required this.total,
    this.maxScore,
    required this.hits,
  });

  factory SearchHits.fromJson(Map<String, dynamic> json) =>
      _$SearchHitsFromJson(json);

  Map<String, dynamic> toJson() => _$SearchHitsToJson(this);
}

@JsonSerializable()
class SearchTotal {
  final int value;
  final String relation;

  const SearchTotal({
    required this.value,
    this.relation = 'eq',
  });

  factory SearchTotal.fromJson(dynamic json) {
    // Handle different versions of Elasticsearch
    if (json is int) {
      return SearchTotal(value: json);
    }
    if (json is Map<String, dynamic>) {
      return _$SearchTotalFromJson(json);
    }
    // Fallback for direct value
    return SearchTotal(value: json['value'] ?? 0);
  }

  Map<String, dynamic> toJson() => _$SearchTotalToJson(this);
}

@JsonSerializable()
class SearchHit {
  @JsonKey(name: '_index')
  final String index;
  @JsonKey(name: '_type')
  final String? type;  // Made nullable since ES 8.x doesn't always include _type
  @JsonKey(name: '_id')
  final String id;
  @JsonKey(name: '_score')
  final double? score;
  @JsonKey(name: '_source')
  final Map<String, dynamic> source;
  final Map<String, dynamic>? highlight;
  final Map<String, List<dynamic>>? sort;

  const SearchHit({
    required this.index,
    this.type,  // Made optional
    required this.id,
    this.score,
    required this.source,
    this.highlight,
    this.sort,
  });

  factory SearchHit.fromJson(Map<String, dynamic> json) =>
      _$SearchHitFromJson(json);

  Map<String, dynamic> toJson() => _$SearchHitToJson(this);
}

@JsonSerializable()
class ElasticsearchError {
  final String type;
  final String reason;
  final String? index;
  final String? shard;

  const ElasticsearchError({
    required this.type,
    required this.reason,
    this.index,
    this.shard,
  });

  factory ElasticsearchError.fromJson(Map<String, dynamic> json) =>
      _$ElasticsearchErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ElasticsearchErrorToJson(this);
}

class QueryTemplate {
  final String name;
  final String description;
  final Map<String, dynamic> query;
  final List<String> supportedVersions;

  const QueryTemplate({
    required this.name,
    required this.description,
    required this.query,
    required this.supportedVersions,
  });
}