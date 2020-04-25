import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/databases/project/get_project_by_key.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/utils/project_from_database.dart';
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
    return projectFromDatabase(results.first);
  }
}
