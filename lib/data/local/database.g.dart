// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String name;
  final DateTime createdAt;
  const Project({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(id: Value(id), name: Value(name), createdAt: Value(createdAt));
  }

  factory Project.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Project copyWith({String? id, String? name, DateTime? createdAt}) =>
      Project(id: id ?? this.id, name: name ?? this.name, createdAt: createdAt ?? this.createdAt);
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project && other.id == this.id && other.name == this.name && other.createdAt == this.createdAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({Value<String>? id, Value<String>? name, Value<DateTime>? createdAt, Value<int>? rowid}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteGroupsTable extends NoteGroups with TableInfo<$NoteGroupsTable, NoteGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES projects (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES note_groups (id) ON DELETE SET NULL'),
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
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, projectId, parentId, name, color, position, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_groups';
  @override
  VerificationContext validateIntegrity(Insertable<NoteGroup> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta, projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta, parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteGroup(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      parentId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color']),
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NoteGroupsTable createAlias(String alias) {
    return $NoteGroupsTable(attachedDatabase, alias);
  }
}

class NoteGroup extends DataClass implements Insertable<NoteGroup> {
  final String id;
  final String projectId;
  final String? parentId;
  final String name;
  final int? color;
  final int position;
  final DateTime createdAt;
  const NoteGroup({
    required this.id,
    required this.projectId,
    this.parentId,
    required this.name,
    this.color,
    required this.position,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NoteGroupsCompanion toCompanion(bool nullToAbsent) {
    return NoteGroupsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      parentId: parentId == null && nullToAbsent ? const Value.absent() : Value(parentId),
      name: Value(name),
      color: color == null && nullToAbsent ? const Value.absent() : Value(color),
      position: Value(position),
      createdAt: Value(createdAt),
    );
  }

  factory NoteGroup.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteGroup(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NoteGroup copyWith({
    String? id,
    String? projectId,
    Value<String?> parentId = const Value.absent(),
    String? name,
    Value<int?> color = const Value.absent(),
    int? position,
    DateTime? createdAt,
  }) => NoteGroup(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
  );
  NoteGroup copyWithCompanion(NoteGroupsCompanion data) {
    return NoteGroup(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteGroup(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, parentId, name, color, position, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteGroup &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.color == this.color &&
          other.position == this.position &&
          other.createdAt == this.createdAt);
}

class NoteGroupsCompanion extends UpdateCompanion<NoteGroup> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<int?> color;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const NoteGroupsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteGroupsCompanion.insert({
    required String id,
    required String projectId,
    this.parentId = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    required int position,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name),
       position = Value(position),
       createdAt = Value(createdAt);
  static Insertable<NoteGroup> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<int>? color,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String?>? parentId,
    Value<String>? name,
    Value<int?>? color,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return NoteGroupsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      color: color ?? this.color,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteGroupsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES projects (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTextMeta = const VerificationMeta('originalText');
  @override
  late final GeneratedColumn<String> originalText = GeneratedColumn<String>(
    'original_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extractedTextMeta = const VerificationMeta('extractedText');
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedTextMeta = const VerificationMeta('editedText');
  @override
  late final GeneratedColumn<String> editedText = GeneratedColumn<String>(
    'edited_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proposedTextMeta = const VerificationMeta('proposedText');
  @override
  late final GeneratedColumn<String> proposedText = GeneratedColumn<String>(
    'proposed_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<NoteSource, String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<NoteSource>($NotesTable.$convertersource);
  @override
  late final GeneratedColumnWithTypeConverter<ProcessingStatus, String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ProcessingStatus>($NotesTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<RewriteStatus, String> rewrite = GeneratedColumn<String>(
    'rewrite',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  ).withConverter<RewriteStatus>($NotesTable.$converterrewrite);
  static const VerificationMeta _attachmentPathMeta = const VerificationMeta('attachmentPath');
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
    'attachment_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentNameMeta = const VerificationMeta('attachmentName');
  @override
  late final GeneratedColumn<String> attachmentName = GeneratedColumn<String>(
    'attachment_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentBytesMeta = const VerificationMeta('attachmentBytes');
  @override
  late final GeneratedColumn<int> attachmentBytes = GeneratedColumn<int>(
    'attachment_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voicePathMeta = const VerificationMeta('voicePath');
  @override
  late final GeneratedColumn<String> voicePath = GeneratedColumn<String>(
    'voice_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathsMeta = const VerificationMeta('imagePaths');
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _conceptsMeta = const VerificationMeta('concepts');
  @override
  late final GeneratedColumn<String> concepts = GeneratedColumn<String>(
    'concepts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _clusterMeta = const VerificationMeta('cluster');
  @override
  late final GeneratedColumn<String> cluster = GeneratedColumn<String>(
    'cluster',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES note_groups (id) ON DELETE SET NULL'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    title,
    originalText,
    extractedText,
    editedText,
    proposedText,
    source,
    status,
    rewrite,
    attachmentPath,
    attachmentName,
    attachmentBytes,
    voicePath,
    durationMs,
    imagePaths,
    concepts,
    cluster,
    createdAt,
    updatedAt,
    groupId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<Note> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta, projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_text')) {
      context.handle(_originalTextMeta, originalText.isAcceptableOrUnknown(data['original_text']!, _originalTextMeta));
    } else if (isInserting) {
      context.missing(_originalTextMeta);
    }
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(data['extracted_text']!, _extractedTextMeta),
      );
    }
    if (data.containsKey('edited_text')) {
      context.handle(_editedTextMeta, editedText.isAcceptableOrUnknown(data['edited_text']!, _editedTextMeta));
    }
    if (data.containsKey('proposed_text')) {
      context.handle(_proposedTextMeta, proposedText.isAcceptableOrUnknown(data['proposed_text']!, _proposedTextMeta));
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
        _attachmentPathMeta,
        attachmentPath.isAcceptableOrUnknown(data['attachment_path']!, _attachmentPathMeta),
      );
    }
    if (data.containsKey('attachment_name')) {
      context.handle(
        _attachmentNameMeta,
        attachmentName.isAcceptableOrUnknown(data['attachment_name']!, _attachmentNameMeta),
      );
    }
    if (data.containsKey('attachment_bytes')) {
      context.handle(
        _attachmentBytesMeta,
        attachmentBytes.isAcceptableOrUnknown(data['attachment_bytes']!, _attachmentBytesMeta),
      );
    }
    if (data.containsKey('voice_path')) {
      context.handle(_voicePathMeta, voicePath.isAcceptableOrUnknown(data['voice_path']!, _voicePathMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(_durationMsMeta, durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('image_paths')) {
      context.handle(_imagePathsMeta, imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta));
    }
    if (data.containsKey('concepts')) {
      context.handle(_conceptsMeta, concepts.isAcceptableOrUnknown(data['concepts']!, _conceptsMeta));
    }
    if (data.containsKey('cluster')) {
      context.handle(_clusterMeta, cluster.isAcceptableOrUnknown(data['cluster']!, _clusterMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta, groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      originalText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}original_text'])!,
      extractedText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}extracted_text']),
      editedText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}edited_text']),
      proposedText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}proposed_text']),
      source: $NotesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      ),
      status: $NotesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      ),
      rewrite: $NotesTable.$converterrewrite.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}rewrite'])!,
      ),
      attachmentPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}attachment_path']),
      attachmentName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}attachment_name']),
      attachmentBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}attachment_bytes']),
      voicePath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}voice_path']),
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      imagePaths: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}image_paths'])!,
      concepts: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}concepts'])!,
      cluster: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cluster']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      groupId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}group_id']),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NoteSource, String, String> $convertersource = const EnumNameConverter<NoteSource>(
    NoteSource.values,
  );
  static JsonTypeConverter2<ProcessingStatus, String, String> $converterstatus =
      const EnumNameConverter<ProcessingStatus>(ProcessingStatus.values);
  static JsonTypeConverter2<RewriteStatus, String, String> $converterrewrite = const EnumNameConverter<RewriteStatus>(
    RewriteStatus.values,
  );
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String projectId;
  final String title;

  /// Exactly what the user typed. Never overwritten.
  final String originalText;

  /// Text the old demo filled in from a recording or PDF. Nothing writes it
  /// now: attachments stay on the phone and are never parsed.
  final String? extractedText;

  /// The version shown when set: an accepted AI rewrite or a user edit.
  final String? editedText;

  /// AI rewrite waiting for accept / reject.
  final String? proposedText;

  /// The main content: `pdf` when a PDF is attached (a voice memo may sit
  /// beside it), `voice` for a recording alone, otherwise `text`.
  final NoteSource source;
  final ProcessingStatus status;
  final RewriteStatus rewrite;

  /// Legacy PDF columns, retained for migration/recovery only since v5.
  final String? attachmentPath;
  final String? attachmentName;
  final int? attachmentBytes;

  /// Legacy recording columns, retained for migration/recovery only since v5.
  final String? voicePath;
  final int? durationMs;

  /// Legacy photo paths separated by '|', retained for migration/recovery only.
  final String imagePaths;

  /// Concepts separated by '|'.
  final String concepts;
  final String? cluster;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? groupId;
  const Note({
    required this.id,
    required this.projectId,
    required this.title,
    required this.originalText,
    this.extractedText,
    this.editedText,
    this.proposedText,
    required this.source,
    required this.status,
    required this.rewrite,
    this.attachmentPath,
    this.attachmentName,
    this.attachmentBytes,
    this.voicePath,
    this.durationMs,
    required this.imagePaths,
    required this.concepts,
    this.cluster,
    required this.createdAt,
    required this.updatedAt,
    this.groupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['title'] = Variable<String>(title);
    map['original_text'] = Variable<String>(originalText);
    if (!nullToAbsent || extractedText != null) {
      map['extracted_text'] = Variable<String>(extractedText);
    }
    if (!nullToAbsent || editedText != null) {
      map['edited_text'] = Variable<String>(editedText);
    }
    if (!nullToAbsent || proposedText != null) {
      map['proposed_text'] = Variable<String>(proposedText);
    }
    {
      map['source'] = Variable<String>($NotesTable.$convertersource.toSql(source));
    }
    {
      map['status'] = Variable<String>($NotesTable.$converterstatus.toSql(status));
    }
    {
      map['rewrite'] = Variable<String>($NotesTable.$converterrewrite.toSql(rewrite));
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    if (!nullToAbsent || attachmentName != null) {
      map['attachment_name'] = Variable<String>(attachmentName);
    }
    if (!nullToAbsent || attachmentBytes != null) {
      map['attachment_bytes'] = Variable<int>(attachmentBytes);
    }
    if (!nullToAbsent || voicePath != null) {
      map['voice_path'] = Variable<String>(voicePath);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['image_paths'] = Variable<String>(imagePaths);
    map['concepts'] = Variable<String>(concepts);
    if (!nullToAbsent || cluster != null) {
      map['cluster'] = Variable<String>(cluster);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      title: Value(title),
      originalText: Value(originalText),
      extractedText: extractedText == null && nullToAbsent ? const Value.absent() : Value(extractedText),
      editedText: editedText == null && nullToAbsent ? const Value.absent() : Value(editedText),
      proposedText: proposedText == null && nullToAbsent ? const Value.absent() : Value(proposedText),
      source: Value(source),
      status: Value(status),
      rewrite: Value(rewrite),
      attachmentPath: attachmentPath == null && nullToAbsent ? const Value.absent() : Value(attachmentPath),
      attachmentName: attachmentName == null && nullToAbsent ? const Value.absent() : Value(attachmentName),
      attachmentBytes: attachmentBytes == null && nullToAbsent ? const Value.absent() : Value(attachmentBytes),
      voicePath: voicePath == null && nullToAbsent ? const Value.absent() : Value(voicePath),
      durationMs: durationMs == null && nullToAbsent ? const Value.absent() : Value(durationMs),
      imagePaths: Value(imagePaths),
      concepts: Value(concepts),
      cluster: cluster == null && nullToAbsent ? const Value.absent() : Value(cluster),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      groupId: groupId == null && nullToAbsent ? const Value.absent() : Value(groupId),
    );
  }

  factory Note.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      originalText: serializer.fromJson<String>(json['originalText']),
      extractedText: serializer.fromJson<String?>(json['extractedText']),
      editedText: serializer.fromJson<String?>(json['editedText']),
      proposedText: serializer.fromJson<String?>(json['proposedText']),
      source: $NotesTable.$convertersource.fromJson(serializer.fromJson<String>(json['source'])),
      status: $NotesTable.$converterstatus.fromJson(serializer.fromJson<String>(json['status'])),
      rewrite: $NotesTable.$converterrewrite.fromJson(serializer.fromJson<String>(json['rewrite'])),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      attachmentName: serializer.fromJson<String?>(json['attachmentName']),
      attachmentBytes: serializer.fromJson<int?>(json['attachmentBytes']),
      voicePath: serializer.fromJson<String?>(json['voicePath']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      imagePaths: serializer.fromJson<String>(json['imagePaths']),
      concepts: serializer.fromJson<String>(json['concepts']),
      cluster: serializer.fromJson<String?>(json['cluster']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      groupId: serializer.fromJson<String?>(json['groupId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'title': serializer.toJson<String>(title),
      'originalText': serializer.toJson<String>(originalText),
      'extractedText': serializer.toJson<String?>(extractedText),
      'editedText': serializer.toJson<String?>(editedText),
      'proposedText': serializer.toJson<String?>(proposedText),
      'source': serializer.toJson<String>($NotesTable.$convertersource.toJson(source)),
      'status': serializer.toJson<String>($NotesTable.$converterstatus.toJson(status)),
      'rewrite': serializer.toJson<String>($NotesTable.$converterrewrite.toJson(rewrite)),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'attachmentName': serializer.toJson<String?>(attachmentName),
      'attachmentBytes': serializer.toJson<int?>(attachmentBytes),
      'voicePath': serializer.toJson<String?>(voicePath),
      'durationMs': serializer.toJson<int?>(durationMs),
      'imagePaths': serializer.toJson<String>(imagePaths),
      'concepts': serializer.toJson<String>(concepts),
      'cluster': serializer.toJson<String?>(cluster),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'groupId': serializer.toJson<String?>(groupId),
    };
  }

  Note copyWith({
    String? id,
    String? projectId,
    String? title,
    String? originalText,
    Value<String?> extractedText = const Value.absent(),
    Value<String?> editedText = const Value.absent(),
    Value<String?> proposedText = const Value.absent(),
    NoteSource? source,
    ProcessingStatus? status,
    RewriteStatus? rewrite,
    Value<String?> attachmentPath = const Value.absent(),
    Value<String?> attachmentName = const Value.absent(),
    Value<int?> attachmentBytes = const Value.absent(),
    Value<String?> voicePath = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    String? imagePaths,
    String? concepts,
    Value<String?> cluster = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> groupId = const Value.absent(),
  }) => Note(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    title: title ?? this.title,
    originalText: originalText ?? this.originalText,
    extractedText: extractedText.present ? extractedText.value : this.extractedText,
    editedText: editedText.present ? editedText.value : this.editedText,
    proposedText: proposedText.present ? proposedText.value : this.proposedText,
    source: source ?? this.source,
    status: status ?? this.status,
    rewrite: rewrite ?? this.rewrite,
    attachmentPath: attachmentPath.present ? attachmentPath.value : this.attachmentPath,
    attachmentName: attachmentName.present ? attachmentName.value : this.attachmentName,
    attachmentBytes: attachmentBytes.present ? attachmentBytes.value : this.attachmentBytes,
    voicePath: voicePath.present ? voicePath.value : this.voicePath,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    imagePaths: imagePaths ?? this.imagePaths,
    concepts: concepts ?? this.concepts,
    cluster: cluster.present ? cluster.value : this.cluster,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    groupId: groupId.present ? groupId.value : this.groupId,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      originalText: data.originalText.present ? data.originalText.value : this.originalText,
      extractedText: data.extractedText.present ? data.extractedText.value : this.extractedText,
      editedText: data.editedText.present ? data.editedText.value : this.editedText,
      proposedText: data.proposedText.present ? data.proposedText.value : this.proposedText,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      rewrite: data.rewrite.present ? data.rewrite.value : this.rewrite,
      attachmentPath: data.attachmentPath.present ? data.attachmentPath.value : this.attachmentPath,
      attachmentName: data.attachmentName.present ? data.attachmentName.value : this.attachmentName,
      attachmentBytes: data.attachmentBytes.present ? data.attachmentBytes.value : this.attachmentBytes,
      voicePath: data.voicePath.present ? data.voicePath.value : this.voicePath,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      imagePaths: data.imagePaths.present ? data.imagePaths.value : this.imagePaths,
      concepts: data.concepts.present ? data.concepts.value : this.concepts,
      cluster: data.cluster.present ? data.cluster.value : this.cluster,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('originalText: $originalText, ')
          ..write('extractedText: $extractedText, ')
          ..write('editedText: $editedText, ')
          ..write('proposedText: $proposedText, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('rewrite: $rewrite, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('attachmentName: $attachmentName, ')
          ..write('attachmentBytes: $attachmentBytes, ')
          ..write('voicePath: $voicePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('concepts: $concepts, ')
          ..write('cluster: $cluster, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('groupId: $groupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    projectId,
    title,
    originalText,
    extractedText,
    editedText,
    proposedText,
    source,
    status,
    rewrite,
    attachmentPath,
    attachmentName,
    attachmentBytes,
    voicePath,
    durationMs,
    imagePaths,
    concepts,
    cluster,
    createdAt,
    updatedAt,
    groupId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.originalText == this.originalText &&
          other.extractedText == this.extractedText &&
          other.editedText == this.editedText &&
          other.proposedText == this.proposedText &&
          other.source == this.source &&
          other.status == this.status &&
          other.rewrite == this.rewrite &&
          other.attachmentPath == this.attachmentPath &&
          other.attachmentName == this.attachmentName &&
          other.attachmentBytes == this.attachmentBytes &&
          other.voicePath == this.voicePath &&
          other.durationMs == this.durationMs &&
          other.imagePaths == this.imagePaths &&
          other.concepts == this.concepts &&
          other.cluster == this.cluster &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.groupId == this.groupId);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> title;
  final Value<String> originalText;
  final Value<String?> extractedText;
  final Value<String?> editedText;
  final Value<String?> proposedText;
  final Value<NoteSource> source;
  final Value<ProcessingStatus> status;
  final Value<RewriteStatus> rewrite;
  final Value<String?> attachmentPath;
  final Value<String?> attachmentName;
  final Value<int?> attachmentBytes;
  final Value<String?> voicePath;
  final Value<int?> durationMs;
  final Value<String> imagePaths;
  final Value<String> concepts;
  final Value<String?> cluster;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> groupId;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalText = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.editedText = const Value.absent(),
    this.proposedText = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.rewrite = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.attachmentName = const Value.absent(),
    this.attachmentBytes = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.concepts = const Value.absent(),
    this.cluster = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String projectId,
    required String title,
    required String originalText,
    this.extractedText = const Value.absent(),
    this.editedText = const Value.absent(),
    this.proposedText = const Value.absent(),
    required NoteSource source,
    required ProcessingStatus status,
    this.rewrite = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.attachmentName = const Value.absent(),
    this.attachmentBytes = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.concepts = const Value.absent(),
    this.cluster = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.groupId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       title = Value(title),
       originalText = Value(originalText),
       source = Value(source),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? title,
    Expression<String>? originalText,
    Expression<String>? extractedText,
    Expression<String>? editedText,
    Expression<String>? proposedText,
    Expression<String>? source,
    Expression<String>? status,
    Expression<String>? rewrite,
    Expression<String>? attachmentPath,
    Expression<String>? attachmentName,
    Expression<int>? attachmentBytes,
    Expression<String>? voicePath,
    Expression<int>? durationMs,
    Expression<String>? imagePaths,
    Expression<String>? concepts,
    Expression<String>? cluster,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? groupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (originalText != null) 'original_text': originalText,
      if (extractedText != null) 'extracted_text': extractedText,
      if (editedText != null) 'edited_text': editedText,
      if (proposedText != null) 'proposed_text': proposedText,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (rewrite != null) 'rewrite': rewrite,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (attachmentName != null) 'attachment_name': attachmentName,
      if (attachmentBytes != null) 'attachment_bytes': attachmentBytes,
      if (voicePath != null) 'voice_path': voicePath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (concepts != null) 'concepts': concepts,
      if (cluster != null) 'cluster': cluster,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (groupId != null) 'group_id': groupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? title,
    Value<String>? originalText,
    Value<String?>? extractedText,
    Value<String?>? editedText,
    Value<String?>? proposedText,
    Value<NoteSource>? source,
    Value<ProcessingStatus>? status,
    Value<RewriteStatus>? rewrite,
    Value<String?>? attachmentPath,
    Value<String?>? attachmentName,
    Value<int?>? attachmentBytes,
    Value<String?>? voicePath,
    Value<int?>? durationMs,
    Value<String>? imagePaths,
    Value<String>? concepts,
    Value<String?>? cluster,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? groupId,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      originalText: originalText ?? this.originalText,
      extractedText: extractedText ?? this.extractedText,
      editedText: editedText ?? this.editedText,
      proposedText: proposedText ?? this.proposedText,
      source: source ?? this.source,
      status: status ?? this.status,
      rewrite: rewrite ?? this.rewrite,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentBytes: attachmentBytes ?? this.attachmentBytes,
      voicePath: voicePath ?? this.voicePath,
      durationMs: durationMs ?? this.durationMs,
      imagePaths: imagePaths ?? this.imagePaths,
      concepts: concepts ?? this.concepts,
      cluster: cluster ?? this.cluster,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      groupId: groupId ?? this.groupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalText.present) {
      map['original_text'] = Variable<String>(originalText.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
    }
    if (editedText.present) {
      map['edited_text'] = Variable<String>(editedText.value);
    }
    if (proposedText.present) {
      map['proposed_text'] = Variable<String>(proposedText.value);
    }
    if (source.present) {
      map['source'] = Variable<String>($NotesTable.$convertersource.toSql(source.value));
    }
    if (status.present) {
      map['status'] = Variable<String>($NotesTable.$converterstatus.toSql(status.value));
    }
    if (rewrite.present) {
      map['rewrite'] = Variable<String>($NotesTable.$converterrewrite.toSql(rewrite.value));
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (attachmentName.present) {
      map['attachment_name'] = Variable<String>(attachmentName.value);
    }
    if (attachmentBytes.present) {
      map['attachment_bytes'] = Variable<int>(attachmentBytes.value);
    }
    if (voicePath.present) {
      map['voice_path'] = Variable<String>(voicePath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (concepts.present) {
      map['concepts'] = Variable<String>(concepts.value);
    }
    if (cluster.present) {
      map['cluster'] = Variable<String>(cluster.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('originalText: $originalText, ')
          ..write('extractedText: $extractedText, ')
          ..write('editedText: $editedText, ')
          ..write('proposedText: $proposedText, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('rewrite: $rewrite, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('attachmentName: $attachmentName, ')
          ..write('attachmentBytes: $attachmentBytes, ')
          ..write('voicePath: $voicePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('concepts: $concepts, ')
          ..write('cluster: $cluster, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('groupId: $groupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteAttachmentsTable extends NoteAttachments with TableInfo<$NoteAttachmentsTable, NoteAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES notes (id) ON DELETE CASCADE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachmentKind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<AttachmentKind>($NoteAttachmentsTable.$converterkind);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transcriptMeta = const VerificationMeta('transcript');
  @override
  late final GeneratedColumn<String> transcript = GeneratedColumn<String>(
    'transcript',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptNoteTextMeta = const VerificationMeta('transcriptNoteText');
  @override
  late final GeneratedColumn<String> transcriptNoteText = GeneratedColumn<String>(
    'transcript_note_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptionOrderMeta = const VerificationMeta('transcriptionOrder');
  @override
  late final GeneratedColumn<int> transcriptionOrder = GeneratedColumn<int>(
    'transcription_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TranscriptionStatus, String> transcriptionStatus =
      GeneratedColumn<String>(
        'transcription_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('none'),
      ).withConverter<TranscriptionStatus>($NoteAttachmentsTable.$convertertranscriptionStatus);
  static const VerificationMeta _transcriptionFailureMeta = const VerificationMeta('transcriptionFailure');
  @override
  late final GeneratedColumn<String> transcriptionFailure = GeneratedColumn<String>(
    'transcription_failure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptionEngineMeta = const VerificationMeta('transcriptionEngine');
  @override
  late final GeneratedColumn<String> transcriptionEngine = GeneratedColumn<String>(
    'transcription_engine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcribedAtMeta = const VerificationMeta('transcribedAt');
  @override
  late final GeneratedColumn<DateTime> transcribedAt = GeneratedColumn<DateTime>(
    'transcribed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptionAttemptsMeta = const VerificationMeta('transcriptionAttempts');
  @override
  late final GeneratedColumn<int> transcriptionAttempts = GeneratedColumn<int>(
    'transcription_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TranscriptionPolicy, String> transcriptionPolicy =
      GeneratedColumn<String>(
        'transcription_policy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('off'),
      ).withConverter<TranscriptionPolicy>($NoteAttachmentsTable.$convertertranscriptionPolicy);
  static const VerificationMeta _transcriptCorrectionMeta = const VerificationMeta('transcriptCorrection');
  @override
  late final GeneratedColumn<String> transcriptCorrection = GeneratedColumn<String>(
    'transcript_correction',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctedAtMeta = const VerificationMeta('correctedAt');
  @override
  late final GeneratedColumn<DateTime> correctedAt = GeneratedColumn<DateTime>(
    'corrected_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transcriptRevisionMeta = const VerificationMeta('transcriptRevision');
  @override
  late final GeneratedColumn<int> transcriptRevision = GeneratedColumn<int>(
    'transcript_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    noteId,
    kind,
    path,
    name,
    bytes,
    durationMs,
    position,
    createdAt,
    transcript,
    transcriptNoteText,
    transcriptionOrder,
    transcriptionStatus,
    transcriptionFailure,
    transcriptionEngine,
    transcribedAt,
    transcriptionAttempts,
    transcriptionPolicy,
    transcriptCorrection,
    correctedAt,
    transcriptRevision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_attachments';
  @override
  VerificationContext validateIntegrity(Insertable<NoteAttachment> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta, noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('bytes')) {
      context.handle(_bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(_durationMsMeta, durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('transcript')) {
      context.handle(_transcriptMeta, transcript.isAcceptableOrUnknown(data['transcript']!, _transcriptMeta));
    }
    if (data.containsKey('transcript_note_text')) {
      context.handle(
        _transcriptNoteTextMeta,
        transcriptNoteText.isAcceptableOrUnknown(data['transcript_note_text']!, _transcriptNoteTextMeta),
      );
    }
    if (data.containsKey('transcription_order')) {
      context.handle(
        _transcriptionOrderMeta,
        transcriptionOrder.isAcceptableOrUnknown(data['transcription_order']!, _transcriptionOrderMeta),
      );
    }
    if (data.containsKey('transcription_failure')) {
      context.handle(
        _transcriptionFailureMeta,
        transcriptionFailure.isAcceptableOrUnknown(data['transcription_failure']!, _transcriptionFailureMeta),
      );
    }
    if (data.containsKey('transcription_engine')) {
      context.handle(
        _transcriptionEngineMeta,
        transcriptionEngine.isAcceptableOrUnknown(data['transcription_engine']!, _transcriptionEngineMeta),
      );
    }
    if (data.containsKey('transcribed_at')) {
      context.handle(
        _transcribedAtMeta,
        transcribedAt.isAcceptableOrUnknown(data['transcribed_at']!, _transcribedAtMeta),
      );
    }
    if (data.containsKey('transcription_attempts')) {
      context.handle(
        _transcriptionAttemptsMeta,
        transcriptionAttempts.isAcceptableOrUnknown(data['transcription_attempts']!, _transcriptionAttemptsMeta),
      );
    }
    if (data.containsKey('transcript_correction')) {
      context.handle(
        _transcriptCorrectionMeta,
        transcriptCorrection.isAcceptableOrUnknown(data['transcript_correction']!, _transcriptCorrectionMeta),
      );
    }
    if (data.containsKey('corrected_at')) {
      context.handle(_correctedAtMeta, correctedAt.isAcceptableOrUnknown(data['corrected_at']!, _correctedAtMeta));
    }
    if (data.containsKey('transcript_revision')) {
      context.handle(
        _transcriptRevisionMeta,
        transcriptRevision.isAcceptableOrUnknown(data['transcript_revision']!, _transcriptRevisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteAttachment(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      kind: $NoteAttachmentsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      ),
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name']),
      bytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}bytes']),
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      transcript: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transcript']),
      transcriptNoteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript_note_text'],
      ),
      transcriptionOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transcription_order'],
      ),
      transcriptionStatus: $NoteAttachmentsTable.$convertertranscriptionStatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transcription_status'])!,
      ),
      transcriptionFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcription_failure'],
      ),
      transcriptionEngine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcription_engine'],
      ),
      transcribedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}transcribed_at']),
      transcriptionAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transcription_attempts'],
      )!,
      transcriptionPolicy: $NoteAttachmentsTable.$convertertranscriptionPolicy.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}transcription_policy'])!,
      ),
      transcriptCorrection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcript_correction'],
      ),
      correctedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}corrected_at']),
      transcriptRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transcript_revision'],
      )!,
    );
  }

  @override
  $NoteAttachmentsTable createAlias(String alias) {
    return $NoteAttachmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AttachmentKind, String, String> $converterkind = const EnumNameConverter<AttachmentKind>(
    AttachmentKind.values,
  );
  static JsonTypeConverter2<TranscriptionStatus, String, String> $convertertranscriptionStatus =
      const EnumNameConverter<TranscriptionStatus>(TranscriptionStatus.values);
  static JsonTypeConverter2<TranscriptionPolicy, String, String> $convertertranscriptionPolicy =
      const EnumNameConverter<TranscriptionPolicy>(TranscriptionPolicy.values);
}

class NoteAttachment extends DataClass implements Insertable<NoteAttachment> {
  final String id;
  final String noteId;
  final AttachmentKind kind;
  final String path;
  final String? name;
  final int? bytes;
  final int? durationMs;
  final int position;
  final DateTime createdAt;
  final String? transcript;

  /// Last transcript represented in the note body, retained across redos so a
  /// different result cannot get appended again on every retry.
  final String? transcriptNoteText;
  final int? transcriptionOrder;
  final TranscriptionStatus transcriptionStatus;
  final String? transcriptionFailure;
  final String? transcriptionEngine;
  final DateTime? transcribedAt;

  /// Runs started since the last manual request, written before inference
  /// begins, so a native crash or out-of-memory kill still counts.
  final int transcriptionAttempts;
  final TranscriptionPolicy transcriptionPolicy;
  final String? transcriptCorrection;
  final DateTime? correctedAt;
  final int transcriptRevision;
  const NoteAttachment({
    required this.id,
    required this.noteId,
    required this.kind,
    required this.path,
    this.name,
    this.bytes,
    this.durationMs,
    required this.position,
    required this.createdAt,
    this.transcript,
    this.transcriptNoteText,
    this.transcriptionOrder,
    required this.transcriptionStatus,
    this.transcriptionFailure,
    this.transcriptionEngine,
    this.transcribedAt,
    required this.transcriptionAttempts,
    required this.transcriptionPolicy,
    this.transcriptCorrection,
    this.correctedAt,
    required this.transcriptRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    {
      map['kind'] = Variable<String>($NoteAttachmentsTable.$converterkind.toSql(kind));
    }
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<int>(bytes);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || transcript != null) {
      map['transcript'] = Variable<String>(transcript);
    }
    if (!nullToAbsent || transcriptNoteText != null) {
      map['transcript_note_text'] = Variable<String>(transcriptNoteText);
    }
    if (!nullToAbsent || transcriptionOrder != null) {
      map['transcription_order'] = Variable<int>(transcriptionOrder);
    }
    {
      map['transcription_status'] = Variable<String>(
        $NoteAttachmentsTable.$convertertranscriptionStatus.toSql(transcriptionStatus),
      );
    }
    if (!nullToAbsent || transcriptionFailure != null) {
      map['transcription_failure'] = Variable<String>(transcriptionFailure);
    }
    if (!nullToAbsent || transcriptionEngine != null) {
      map['transcription_engine'] = Variable<String>(transcriptionEngine);
    }
    if (!nullToAbsent || transcribedAt != null) {
      map['transcribed_at'] = Variable<DateTime>(transcribedAt);
    }
    map['transcription_attempts'] = Variable<int>(transcriptionAttempts);
    {
      map['transcription_policy'] = Variable<String>(
        $NoteAttachmentsTable.$convertertranscriptionPolicy.toSql(transcriptionPolicy),
      );
    }
    if (!nullToAbsent || transcriptCorrection != null) {
      map['transcript_correction'] = Variable<String>(transcriptCorrection);
    }
    if (!nullToAbsent || correctedAt != null) {
      map['corrected_at'] = Variable<DateTime>(correctedAt);
    }
    map['transcript_revision'] = Variable<int>(transcriptRevision);
    return map;
  }

  NoteAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return NoteAttachmentsCompanion(
      id: Value(id),
      noteId: Value(noteId),
      kind: Value(kind),
      path: Value(path),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      bytes: bytes == null && nullToAbsent ? const Value.absent() : Value(bytes),
      durationMs: durationMs == null && nullToAbsent ? const Value.absent() : Value(durationMs),
      position: Value(position),
      createdAt: Value(createdAt),
      transcript: transcript == null && nullToAbsent ? const Value.absent() : Value(transcript),
      transcriptNoteText: transcriptNoteText == null && nullToAbsent ? const Value.absent() : Value(transcriptNoteText),
      transcriptionOrder: transcriptionOrder == null && nullToAbsent ? const Value.absent() : Value(transcriptionOrder),
      transcriptionStatus: Value(transcriptionStatus),
      transcriptionFailure: transcriptionFailure == null && nullToAbsent
          ? const Value.absent()
          : Value(transcriptionFailure),
      transcriptionEngine: transcriptionEngine == null && nullToAbsent
          ? const Value.absent()
          : Value(transcriptionEngine),
      transcribedAt: transcribedAt == null && nullToAbsent ? const Value.absent() : Value(transcribedAt),
      transcriptionAttempts: Value(transcriptionAttempts),
      transcriptionPolicy: Value(transcriptionPolicy),
      transcriptCorrection: transcriptCorrection == null && nullToAbsent
          ? const Value.absent()
          : Value(transcriptCorrection),
      correctedAt: correctedAt == null && nullToAbsent ? const Value.absent() : Value(correctedAt),
      transcriptRevision: Value(transcriptRevision),
    );
  }

  factory NoteAttachment.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteAttachment(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      kind: $NoteAttachmentsTable.$converterkind.fromJson(serializer.fromJson<String>(json['kind'])),
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String?>(json['name']),
      bytes: serializer.fromJson<int?>(json['bytes']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      transcript: serializer.fromJson<String?>(json['transcript']),
      transcriptNoteText: serializer.fromJson<String?>(json['transcriptNoteText']),
      transcriptionOrder: serializer.fromJson<int?>(json['transcriptionOrder']),
      transcriptionStatus: $NoteAttachmentsTable.$convertertranscriptionStatus.fromJson(
        serializer.fromJson<String>(json['transcriptionStatus']),
      ),
      transcriptionFailure: serializer.fromJson<String?>(json['transcriptionFailure']),
      transcriptionEngine: serializer.fromJson<String?>(json['transcriptionEngine']),
      transcribedAt: serializer.fromJson<DateTime?>(json['transcribedAt']),
      transcriptionAttempts: serializer.fromJson<int>(json['transcriptionAttempts']),
      transcriptionPolicy: $NoteAttachmentsTable.$convertertranscriptionPolicy.fromJson(
        serializer.fromJson<String>(json['transcriptionPolicy']),
      ),
      transcriptCorrection: serializer.fromJson<String?>(json['transcriptCorrection']),
      correctedAt: serializer.fromJson<DateTime?>(json['correctedAt']),
      transcriptRevision: serializer.fromJson<int>(json['transcriptRevision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'kind': serializer.toJson<String>($NoteAttachmentsTable.$converterkind.toJson(kind)),
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String?>(name),
      'bytes': serializer.toJson<int?>(bytes),
      'durationMs': serializer.toJson<int?>(durationMs),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'transcript': serializer.toJson<String?>(transcript),
      'transcriptNoteText': serializer.toJson<String?>(transcriptNoteText),
      'transcriptionOrder': serializer.toJson<int?>(transcriptionOrder),
      'transcriptionStatus': serializer.toJson<String>(
        $NoteAttachmentsTable.$convertertranscriptionStatus.toJson(transcriptionStatus),
      ),
      'transcriptionFailure': serializer.toJson<String?>(transcriptionFailure),
      'transcriptionEngine': serializer.toJson<String?>(transcriptionEngine),
      'transcribedAt': serializer.toJson<DateTime?>(transcribedAt),
      'transcriptionAttempts': serializer.toJson<int>(transcriptionAttempts),
      'transcriptionPolicy': serializer.toJson<String>(
        $NoteAttachmentsTable.$convertertranscriptionPolicy.toJson(transcriptionPolicy),
      ),
      'transcriptCorrection': serializer.toJson<String?>(transcriptCorrection),
      'correctedAt': serializer.toJson<DateTime?>(correctedAt),
      'transcriptRevision': serializer.toJson<int>(transcriptRevision),
    };
  }

  NoteAttachment copyWith({
    String? id,
    String? noteId,
    AttachmentKind? kind,
    String? path,
    Value<String?> name = const Value.absent(),
    Value<int?> bytes = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    int? position,
    DateTime? createdAt,
    Value<String?> transcript = const Value.absent(),
    Value<String?> transcriptNoteText = const Value.absent(),
    Value<int?> transcriptionOrder = const Value.absent(),
    TranscriptionStatus? transcriptionStatus,
    Value<String?> transcriptionFailure = const Value.absent(),
    Value<String?> transcriptionEngine = const Value.absent(),
    Value<DateTime?> transcribedAt = const Value.absent(),
    int? transcriptionAttempts,
    TranscriptionPolicy? transcriptionPolicy,
    Value<String?> transcriptCorrection = const Value.absent(),
    Value<DateTime?> correctedAt = const Value.absent(),
    int? transcriptRevision,
  }) => NoteAttachment(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    kind: kind ?? this.kind,
    path: path ?? this.path,
    name: name.present ? name.value : this.name,
    bytes: bytes.present ? bytes.value : this.bytes,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    transcript: transcript.present ? transcript.value : this.transcript,
    transcriptNoteText: transcriptNoteText.present ? transcriptNoteText.value : this.transcriptNoteText,
    transcriptionOrder: transcriptionOrder.present ? transcriptionOrder.value : this.transcriptionOrder,
    transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
    transcriptionFailure: transcriptionFailure.present ? transcriptionFailure.value : this.transcriptionFailure,
    transcriptionEngine: transcriptionEngine.present ? transcriptionEngine.value : this.transcriptionEngine,
    transcribedAt: transcribedAt.present ? transcribedAt.value : this.transcribedAt,
    transcriptionAttempts: transcriptionAttempts ?? this.transcriptionAttempts,
    transcriptionPolicy: transcriptionPolicy ?? this.transcriptionPolicy,
    transcriptCorrection: transcriptCorrection.present ? transcriptCorrection.value : this.transcriptCorrection,
    correctedAt: correctedAt.present ? correctedAt.value : this.correctedAt,
    transcriptRevision: transcriptRevision ?? this.transcriptRevision,
  );
  NoteAttachment copyWithCompanion(NoteAttachmentsCompanion data) {
    return NoteAttachment(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      kind: data.kind.present ? data.kind.value : this.kind,
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      transcript: data.transcript.present ? data.transcript.value : this.transcript,
      transcriptNoteText: data.transcriptNoteText.present ? data.transcriptNoteText.value : this.transcriptNoteText,
      transcriptionOrder: data.transcriptionOrder.present ? data.transcriptionOrder.value : this.transcriptionOrder,
      transcriptionStatus: data.transcriptionStatus.present ? data.transcriptionStatus.value : this.transcriptionStatus,
      transcriptionFailure: data.transcriptionFailure.present
          ? data.transcriptionFailure.value
          : this.transcriptionFailure,
      transcriptionEngine: data.transcriptionEngine.present ? data.transcriptionEngine.value : this.transcriptionEngine,
      transcribedAt: data.transcribedAt.present ? data.transcribedAt.value : this.transcribedAt,
      transcriptionAttempts: data.transcriptionAttempts.present
          ? data.transcriptionAttempts.value
          : this.transcriptionAttempts,
      transcriptionPolicy: data.transcriptionPolicy.present ? data.transcriptionPolicy.value : this.transcriptionPolicy,
      transcriptCorrection: data.transcriptCorrection.present
          ? data.transcriptCorrection.value
          : this.transcriptCorrection,
      correctedAt: data.correctedAt.present ? data.correctedAt.value : this.correctedAt,
      transcriptRevision: data.transcriptRevision.present ? data.transcriptRevision.value : this.transcriptRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteAttachment(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('bytes: $bytes, ')
          ..write('durationMs: $durationMs, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('transcript: $transcript, ')
          ..write('transcriptNoteText: $transcriptNoteText, ')
          ..write('transcriptionOrder: $transcriptionOrder, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('transcriptionFailure: $transcriptionFailure, ')
          ..write('transcriptionEngine: $transcriptionEngine, ')
          ..write('transcribedAt: $transcribedAt, ')
          ..write('transcriptionAttempts: $transcriptionAttempts, ')
          ..write('transcriptionPolicy: $transcriptionPolicy, ')
          ..write('transcriptCorrection: $transcriptCorrection, ')
          ..write('correctedAt: $correctedAt, ')
          ..write('transcriptRevision: $transcriptRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    noteId,
    kind,
    path,
    name,
    bytes,
    durationMs,
    position,
    createdAt,
    transcript,
    transcriptNoteText,
    transcriptionOrder,
    transcriptionStatus,
    transcriptionFailure,
    transcriptionEngine,
    transcribedAt,
    transcriptionAttempts,
    transcriptionPolicy,
    transcriptCorrection,
    correctedAt,
    transcriptRevision,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteAttachment &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.kind == this.kind &&
          other.path == this.path &&
          other.name == this.name &&
          other.bytes == this.bytes &&
          other.durationMs == this.durationMs &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.transcript == this.transcript &&
          other.transcriptNoteText == this.transcriptNoteText &&
          other.transcriptionOrder == this.transcriptionOrder &&
          other.transcriptionStatus == this.transcriptionStatus &&
          other.transcriptionFailure == this.transcriptionFailure &&
          other.transcriptionEngine == this.transcriptionEngine &&
          other.transcribedAt == this.transcribedAt &&
          other.transcriptionAttempts == this.transcriptionAttempts &&
          other.transcriptionPolicy == this.transcriptionPolicy &&
          other.transcriptCorrection == this.transcriptCorrection &&
          other.correctedAt == this.correctedAt &&
          other.transcriptRevision == this.transcriptRevision);
}

class NoteAttachmentsCompanion extends UpdateCompanion<NoteAttachment> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<AttachmentKind> kind;
  final Value<String> path;
  final Value<String?> name;
  final Value<int?> bytes;
  final Value<int?> durationMs;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<String?> transcript;
  final Value<String?> transcriptNoteText;
  final Value<int?> transcriptionOrder;
  final Value<TranscriptionStatus> transcriptionStatus;
  final Value<String?> transcriptionFailure;
  final Value<String?> transcriptionEngine;
  final Value<DateTime?> transcribedAt;
  final Value<int> transcriptionAttempts;
  final Value<TranscriptionPolicy> transcriptionPolicy;
  final Value<String?> transcriptCorrection;
  final Value<DateTime?> correctedAt;
  final Value<int> transcriptRevision;
  final Value<int> rowid;
  const NoteAttachmentsCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.kind = const Value.absent(),
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.bytes = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.transcript = const Value.absent(),
    this.transcriptNoteText = const Value.absent(),
    this.transcriptionOrder = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.transcriptionFailure = const Value.absent(),
    this.transcriptionEngine = const Value.absent(),
    this.transcribedAt = const Value.absent(),
    this.transcriptionAttempts = const Value.absent(),
    this.transcriptionPolicy = const Value.absent(),
    this.transcriptCorrection = const Value.absent(),
    this.correctedAt = const Value.absent(),
    this.transcriptRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteAttachmentsCompanion.insert({
    required String id,
    required String noteId,
    required AttachmentKind kind,
    required String path,
    this.name = const Value.absent(),
    this.bytes = const Value.absent(),
    this.durationMs = const Value.absent(),
    required int position,
    required DateTime createdAt,
    this.transcript = const Value.absent(),
    this.transcriptNoteText = const Value.absent(),
    this.transcriptionOrder = const Value.absent(),
    this.transcriptionStatus = const Value.absent(),
    this.transcriptionFailure = const Value.absent(),
    this.transcriptionEngine = const Value.absent(),
    this.transcribedAt = const Value.absent(),
    this.transcriptionAttempts = const Value.absent(),
    this.transcriptionPolicy = const Value.absent(),
    this.transcriptCorrection = const Value.absent(),
    this.correctedAt = const Value.absent(),
    this.transcriptRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       noteId = Value(noteId),
       kind = Value(kind),
       path = Value(path),
       position = Value(position),
       createdAt = Value(createdAt);
  static Insertable<NoteAttachment> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? kind,
    Expression<String>? path,
    Expression<String>? name,
    Expression<int>? bytes,
    Expression<int>? durationMs,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<String>? transcript,
    Expression<String>? transcriptNoteText,
    Expression<int>? transcriptionOrder,
    Expression<String>? transcriptionStatus,
    Expression<String>? transcriptionFailure,
    Expression<String>? transcriptionEngine,
    Expression<DateTime>? transcribedAt,
    Expression<int>? transcriptionAttempts,
    Expression<String>? transcriptionPolicy,
    Expression<String>? transcriptCorrection,
    Expression<DateTime>? correctedAt,
    Expression<int>? transcriptRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (kind != null) 'kind': kind,
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (bytes != null) 'bytes': bytes,
      if (durationMs != null) 'duration_ms': durationMs,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (transcript != null) 'transcript': transcript,
      if (transcriptNoteText != null) 'transcript_note_text': transcriptNoteText,
      if (transcriptionOrder != null) 'transcription_order': transcriptionOrder,
      if (transcriptionStatus != null) 'transcription_status': transcriptionStatus,
      if (transcriptionFailure != null) 'transcription_failure': transcriptionFailure,
      if (transcriptionEngine != null) 'transcription_engine': transcriptionEngine,
      if (transcribedAt != null) 'transcribed_at': transcribedAt,
      if (transcriptionAttempts != null) 'transcription_attempts': transcriptionAttempts,
      if (transcriptionPolicy != null) 'transcription_policy': transcriptionPolicy,
      if (transcriptCorrection != null) 'transcript_correction': transcriptCorrection,
      if (correctedAt != null) 'corrected_at': correctedAt,
      if (transcriptRevision != null) 'transcript_revision': transcriptRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteAttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? noteId,
    Value<AttachmentKind>? kind,
    Value<String>? path,
    Value<String?>? name,
    Value<int?>? bytes,
    Value<int?>? durationMs,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<String?>? transcript,
    Value<String?>? transcriptNoteText,
    Value<int?>? transcriptionOrder,
    Value<TranscriptionStatus>? transcriptionStatus,
    Value<String?>? transcriptionFailure,
    Value<String?>? transcriptionEngine,
    Value<DateTime?>? transcribedAt,
    Value<int>? transcriptionAttempts,
    Value<TranscriptionPolicy>? transcriptionPolicy,
    Value<String?>? transcriptCorrection,
    Value<DateTime?>? correctedAt,
    Value<int>? transcriptRevision,
    Value<int>? rowid,
  }) {
    return NoteAttachmentsCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      kind: kind ?? this.kind,
      path: path ?? this.path,
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      durationMs: durationMs ?? this.durationMs,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      transcript: transcript ?? this.transcript,
      transcriptNoteText: transcriptNoteText ?? this.transcriptNoteText,
      transcriptionOrder: transcriptionOrder ?? this.transcriptionOrder,
      transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
      transcriptionFailure: transcriptionFailure ?? this.transcriptionFailure,
      transcriptionEngine: transcriptionEngine ?? this.transcriptionEngine,
      transcribedAt: transcribedAt ?? this.transcribedAt,
      transcriptionAttempts: transcriptionAttempts ?? this.transcriptionAttempts,
      transcriptionPolicy: transcriptionPolicy ?? this.transcriptionPolicy,
      transcriptCorrection: transcriptCorrection ?? this.transcriptCorrection,
      correctedAt: correctedAt ?? this.correctedAt,
      transcriptRevision: transcriptRevision ?? this.transcriptRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($NoteAttachmentsTable.$converterkind.toSql(kind.value));
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (transcript.present) {
      map['transcript'] = Variable<String>(transcript.value);
    }
    if (transcriptNoteText.present) {
      map['transcript_note_text'] = Variable<String>(transcriptNoteText.value);
    }
    if (transcriptionOrder.present) {
      map['transcription_order'] = Variable<int>(transcriptionOrder.value);
    }
    if (transcriptionStatus.present) {
      map['transcription_status'] = Variable<String>(
        $NoteAttachmentsTable.$convertertranscriptionStatus.toSql(transcriptionStatus.value),
      );
    }
    if (transcriptionFailure.present) {
      map['transcription_failure'] = Variable<String>(transcriptionFailure.value);
    }
    if (transcriptionEngine.present) {
      map['transcription_engine'] = Variable<String>(transcriptionEngine.value);
    }
    if (transcribedAt.present) {
      map['transcribed_at'] = Variable<DateTime>(transcribedAt.value);
    }
    if (transcriptionAttempts.present) {
      map['transcription_attempts'] = Variable<int>(transcriptionAttempts.value);
    }
    if (transcriptionPolicy.present) {
      map['transcription_policy'] = Variable<String>(
        $NoteAttachmentsTable.$convertertranscriptionPolicy.toSql(transcriptionPolicy.value),
      );
    }
    if (transcriptCorrection.present) {
      map['transcript_correction'] = Variable<String>(transcriptCorrection.value);
    }
    if (correctedAt.present) {
      map['corrected_at'] = Variable<DateTime>(correctedAt.value);
    }
    if (transcriptRevision.present) {
      map['transcript_revision'] = Variable<int>(transcriptRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('kind: $kind, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('bytes: $bytes, ')
          ..write('durationMs: $durationMs, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('transcript: $transcript, ')
          ..write('transcriptNoteText: $transcriptNoteText, ')
          ..write('transcriptionOrder: $transcriptionOrder, ')
          ..write('transcriptionStatus: $transcriptionStatus, ')
          ..write('transcriptionFailure: $transcriptionFailure, ')
          ..write('transcriptionEngine: $transcriptionEngine, ')
          ..write('transcribedAt: $transcribedAt, ')
          ..write('transcriptionAttempts: $transcriptionAttempts, ')
          ..write('transcriptionPolicy: $transcriptionPolicy, ')
          ..write('transcriptCorrection: $transcriptCorrection, ')
          ..write('correctedAt: $correctedAt, ')
          ..write('transcriptRevision: $transcriptRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteLinksTable extends NoteLinks with TableInfo<$NoteLinksTable, NoteLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES projects (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES notes (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta('targetId');
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES notes (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta('strength');
  @override
  late final GeneratedColumn<double> strength = GeneratedColumn<double>(
    'strength',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LinkOrigin, String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ai'),
  ).withConverter<LinkOrigin>($NoteLinksTable.$converterorigin);
  static const VerificationMeta _dismissedMeta = const VerificationMeta('dismissed');
  @override
  late final GeneratedColumn<bool> dismissed = GeneratedColumn<bool>(
    'dismissed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("dismissed" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    sourceId,
    targetId,
    label,
    strength,
    origin,
    dismissed,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_links';
  @override
  VerificationContext validateIntegrity(Insertable<NoteLink> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta, projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta, sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(_targetIdMeta, targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta));
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(_labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('strength')) {
      context.handle(_strengthMeta, strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta));
    } else if (isInserting) {
      context.missing(_strengthMeta);
    }
    if (data.containsKey('dismissed')) {
      context.handle(_dismissedMeta, dismissed.isAcceptableOrUnknown(data['dismissed']!, _dismissedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteLink(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      sourceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      targetId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}target_id'])!,
      label: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      strength: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}strength'])!,
      origin: $NoteLinksTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}origin'])!,
      ),
      dismissed: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}dismissed'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
    );
  }

  @override
  $NoteLinksTable createAlias(String alias) {
    return $NoteLinksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LinkOrigin, String, String> $converterorigin = const EnumNameConverter<LinkOrigin>(
    LinkOrigin.values,
  );
}

class NoteLink extends DataClass implements Insertable<NoteLink> {
  final String id;
  final String projectId;
  final String sourceId;
  final String targetId;
  final String label;
  final double strength;
  final LinkOrigin origin;
  final bool dismissed;
  final DateTime? createdAt;
  const NoteLink({
    required this.id,
    required this.projectId,
    required this.sourceId,
    required this.targetId,
    required this.label,
    required this.strength,
    required this.origin,
    required this.dismissed,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['source_id'] = Variable<String>(sourceId);
    map['target_id'] = Variable<String>(targetId);
    map['label'] = Variable<String>(label);
    map['strength'] = Variable<double>(strength);
    {
      map['origin'] = Variable<String>($NoteLinksTable.$converterorigin.toSql(origin));
    }
    map['dismissed'] = Variable<bool>(dismissed);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  NoteLinksCompanion toCompanion(bool nullToAbsent) {
    return NoteLinksCompanion(
      id: Value(id),
      projectId: Value(projectId),
      sourceId: Value(sourceId),
      targetId: Value(targetId),
      label: Value(label),
      strength: Value(strength),
      origin: Value(origin),
      dismissed: Value(dismissed),
      createdAt: createdAt == null && nullToAbsent ? const Value.absent() : Value(createdAt),
    );
  }

  factory NoteLink.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteLink(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      targetId: serializer.fromJson<String>(json['targetId']),
      label: serializer.fromJson<String>(json['label']),
      strength: serializer.fromJson<double>(json['strength']),
      origin: $NoteLinksTable.$converterorigin.fromJson(serializer.fromJson<String>(json['origin'])),
      dismissed: serializer.fromJson<bool>(json['dismissed']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'sourceId': serializer.toJson<String>(sourceId),
      'targetId': serializer.toJson<String>(targetId),
      'label': serializer.toJson<String>(label),
      'strength': serializer.toJson<double>(strength),
      'origin': serializer.toJson<String>($NoteLinksTable.$converterorigin.toJson(origin)),
      'dismissed': serializer.toJson<bool>(dismissed),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  NoteLink copyWith({
    String? id,
    String? projectId,
    String? sourceId,
    String? targetId,
    String? label,
    double? strength,
    LinkOrigin? origin,
    bool? dismissed,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => NoteLink(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    sourceId: sourceId ?? this.sourceId,
    targetId: targetId ?? this.targetId,
    label: label ?? this.label,
    strength: strength ?? this.strength,
    origin: origin ?? this.origin,
    dismissed: dismissed ?? this.dismissed,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  NoteLink copyWithCompanion(NoteLinksCompanion data) {
    return NoteLink(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      label: data.label.present ? data.label.value : this.label,
      strength: data.strength.present ? data.strength.value : this.strength,
      origin: data.origin.present ? data.origin.value : this.origin,
      dismissed: data.dismissed.present ? data.dismissed.value : this.dismissed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteLink(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('label: $label, ')
          ..write('strength: $strength, ')
          ..write('origin: $origin, ')
          ..write('dismissed: $dismissed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, sourceId, targetId, label, strength, origin, dismissed, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteLink &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.sourceId == this.sourceId &&
          other.targetId == this.targetId &&
          other.label == this.label &&
          other.strength == this.strength &&
          other.origin == this.origin &&
          other.dismissed == this.dismissed &&
          other.createdAt == this.createdAt);
}

class NoteLinksCompanion extends UpdateCompanion<NoteLink> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> sourceId;
  final Value<String> targetId;
  final Value<String> label;
  final Value<double> strength;
  final Value<LinkOrigin> origin;
  final Value<bool> dismissed;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const NoteLinksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.label = const Value.absent(),
    this.strength = const Value.absent(),
    this.origin = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteLinksCompanion.insert({
    required String id,
    required String projectId,
    required String sourceId,
    required String targetId,
    required String label,
    required double strength,
    this.origin = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       sourceId = Value(sourceId),
       targetId = Value(targetId),
       label = Value(label),
       strength = Value(strength);
  static Insertable<NoteLink> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? sourceId,
    Expression<String>? targetId,
    Expression<String>? label,
    Expression<double>? strength,
    Expression<String>? origin,
    Expression<bool>? dismissed,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (sourceId != null) 'source_id': sourceId,
      if (targetId != null) 'target_id': targetId,
      if (label != null) 'label': label,
      if (strength != null) 'strength': strength,
      if (origin != null) 'origin': origin,
      if (dismissed != null) 'dismissed': dismissed,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? sourceId,
    Value<String>? targetId,
    Value<String>? label,
    Value<double>? strength,
    Value<LinkOrigin>? origin,
    Value<bool>? dismissed,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return NoteLinksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      label: label ?? this.label,
      strength: strength ?? this.strength,
      origin: origin ?? this.origin,
      dismissed: dismissed ?? this.dismissed,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (strength.present) {
      map['strength'] = Variable<double>(strength.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>($NoteLinksTable.$converterorigin.toSql(origin.value));
    }
    if (dismissed.present) {
      map['dismissed'] = Variable<bool>(dismissed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteLinksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('label: $label, ')
          ..write('strength: $strength, ')
          ..write('origin: $origin, ')
          ..write('dismissed: $dismissed, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatEntriesTable extends ChatEntries with TableInfo<$ChatEntriesTable, ChatEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES projects (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdsMeta = const VerificationMeta('sourceIds');
  @override
  late final GeneratedColumn<String> sourceIds = GeneratedColumn<String>(
    'source_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _foundMeta = const VerificationMeta('found');
  @override
  late final GeneratedColumn<bool> found = GeneratedColumn<bool>(
    'found',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("found" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, projectId, role, body, sourceIds, found, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_entries';
  @override
  VerificationContext validateIntegrity(Insertable<ChatEntry> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta, projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(_roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('source_ids')) {
      context.handle(_sourceIdsMeta, sourceIds.isAcceptableOrUnknown(data['source_ids']!, _sourceIdsMeta));
    }
    if (data.containsKey('found')) {
      context.handle(_foundMeta, found.isAcceptableOrUnknown(data['found']!, _foundMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatEntry(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      role: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      sourceIds: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_ids'])!,
      found: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}found'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ChatEntriesTable createAlias(String alias) {
    return $ChatEntriesTable(attachedDatabase, alias);
  }
}

class ChatEntry extends DataClass implements Insertable<ChatEntry> {
  final String id;
  final String projectId;
  final String role;
  final String body;

  /// Cited note ids separated by '|'.
  final String sourceIds;
  final bool found;
  final DateTime createdAt;
  const ChatEntry({
    required this.id,
    required this.projectId,
    required this.role,
    required this.body,
    required this.sourceIds,
    required this.found,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['role'] = Variable<String>(role);
    map['body'] = Variable<String>(body);
    map['source_ids'] = Variable<String>(sourceIds);
    map['found'] = Variable<bool>(found);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ChatEntriesCompanion toCompanion(bool nullToAbsent) {
    return ChatEntriesCompanion(
      id: Value(id),
      projectId: Value(projectId),
      role: Value(role),
      body: Value(body),
      sourceIds: Value(sourceIds),
      found: Value(found),
      createdAt: Value(createdAt),
    );
  }

  factory ChatEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatEntry(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      role: serializer.fromJson<String>(json['role']),
      body: serializer.fromJson<String>(json['body']),
      sourceIds: serializer.fromJson<String>(json['sourceIds']),
      found: serializer.fromJson<bool>(json['found']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'role': serializer.toJson<String>(role),
      'body': serializer.toJson<String>(body),
      'sourceIds': serializer.toJson<String>(sourceIds),
      'found': serializer.toJson<bool>(found),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ChatEntry copyWith({
    String? id,
    String? projectId,
    String? role,
    String? body,
    String? sourceIds,
    bool? found,
    DateTime? createdAt,
  }) => ChatEntry(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    role: role ?? this.role,
    body: body ?? this.body,
    sourceIds: sourceIds ?? this.sourceIds,
    found: found ?? this.found,
    createdAt: createdAt ?? this.createdAt,
  );
  ChatEntry copyWithCompanion(ChatEntriesCompanion data) {
    return ChatEntry(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      role: data.role.present ? data.role.value : this.role,
      body: data.body.present ? data.body.value : this.body,
      sourceIds: data.sourceIds.present ? data.sourceIds.value : this.sourceIds,
      found: data.found.present ? data.found.value : this.found,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatEntry(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('role: $role, ')
          ..write('body: $body, ')
          ..write('sourceIds: $sourceIds, ')
          ..write('found: $found, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, role, body, sourceIds, found, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatEntry &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.role == this.role &&
          other.body == this.body &&
          other.sourceIds == this.sourceIds &&
          other.found == this.found &&
          other.createdAt == this.createdAt);
}

class ChatEntriesCompanion extends UpdateCompanion<ChatEntry> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> role;
  final Value<String> body;
  final Value<String> sourceIds;
  final Value<bool> found;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ChatEntriesCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.role = const Value.absent(),
    this.body = const Value.absent(),
    this.sourceIds = const Value.absent(),
    this.found = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatEntriesCompanion.insert({
    required String id,
    required String projectId,
    required String role,
    required String body,
    this.sourceIds = const Value.absent(),
    this.found = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       role = Value(role),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<ChatEntry> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? role,
    Expression<String>? body,
    Expression<String>? sourceIds,
    Expression<bool>? found,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (role != null) 'role': role,
      if (body != null) 'body': body,
      if (sourceIds != null) 'source_ids': sourceIds,
      if (found != null) 'found': found,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? role,
    Value<String>? body,
    Value<String>? sourceIds,
    Value<bool>? found,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ChatEntriesCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      role: role ?? this.role,
      body: body ?? this.body,
      sourceIds: sourceIds ?? this.sourceIds,
      found: found ?? this.found,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (sourceIds.present) {
      map['source_ids'] = Variable<String>(sourceIds.value);
    }
    if (found.present) {
      map['found'] = Variable<bool>(found.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatEntriesCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('role: $role, ')
          ..write('body: $body, ')
          ..write('sourceIds: $sourceIds, ')
          ..write('found: $found, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(key: serializer.fromJson<String>(json['key']), value: serializer.fromJson<String>(json['value']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String>(value)};
  }

  Setting copyWith({String? key, String? value}) => Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<Setting> custom({Expression<String>? key, Expression<String>? value, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
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
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FikraDatabase extends GeneratedDatabase {
  _$FikraDatabase(QueryExecutor e) : super(e);
  $FikraDatabaseManager get managers => $FikraDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $NoteGroupsTable noteGroups = $NoteGroupsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $NoteAttachmentsTable noteAttachments = $NoteAttachmentsTable(this);
  late final $NoteLinksTable noteLinks = $NoteLinksTable(this);
  late final $ChatEntriesTable chatEntries = $ChatEntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index noteGroupsProject = Index(
    'note_groups_project',
    'CREATE INDEX note_groups_project ON note_groups (project_id)',
  );
  late final Index noteGroupsParent = Index(
    'note_groups_parent',
    'CREATE INDEX note_groups_parent ON note_groups (parent_id)',
  );
  late final Index notesProjectCreated = Index(
    'notes_project_created',
    'CREATE INDEX notes_project_created ON notes (project_id, created_at)',
  );
  late final Index notesStatus = Index('notes_status', 'CREATE INDEX notes_status ON notes (status)');
  late final Index notesGroup = Index('notes_group', 'CREATE INDEX notes_group ON notes (group_id)');
  late final Index noteAttachmentsNote = Index(
    'note_attachments_note',
    'CREATE INDEX note_attachments_note ON note_attachments (note_id)',
  );
  late final Index noteLinksProject = Index(
    'note_links_project',
    'CREATE INDEX note_links_project ON note_links (project_id)',
  );
  late final Index noteLinksSource = Index(
    'note_links_source',
    'CREATE INDEX note_links_source ON note_links (source_id)',
  );
  late final Index noteLinksTarget = Index(
    'note_links_target',
    'CREATE INDEX note_links_target ON note_links (target_id)',
  );
  late final Index chatEntriesProjectCreated = Index(
    'chat_entries_project_created',
    'CREATE INDEX chat_entries_project_created ON chat_entries (project_id, created_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    noteGroups,
    notes,
    noteAttachments,
    noteLinks,
    chatEntries,
    settings,
    noteGroupsProject,
    noteGroupsParent,
    notesProjectCreated,
    notesStatus,
    notesGroup,
    noteAttachmentsNote,
    noteLinksProject,
    noteLinksSource,
    noteLinksTarget,
    chatEntriesProjectCreated,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('projects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('note_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('note_groups', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('note_groups', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('projects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('note_groups', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('notes', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('notes', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('note_attachments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('projects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('note_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('notes', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('note_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('notes', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('note_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('projects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('chat_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ProjectsTableReferences extends BaseReferences<_$FikraDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NoteGroupsTable, List<NoteGroup>> _noteGroupsRefsTable(_$FikraDatabase db) =>
      MultiTypedResultKey.fromTable(db.noteGroups, aliasName: 'projects__id__note_groups__project_id');

  $$NoteGroupsTableProcessedTableManager get noteGroupsRefs {
    final manager = $$NoteGroupsTableTableManager(
      $_db,
      $_db.noteGroups,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteGroupsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NotesTable, List<Note>> _notesRefsTable(_$FikraDatabase db) =>
      MultiTypedResultKey.fromTable(db.notes, aliasName: 'projects__id__notes__project_id');

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NoteLinksTable, List<NoteLink>> _noteLinksRefsTable(_$FikraDatabase db) =>
      MultiTypedResultKey.fromTable(db.noteLinks, aliasName: 'projects__id__note_links__project_id');

  $$NoteLinksTableProcessedTableManager get noteLinksRefs {
    final manager = $$NoteLinksTableTableManager(
      $_db,
      $_db.noteLinks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteLinksRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ChatEntriesTable, List<ChatEntry>> _chatEntriesRefsTable(_$FikraDatabase db) =>
      MultiTypedResultKey.fromTable(db.chatEntries, aliasName: 'projects__id__chat_entries__project_id');

  $$ChatEntriesTableProcessedTableManager get chatEntriesRefs {
    final manager = $$ChatEntriesTableTableManager(
      $_db,
      $_db.chatEntries,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatEntriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer extends Composer<_$FikraDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> noteGroupsRefs(Expression<bool> Function($$NoteGroupsTableFilterComposer f) f) {
    final $$NoteGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteGroups,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteGroupsTableFilterComposer(
            $db: $db,
            $table: $db.noteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notesRefs(Expression<bool> Function($$NotesTableFilterComposer f) f) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> noteLinksRefs(Expression<bool> Function($$NoteLinksTableFilterComposer f) f) {
    final $$NoteLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteLinks,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteLinksTableFilterComposer(
            $db: $db,
            $table: $db.noteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chatEntriesRefs(Expression<bool> Function($$ChatEntriesTableFilterComposer f) f) {
    final $$ChatEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatEntries,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ChatEntriesTableFilterComposer(
            $db: $db,
            $table: $db.chatEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer extends Composer<_$FikraDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer extends Composer<_$FikraDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> noteGroupsRefs<T extends Object>(Expression<T> Function($$NoteGroupsTableAnnotationComposer a) f) {
    final $$NoteGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteGroups,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notesRefs<T extends Object>(Expression<T> Function($$NotesTableAnnotationComposer a) f) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> noteLinksRefs<T extends Object>(Expression<T> Function($$NoteLinksTableAnnotationComposer a) f) {
    final $$NoteLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteLinks,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.noteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chatEntriesRefs<T extends Object>(Expression<T> Function($$ChatEntriesTableAnnotationComposer a) f) {
    final $$ChatEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatEntries,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ChatEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.chatEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$FikraDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool noteGroupsRefs, bool notesRefs, bool noteLinksRefs, bool chatEntriesRefs})
        > {
  $$ProjectsTableTableManager(_$FikraDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ProjectsCompanion(id: id, name: name, createdAt: createdAt, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String name,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) => ProjectsCompanion.insert(id: id, name: name, createdAt: createdAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$ProjectsTable, Project>(table), $$ProjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({noteGroupsRefs = false, notesRefs = false, noteLinksRefs = false, chatEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (noteGroupsRefs) db.noteGroups,
                    if (notesRefs) db.notes,
                    if (noteLinksRefs) db.noteLinks,
                    if (chatEntriesRefs) db.chatEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (noteGroupsRefs)
                        await $_getPrefetchedDataByColumns<Project, $ProjectsTable, NoteGroup, $NoteGroupsTable>(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences._noteGroupsRefsTable(db),
                          managerFromTypedResult: (p0) => $$ProjectsTableReferences(db, table, p0).noteGroupsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (notesRefs)
                        await $_getPrefetchedDataByColumns<Project, $ProjectsTable, Note, $NotesTable>(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences._notesRefsTable(db),
                          managerFromTypedResult: (p0) => $$ProjectsTableReferences(db, table, p0).notesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (noteLinksRefs)
                        await $_getPrefetchedDataByColumns<Project, $ProjectsTable, NoteLink, $NoteLinksTable>(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences._noteLinksRefsTable(db),
                          managerFromTypedResult: (p0) => $$ProjectsTableReferences(db, table, p0).noteLinksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                      if (chatEntriesRefs)
                        await $_getPrefetchedDataByColumns<Project, $ProjectsTable, ChatEntry, $ChatEntriesTable>(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences._chatEntriesRefsTable(db),
                          managerFromTypedResult: (p0) => $$ProjectsTableReferences(db, table, p0).chatEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'project_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$FikraDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool noteGroupsRefs, bool notesRefs, bool noteLinksRefs, bool chatEntriesRefs})
    >;
typedef $$NoteGroupsTableCreateCompanionBuilder = NoteGroupsCompanion Function({
  required String id,
  required String projectId,
  Value<String?> parentId,
  required String name,
  Value<int?> color,
  required int position,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$NoteGroupsTableUpdateCompanionBuilder = NoteGroupsCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String?> parentId,
  Value<String> name,
  Value<int?> color,
  Value<int> position,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$NoteGroupsTableReferences extends BaseReferences<_$FikraDatabase, $NoteGroupsTable, NoteGroup> {
  $$NoteGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$FikraDatabase db) =>
      db.projects.createAlias('note_groups__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $NoteGroupsTable _parentIdTable(_$FikraDatabase db) =>
      db.noteGroups.createAlias('note_groups__parent_id__note_groups__id');

  $$NoteGroupsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$NoteGroupsTableTableManager($_db, $_db.noteGroups).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$NotesTable, List<Note>> _notesRefsTable(_$FikraDatabase db) =>
      MultiTypedResultKey.fromTable(db.notes, aliasName: 'note_groups__id__notes__group_id');

  $$NotesTableProcessedTableManager get notesRefs {
    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_notesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NoteGroupsTableFilterComposer extends Composer<_$FikraDatabase, $NoteGroupsTable> {
  $$NoteGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NoteGroupsTableFilterComposer get parentId {
    final $$NoteGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.noteGroups,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteGroupsTableFilterComposer(
            $db: $db,
            $table: $db.noteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> notesRefs(Expression<bool> Function($$NotesTableFilterComposer f) f) {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.groupId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NoteGroupsTableOrderingComposer extends Composer<_$FikraDatabase, $NoteGroupsTable> {
  $$NoteGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NoteGroupsTableOrderingComposer get parentId {
    final $$NoteGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.noteGroups,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.noteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteGroupsTableAnnotationComposer extends Composer<_$FikraDatabase, $NoteGroupsTable> {
  $$NoteGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NoteGroupsTableAnnotationComposer get parentId {
    final $$NoteGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.noteGroups,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> notesRefs<T extends Object>(Expression<T> Function($$NotesTableAnnotationComposer a) f) {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.groupId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NoteGroupsTableTableManager
    extends
        RootTableManager<
          _$FikraDatabase,
          $NoteGroupsTable,
          NoteGroup,
          $$NoteGroupsTableFilterComposer,
          $$NoteGroupsTableOrderingComposer,
          $$NoteGroupsTableAnnotationComposer,
          $$NoteGroupsTableCreateCompanionBuilder,
          $$NoteGroupsTableUpdateCompanionBuilder,
          (NoteGroup, $$NoteGroupsTableReferences),
          NoteGroup,
          PrefetchHooks Function({bool projectId, bool parentId, bool notesRefs})
        > {
  $$NoteGroupsTableTableManager(_$FikraDatabase db, $NoteGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NoteGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NoteGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NoteGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteGroupsCompanion(
                id: id,
                projectId: projectId,
                parentId: parentId,
                name: name,
                color: color,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                Value<String?> parentId = const Value.absent(),
                required String name,
                Value<int?> color = const Value.absent(),
                required int position,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NoteGroupsCompanion.insert(
                id: id,
                projectId: projectId,
                parentId: parentId,
                name: name,
                color: color,
                position: position,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$NoteGroupsTable, NoteGroup>(table), $$NoteGroupsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({projectId = false, parentId = false, notesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (notesRefs) db.notes],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$NoteGroupsTableReferences._projectIdTable(db),
                        referencedColumn: $$NoteGroupsTableReferences._projectIdTable(db).id,
                      ) as T;
                    }
                    if (parentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parentId,
                        referencedTable: $$NoteGroupsTableReferences._parentIdTable(db),
                        referencedColumn: $$NoteGroupsTableReferences._parentIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notesRefs)
                    await $_getPrefetchedDataByColumns<NoteGroup, $NoteGroupsTable, Note, $NotesTable>(
                      currentTable: table,
                      referencedTable: $$NoteGroupsTableReferences._notesRefsTable(db),
                      managerFromTypedResult: (p0) => $$NoteGroupsTableReferences(db, table, p0).notesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'group_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NoteGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$FikraDatabase,
      $NoteGroupsTable,
      NoteGroup,
      $$NoteGroupsTableFilterComposer,
      $$NoteGroupsTableOrderingComposer,
      $$NoteGroupsTableAnnotationComposer,
      $$NoteGroupsTableCreateCompanionBuilder,
      $$NoteGroupsTableUpdateCompanionBuilder,
      (NoteGroup, $$NoteGroupsTableReferences),
      NoteGroup,
      PrefetchHooks Function({bool projectId, bool parentId, bool notesRefs})
    >;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  required String id,
  required String projectId,
  required String title,
  required String originalText,
  Value<String?> extractedText,
  Value<String?> editedText,
  Value<String?> proposedText,
  required NoteSource source,
  required ProcessingStatus status,
  Value<RewriteStatus> rewrite,
  Value<String?> attachmentPath,
  Value<String?> attachmentName,
  Value<int?> attachmentBytes,
  Value<String?> voicePath,
  Value<int?> durationMs,
  Value<String> imagePaths,
  Value<String> concepts,
  Value<String?> cluster,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> groupId,
  Value<int> rowid,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> title,
  Value<String> originalText,
  Value<String?> extractedText,
  Value<String?> editedText,
  Value<String?> proposedText,
  Value<NoteSource> source,
  Value<ProcessingStatus> status,
  Value<RewriteStatus> rewrite,
  Value<String?> attachmentPath,
  Value<String?> attachmentName,
  Value<int?> attachmentBytes,
  Value<String?> voicePath,
  Value<int?> durationMs,
  Value<String> imagePaths,
  Value<String> concepts,
  Value<String?> cluster,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> groupId,
  Value<int> rowid,
});

final class $$NotesTableReferences extends BaseReferences<_$FikraDatabase, $NotesTable, Note> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$FikraDatabase db) =>
      db.projects.createAlias('notes__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $NoteGroupsTable _groupIdTable(_$FikraDatabase db) =>
      db.noteGroups.createAlias('notes__group_id__note_groups__id');

  $$NoteGroupsTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<String>('group_id');
    if ($_column == null) return null;
    final manager = $$NoteGroupsTableTableManager($_db, $_db.noteGroups).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$NoteAttachmentsTable, List<NoteAttachment>> _noteAttachmentsRefsTable(
    _$FikraDatabase db,
  ) => MultiTypedResultKey.fromTable(db.noteAttachments, aliasName: 'notes__id__note_attachments__note_id');

  $$NoteAttachmentsTableProcessedTableManager get noteAttachmentsRefs {
    final manager = $$NoteAttachmentsTableTableManager(
      $_db,
      $_db.noteAttachments,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteAttachmentsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NoteLinksTable, List<NoteLink>> _outgoingLinksTable(_$FikraDatabase db) =>
      MultiTypedResultKey.fromTable(db.noteLinks, aliasName: 'notes__id__note_links__source_id');

  $$NoteLinksTableProcessedTableManager get outgoingLinks {
    final manager = $$NoteLinksTableTableManager(
      $_db,
      $_db.noteLinks,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outgoingLinksTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NoteLinksTable, List<NoteLink>> _incomingLinksTable(_$FikraDatabase db) =>
      MultiTypedResultKey.fromTable(db.noteLinks, aliasName: 'notes__id__note_links__target_id');

  $$NoteLinksTableProcessedTableManager get incomingLinks {
    final manager = $$NoteLinksTableTableManager(
      $_db,
      $_db.noteLinks,
    ).filter((f) => f.targetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomingLinksTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NotesTableFilterComposer extends Composer<_$FikraDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalText =>
      $composableBuilder(column: $table.originalText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get extractedText =>
      $composableBuilder(column: $table.extractedText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get editedText =>
      $composableBuilder(column: $table.editedText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get proposedText =>
      $composableBuilder(column: $table.proposedText, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<NoteSource, NoteSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ProcessingStatus, ProcessingStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<RewriteStatus, RewriteStatus, String> get rewrite =>
      $composableBuilder(column: $table.rewrite, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get attachmentPath =>
      $composableBuilder(column: $table.attachmentPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachmentName =>
      $composableBuilder(column: $table.attachmentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attachmentBytes =>
      $composableBuilder(column: $table.attachmentBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get voicePath =>
      $composableBuilder(column: $table.voicePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePaths =>
      $composableBuilder(column: $table.imagePaths, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get concepts =>
      $composableBuilder(column: $table.concepts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cluster =>
      $composableBuilder(column: $table.cluster, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NoteGroupsTableFilterComposer get groupId {
    final $$NoteGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.noteGroups,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteGroupsTableFilterComposer(
            $db: $db,
            $table: $db.noteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> noteAttachmentsRefs(Expression<bool> Function($$NoteAttachmentsTableFilterComposer f) f) {
    final $$NoteAttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteAttachments,
      getReferencedColumn: (t) => t.noteId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteAttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.noteAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outgoingLinks(Expression<bool> Function($$NoteLinksTableFilterComposer f) f) {
    final $$NoteLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteLinks,
      getReferencedColumn: (t) => t.sourceId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteLinksTableFilterComposer(
            $db: $db,
            $table: $db.noteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingLinks(Expression<bool> Function($$NoteLinksTableFilterComposer f) f) {
    final $$NoteLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteLinks,
      getReferencedColumn: (t) => t.targetId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteLinksTableFilterComposer(
            $db: $db,
            $table: $db.noteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableOrderingComposer extends Composer<_$FikraDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalText =>
      $composableBuilder(column: $table.originalText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get extractedText =>
      $composableBuilder(column: $table.extractedText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get editedText =>
      $composableBuilder(column: $table.editedText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get proposedText =>
      $composableBuilder(column: $table.proposedText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rewrite =>
      $composableBuilder(column: $table.rewrite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachmentPath =>
      $composableBuilder(column: $table.attachmentPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachmentName =>
      $composableBuilder(column: $table.attachmentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attachmentBytes =>
      $composableBuilder(column: $table.attachmentBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voicePath =>
      $composableBuilder(column: $table.voicePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePaths =>
      $composableBuilder(column: $table.imagePaths, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get concepts =>
      $composableBuilder(column: $table.concepts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cluster =>
      $composableBuilder(column: $table.cluster, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NoteGroupsTableOrderingComposer get groupId {
    final $$NoteGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.noteGroups,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.noteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotesTableAnnotationComposer extends Composer<_$FikraDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalText =>
      $composableBuilder(column: $table.originalText, builder: (column) => column);

  GeneratedColumn<String> get extractedText =>
      $composableBuilder(column: $table.extractedText, builder: (column) => column);

  GeneratedColumn<String> get editedText => $composableBuilder(column: $table.editedText, builder: (column) => column);

  GeneratedColumn<String> get proposedText =>
      $composableBuilder(column: $table.proposedText, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NoteSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProcessingStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RewriteStatus, String> get rewrite =>
      $composableBuilder(column: $table.rewrite, builder: (column) => column);

  GeneratedColumn<String> get attachmentPath =>
      $composableBuilder(column: $table.attachmentPath, builder: (column) => column);

  GeneratedColumn<String> get attachmentName =>
      $composableBuilder(column: $table.attachmentName, builder: (column) => column);

  GeneratedColumn<int> get attachmentBytes =>
      $composableBuilder(column: $table.attachmentBytes, builder: (column) => column);

  GeneratedColumn<String> get voicePath => $composableBuilder(column: $table.voicePath, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get imagePaths => $composableBuilder(column: $table.imagePaths, builder: (column) => column);

  GeneratedColumn<String> get concepts => $composableBuilder(column: $table.concepts, builder: (column) => column);

  GeneratedColumn<String> get cluster => $composableBuilder(column: $table.cluster, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NoteGroupsTableAnnotationComposer get groupId {
    final $$NoteGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.noteGroups,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> noteAttachmentsRefs<T extends Object>(
    Expression<T> Function($$NoteAttachmentsTableAnnotationComposer a) f,
  ) {
    final $$NoteAttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteAttachments,
      getReferencedColumn: (t) => t.noteId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteAttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteAttachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outgoingLinks<T extends Object>(Expression<T> Function($$NoteLinksTableAnnotationComposer a) f) {
    final $$NoteLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteLinks,
      getReferencedColumn: (t) => t.sourceId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.noteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomingLinks<T extends Object>(Expression<T> Function($$NoteLinksTableAnnotationComposer a) f) {
    final $$NoteLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteLinks,
      getReferencedColumn: (t) => t.targetId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NoteLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.noteLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$FikraDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, $$NotesTableReferences),
          Note,
          PrefetchHooks Function({
            bool projectId,
            bool groupId,
            bool noteAttachmentsRefs,
            bool outgoingLinks,
            bool incomingLinks,
          })
        > {
  $$NotesTableTableManager(_$FikraDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> originalText = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<String?> editedText = const Value.absent(),
                Value<String?> proposedText = const Value.absent(),
                Value<NoteSource> source = const Value.absent(),
                Value<ProcessingStatus> status = const Value.absent(),
                Value<RewriteStatus> rewrite = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<String?> attachmentName = const Value.absent(),
                Value<int?> attachmentBytes = const Value.absent(),
                Value<String?> voicePath = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String> imagePaths = const Value.absent(),
                Value<String> concepts = const Value.absent(),
                Value<String?> cluster = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                projectId: projectId,
                title: title,
                originalText: originalText,
                extractedText: extractedText,
                editedText: editedText,
                proposedText: proposedText,
                source: source,
                status: status,
                rewrite: rewrite,
                attachmentPath: attachmentPath,
                attachmentName: attachmentName,
                attachmentBytes: attachmentBytes,
                voicePath: voicePath,
                durationMs: durationMs,
                imagePaths: imagePaths,
                concepts: concepts,
                cluster: cluster,
                createdAt: createdAt,
                updatedAt: updatedAt,
                groupId: groupId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String title,
                required String originalText,
                Value<String?> extractedText = const Value.absent(),
                Value<String?> editedText = const Value.absent(),
                Value<String?> proposedText = const Value.absent(),
                required NoteSource source,
                required ProcessingStatus status,
                Value<RewriteStatus> rewrite = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<String?> attachmentName = const Value.absent(),
                Value<int?> attachmentBytes = const Value.absent(),
                Value<String?> voicePath = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<String> imagePaths = const Value.absent(),
                Value<String> concepts = const Value.absent(),
                Value<String?> cluster = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> groupId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                projectId: projectId,
                title: title,
                originalText: originalText,
                extractedText: extractedText,
                editedText: editedText,
                proposedText: proposedText,
                source: source,
                status: status,
                rewrite: rewrite,
                attachmentPath: attachmentPath,
                attachmentName: attachmentName,
                attachmentBytes: attachmentBytes,
                voicePath: voicePath,
                durationMs: durationMs,
                imagePaths: imagePaths,
                concepts: concepts,
                cluster: cluster,
                createdAt: createdAt,
                updatedAt: updatedAt,
                groupId: groupId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$NotesTable, Note>(table), $$NotesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({
                projectId = false,
                groupId = false,
                noteAttachmentsRefs = false,
                outgoingLinks = false,
                incomingLinks = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (noteAttachmentsRefs) db.noteAttachments,
                    if (outgoingLinks) db.noteLinks,
                    if (incomingLinks) db.noteLinks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (projectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.projectId,
                            referencedTable: $$NotesTableReferences._projectIdTable(db),
                            referencedColumn: $$NotesTableReferences._projectIdTable(db).id,
                          ) as T;
                        }
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$NotesTableReferences._groupIdTable(db),
                            referencedColumn: $$NotesTableReferences._groupIdTable(db).id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (noteAttachmentsRefs)
                        await $_getPrefetchedDataByColumns<Note, $NotesTable, NoteAttachment, $NoteAttachmentsTable>(
                          currentTable: table,
                          referencedTable: $$NotesTableReferences._noteAttachmentsRefsTable(db),
                          managerFromTypedResult: (p0) => $$NotesTableReferences(db, table, p0).noteAttachmentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'note_id',
                          typedResults: items,
                        ),
                      if (outgoingLinks)
                        await $_getPrefetchedDataByColumns<Note, $NotesTable, NoteLink, $NoteLinksTable>(
                          currentTable: table,
                          referencedTable: $$NotesTableReferences._outgoingLinksTable(db),
                          managerFromTypedResult: (p0) => $$NotesTableReferences(db, table, p0).outgoingLinks,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                      if (incomingLinks)
                        await $_getPrefetchedDataByColumns<Note, $NotesTable, NoteLink, $NoteLinksTable>(
                          currentTable: table,
                          referencedTable: $$NotesTableReferences._incomingLinksTable(db),
                          managerFromTypedResult: (p0) => $$NotesTableReferences(db, table, p0).incomingLinks,
                          currentColumn: 'id',
                          referencedColumn: 'target_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$FikraDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, $$NotesTableReferences),
      Note,
      PrefetchHooks Function({
        bool projectId,
        bool groupId,
        bool noteAttachmentsRefs,
        bool outgoingLinks,
        bool incomingLinks,
      })
    >;
typedef $$NoteAttachmentsTableCreateCompanionBuilder = NoteAttachmentsCompanion Function({
  required String id,
  required String noteId,
  required AttachmentKind kind,
  required String path,
  Value<String?> name,
  Value<int?> bytes,
  Value<int?> durationMs,
  required int position,
  required DateTime createdAt,
  Value<String?> transcript,
  Value<String?> transcriptNoteText,
  Value<int?> transcriptionOrder,
  Value<TranscriptionStatus> transcriptionStatus,
  Value<String?> transcriptionFailure,
  Value<String?> transcriptionEngine,
  Value<DateTime?> transcribedAt,
  Value<int> transcriptionAttempts,
  Value<TranscriptionPolicy> transcriptionPolicy,
  Value<String?> transcriptCorrection,
  Value<DateTime?> correctedAt,
  Value<int> transcriptRevision,
  Value<int> rowid,
});
typedef $$NoteAttachmentsTableUpdateCompanionBuilder = NoteAttachmentsCompanion Function({
  Value<String> id,
  Value<String> noteId,
  Value<AttachmentKind> kind,
  Value<String> path,
  Value<String?> name,
  Value<int?> bytes,
  Value<int?> durationMs,
  Value<int> position,
  Value<DateTime> createdAt,
  Value<String?> transcript,
  Value<String?> transcriptNoteText,
  Value<int?> transcriptionOrder,
  Value<TranscriptionStatus> transcriptionStatus,
  Value<String?> transcriptionFailure,
  Value<String?> transcriptionEngine,
  Value<DateTime?> transcribedAt,
  Value<int> transcriptionAttempts,
  Value<TranscriptionPolicy> transcriptionPolicy,
  Value<String?> transcriptCorrection,
  Value<DateTime?> correctedAt,
  Value<int> transcriptRevision,
  Value<int> rowid,
});

final class $$NoteAttachmentsTableReferences
    extends BaseReferences<_$FikraDatabase, $NoteAttachmentsTable, NoteAttachment> {
  $$NoteAttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotesTable _noteIdTable(_$FikraDatabase db) => db.notes.createAlias('note_attachments__note_id__notes__id');

  $$NotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NotesTableTableManager($_db, $_db.notes).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NoteAttachmentsTableFilterComposer extends Composer<_$FikraDatabase, $NoteAttachmentsTable> {
  $$NoteAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AttachmentKind, AttachmentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get path => $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytes => $composableBuilder(column: $table.bytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcript =>
      $composableBuilder(column: $table.transcript, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcriptNoteText =>
      $composableBuilder(column: $table.transcriptNoteText, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transcriptionOrder =>
      $composableBuilder(column: $table.transcriptionOrder, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TranscriptionStatus, TranscriptionStatus, String> get transcriptionStatus =>
      $composableBuilder(
        column: $table.transcriptionStatus,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get transcriptionFailure =>
      $composableBuilder(column: $table.transcriptionFailure, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcriptionEngine =>
      $composableBuilder(column: $table.transcriptionEngine, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get transcribedAt =>
      $composableBuilder(column: $table.transcribedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transcriptionAttempts =>
      $composableBuilder(column: $table.transcriptionAttempts, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TranscriptionPolicy, TranscriptionPolicy, String> get transcriptionPolicy =>
      $composableBuilder(
        column: $table.transcriptionPolicy,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get transcriptCorrection =>
      $composableBuilder(column: $table.transcriptCorrection, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get correctedAt =>
      $composableBuilder(column: $table.correctedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get transcriptRevision =>
      $composableBuilder(column: $table.transcriptRevision, builder: (column) => ColumnFilters(column));

  $$NotesTableFilterComposer get noteId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteAttachmentsTableOrderingComposer extends Composer<_$FikraDatabase, $NoteAttachmentsTable> {
  $$NoteAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcript =>
      $composableBuilder(column: $table.transcript, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptNoteText =>
      $composableBuilder(column: $table.transcriptNoteText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transcriptionOrder =>
      $composableBuilder(column: $table.transcriptionOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionStatus =>
      $composableBuilder(column: $table.transcriptionStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionFailure =>
      $composableBuilder(column: $table.transcriptionFailure, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionEngine =>
      $composableBuilder(column: $table.transcriptionEngine, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get transcribedAt =>
      $composableBuilder(column: $table.transcribedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transcriptionAttempts =>
      $composableBuilder(column: $table.transcriptionAttempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptionPolicy =>
      $composableBuilder(column: $table.transcriptionPolicy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcriptCorrection =>
      $composableBuilder(column: $table.transcriptCorrection, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get correctedAt =>
      $composableBuilder(column: $table.correctedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get transcriptRevision =>
      $composableBuilder(column: $table.transcriptRevision, builder: (column) => ColumnOrderings(column));

  $$NotesTableOrderingComposer get noteId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteAttachmentsTableAnnotationComposer extends Composer<_$FikraDatabase, $NoteAttachmentsTable> {
  $$NoteAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AttachmentKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get bytes => $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get transcript => $composableBuilder(column: $table.transcript, builder: (column) => column);

  GeneratedColumn<String> get transcriptNoteText =>
      $composableBuilder(column: $table.transcriptNoteText, builder: (column) => column);

  GeneratedColumn<int> get transcriptionOrder =>
      $composableBuilder(column: $table.transcriptionOrder, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TranscriptionStatus, String> get transcriptionStatus =>
      $composableBuilder(column: $table.transcriptionStatus, builder: (column) => column);

  GeneratedColumn<String> get transcriptionFailure =>
      $composableBuilder(column: $table.transcriptionFailure, builder: (column) => column);

  GeneratedColumn<String> get transcriptionEngine =>
      $composableBuilder(column: $table.transcriptionEngine, builder: (column) => column);

  GeneratedColumn<DateTime> get transcribedAt =>
      $composableBuilder(column: $table.transcribedAt, builder: (column) => column);

  GeneratedColumn<int> get transcriptionAttempts =>
      $composableBuilder(column: $table.transcriptionAttempts, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TranscriptionPolicy, String> get transcriptionPolicy =>
      $composableBuilder(column: $table.transcriptionPolicy, builder: (column) => column);

  GeneratedColumn<String> get transcriptCorrection =>
      $composableBuilder(column: $table.transcriptCorrection, builder: (column) => column);

  GeneratedColumn<DateTime> get correctedAt =>
      $composableBuilder(column: $table.correctedAt, builder: (column) => column);

  GeneratedColumn<int> get transcriptRevision =>
      $composableBuilder(column: $table.transcriptRevision, builder: (column) => column);

  $$NotesTableAnnotationComposer get noteId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteAttachmentsTableTableManager
    extends
        RootTableManager<
          _$FikraDatabase,
          $NoteAttachmentsTable,
          NoteAttachment,
          $$NoteAttachmentsTableFilterComposer,
          $$NoteAttachmentsTableOrderingComposer,
          $$NoteAttachmentsTableAnnotationComposer,
          $$NoteAttachmentsTableCreateCompanionBuilder,
          $$NoteAttachmentsTableUpdateCompanionBuilder,
          (NoteAttachment, $$NoteAttachmentsTableReferences),
          NoteAttachment,
          PrefetchHooks Function({bool noteId})
        > {
  $$NoteAttachmentsTableTableManager(_$FikraDatabase db, $NoteAttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NoteAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NoteAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NoteAttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<AttachmentKind> kind = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> transcript = const Value.absent(),
                Value<String?> transcriptNoteText = const Value.absent(),
                Value<int?> transcriptionOrder = const Value.absent(),
                Value<TranscriptionStatus> transcriptionStatus = const Value.absent(),
                Value<String?> transcriptionFailure = const Value.absent(),
                Value<String?> transcriptionEngine = const Value.absent(),
                Value<DateTime?> transcribedAt = const Value.absent(),
                Value<int> transcriptionAttempts = const Value.absent(),
                Value<TranscriptionPolicy> transcriptionPolicy = const Value.absent(),
                Value<String?> transcriptCorrection = const Value.absent(),
                Value<DateTime?> correctedAt = const Value.absent(),
                Value<int> transcriptRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteAttachmentsCompanion(
                id: id,
                noteId: noteId,
                kind: kind,
                path: path,
                name: name,
                bytes: bytes,
                durationMs: durationMs,
                position: position,
                createdAt: createdAt,
                transcript: transcript,
                transcriptNoteText: transcriptNoteText,
                transcriptionOrder: transcriptionOrder,
                transcriptionStatus: transcriptionStatus,
                transcriptionFailure: transcriptionFailure,
                transcriptionEngine: transcriptionEngine,
                transcribedAt: transcribedAt,
                transcriptionAttempts: transcriptionAttempts,
                transcriptionPolicy: transcriptionPolicy,
                transcriptCorrection: transcriptCorrection,
                correctedAt: correctedAt,
                transcriptRevision: transcriptRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String noteId,
                required AttachmentKind kind,
                required String path,
                Value<String?> name = const Value.absent(),
                Value<int?> bytes = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                required int position,
                required DateTime createdAt,
                Value<String?> transcript = const Value.absent(),
                Value<String?> transcriptNoteText = const Value.absent(),
                Value<int?> transcriptionOrder = const Value.absent(),
                Value<TranscriptionStatus> transcriptionStatus = const Value.absent(),
                Value<String?> transcriptionFailure = const Value.absent(),
                Value<String?> transcriptionEngine = const Value.absent(),
                Value<DateTime?> transcribedAt = const Value.absent(),
                Value<int> transcriptionAttempts = const Value.absent(),
                Value<TranscriptionPolicy> transcriptionPolicy = const Value.absent(),
                Value<String?> transcriptCorrection = const Value.absent(),
                Value<DateTime?> correctedAt = const Value.absent(),
                Value<int> transcriptRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteAttachmentsCompanion.insert(
                id: id,
                noteId: noteId,
                kind: kind,
                path: path,
                name: name,
                bytes: bytes,
                durationMs: durationMs,
                position: position,
                createdAt: createdAt,
                transcript: transcript,
                transcriptNoteText: transcriptNoteText,
                transcriptionOrder: transcriptionOrder,
                transcriptionStatus: transcriptionStatus,
                transcriptionFailure: transcriptionFailure,
                transcriptionEngine: transcriptionEngine,
                transcribedAt: transcribedAt,
                transcriptionAttempts: transcriptionAttempts,
                transcriptionPolicy: transcriptionPolicy,
                transcriptCorrection: transcriptCorrection,
                correctedAt: correctedAt,
                transcriptRevision: transcriptRevision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteAttachmentsTable, NoteAttachment>(table),
                  $$NoteAttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (noteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.noteId,
                        referencedTable: $$NoteAttachmentsTableReferences._noteIdTable(db),
                        referencedColumn: $$NoteAttachmentsTableReferences._noteIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NoteAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$FikraDatabase,
      $NoteAttachmentsTable,
      NoteAttachment,
      $$NoteAttachmentsTableFilterComposer,
      $$NoteAttachmentsTableOrderingComposer,
      $$NoteAttachmentsTableAnnotationComposer,
      $$NoteAttachmentsTableCreateCompanionBuilder,
      $$NoteAttachmentsTableUpdateCompanionBuilder,
      (NoteAttachment, $$NoteAttachmentsTableReferences),
      NoteAttachment,
      PrefetchHooks Function({bool noteId})
    >;
typedef $$NoteLinksTableCreateCompanionBuilder = NoteLinksCompanion Function({
  required String id,
  required String projectId,
  required String sourceId,
  required String targetId,
  required String label,
  required double strength,
  Value<LinkOrigin> origin,
  Value<bool> dismissed,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});
typedef $$NoteLinksTableUpdateCompanionBuilder = NoteLinksCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> sourceId,
  Value<String> targetId,
  Value<String> label,
  Value<double> strength,
  Value<LinkOrigin> origin,
  Value<bool> dismissed,
  Value<DateTime?> createdAt,
  Value<int> rowid,
});

final class $$NoteLinksTableReferences extends BaseReferences<_$FikraDatabase, $NoteLinksTable, NoteLink> {
  $$NoteLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$FikraDatabase db) =>
      db.projects.createAlias('note_links__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $NotesTable _sourceIdTable(_$FikraDatabase db) => db.notes.createAlias('note_links__source_id__notes__id');

  $$NotesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$NotesTableTableManager($_db, $_db.notes).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $NotesTable _targetIdTable(_$FikraDatabase db) => db.notes.createAlias('note_links__target_id__notes__id');

  $$NotesTableProcessedTableManager get targetId {
    final $_column = $_itemColumn<String>('target_id')!;

    final manager = $$NotesTableTableManager($_db, $_db.notes).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NoteLinksTableFilterComposer extends Composer<_$FikraDatabase, $NoteLinksTable> {
  $$NoteLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<LinkOrigin, LinkOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableFilterComposer get sourceId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableFilterComposer get targetId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteLinksTableOrderingComposer extends Composer<_$FikraDatabase, $NoteLinksTable> {
  $$NoteLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableOrderingComposer get sourceId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableOrderingComposer get targetId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteLinksTableAnnotationComposer extends Composer<_$FikraDatabase, $NoteLinksTable> {
  $$NoteLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label => $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get strength => $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LinkOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<bool> get dismissed => $composableBuilder(column: $table.dismissed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableAnnotationComposer get sourceId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NotesTableAnnotationComposer get targetId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteLinksTableTableManager
    extends
        RootTableManager<
          _$FikraDatabase,
          $NoteLinksTable,
          NoteLink,
          $$NoteLinksTableFilterComposer,
          $$NoteLinksTableOrderingComposer,
          $$NoteLinksTableAnnotationComposer,
          $$NoteLinksTableCreateCompanionBuilder,
          $$NoteLinksTableUpdateCompanionBuilder,
          (NoteLink, $$NoteLinksTableReferences),
          NoteLink,
          PrefetchHooks Function({bool projectId, bool sourceId, bool targetId})
        > {
  $$NoteLinksTableTableManager(_$FikraDatabase db, $NoteLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NoteLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NoteLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NoteLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> strength = const Value.absent(),
                Value<LinkOrigin> origin = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteLinksCompanion(
                id: id,
                projectId: projectId,
                sourceId: sourceId,
                targetId: targetId,
                label: label,
                strength: strength,
                origin: origin,
                dismissed: dismissed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String sourceId,
                required String targetId,
                required String label,
                required double strength,
                Value<LinkOrigin> origin = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteLinksCompanion.insert(
                id: id,
                projectId: projectId,
                sourceId: sourceId,
                targetId: targetId,
                label: label,
                strength: strength,
                origin: origin,
                dismissed: dismissed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$NoteLinksTable, NoteLink>(table), $$NoteLinksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({projectId = false, sourceId = false, targetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$NoteLinksTableReferences._projectIdTable(db),
                        referencedColumn: $$NoteLinksTableReferences._projectIdTable(db).id,
                      ) as T;
                    }
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: $$NoteLinksTableReferences._sourceIdTable(db),
                        referencedColumn: $$NoteLinksTableReferences._sourceIdTable(db).id,
                      ) as T;
                    }
                    if (targetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.targetId,
                        referencedTable: $$NoteLinksTableReferences._targetIdTable(db),
                        referencedColumn: $$NoteLinksTableReferences._targetIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NoteLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$FikraDatabase,
      $NoteLinksTable,
      NoteLink,
      $$NoteLinksTableFilterComposer,
      $$NoteLinksTableOrderingComposer,
      $$NoteLinksTableAnnotationComposer,
      $$NoteLinksTableCreateCompanionBuilder,
      $$NoteLinksTableUpdateCompanionBuilder,
      (NoteLink, $$NoteLinksTableReferences),
      NoteLink,
      PrefetchHooks Function({bool projectId, bool sourceId, bool targetId})
    >;
typedef $$ChatEntriesTableCreateCompanionBuilder = ChatEntriesCompanion Function({
  required String id,
  required String projectId,
  required String role,
  required String body,
  Value<String> sourceIds,
  Value<bool> found,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ChatEntriesTableUpdateCompanionBuilder = ChatEntriesCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> role,
  Value<String> body,
  Value<String> sourceIds,
  Value<bool> found,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ChatEntriesTableReferences extends BaseReferences<_$FikraDatabase, $ChatEntriesTable, ChatEntry> {
  $$ChatEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$FikraDatabase db) =>
      db.projects.createAlias('chat_entries__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChatEntriesTableFilterComposer extends Composer<_$FikraDatabase, $ChatEntriesTable> {
  $$ChatEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceIds =>
      $composableBuilder(column: $table.sourceIds, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get found => $composableBuilder(column: $table.found, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatEntriesTableOrderingComposer extends Composer<_$FikraDatabase, $ChatEntriesTable> {
  $$ChatEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceIds =>
      $composableBuilder(column: $table.sourceIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get found =>
      $composableBuilder(column: $table.found, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatEntriesTableAnnotationComposer extends Composer<_$FikraDatabase, $ChatEntriesTable> {
  $$ChatEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role => $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get body => $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get sourceIds => $composableBuilder(column: $table.sourceIds, builder: (column) => column);

  GeneratedColumn<bool> get found => $composableBuilder(column: $table.found, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatEntriesTableTableManager
    extends
        RootTableManager<
          _$FikraDatabase,
          $ChatEntriesTable,
          ChatEntry,
          $$ChatEntriesTableFilterComposer,
          $$ChatEntriesTableOrderingComposer,
          $$ChatEntriesTableAnnotationComposer,
          $$ChatEntriesTableCreateCompanionBuilder,
          $$ChatEntriesTableUpdateCompanionBuilder,
          (ChatEntry, $$ChatEntriesTableReferences),
          ChatEntry,
          PrefetchHooks Function({bool projectId})
        > {
  $$ChatEntriesTableTableManager(_$FikraDatabase db, $ChatEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ChatEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ChatEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ChatEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> sourceIds = const Value.absent(),
                Value<bool> found = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChatEntriesCompanion(
                id: id,
                projectId: projectId,
                role: role,
                body: body,
                sourceIds: sourceIds,
                found: found,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String role,
                required String body,
                Value<String> sourceIds = const Value.absent(),
                Value<bool> found = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ChatEntriesCompanion.insert(
                id: id,
                projectId: projectId,
                role: role,
                body: body,
                sourceIds: sourceIds,
                found: found,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$ChatEntriesTable, ChatEntry>(table), $$ChatEntriesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$ChatEntriesTableReferences._projectIdTable(db),
                        referencedColumn: $$ChatEntriesTableReferences._projectIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChatEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$FikraDatabase,
      $ChatEntriesTable,
      ChatEntry,
      $$ChatEntriesTableFilterComposer,
      $$ChatEntriesTableOrderingComposer,
      $$ChatEntriesTableAnnotationComposer,
      $$ChatEntriesTableCreateCompanionBuilder,
      $$ChatEntriesTableUpdateCompanionBuilder,
      (ChatEntry, $$ChatEntriesTableReferences),
      ChatEntry,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer extends Composer<_$FikraDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer extends Composer<_$FikraDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer extends Composer<_$FikraDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$FikraDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$FikraDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$FikraDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$FikraDatabase, $SettingsTable, Setting>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$FikraDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$FikraDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $FikraDatabaseManager {
  final _$FikraDatabase _db;
  $FikraDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects => $$ProjectsTableTableManager(_db, _db.projects);
  $$NoteGroupsTableTableManager get noteGroups => $$NoteGroupsTableTableManager(_db, _db.noteGroups);
  $$NotesTableTableManager get notes => $$NotesTableTableManager(_db, _db.notes);
  $$NoteAttachmentsTableTableManager get noteAttachments =>
      $$NoteAttachmentsTableTableManager(_db, _db.noteAttachments);
  $$NoteLinksTableTableManager get noteLinks => $$NoteLinksTableTableManager(_db, _db.noteLinks);
  $$ChatEntriesTableTableManager get chatEntries => $$ChatEntriesTableTableManager(_db, _db.chatEntries);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
}
