import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/databases/project/get_project_by_key.dart';
import 'package:backend/src/endpoint.dart';
import 'package:meta/meta.dart';

@immutable
class GetProjectByKey extends Endpoint<String, ProjectsData> {
  final GetProjectByKeyFromDatabase _getProjectByKeyFromDatabase;

  GetProjectByKey(this._getProjectByKeyFromDatabase);

  @override
  Future<ProjectsData> request(String input) async {
    final results = await _getProjectByKeyFromDatabase.request(input);
    if (results.isEmpty || results.length > 1) {
      return null;
    }
    final result = results.first;
    final groupLimitation = result.elementAt(7) as int;
    final secure = result.elementAt(8) as bool;
    final prod = ProjectEnvironment(result.elementAt(0) as String, result.elementAt(1) as String, webHook: result.elementAt(2) as String);
    final dev = ProjectEnvironment(result.elementAt(3) as String, result.elementAt(4) as String, webHook: result.elementAt(5) as String);
    return ProjectsData(dev, SubscriptionType.values[result.elementAt(6) as int], production: prod, groupLimitation: groupLimitation, isSecure: secure);
  }
}
