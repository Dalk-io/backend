import 'package:meta/meta.dart';

@immutable
class Project {
  final String id;
  final String webhook;

  Project(this.id, this.webhook);
}
