// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ImagesTable extends Images with TableInfo<$ImagesTable, Image> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<int> takenAt = GeneratedColumn<int>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _indexedAtMeta = const VerificationMeta(
    'indexedAt',
  );
  @override
  late final GeneratedColumn<int> indexedAt = GeneratedColumn<int>(
    'indexed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phashMeta = const VerificationMeta('phash');
  @override
  late final GeneratedColumn<int> phash = GeneratedColumn<int>(
    'phash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _semanticVectorMeta = const VerificationMeta(
    'semanticVector',
  );
  @override
  late final GeneratedColumn<Uint8List> semanticVector =
      GeneratedColumn<Uint8List>(
        'semantic_vector',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isScreenshotMeta = const VerificationMeta(
    'isScreenshot',
  );
  @override
  late final GeneratedColumn<bool> isScreenshot = GeneratedColumn<bool>(
    'is_screenshot',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_screenshot" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasTextMeta = const VerificationMeta(
    'hasText',
  );
  @override
  late final GeneratedColumn<bool> hasText = GeneratedColumn<bool>(
    'has_text',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_text" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blurScoreMeta = const VerificationMeta(
    'blurScore',
  );
  @override
  late final GeneratedColumn<double> blurScore = GeneratedColumn<double>(
    'blur_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dominantHueMeta = const VerificationMeta(
    'dominantHue',
  );
  @override
  late final GeneratedColumn<double> dominantHue = GeneratedColumn<double>(
    'dominant_hue',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorWarmthMeta = const VerificationMeta(
    'colorWarmth',
  );
  @override
  late final GeneratedColumn<double> colorWarmth = GeneratedColumn<double>(
    'color_warmth',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clusterIdMeta = const VerificationMeta(
    'clusterId',
  );
  @override
  late final GeneratedColumn<String> clusterId = GeneratedColumn<String>(
    'cluster_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLatMeta = const VerificationMeta('gpsLat');
  @override
  late final GeneratedColumn<double> gpsLat = GeneratedColumn<double>(
    'gps_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gpsLonMeta = const VerificationMeta('gpsLon');
  @override
  late final GeneratedColumn<double> gpsLon = GeneratedColumn<double>(
    'gps_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    fileName,
    width,
    height,
    fileSize,
    takenAt,
    indexedAt,
    phash,
    semanticVector,
    isScreenshot,
    hasText,
    tags,
    blurScore,
    dominantHue,
    colorWarmth,
    clusterId,
    gpsLat,
    gpsLon,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'images';
  @override
  VerificationContext validateIntegrity(
    Insertable<Image> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('indexed_at')) {
      context.handle(
        _indexedAtMeta,
        indexedAt.isAcceptableOrUnknown(data['indexed_at']!, _indexedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_indexedAtMeta);
    }
    if (data.containsKey('phash')) {
      context.handle(
        _phashMeta,
        phash.isAcceptableOrUnknown(data['phash']!, _phashMeta),
      );
    }
    if (data.containsKey('semantic_vector')) {
      context.handle(
        _semanticVectorMeta,
        semanticVector.isAcceptableOrUnknown(
          data['semantic_vector']!,
          _semanticVectorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_semanticVectorMeta);
    }
    if (data.containsKey('is_screenshot')) {
      context.handle(
        _isScreenshotMeta,
        isScreenshot.isAcceptableOrUnknown(
          data['is_screenshot']!,
          _isScreenshotMeta,
        ),
      );
    }
    if (data.containsKey('has_text')) {
      context.handle(
        _hasTextMeta,
        hasText.isAcceptableOrUnknown(data['has_text']!, _hasTextMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('blur_score')) {
      context.handle(
        _blurScoreMeta,
        blurScore.isAcceptableOrUnknown(data['blur_score']!, _blurScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_blurScoreMeta);
    }
    if (data.containsKey('dominant_hue')) {
      context.handle(
        _dominantHueMeta,
        dominantHue.isAcceptableOrUnknown(
          data['dominant_hue']!,
          _dominantHueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dominantHueMeta);
    }
    if (data.containsKey('color_warmth')) {
      context.handle(
        _colorWarmthMeta,
        colorWarmth.isAcceptableOrUnknown(
          data['color_warmth']!,
          _colorWarmthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_colorWarmthMeta);
    }
    if (data.containsKey('cluster_id')) {
      context.handle(
        _clusterIdMeta,
        clusterId.isAcceptableOrUnknown(data['cluster_id']!, _clusterIdMeta),
      );
    }
    if (data.containsKey('gps_lat')) {
      context.handle(
        _gpsLatMeta,
        gpsLat.isAcceptableOrUnknown(data['gps_lat']!, _gpsLatMeta),
      );
    }
    if (data.containsKey('gps_lon')) {
      context.handle(
        _gpsLonMeta,
        gpsLon.isAcceptableOrUnknown(data['gps_lon']!, _gpsLonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Image map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Image(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}taken_at'],
      ),
      indexedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}indexed_at'],
      )!,
      phash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phash'],
      ),
      semanticVector: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}semantic_vector'],
      )!,
      isScreenshot: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_screenshot'],
      )!,
      hasText: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_text'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      blurScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}blur_score'],
      )!,
      dominantHue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dominant_hue'],
      )!,
      colorWarmth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}color_warmth'],
      )!,
      clusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cluster_id'],
      ),
      gpsLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lat'],
      ),
      gpsLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_lon'],
      ),
    );
  }

  @override
  $ImagesTable createAlias(String alias) {
    return $ImagesTable(attachedDatabase, alias);
  }
}

class Image extends DataClass implements Insertable<Image> {
  final String id;
  final String filePath;
  final String fileName;
  final int width;
  final int height;
  final int fileSize;
  final int? takenAt;
  final int indexedAt;
  final int? phash;
  final Uint8List semanticVector;
  final bool isScreenshot;
  final bool hasText;
  final String? tags;
  final double blurScore;
  final double dominantHue;
  final double colorWarmth;
  final String? clusterId;
  final double? gpsLat;
  final double? gpsLon;
  const Image({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.width,
    required this.height,
    required this.fileSize,
    this.takenAt,
    required this.indexedAt,
    this.phash,
    required this.semanticVector,
    required this.isScreenshot,
    required this.hasText,
    this.tags,
    required this.blurScore,
    required this.dominantHue,
    required this.colorWarmth,
    this.clusterId,
    this.gpsLat,
    this.gpsLon,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_path'] = Variable<String>(filePath);
    map['file_name'] = Variable<String>(fileName);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<int>(takenAt);
    }
    map['indexed_at'] = Variable<int>(indexedAt);
    if (!nullToAbsent || phash != null) {
      map['phash'] = Variable<int>(phash);
    }
    map['semantic_vector'] = Variable<Uint8List>(semanticVector);
    map['is_screenshot'] = Variable<bool>(isScreenshot);
    map['has_text'] = Variable<bool>(hasText);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['blur_score'] = Variable<double>(blurScore);
    map['dominant_hue'] = Variable<double>(dominantHue);
    map['color_warmth'] = Variable<double>(colorWarmth);
    if (!nullToAbsent || clusterId != null) {
      map['cluster_id'] = Variable<String>(clusterId);
    }
    if (!nullToAbsent || gpsLat != null) {
      map['gps_lat'] = Variable<double>(gpsLat);
    }
    if (!nullToAbsent || gpsLon != null) {
      map['gps_lon'] = Variable<double>(gpsLon);
    }
    return map;
  }

