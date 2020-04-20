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
    final groupLimitation = result.elementAt(6) as int;
    final secure = result.elementAt(7) as bool;
    final prod = ProjectInformations(
      result.elementAt(0) as String,
      result.elementAt(1) as String,
      webhook: result.elementAt(2) as String,
      groupLimitation: groupLimitation,
      secure: secure,
    );
    final dev = ProjectInformations(
      result.elementAt(3) as String,
      result.elementAt(4) as String,
      webhook: result.elementAt(5) as String,
      groupLimitation: groupLimitation,
      secure: secure,
    );
    return Project(production: prod, development: dev);
  }
}
