import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';

@freezed
abstract class _ProjectBase with _$_ProjectBase {
  const factory _ProjectBase({
    @required String name,
    @required ProjectInformations production,
    @required ProjectInformations development,
  }) = Project;
}

class ProjectInformations {
  final String key;
  final String secret;
  final String webhook;
  final int groupLimitation;
  final bool secure;

  ProjectInformations(this.key, this.secret, {this.webhook, this.groupLimitation = -1, this.secure = false});

  @override
  String toString() => 'ProjectInformations{ $key, $secret, $groupLimitation, $webhook, $secure }';
}
