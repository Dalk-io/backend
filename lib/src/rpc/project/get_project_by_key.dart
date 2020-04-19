import 'package:backend/src/databases/project/get_project_by_key.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/models/project.dart';
import 'package:meta/meta.dart';

@immutable
class GetProjectByKey extends Endpoint<String, Project> {
  final GetProjectByKeyFromDatabase _getProjectByKeyFromDatabase;

  GetProjectByKey(this._getProjectByKeyFromDatabase);

  @override
  Future<Project> request(String input) async {
    final results = await _getProjectByKeyFromDatabase.request(input);
    if (results.isEmpty || results.length > 1) {
      return null;
    }
    final result = results.first;
    final groupLimitation = result.elementAt(7) as int;
    final prod = ProjectInformations(
      result.elementAt(1) as String,
      result.elementAt(2) as String,
      webhook: result.elementAt(3) as String,
      groupLimitation: groupLimitation,
    );
    final dev = ProjectInformations(result.elementAt(4) as String, result.elementAt(5) as String, webhook: result.elementAt(6) as String);
    return Project(name: result.elementAt(0) as String, production: prod, development: dev);
  }
}
