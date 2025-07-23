// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResult _$SearchResultFromJson(Map<String, dynamic> json) => SearchResult(
      took: (json['took'] as num?)?.toInt(),
      timedOut: json['timed_out'] as bool?,
      shards: json['_shards'] as Map<String, dynamic>?,
      hits: SearchHits.fromJson(json['hits'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchResultToJson(SearchResult instance) =>
    <String, dynamic>{
      'took': instance.took,
      'timed_out': instance.timedOut,
      '_shards': instance.shards,
      'hits': instance.hits,
    };

SearchHits _$SearchHitsFromJson(Map<String, dynamic> json) => SearchHits(
      total: SearchTotal.fromJson(json['total']),
      maxScore: (json['max_score'] as num?)?.toDouble(),
      hits: (json['hits'] as List<dynamic>)
          .map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchHitsToJson(SearchHits instance) =>
    <String, dynamic>{
      'total': instance.total,
      'max_score': instance.maxScore,
      'hits': instance.hits,
    };

SearchTotal _$SearchTotalFromJson(Map<String, dynamic> json) => SearchTotal(
      value: (json['value'] as num).toInt(),
      relation: json['relation'] as String? ?? 'eq',
    );

Map<String, dynamic> _$SearchTotalToJson(SearchTotal instance) =>
    <String, dynamic>{
      'value': instance.value,
      'relation': instance.relation,
    };

SearchHit _$SearchHitFromJson(Map<String, dynamic> json) => SearchHit(
      index: json['_index'] as String,
      type: json['_type'] as String?,
      id: json['_id'] as String,
      score: (json['_score'] as num?)?.toDouble(),
      source: json['_source'] as Map<String, dynamic>,
      highlight: json['highlight'] as Map<String, dynamic>?,
      sort: (json['sort'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as List<dynamic>),
      ),
    );

Map<String, dynamic> _$SearchHitToJson(SearchHit instance) => <String, dynamic>{
      '_index': instance.index,
      '_type': instance.type,
      '_id': instance.id,
      '_score': instance.score,
      '_source': instance.source,
      'highlight': instance.highlight,
      'sort': instance.sort,
    };

ElasticsearchError _$ElasticsearchErrorFromJson(Map<String, dynamic> json) =>
    ElasticsearchError(
      type: json['type'] as String,
      reason: json['reason'] as String,
      index: json['index'] as String?,
      shard: json['shard'] as String?,
    );

Map<String, dynamic> _$ElasticsearchErrorToJson(ElasticsearchError instance) =>
    <String, dynamic>{
      'type': instance.type,
      'reason': instance.reason,
      'index': instance.index,
      'shard': instance.shard,
    };
