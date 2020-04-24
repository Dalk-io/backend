import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/databases/project/get_project_by_id.dart';
import 'package:backend/src/endpoint.dart';

class GetProjectById extends Endpoint<int, ProjectsData> {
  final GetProjectByIdFromDatabase _getProjectByIdFromDatabase;

  GetProjectById(this._getProjectByIdFromDatabase);

  @override
  Future<ProjectsData> request(int input) async {
    final results = await _getProjectByIdFromDatabase.request(input);
    final result = results.first;
    final groupLimitation = result[7] as int;
    final secure = result[8] as bool;
    final production = _getProductionEnvironment(result);
    final development = ProjectEnvironment(result[3] as String, result[4] as String, webHook: result[5] as String);
    return ProjectsData(development, SubscriptionType.values[result[6] as int], production: production, groupLimitation: groupLimitation, isSecure: secure);
  }

  ProjectEnvironment _getProductionEnvironment(List<dynamic> result) {
    if (result[0] == null) {
      return null;
    }
    return ProjectEnvironment(result[0] as String, result[1] as String, webHook: result[2] as String);
  }
}