  ImagesCompanion toCompanion(bool nullToAbsent) {
    return ImagesCompanion(
      id: Value(id),
      filePath: Value(filePath),
      fileName: Value(fileName),
      width: Value(width),
      height: Value(height),
      fileSize: Value(fileSize),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      indexedAt: Value(indexedAt),
      phash: phash == null && nullToAbsent
          ? const Value.absent()
          : Value(phash),
      semanticVector: Value(semanticVector),
      isScreenshot: Value(isScreenshot),
      hasText: Value(hasText),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      blurScore: Value(blurScore),
      dominantHue: Value(dominantHue),
      colorWarmth: Value(colorWarmth),
      clusterId: clusterId == null && nullToAbsent
          ? const Value.absent()
          : Value(clusterId),
      gpsLat: gpsLat == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLat),
      gpsLon: gpsLon == null && nullToAbsent
          ? const Value.absent()
          : Value(gpsLon),
    );
  }

  factory Image.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Image(
      id: serializer.fromJson<String>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      takenAt: serializer.fromJson<int?>(json['takenAt']),
      indexedAt: serializer.fromJson<int>(json['indexedAt']),
      phash: serializer.fromJson<int?>(json['phash']),
      semanticVector: serializer.fromJson<Uint8List>(json['semanticVector']),
      isScreenshot: serializer.fromJson<bool>(json['isScreenshot']),
      hasText: serializer.fromJson<bool>(json['hasText']),
      tags: serializer.fromJson<String?>(json['tags']),
      blurScore: serializer.fromJson<double>(json['blurScore']),
      dominantHue: serializer.fromJson<double>(json['dominantHue']),
      colorWarmth: serializer.fromJson<double>(json['colorWarmth']),
      clusterId: serializer.fromJson<String?>(json['clusterId']),
      gpsLat: serializer.fromJson<double?>(json['gpsLat']),
      gpsLon: serializer.fromJson<double?>(json['gpsLon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filePath': serializer.toJson<String>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'fileSize': serializer.toJson<int>(fileSize),
      'takenAt': serializer.toJson<int?>(takenAt),
      'indexedAt': serializer.toJson<int>(indexedAt),
      'phash': serializer.toJson<int?>(phash),
      'semanticVector': serializer.toJson<Uint8List>(semanticVector),
      'isScreenshot': serializer.toJson<bool>(isScreenshot),
      'hasText': serializer.toJson<bool>(hasText),
      'tags': serializer.toJson<String?>(tags),
      'blurScore': serializer.toJson<double>(blurScore),
      'dominantHue': serializer.toJson<double>(dominantHue),
      'colorWarmth': serializer.toJson<double>(colorWarmth),
      'clusterId': serializer.toJson<String?>(clusterId),
      'gpsLat': serializer.toJson<double?>(gpsLat),
      'gpsLon': serializer.toJson<double?>(gpsLon),
    };
  }

  Image copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? width,
    int? height,
    int? fileSize,
    Value<int?> takenAt = const Value.absent(),
    int? indexedAt,
    Value<int?> phash = const Value.absent(),
    Uint8List? semanticVector,
    bool? isScreenshot,
    bool? hasText,
    Value<String?> tags = const Value.absent(),
    double? blurScore,
    double? dominantHue,
    double? colorWarmth,
    Value<String?> clusterId = const Value.absent(),
    Value<double?> gpsLat = const Value.absent(),
    Value<double?> gpsLon = const Value.absent(),
  }) => Image(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    fileName: fileName ?? this.fileName,
    width: width ?? this.width,
    height: height ?? this.height,
    fileSize: fileSize ?? this.fileSize,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    indexedAt: indexedAt ?? this.indexedAt,
    phash: phash.present ? phash.value : this.phash,
    semanticVector: semanticVector ?? this.semanticVector,
    isScreenshot: isScreenshot ?? this.isScreenshot,
    hasText: hasText ?? this.hasText,
    tags: tags.present ? tags.value : this.tags,
    blurScore: blurScore ?? this.blurScore,
    dominantHue: dominantHue ?? this.dominantHue,
    colorWarmth: colorWarmth ?? this.colorWarmth,
    clusterId: clusterId.present ? clusterId.value : this.clusterId,
    gpsLat: gpsLat.present ? gpsLat.value : this.gpsLat,
    gpsLon: gpsLon.present ? gpsLon.value : this.gpsLon,
  );
  Image copyWithCompanion(ImagesCompanion data) {
    return Image(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      indexedAt: data.indexedAt.present ? data.indexedAt.value : this.indexedAt,
      phash: data.phash.present ? data.phash.value : this.phash,
      semanticVector: data.semanticVector.present
          ? data.semanticVector.value
          : this.semanticVector,
      isScreenshot: data.isScreenshot.present
          ? data.isScreenshot.value
          : this.isScreenshot,
      hasText: data.hasText.present ? data.hasText.value : this.hasText,
      tags: data.tags.present ? data.tags.value : this.tags,
      blurScore: data.blurScore.present ? data.blurScore.value : this.blurScore,
      dominantHue: data.dominantHue.present
          ? data.dominantHue.value
          : this.dominantHue,
      colorWarmth: data.colorWarmth.present
          ? data.colorWarmth.value
          : this.colorWarmth,
      clusterId: data.clusterId.present ? data.clusterId.value : this.clusterId,
      gpsLat: data.gpsLat.present ? data.gpsLat.value : this.gpsLat,
      gpsLon: data.gpsLon.present ? data.gpsLon.value : this.gpsLon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Image(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('takenAt: $takenAt, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('phash: $phash, ')
          ..write('semanticVector: $semanticVector, ')
          ..write('isScreenshot: $isScreenshot, ')
          ..write('hasText: $hasText, ')
          ..write('tags: $tags, ')
          ..write('blurScore: $blurScore, ')
          ..write('dominantHue: $dominantHue, ')
          ..write('colorWarmth: $colorWarmth, ')
          ..write('clusterId: $clusterId, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLon: $gpsLon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    fileName,
    width,
    height,
    fileSize,
    takenAt,
    indexedAt,
    phash,
    $driftBlobEquality.hash(semanticVector),
    isScreenshot,
    hasText,
    tags,
    blurScore,
    dominantHue,
    colorWarmth,
    clusterId,
    gpsLat,
    gpsLon,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Image &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.width == this.width &&
          other.height == this.height &&
          other.fileSize == this.fileSize &&
          other.takenAt == this.takenAt &&
          other.indexedAt == this.indexedAt &&
          other.phash == this.phash &&
          $driftBlobEquality.equals(
            other.semanticVector,
            this.semanticVector,
          ) &&
          other.isScreenshot == this.isScreenshot &&
          other.hasText == this.hasText &&
          other.tags == this.tags &&
          other.blurScore == this.blurScore &&
          other.dominantHue == this.dominantHue &&
          other.colorWarmth == this.colorWarmth &&
          other.clusterId == this.clusterId &&
          other.gpsLat == this.gpsLat &&
          other.gpsLon == this.gpsLon);
}

class ImagesCompanion extends UpdateCompanion<Image> {
  final Value<String> id;
  final Value<String> filePath;
  final Value<String> fileName;
  final Value<int> width;
  final Value<int> height;
  final Value<int> fileSize;
  final Value<int?> takenAt;
  final Value<int> indexedAt;
  final Value<int?> phash;
  final Value<Uint8List> semanticVector;
  final Value<bool> isScreenshot;
  final Value<bool> hasText;
  final Value<String?> tags;
  final Value<double> blurScore;
  final Value<double> dominantHue;
  final Value<double> colorWarmth;
  final Value<String?> clusterId;
  final Value<double?> gpsLat;
  final Value<double?> gpsLon;
  final Value<int> rowid;
  const ImagesCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.indexedAt = const Value.absent(),
    this.phash = const Value.absent(),
    this.semanticVector = const Value.absent(),
    this.isScreenshot = const Value.absent(),
    this.hasText = const Value.absent(),
    this.tags = const Value.absent(),
    this.blurScore = const Value.absent(),
    this.dominantHue = const Value.absent(),
    this.colorWarmth = const Value.absent(),
    this.clusterId = const Value.absent(),
    this.gpsLat = const Value.absent(),
    this.gpsLon = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImagesCompanion.insert({
    required String id,
    required String filePath,
    required String fileName,
    required int width,
    required int height,
    required int fileSize,
    this.takenAt = const Value.absent(),
    required int indexedAt,
    this.phash = const Value.absent(),
    required Uint8List semanticVector,
    this.isScreenshot = const Value.absent(),
    this.hasText = const Value.absent(),
    this.tags = const Value.absent(),
    required double blurScore,
    required double dominantHue,
    required double colorWarmth,
    this.clusterId = const Value.absent(),
    this.gpsLat = const Value.absent(),
    this.gpsLon = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       filePath = Value(filePath),
       fileName = Value(fileName),
       width = Value(width),
       height = Value(height),
       fileSize = Value(fileSize),
       indexedAt = Value(indexedAt),
       semanticVector = Value(semanticVector),
       blurScore = Value(blurScore),
       dominantHue = Value(dominantHue),
       colorWarmth = Value(colorWarmth);
  static Insertable<Image> custom({
    Expression<String>? id,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? fileSize,
    Expression<int>? takenAt,
    Expression<int>? indexedAt,
    Expression<int>? phash,
    Expression<Uint8List>? semanticVector,
    Expression<bool>? isScreenshot,
    Expression<bool>? hasText,
    Expression<String>? tags,
    Expression<double>? blurScore,
    Expression<double>? dominantHue,
    Expression<double>? colorWarmth,
    Expression<String>? clusterId,
    Expression<double>? gpsLat,
    Expression<double>? gpsLon,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fileSize != null) 'file_size': fileSize,
      if (takenAt != null) 'taken_at': takenAt,
      if (indexedAt != null) 'indexed_at': indexedAt,
      if (phash != null) 'phash': phash,
      if (semanticVector != null) 'semantic_vector': semanticVector,
      if (isScreenshot != null) 'is_screenshot': isScreenshot,
      if (hasText != null) 'has_text': hasText,
      if (tags != null) 'tags': tags,
      if (blurScore != null) 'blur_score': blurScore,
      if (dominantHue != null) 'dominant_hue': dominantHue,
      if (colorWarmth != null) 'color_warmth': colorWarmth,
      if (clusterId != null) 'cluster_id': clusterId,
      if (gpsLat != null) 'gps_lat': gpsLat,
      if (gpsLon != null) 'gps_lon': gpsLon,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImagesCompanion copyWith({
    Value<String>? id,
    Value<String>? filePath,
    Value<String>? fileName,
    Value<int>? width,
    Value<int>? height,
    Value<int>? fileSize,
    Value<int?>? takenAt,
    Value<int>? indexedAt,
    Value<int?>? phash,
    Value<Uint8List>? semanticVector,
    Value<bool>? isScreenshot,
    Value<bool>? hasText,
    Value<String?>? tags,
    Value<double>? blurScore,
    Value<double>? dominantHue,
    Value<double>? colorWarmth,
    Value<String?>? clusterId,
    Value<double?>? gpsLat,
    Value<double?>? gpsLon,
    Value<int>? rowid,
  }) {
    return ImagesCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      takenAt: takenAt ?? this.takenAt,
      indexedAt: indexedAt ?? this.indexedAt,
      phash: phash ?? this.phash,
      semanticVector: semanticVector ?? this.semanticVector,
      isScreenshot: isScreenshot ?? this.isScreenshot,
      hasText: hasText ?? this.hasText,
      tags: tags ?? this.tags,
      blurScore: blurScore ?? this.blurScore,
      dominantHue: dominantHue ?? this.dominantHue,
      colorWarmth: colorWarmth ?? this.colorWarmth,
      clusterId: clusterId ?? this.clusterId,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLon: gpsLon ?? this.gpsLon,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<int>(takenAt.value);
    }
    if (indexedAt.present) {
      map['indexed_at'] = Variable<int>(indexedAt.value);
    }
    if (phash.present) {
      map['phash'] = Variable<int>(phash.value);
    }
    if (semanticVector.present) {
      map['semantic_vector'] = Variable<Uint8List>(semanticVector.value);
    }
    if (isScreenshot.present) {
      map['is_screenshot'] = Variable<bool>(isScreenshot.value);
    }
    if (hasText.present) {
      map['has_text'] = Variable<bool>(hasText.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (blurScore.present) {
      map['blur_score'] = Variable<double>(blurScore.value);
    }
    if (dominantHue.present) {
      map['dominant_hue'] = Variable<double>(dominantHue.value);
    }
    if (colorWarmth.present) {
      map['color_warmth'] = Variable<double>(colorWarmth.value);
    }
    if (clusterId.present) {
      map['cluster_id'] = Variable<String>(clusterId.value);
    }
    if (gpsLat.present) {
      map['gps_lat'] = Variable<double>(gpsLat.value);
    }
    if (gpsLon.present) {
      map['gps_lon'] = Variable<double>(gpsLon.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImagesCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('takenAt: $takenAt, ')
          ..write('indexedAt: $indexedAt, ')
          ..write('phash: $phash, ')
          ..write('semanticVector: $semanticVector, ')
          ..write('isScreenshot: $isScreenshot, ')
          ..write('hasText: $hasText, ')
          ..write('tags: $tags, ')
          ..write('blurScore: $blurScore, ')
          ..write('dominantHue: $dominantHue, ')
          ..write('colorWarmth: $colorWarmth, ')
          ..write('clusterId: $clusterId, ')
          ..write('gpsLat: $gpsLat, ')
          ..write('gpsLon: $gpsLon, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmartFoldersTable extends SmartFolders
    with TableInfo<$SmartFoldersTable, SmartFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootRuleIdMeta = const VerificationMeta(
    'rootRuleId',
  );
  @override
  late final GeneratedColumn<String> rootRuleId = GeneratedColumn<String>(
    'root_rule_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMatchedAtMeta = const VerificationMeta(
    'lastMatchedAt',
  );
  @override
  late final GeneratedColumn<int> lastMatchedAt = GeneratedColumn<int>(
    'last_matched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exportPathMeta = const VerificationMeta(
    'exportPath',
  );
  @override
  late final GeneratedColumn<String> exportPath = GeneratedColumn<String>(
    'export_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exportModeMeta = const VerificationMeta(
    'exportMode',
  );
  @override
  late final GeneratedColumn<String> exportMode = GeneratedColumn<String>(
    'export_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastExportedAtMeta = const VerificationMeta(
    'lastExportedAt',
  );
  @override
  late final GeneratedColumn<int> lastExportedAt = GeneratedColumn<int>(
    'last_exported_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    color,
    rootRuleId,
    sortOrder,
    createdAt,
    lastMatchedAt,
    exportPath,
    exportMode,
    lastExportedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('root_rule_id')) {
      context.handle(
        _rootRuleIdMeta,
        rootRuleId.isAcceptableOrUnknown(
          data['root_rule_id']!,
          _rootRuleIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_matched_at')) {
      context.handle(
        _lastMatchedAtMeta,
        lastMatchedAt.isAcceptableOrUnknown(
          data['last_matched_at']!,
          _lastMatchedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastMatchedAtMeta);
    }
    if (data.containsKey('export_path')) {
      context.handle(
        _exportPathMeta,
        exportPath.isAcceptableOrUnknown(data['export_path']!, _exportPathMeta),
      );
    }
    if (data.containsKey('export_mode')) {
      context.handle(
        _exportModeMeta,
        exportMode.isAcceptableOrUnknown(data['export_mode']!, _exportModeMeta),
      );
    }
    if (data.containsKey('last_exported_at')) {
      context.handle(
        _lastExportedAtMeta,
        lastExportedAt.isAcceptableOrUnknown(
          data['last_exported_at']!,
          _lastExportedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmartFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      rootRuleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_rule_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastMatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_matched_at'],
      )!,
      exportPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}export_path'],
      ),
      exportMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}export_mode'],
      ),
      lastExportedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_exported_at'],
      ),
    );
  }

  @override
  $SmartFoldersTable createAlias(String alias) {
    return $SmartFoldersTable(attachedDatabase, alias);
  }
}

class SmartFolder extends DataClass implements Insertable<SmartFolder> {
  final String id;
  final String name;
  final String icon;
  final int color;
  final String? rootRuleId;
  final int sortOrder;
  final int createdAt;
  final int lastMatchedAt;
  final String? exportPath;
  final String? exportMode;
  final int? lastExportedAt;
  const SmartFolder({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.rootRuleId,
    required this.sortOrder,
    required this.createdAt,
    required this.lastMatchedAt,
    this.exportPath,
    this.exportMode,
    this.lastExportedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || rootRuleId != null) {
      map['root_rule_id'] = Variable<String>(rootRuleId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['last_matched_at'] = Variable<int>(lastMatchedAt);
    if (!nullToAbsent || exportPath != null) {
      map['export_path'] = Variable<String>(exportPath);
    }
    if (!nullToAbsent || exportMode != null) {
      map['export_mode'] = Variable<String>(exportMode);
    }
    if (!nullToAbsent || lastExportedAt != null) {
      map['last_exported_at'] = Variable<int>(lastExportedAt);
    }
    return map;
  }

  SmartFoldersCompanion toCompanion(bool nullToAbsent) {
    return SmartFoldersCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      rootRuleId: rootRuleId == null && nullToAbsent
          ? const Value.absent()
          : Value(rootRuleId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      lastMatchedAt: Value(lastMatchedAt),
      exportPath: exportPath == null && nullToAbsent
          ? const Value.absent()
          : Value(exportPath),
      exportMode: exportMode == null && nullToAbsent
          ? const Value.absent()
          : Value(exportMode),
      lastExportedAt: lastExportedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExportedAt),
    );
  }

  factory SmartFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartFolder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      rootRuleId: serializer.fromJson<String?>(json['rootRuleId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastMatchedAt: serializer.fromJson<int>(json['lastMatchedAt']),
      exportPath: serializer.fromJson<String?>(json['exportPath']),
      exportMode: serializer.fromJson<String?>(json['exportMode']),
      lastExportedAt: serializer.fromJson<int?>(json['lastExportedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'rootRuleId': serializer.toJson<String?>(rootRuleId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastMatchedAt': serializer.toJson<int>(lastMatchedAt),
      'exportPath': serializer.toJson<String?>(exportPath),
      'exportMode': serializer.toJson<String?>(exportMode),
      'lastExportedAt': serializer.toJson<int?>(lastExportedAt),
    };
  }

  SmartFolder copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    Value<String?> rootRuleId = const Value.absent(),
    int? sortOrder,
    int? createdAt,
    int? lastMatchedAt,
    Value<String?> exportPath = const Value.absent(),
    Value<String?> exportMode = const Value.absent(),
    Value<int?> lastExportedAt = const Value.absent(),
  }) => SmartFolder(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    rootRuleId: rootRuleId.present ? rootRuleId.value : this.rootRuleId,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    lastMatchedAt: lastMatchedAt ?? this.lastMatchedAt,
    exportPath: exportPath.present ? exportPath.value : this.exportPath,
    exportMode: exportMode.present ? exportMode.value : this.exportMode,
    lastExportedAt: lastExportedAt.present
        ? lastExportedAt.value
        : this.lastExportedAt,
  );
  SmartFolder copyWithCompanion(SmartFoldersCompanion data) {
    return SmartFolder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      rootRuleId: data.rootRuleId.present
          ? data.rootRuleId.value
          : this.rootRuleId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastMatchedAt: data.lastMatchedAt.present
          ? data.lastMatchedAt.value
          : this.lastMatchedAt,
      exportPath: data.exportPath.present
          ? data.exportPath.value
          : this.exportPath,
      exportMode: data.exportMode.present
          ? data.exportMode.value
          : this.exportMode,
      lastExportedAt: data.lastExportedAt.present
          ? data.lastExportedAt.value
          : this.lastExportedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartFolder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('rootRuleId: $rootRuleId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMatchedAt: $lastMatchedAt, ')
          ..write('exportPath: $exportPath, ')
          ..write('exportMode: $exportMode, ')
          ..write('lastExportedAt: $lastExportedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    icon,
    color,
    rootRuleId,
    sortOrder,
    createdAt,
    lastMatchedAt,
    exportPath,
    exportMode,
    lastExportedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartFolder &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.rootRuleId == this.rootRuleId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.lastMatchedAt == this.lastMatchedAt &&
          other.exportPath == this.exportPath &&
          other.exportMode == this.exportMode &&
          other.lastExportedAt == this.lastExportedAt);
}

class SmartFoldersCompanion extends UpdateCompanion<SmartFolder> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> color;
  final Value<String?> rootRuleId;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> lastMatchedAt;
  final Value<String?> exportPath;
  final Value<String?> exportMode;
  final Value<int?> lastExportedAt;
  final Value<int> rowid;
  const SmartFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.rootRuleId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastMatchedAt = const Value.absent(),
    this.exportPath = const Value.absent(),
    this.exportMode = const Value.absent(),
    this.lastExportedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmartFoldersCompanion.insert({
    required String id,
    required String name,
    required String icon,
    required int color,
    this.rootRuleId = const Value.absent(),
    required int sortOrder,
    required int createdAt,
    required int lastMatchedAt,
    this.exportPath = const Value.absent(),
    this.exportMode = const Value.absent(),
    this.lastExportedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       icon = Value(icon),
       color = Value(color),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       lastMatchedAt = Value(lastMatchedAt);
  static Insertable<SmartFolder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<String>? rootRuleId,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? lastMatchedAt,
    Expression<String>? exportPath,
    Expression<String>? exportMode,
    Expression<int>? lastExportedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (rootRuleId != null) 'root_rule_id': rootRuleId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (lastMatchedAt != null) 'last_matched_at': lastMatchedAt,
      if (exportPath != null) 'export_path': exportPath,
      if (exportMode != null) 'export_mode': exportMode,
      if (lastExportedAt != null) 'last_exported_at': lastExportedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmartFoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<int>? color,
    Value<String?>? rootRuleId,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? lastMatchedAt,
    Value<String?>? exportPath,
    Value<String?>? exportMode,
    Value<int?>? lastExportedAt,
    Value<int>? rowid,
  }) {
    return SmartFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      rootRuleId: rootRuleId ?? this.rootRuleId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      lastMatchedAt: lastMatchedAt ?? this.lastMatchedAt,
      exportPath: exportPath ?? this.exportPath,
      exportMode: exportMode ?? this.exportMode,
      lastExportedAt: lastExportedAt ?? this.lastExportedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (rootRuleId.present) {
      map['root_rule_id'] = Variable<String>(rootRuleId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastMatchedAt.present) {
      map['last_matched_at'] = Variable<int>(lastMatchedAt.value);
    }
    if (exportPath.present) {
      map['export_path'] = Variable<String>(exportPath.value);
    }
    if (exportMode.present) {
      map['export_mode'] = Variable<String>(exportMode.value);
    }
    if (lastExportedAt.present) {
      map['last_exported_at'] = Variable<int>(lastExportedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmartFoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('rootRuleId: $rootRuleId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastMatchedAt: $lastMatchedAt, ')
          ..write('exportPath: $exportPath, ')
          ..write('exportMode: $exportMode, ')
          ..write('lastExportedAt: $lastExportedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FolderRulesTable extends FolderRules
    with TableInfo<$FolderRulesTable, FolderRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nodeTypeMeta = const VerificationMeta(
    'nodeType',
  );
  @override
  late final GeneratedColumn<String> nodeType = GeneratedColumn<String>(
    'node_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _featureTypeMeta = const VerificationMeta(
    'featureType',
  );
  @override
  late final GeneratedColumn<String> featureType = GeneratedColumn<String>(
    'feature_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _comparatorMeta = const VerificationMeta(
    'comparator',
  );
  @override
  late final GeneratedColumn<String> comparator = GeneratedColumn<String>(
    'comparator',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    folderId,
    parentId,
    nodeType,
    featureType,
    comparator,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folder_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('node_type')) {
      context.handle(
        _nodeTypeMeta,
        nodeType.isAcceptableOrUnknown(data['node_type']!, _nodeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeTypeMeta);
    }
    if (data.containsKey('feature_type')) {
      context.handle(
        _featureTypeMeta,
        featureType.isAcceptableOrUnknown(
          data['feature_type']!,
          _featureTypeMeta,
        ),
      );
    }
    if (data.containsKey('comparator')) {
      context.handle(
        _comparatorMeta,
        comparator.isAcceptableOrUnknown(data['comparator']!, _comparatorMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FolderRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      nodeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_type'],
      )!,
      featureType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feature_type'],
      ),
      comparator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comparator'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $FolderRulesTable createAlias(String alias) {
    return $FolderRulesTable(attachedDatabase, alias);
  }
}

class FolderRule extends DataClass implements Insertable<FolderRule> {
  final String id;
  final String folderId;
  final String? parentId;
  final String nodeType;
  final String? featureType;
  final String? comparator;
  final String? value;
  const FolderRule({
    required this.id,
    required this.folderId,
    this.parentId,
    required this.nodeType,
    this.featureType,
    this.comparator,
    this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['folder_id'] = Variable<String>(folderId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['node_type'] = Variable<String>(nodeType);
    if (!nullToAbsent || featureType != null) {
      map['feature_type'] = Variable<String>(featureType);
    }
    if (!nullToAbsent || comparator != null) {
      map['comparator'] = Variable<String>(comparator);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  FolderRulesCompanion toCompanion(bool nullToAbsent) {
    return FolderRulesCompanion(
      id: Value(id),
      folderId: Value(folderId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      nodeType: Value(nodeType),
      featureType: featureType == null && nullToAbsent
          ? const Value.absent()
          : Value(featureType),
      comparator: comparator == null && nullToAbsent
          ? const Value.absent()
          : Value(comparator),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory FolderRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderRule(
      id: serializer.fromJson<String>(json['id']),
      folderId: serializer.fromJson<String>(json['folderId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      nodeType: serializer.fromJson<String>(json['nodeType']),
      featureType: serializer.fromJson<String?>(json['featureType']),
      comparator: serializer.fromJson<String?>(json['comparator']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderId': serializer.toJson<String>(folderId),
      'parentId': serializer.toJson<String?>(parentId),
      'nodeType': serializer.toJson<String>(nodeType),
      'featureType': serializer.toJson<String?>(featureType),
      'comparator': serializer.toJson<String?>(comparator),
      'value': serializer.toJson<String?>(value),
    };
  }

  FolderRule copyWith({
    String? id,
    String? folderId,
    Value<String?> parentId = const Value.absent(),
    String? nodeType,
    Value<String?> featureType = const Value.absent(),
    Value<String?> comparator = const Value.absent(),
    Value<String?> value = const Value.absent(),
  }) => FolderRule(
    id: id ?? this.id,
    folderId: folderId ?? this.folderId,
    parentId: parentId.present ? parentId.value : this.parentId,
    nodeType: nodeType ?? this.nodeType,
    featureType: featureType.present ? featureType.value : this.featureType,
    comparator: comparator.present ? comparator.value : this.comparator,
    value: value.present ? value.value : this.value,
  );
  FolderRule copyWithCompanion(FolderRulesCompanion data) {
    return FolderRule(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      nodeType: data.nodeType.present ? data.nodeType.value : this.nodeType,
      featureType: data.featureType.present
          ? data.featureType.value
          : this.featureType,
      comparator: data.comparator.present
          ? data.comparator.value
          : this.comparator,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderRule(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('parentId: $parentId, ')
          ..write('nodeType: $nodeType, ')
          ..write('featureType: $featureType, ')
          ..write('comparator: $comparator, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    folderId,
    parentId,
    nodeType,
    featureType,
    comparator,
    value,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderRule &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.parentId == this.parentId &&
          other.nodeType == this.nodeType &&
          other.featureType == this.featureType &&
          other.comparator == this.comparator &&
          other.value == this.value);
}

class FolderRulesCompanion extends UpdateCompanion<FolderRule> {
  final Value<String> id;
  final Value<String> folderId;
  final Value<String?> parentId;
  final Value<String> nodeType;
  final Value<String?> featureType;
  final Value<String?> comparator;
  final Value<String?> value;
  final Value<int> rowid;
  const FolderRulesCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.featureType = const Value.absent(),
    this.comparator = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderRulesCompanion.insert({
    required String id,
    required String folderId,
    this.parentId = const Value.absent(),
    required String nodeType,
    this.featureType = const Value.absent(),
    this.comparator = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       folderId = Value(folderId),
       nodeType = Value(nodeType);
  static Insertable<FolderRule> custom({
    Expression<String>? id,
    Expression<String>? folderId,
    Expression<String>? parentId,
    Expression<String>? nodeType,
    Expression<String>? featureType,
    Expression<String>? comparator,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (parentId != null) 'parent_id': parentId,
      if (nodeType != null) 'node_type': nodeType,
      if (featureType != null) 'feature_type': featureType,
      if (comparator != null) 'comparator': comparator,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? folderId,
    Value<String?>? parentId,
    Value<String>? nodeType,
    Value<String?>? featureType,
    Value<String?>? comparator,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return FolderRulesCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      parentId: parentId ?? this.parentId,
      nodeType: nodeType ?? this.nodeType,
      featureType: featureType ?? this.featureType,
      comparator: comparator ?? this.comparator,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (nodeType.present) {
      map['node_type'] = Variable<String>(nodeType.value);
    }
    if (featureType.present) {
      map['feature_type'] = Variable<String>(featureType.value);
    }
    if (comparator.present) {
      map['comparator'] = Variable<String>(comparator.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderRulesCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('parentId: $parentId, ')
          ..write('nodeType: $nodeType, ')
          ..write('featureType: $featureType, ')
          ..write('comparator: $comparator, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClustersTable extends Clusters with TableInfo<$ClustersTable, Cluster> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClustersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centroidVectorMeta = const VerificationMeta(
    'centroidVector',
  );
  @override
  late final GeneratedColumn<Uint8List> centroidVector =
      GeneratedColumn<Uint8List>(
        'centroid_vector',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _imageCountMeta = const VerificationMeta(
    'imageCount',
  );
  @override
  late final GeneratedColumn<int> imageCount = GeneratedColumn<int>(
    'image_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUserNamedMeta = const VerificationMeta(
    'isUserNamed',
  );
  @override
  late final GeneratedColumn<bool> isUserNamed = GeneratedColumn<bool>(
    'is_user_named',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user_named" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    centroidVector,
    imageCount,
    createdAt,
    isUserNamed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clusters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cluster> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('centroid_vector')) {
      context.handle(
        _centroidVectorMeta,
        centroidVector.isAcceptableOrUnknown(
          data['centroid_vector']!,
          _centroidVectorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centroidVectorMeta);
    }
    if (data.containsKey('image_count')) {
      context.handle(
        _imageCountMeta,
        imageCount.isAcceptableOrUnknown(data['image_count']!, _imageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_imageCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_user_named')) {
      context.handle(
        _isUserNamedMeta,
        isUserNamed.isAcceptableOrUnknown(
          data['is_user_named']!,
          _isUserNamedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cluster map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cluster(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      centroidVector: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}centroid_vector'],
      )!,
      imageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}image_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      isUserNamed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user_named'],
      )!,
    );
  }

  @override
  $ClustersTable createAlias(String alias) {
    return $ClustersTable(attachedDatabase, alias);
  }
}

class Cluster extends DataClass implements Insertable<Cluster> {
  final String id;
  final String name;
  final Uint8List centroidVector;
  final int imageCount;
  final int createdAt;
  final bool isUserNamed;
  const Cluster({
    required this.id,
    required this.name,
    required this.centroidVector,
    required this.imageCount,
    required this.createdAt,
    required this.isUserNamed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['centroid_vector'] = Variable<Uint8List>(centroidVector);
    map['image_count'] = Variable<int>(imageCount);
    map['created_at'] = Variable<int>(createdAt);
    map['is_user_named'] = Variable<bool>(isUserNamed);
    return map;
  }

  ClustersCompanion toCompanion(bool nullToAbsent) {
    return ClustersCompanion(
      id: Value(id),
      name: Value(name),
      centroidVector: Value(centroidVector),
      imageCount: Value(imageCount),
      createdAt: Value(createdAt),
      isUserNamed: Value(isUserNamed),
    );
  }

  factory Cluster.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cluster(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      centroidVector: serializer.fromJson<Uint8List>(json['centroidVector']),
      imageCount: serializer.fromJson<int>(json['imageCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      isUserNamed: serializer.fromJson<bool>(json['isUserNamed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'centroidVector': serializer.toJson<Uint8List>(centroidVector),
      'imageCount': serializer.toJson<int>(imageCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'isUserNamed': serializer.toJson<bool>(isUserNamed),
    };
  }

  Cluster copyWith({
    String? id,
    String? name,
    Uint8List? centroidVector,
    int? imageCount,
    int? createdAt,
    bool? isUserNamed,
  }) => Cluster(
    id: id ?? this.id,
    name: name ?? this.name,
    centroidVector: centroidVector ?? this.centroidVector,
    imageCount: imageCount ?? this.imageCount,
    createdAt: createdAt ?? this.createdAt,
    isUserNamed: isUserNamed ?? this.isUserNamed,
  );
  Cluster copyWithCompanion(ClustersCompanion data) {
    return Cluster(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      centroidVector: data.centroidVector.present
          ? data.centroidVector.value
          : this.centroidVector,
      imageCount: data.imageCount.present
          ? data.imageCount.value
          : this.imageCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isUserNamed: data.isUserNamed.present
          ? data.isUserNamed.value
          : this.isUserNamed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cluster(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('centroidVector: $centroidVector, ')
          ..write('imageCount: $imageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('isUserNamed: $isUserNamed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    $driftBlobEquality.hash(centroidVector),
    imageCount,
    createdAt,
    isUserNamed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cluster &&
          other.id == this.id &&
          other.name == this.name &&
          $driftBlobEquality.equals(
            other.centroidVector,
            this.centroidVector,
          ) &&
          other.imageCount == this.imageCount &&
          other.createdAt == this.createdAt &&
          other.isUserNamed == this.isUserNamed);
}

class ClustersCompanion extends UpdateCompanion<Cluster> {
  final Value<String> id;
  final Value<String> name;
  final Value<Uint8List> centroidVector;
  final Value<int> imageCount;
  final Value<int> createdAt;
  final Value<bool> isUserNamed;
  final Value<int> rowid;
  const ClustersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.centroidVector = const Value.absent(),
    this.imageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isUserNamed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClustersCompanion.insert({
    required String id,
    required String name,
    required Uint8List centroidVector,
    required int imageCount,
    required int createdAt,
    this.isUserNamed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       centroidVector = Value(centroidVector),
       imageCount = Value(imageCount),
       createdAt = Value(createdAt);
  static Insertable<Cluster> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<Uint8List>? centroidVector,
    Expression<int>? imageCount,
    Expression<int>? createdAt,
    Expression<bool>? isUserNamed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (centroidVector != null) 'centroid_vector': centroidVector,
      if (imageCount != null) 'image_count': imageCount,
      if (createdAt != null) 'created_at': createdAt,
      if (isUserNamed != null) 'is_user_named': isUserNamed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClustersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<Uint8List>? centroidVector,
    Value<int>? imageCount,
    Value<int>? createdAt,
    Value<bool>? isUserNamed,
    Value<int>? rowid,
  }) {
    return ClustersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      centroidVector: centroidVector ?? this.centroidVector,
      imageCount: imageCount ?? this.imageCount,
      createdAt: createdAt ?? this.createdAt,
      isUserNamed: isUserNamed ?? this.isUserNamed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (centroidVector.present) {
      map['centroid_vector'] = Variable<Uint8List>(centroidVector.value);
    }
    if (imageCount.present) {
      map['image_count'] = Variable<int>(imageCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isUserNamed.present) {
      map['is_user_named'] = Variable<bool>(isUserNamed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClustersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('centroidVector: $centroidVector, ')
          ..write('imageCount: $imageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('isUserNamed: $isUserNamed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImageFolderMapTable extends ImageFolderMap
    with TableInfo<$ImageFolderMapTable, ImageFolderMapData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageFolderMapTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageIdMeta = const VerificationMeta(
    'imageId',
  );
  @override
  late final GeneratedColumn<String> imageId = GeneratedColumn<String>(
    'image_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assignedAtMeta = const VerificationMeta(
    'assignedAt',
  );
  @override
  late final GeneratedColumn<int> assignedAt = GeneratedColumn<int>(
    'assigned_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPhysicalPrimaryMeta = const VerificationMeta(
    'isPhysicalPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPhysicalPrimary = GeneratedColumn<bool>(
    'is_physical_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_physical_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    imageId,
    folderId,
    source,
    assignedAt,
    isPhysicalPrimary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_folder_map';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageFolderMapData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('image_id')) {
      context.handle(
        _imageIdMeta,
        imageId.isAcceptableOrUnknown(data['image_id']!, _imageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_imageIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('assigned_at')) {
      context.handle(
        _assignedAtMeta,
        assignedAt.isAcceptableOrUnknown(data['assigned_at']!, _assignedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_assignedAtMeta);
    }
    if (data.containsKey('is_physical_primary')) {
      context.handle(
        _isPhysicalPrimaryMeta,
        isPhysicalPrimary.isAcceptableOrUnknown(
          data['is_physical_primary']!,
          _isPhysicalPrimaryMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImageFolderMapData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageFolderMapData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      imageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      assignedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}assigned_at'],
      )!,
      isPhysicalPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_physical_primary'],
      )!,
    );
  }

  @override
  $ImageFolderMapTable createAlias(String alias) {
    return $ImageFolderMapTable(attachedDatabase, alias);
  }
}

class ImageFolderMapData extends DataClass
    implements Insertable<ImageFolderMapData> {
  final String id;
  final String imageId;
  final String folderId;
  final String source;
  final int assignedAt;
  final bool isPhysicalPrimary;
  const ImageFolderMapData({
    required this.id,
    required this.imageId,
    required this.folderId,
    required this.source,
    required this.assignedAt,
    required this.isPhysicalPrimary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['image_id'] = Variable<String>(imageId);
    map['folder_id'] = Variable<String>(folderId);
    map['source'] = Variable<String>(source);
    map['assigned_at'] = Variable<int>(assignedAt);
    map['is_physical_primary'] = Variable<bool>(isPhysicalPrimary);
    return map;
  }

  ImageFolderMapCompanion toCompanion(bool nullToAbsent) {
    return ImageFolderMapCompanion(
      id: Value(id),
      imageId: Value(imageId),
      folderId: Value(folderId),
      source: Value(source),
      assignedAt: Value(assignedAt),
      isPhysicalPrimary: Value(isPhysicalPrimary),
    );
  }

  factory ImageFolderMapData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageFolderMapData(
      id: serializer.fromJson<String>(json['id']),
      imageId: serializer.fromJson<String>(json['imageId']),
      folderId: serializer.fromJson<String>(json['folderId']),
      source: serializer.fromJson<String>(json['source']),
      assignedAt: serializer.fromJson<int>(json['assignedAt']),
      isPhysicalPrimary: serializer.fromJson<bool>(json['isPhysicalPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'imageId': serializer.toJson<String>(imageId),
      'folderId': serializer.toJson<String>(folderId),
      'source': serializer.toJson<String>(source),
      'assignedAt': serializer.toJson<int>(assignedAt),
      'isPhysicalPrimary': serializer.toJson<bool>(isPhysicalPrimary),
    };
  }

  ImageFolderMapData copyWith({
    String? id,
    String? imageId,
    String? folderId,
    String? source,
    int? assignedAt,
    bool? isPhysicalPrimary,
  }) => ImageFolderMapData(
    id: id ?? this.id,
    imageId: imageId ?? this.imageId,
    folderId: folderId ?? this.folderId,
    source: source ?? this.source,
    assignedAt: assignedAt ?? this.assignedAt,
    isPhysicalPrimary: isPhysicalPrimary ?? this.isPhysicalPrimary,
  );
  ImageFolderMapData copyWithCompanion(ImageFolderMapCompanion data) {
    return ImageFolderMapData(
      id: data.id.present ? data.id.value : this.id,
      imageId: data.imageId.present ? data.imageId.value : this.imageId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      source: data.source.present ? data.source.value : this.source,
      assignedAt: data.assignedAt.present
          ? data.assignedAt.value
          : this.assignedAt,
      isPhysicalPrimary: data.isPhysicalPrimary.present
          ? data.isPhysicalPrimary.value
          : this.isPhysicalPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageFolderMapData(')
          ..write('id: $id, ')
          ..write('imageId: $imageId, ')
          ..write('folderId: $folderId, ')
          ..write('source: $source, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('isPhysicalPrimary: $isPhysicalPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, imageId, folderId, source, assignedAt, isPhysicalPrimary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageFolderMapData &&
          other.id == this.id &&
          other.imageId == this.imageId &&
          other.folderId == this.folderId &&
          other.source == this.source &&
          other.assignedAt == this.assignedAt &&
          other.isPhysicalPrimary == this.isPhysicalPrimary);
}

class ImageFolderMapCompanion extends UpdateCompanion<ImageFolderMapData> {
  final Value<String> id;
  final Value<String> imageId;
  final Value<String> folderId;
  final Value<String> source;
  final Value<int> assignedAt;
  final Value<bool> isPhysicalPrimary;
  final Value<int> rowid;
  const ImageFolderMapCompanion({
    this.id = const Value.absent(),
    this.imageId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.source = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.isPhysicalPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageFolderMapCompanion.insert({
    required String id,
    required String imageId,
    required String folderId,
    required String source,
    required int assignedAt,
    this.isPhysicalPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       imageId = Value(imageId),
       folderId = Value(folderId),
       source = Value(source),
       assignedAt = Value(assignedAt);
  static Insertable<ImageFolderMapData> custom({
    Expression<String>? id,
    Expression<String>? imageId,
    Expression<String>? folderId,
    Expression<String>? source,
    Expression<int>? assignedAt,
    Expression<bool>? isPhysicalPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (imageId != null) 'image_id': imageId,
      if (folderId != null) 'folder_id': folderId,
      if (source != null) 'source': source,
      if (assignedAt != null) 'assigned_at': assignedAt,
      if (isPhysicalPrimary != null) 'is_physical_primary': isPhysicalPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageFolderMapCompanion copyWith({
    Value<String>? id,
    Value<String>? imageId,
    Value<String>? folderId,
    Value<String>? source,
    Value<int>? assignedAt,
    Value<bool>? isPhysicalPrimary,
    Value<int>? rowid,
  }) {
    return ImageFolderMapCompanion(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      folderId: folderId ?? this.folderId,
      source: source ?? this.source,
      assignedAt: assignedAt ?? this.assignedAt,
      isPhysicalPrimary: isPhysicalPrimary ?? this.isPhysicalPrimary,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (imageId.present) {
      map['image_id'] = Variable<String>(imageId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<int>(assignedAt.value);
    }
    if (isPhysicalPrimary.present) {
      map['is_physical_primary'] = Variable<bool>(isPhysicalPrimary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageFolderMapCompanion(')
          ..write('id: $id, ')
          ..write('imageId: $imageId, ')
          ..write('folderId: $folderId, ')
          ..write('source: $source, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('isPhysicalPrimary: $isPhysicalPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ImagesTable images = $ImagesTable(this);
  late final $SmartFoldersTable smartFolders = $SmartFoldersTable(this);
  late final $FolderRulesTable folderRules = $FolderRulesTable(this);
  late final $ClustersTable clusters = $ClustersTable(this);
  late final $ImageFolderMapTable imageFolderMap = $ImageFolderMapTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    images,
    smartFolders,
    folderRules,
    clusters,
    imageFolderMap,
  ];
}

typedef $$ImagesTableCreateCompanionBuilder =
    ImagesCompanion Function({
      required String id,
      required String filePath,
      required String fileName,
      required int width,
      required int height,
      required int fileSize,
      Value<int?> takenAt,
      required int indexedAt,
      Value<int?> phash,
      required Uint8List semanticVector,
      Value<bool> isScreenshot,
      Value<bool> hasText,
      Value<String?> tags,
      required double blurScore,
      required double dominantHue,
      required double colorWarmth,
      Value<String?> clusterId,
      Value<double?> gpsLat,
      Value<double?> gpsLon,
      Value<int> rowid,
    });
typedef $$ImagesTableUpdateCompanionBuilder =
    ImagesCompanion Function({
      Value<String> id,
      Value<String> filePath,
      Value<String> fileName,
      Value<int> width,
      Value<int> height,
      Value<int> fileSize,
      Value<int?> takenAt,
      Value<int> indexedAt,
      Value<int?> phash,
      Value<Uint8List> semanticVector,
      Value<bool> isScreenshot,
      Value<bool> hasText,
      Value<String?> tags,
      Value<double> blurScore,
      Value<double> dominantHue,
      Value<double> colorWarmth,
      Value<String?> clusterId,
      Value<double?> gpsLat,
      Value<double?> gpsLon,
      Value<int> rowid,
    });

class $$ImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phash => $composableBuilder(
    column: $table.phash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get semanticVector => $composableBuilder(
    column: $table.semanticVector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isScreenshot => $composableBuilder(
    column: $table.isScreenshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasText => $composableBuilder(
    column: $table.hasText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get blurScore => $composableBuilder(
    column: $table.blurScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dominantHue => $composableBuilder(
    column: $table.dominantHue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get colorWarmth => $composableBuilder(
    column: $table.colorWarmth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsLat => $composableBuilder(
    column: $table.gpsLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsLon => $composableBuilder(
    column: $table.gpsLon,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indexedAt => $composableBuilder(
    column: $table.indexedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phash => $composableBuilder(
    column: $table.phash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get semanticVector => $composableBuilder(
    column: $table.semanticVector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isScreenshot => $composableBuilder(
    column: $table.isScreenshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasText => $composableBuilder(
    column: $table.hasText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get blurScore => $composableBuilder(
    column: $table.blurScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dominantHue => $composableBuilder(
    column: $table.dominantHue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get colorWarmth => $composableBuilder(
    column: $table.colorWarmth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clusterId => $composableBuilder(
    column: $table.clusterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsLat => $composableBuilder(
    column: $table.gpsLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsLon => $composableBuilder(
    column: $table.gpsLon,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<int> get indexedAt =>
      $composableBuilder(column: $table.indexedAt, builder: (column) => column);

  GeneratedColumn<int> get phash =>
      $composableBuilder(column: $table.phash, builder: (column) => column);

  GeneratedColumn<Uint8List> get semanticVector => $composableBuilder(
    column: $table.semanticVector,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isScreenshot => $composableBuilder(
    column: $table.isScreenshot,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasText =>
      $composableBuilder(column: $table.hasText, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<double> get blurScore =>
      $composableBuilder(column: $table.blurScore, builder: (column) => column);

  GeneratedColumn<double> get dominantHue => $composableBuilder(
    column: $table.dominantHue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get colorWarmth => $composableBuilder(
    column: $table.colorWarmth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clusterId =>
      $composableBuilder(column: $table.clusterId, builder: (column) => column);

  GeneratedColumn<double> get gpsLat =>
      $composableBuilder(column: $table.gpsLat, builder: (column) => column);

  GeneratedColumn<double> get gpsLon =>
      $composableBuilder(column: $table.gpsLon, builder: (column) => column);
}

class $$ImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImagesTable,
          Image,
          $$ImagesTableFilterComposer,
          $$ImagesTableOrderingComposer,
          $$ImagesTableAnnotationComposer,
          $$ImagesTableCreateCompanionBuilder,
          $$ImagesTableUpdateCompanionBuilder,
          (Image, BaseReferences<_$AppDatabase, $ImagesTable, Image>),
          Image,
          PrefetchHooks Function()
        > {
  $$ImagesTableTableManager(_$AppDatabase db, $ImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int?> takenAt = const Value.absent(),
                Value<int> indexedAt = const Value.absent(),
                Value<int?> phash = const Value.absent(),
                Value<Uint8List> semanticVector = const Value.absent(),
                Value<bool> isScreenshot = const Value.absent(),
                Value<bool> hasText = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<double> blurScore = const Value.absent(),
                Value<double> dominantHue = const Value.absent(),
                Value<double> colorWarmth = const Value.absent(),
                Value<String?> clusterId = const Value.absent(),
                Value<double?> gpsLat = const Value.absent(),
                Value<double?> gpsLon = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion(
                id: id,
                filePath: filePath,
                fileName: fileName,
                width: width,
                height: height,
                fileSize: fileSize,
                takenAt: takenAt,
                indexedAt: indexedAt,
                phash: phash,
                semanticVector: semanticVector,
                isScreenshot: isScreenshot,
                hasText: hasText,
                tags: tags,
                blurScore: blurScore,
                dominantHue: dominantHue,
                colorWarmth: colorWarmth,
                clusterId: clusterId,
                gpsLat: gpsLat,
                gpsLon: gpsLon,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String filePath,
                required String fileName,
                required int width,
                required int height,
                required int fileSize,
                Value<int?> takenAt = const Value.absent(),
                required int indexedAt,
                Value<int?> phash = const Value.absent(),
                required Uint8List semanticVector,
                Value<bool> isScreenshot = const Value.absent(),
                Value<bool> hasText = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                required double blurScore,
                required double dominantHue,
                required double colorWarmth,
                Value<String?> clusterId = const Value.absent(),
                Value<double?> gpsLat = const Value.absent(),
                Value<double?> gpsLon = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion.insert(
                id: id,
                filePath: filePath,
                fileName: fileName,
                width: width,
                height: height,
                fileSize: fileSize,
                takenAt: takenAt,
                indexedAt: indexedAt,
                phash: phash,
                semanticVector: semanticVector,
                isScreenshot: isScreenshot,
                hasText: hasText,
                tags: tags,
                blurScore: blurScore,
                dominantHue: dominantHue,
                colorWarmth: colorWarmth,
                clusterId: clusterId,
                gpsLat: gpsLat,
                gpsLon: gpsLon,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImagesTable,
      Image,
      $$ImagesTableFilterComposer,
      $$ImagesTableOrderingComposer,
      $$ImagesTableAnnotationComposer,
      $$ImagesTableCreateCompanionBuilder,
      $$ImagesTableUpdateCompanionBuilder,
      (Image, BaseReferences<_$AppDatabase, $ImagesTable, Image>),
      Image,
      PrefetchHooks Function()
    >;
typedef $$SmartFoldersTableCreateCompanionBuilder =
    SmartFoldersCompanion Function({
      required String id,
      required String name,
      required String icon,
      required int color,
      Value<String?> rootRuleId,
      required int sortOrder,
      required int createdAt,
      required int lastMatchedAt,
      Value<String?> exportPath,
      Value<String?> exportMode,
      Value<int?> lastExportedAt,
      Value<int> rowid,
    });
typedef $$SmartFoldersTableUpdateCompanionBuilder =
    SmartFoldersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> icon,
      Value<int> color,
      Value<String?> rootRuleId,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> lastMatchedAt,
      Value<String?> exportPath,
      Value<String?> exportMode,
      Value<int?> lastExportedAt,
      Value<int> rowid,
    });

class $$SmartFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $SmartFoldersTable> {
  $$SmartFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootRuleId => $composableBuilder(
    column: $table.rootRuleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastMatchedAt => $composableBuilder(
    column: $table.lastMatchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exportPath => $composableBuilder(
    column: $table.exportPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exportMode => $composableBuilder(
    column: $table.exportMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastExportedAt => $composableBuilder(
    column: $table.lastExportedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmartFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartFoldersTable> {
  $$SmartFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootRuleId => $composableBuilder(
    column: $table.rootRuleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastMatchedAt => $composableBuilder(
    column: $table.lastMatchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exportPath => $composableBuilder(
    column: $table.exportPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exportMode => $composableBuilder(
    column: $table.exportMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastExportedAt => $composableBuilder(
    column: $table.lastExportedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmartFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartFoldersTable> {
  $$SmartFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get rootRuleId => $composableBuilder(
    column: $table.rootRuleId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastMatchedAt => $composableBuilder(
    column: $table.lastMatchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exportPath => $composableBuilder(
    column: $table.exportPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exportMode => $composableBuilder(
    column: $table.exportMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastExportedAt => $composableBuilder(
    column: $table.lastExportedAt,
    builder: (column) => column,
  );
}

class $$SmartFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartFoldersTable,
          SmartFolder,
          $$SmartFoldersTableFilterComposer,
          $$SmartFoldersTableOrderingComposer,
          $$SmartFoldersTableAnnotationComposer,
          $$SmartFoldersTableCreateCompanionBuilder,
          $$SmartFoldersTableUpdateCompanionBuilder,
          (
            SmartFolder,
            BaseReferences<_$AppDatabase, $SmartFoldersTable, SmartFolder>,
          ),
          SmartFolder,
          PrefetchHooks Function()
        > {
  $$SmartFoldersTableTableManager(_$AppDatabase db, $SmartFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmartFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmartFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String?> rootRuleId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> lastMatchedAt = const Value.absent(),
                Value<String?> exportPath = const Value.absent(),
                Value<String?> exportMode = const Value.absent(),
                Value<int?> lastExportedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmartFoldersCompanion(
                id: id,
                name: name,
                icon: icon,
                color: color,
                rootRuleId: rootRuleId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                lastMatchedAt: lastMatchedAt,
                exportPath: exportPath,
                exportMode: exportMode,
                lastExportedAt: lastExportedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String icon,
                required int color,
                Value<String?> rootRuleId = const Value.absent(),
                required int sortOrder,
                required int createdAt,
                required int lastMatchedAt,
                Value<String?> exportPath = const Value.absent(),
                Value<String?> exportMode = const Value.absent(),
                Value<int?> lastExportedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmartFoldersCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                color: color,
                rootRuleId: rootRuleId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                lastMatchedAt: lastMatchedAt,
                exportPath: exportPath,
                exportMode: exportMode,
                lastExportedAt: lastExportedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmartFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartFoldersTable,
      SmartFolder,
      $$SmartFoldersTableFilterComposer,
      $$SmartFoldersTableOrderingComposer,
      $$SmartFoldersTableAnnotationComposer,
      $$SmartFoldersTableCreateCompanionBuilder,
      $$SmartFoldersTableUpdateCompanionBuilder,
      (
        SmartFolder,
        BaseReferences<_$AppDatabase, $SmartFoldersTable, SmartFolder>,
      ),
      SmartFolder,
      PrefetchHooks Function()
    >;
typedef $$FolderRulesTableCreateCompanionBuilder =
    FolderRulesCompanion Function({
      required String id,
      required String folderId,
      Value<String?> parentId,
      required String nodeType,
      Value<String?> featureType,
      Value<String?> comparator,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$FolderRulesTableUpdateCompanionBuilder =
    FolderRulesCompanion Function({
      Value<String> id,
      Value<String> folderId,
      Value<String?> parentId,
      Value<String> nodeType,
      Value<String?> featureType,
      Value<String?> comparator,
      Value<String?> value,
      Value<int> rowid,
    });

class $$FolderRulesTableFilterComposer
    extends Composer<_$AppDatabase, $FolderRulesTable> {
  $$FolderRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get featureType => $composableBuilder(
    column: $table.featureType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comparator => $composableBuilder(
    column: $table.comparator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FolderRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $FolderRulesTable> {
  $$FolderRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get featureType => $composableBuilder(
    column: $table.featureType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comparator => $composableBuilder(
    column: $table.comparator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FolderRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FolderRulesTable> {
  $$FolderRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get nodeType =>
      $composableBuilder(column: $table.nodeType, builder: (column) => column);

  GeneratedColumn<String> get featureType => $composableBuilder(
    column: $table.featureType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get comparator => $composableBuilder(
    column: $table.comparator,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$FolderRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FolderRulesTable,
          FolderRule,
          $$FolderRulesTableFilterComposer,
          $$FolderRulesTableOrderingComposer,
          $$FolderRulesTableAnnotationComposer,
          $$FolderRulesTableCreateCompanionBuilder,
          $$FolderRulesTableUpdateCompanionBuilder,
          (
            FolderRule,
            BaseReferences<_$AppDatabase, $FolderRulesTable, FolderRule>,
          ),
          FolderRule,
          PrefetchHooks Function()
        > {
  $$FolderRulesTableTableManager(_$AppDatabase db, $FolderRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FolderRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> nodeType = const Value.absent(),
                Value<String?> featureType = const Value.absent(),
                Value<String?> comparator = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderRulesCompanion(
                id: id,
                folderId: folderId,
                parentId: parentId,
                nodeType: nodeType,
                featureType: featureType,
                comparator: comparator,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String folderId,
                Value<String?> parentId = const Value.absent(),
                required String nodeType,
                Value<String?> featureType = const Value.absent(),
                Value<String?> comparator = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderRulesCompanion.insert(
                id: id,
                folderId: folderId,
                parentId: parentId,
                nodeType: nodeType,
                featureType: featureType,
                comparator: comparator,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FolderRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FolderRulesTable,
      FolderRule,
      $$FolderRulesTableFilterComposer,
      $$FolderRulesTableOrderingComposer,
      $$FolderRulesTableAnnotationComposer,
      $$FolderRulesTableCreateCompanionBuilder,
      $$FolderRulesTableUpdateCompanionBuilder,
      (
        FolderRule,
        BaseReferences<_$AppDatabase, $FolderRulesTable, FolderRule>,
      ),
      FolderRule,
      PrefetchHooks Function()
    >;
typedef $$ClustersTableCreateCompanionBuilder =
    ClustersCompanion Function({
      required String id,
      required String name,
      required Uint8List centroidVector,
      required int imageCount,
      required int createdAt,
      Value<bool> isUserNamed,
      Value<int> rowid,
    });
typedef $$ClustersTableUpdateCompanionBuilder =
    ClustersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<Uint8List> centroidVector,
      Value<int> imageCount,
      Value<int> createdAt,
      Value<bool> isUserNamed,
      Value<int> rowid,
    });

class $$ClustersTableFilterComposer
    extends Composer<_$AppDatabase, $ClustersTable> {
  $$ClustersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get centroidVector => $composableBuilder(
    column: $table.centroidVector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUserNamed => $composableBuilder(
    column: $table.isUserNamed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClustersTableOrderingComposer
    extends Composer<_$AppDatabase, $ClustersTable> {
  $$ClustersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get centroidVector => $composableBuilder(
    column: $table.centroidVector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUserNamed => $composableBuilder(
    column: $table.isUserNamed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClustersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClustersTable> {
  $$ClustersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<Uint8List> get centroidVector => $composableBuilder(
    column: $table.centroidVector,
    builder: (column) => column,
  );

  GeneratedColumn<int> get imageCount => $composableBuilder(
    column: $table.imageCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isUserNamed => $composableBuilder(
    column: $table.isUserNamed,
    builder: (column) => column,
  );
}

class $$ClustersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClustersTable,
          Cluster,
          $$ClustersTableFilterComposer,
          $$ClustersTableOrderingComposer,
          $$ClustersTableAnnotationComposer,
          $$ClustersTableCreateCompanionBuilder,
          $$ClustersTableUpdateCompanionBuilder,
          (Cluster, BaseReferences<_$AppDatabase, $ClustersTable, Cluster>),
          Cluster,
          PrefetchHooks Function()
        > {
  $$ClustersTableTableManager(_$AppDatabase db, $ClustersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClustersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClustersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClustersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<Uint8List> centroidVector = const Value.absent(),
                Value<int> imageCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<bool> isUserNamed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClustersCompanion(
                id: id,
                name: name,
                centroidVector: centroidVector,
                imageCount: imageCount,
                createdAt: createdAt,
                isUserNamed: isUserNamed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required Uint8List centroidVector,
                required int imageCount,
                required int createdAt,
                Value<bool> isUserNamed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClustersCompanion.insert(
                id: id,
                name: name,
                centroidVector: centroidVector,
                imageCount: imageCount,
                createdAt: createdAt,
                isUserNamed: isUserNamed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClustersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClustersTable,
      Cluster,
      $$ClustersTableFilterComposer,
      $$ClustersTableOrderingComposer,
      $$ClustersTableAnnotationComposer,
      $$ClustersTableCreateCompanionBuilder,
      $$ClustersTableUpdateCompanionBuilder,
      (Cluster, BaseReferences<_$AppDatabase, $ClustersTable, Cluster>),
      Cluster,
      PrefetchHooks Function()
    >;
typedef $$ImageFolderMapTableCreateCompanionBuilder =
    ImageFolderMapCompanion Function({
      required String id,
      required String imageId,
      required String folderId,
      required String source,
      required int assignedAt,
      Value<bool> isPhysicalPrimary,
      Value<int> rowid,
    });
typedef $$ImageFolderMapTableUpdateCompanionBuilder =
    ImageFolderMapCompanion Function({
      Value<String> id,
      Value<String> imageId,
      Value<String> folderId,
      Value<String> source,
      Value<int> assignedAt,
      Value<bool> isPhysicalPrimary,
      Value<int> rowid,
    });

class $$ImageFolderMapTableFilterComposer
    extends Composer<_$AppDatabase, $ImageFolderMapTable> {
  $$ImageFolderMapTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageId => $composableBuilder(
    column: $table.imageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPhysicalPrimary => $composableBuilder(
    column: $table.isPhysicalPrimary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImageFolderMapTableOrderingComposer
    extends Composer<_$AppDatabase, $ImageFolderMapTable> {
  $$ImageFolderMapTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageId => $composableBuilder(
    column: $table.imageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPhysicalPrimary => $composableBuilder(
    column: $table.isPhysicalPrimary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImageFolderMapTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImageFolderMapTable> {
  $$ImageFolderMapTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get imageId =>
      $composableBuilder(column: $table.imageId, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPhysicalPrimary => $composableBuilder(
    column: $table.isPhysicalPrimary,
    builder: (column) => column,
  );
}

class $$ImageFolderMapTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImageFolderMapTable,
          ImageFolderMapData,
          $$ImageFolderMapTableFilterComposer,
          $$ImageFolderMapTableOrderingComposer,
          $$ImageFolderMapTableAnnotationComposer,
          $$ImageFolderMapTableCreateCompanionBuilder,
          $$ImageFolderMapTableUpdateCompanionBuilder,
          (
            ImageFolderMapData,
            BaseReferences<
              _$AppDatabase,
              $ImageFolderMapTable,
              ImageFolderMapData
            >,
          ),
          ImageFolderMapData,
          PrefetchHooks Function()
        > {
  $$ImageFolderMapTableTableManager(
    _$AppDatabase db,
    $ImageFolderMapTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageFolderMapTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageFolderMapTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImageFolderMapTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> imageId = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> assignedAt = const Value.absent(),
                Value<bool> isPhysicalPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageFolderMapCompanion(
                id: id,
                imageId: imageId,
                folderId: folderId,
                source: source,
                assignedAt: assignedAt,
                isPhysicalPrimary: isPhysicalPrimary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String imageId,
                required String folderId,
                required String source,
                required int assignedAt,
                Value<bool> isPhysicalPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageFolderMapCompanion.insert(
                id: id,
                imageId: imageId,
                folderId: folderId,
                source: source,
                assignedAt: assignedAt,
                isPhysicalPrimary: isPhysicalPrimary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImageFolderMapTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImageFolderMapTable,
      ImageFolderMapData,
      $$ImageFolderMapTableFilterComposer,
      $$ImageFolderMapTableOrderingComposer,
      $$ImageFolderMapTableAnnotationComposer,
      $$ImageFolderMapTableCreateCompanionBuilder,
      $$ImageFolderMapTableUpdateCompanionBuilder,
      (
        ImageFolderMapData,
        BaseReferences<_$AppDatabase, $ImageFolderMapTable, ImageFolderMapData>,
      ),
      ImageFolderMapData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db, _db.images);
  $$SmartFoldersTableTableManager get smartFolders =>
      $$SmartFoldersTableTableManager(_db, _db.smartFolders);
  $$FolderRulesTableTableManager get folderRules =>
      $$FolderRulesTableTableManager(_db, _db.folderRules);
  $$ClustersTableTableManager get clusters =>
      $$ClustersTableTableManager(_db, _db.clusters);
  $$ImageFolderMapTableTableManager get imageFolderMap =>
      $$ImageFolderMapTableTableManager(_db, _db.imageFolderMap);
}
