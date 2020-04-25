import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/databases/project/get_project_by_id.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/utils/project_from_database.dart';

class GetProjectById extends Endpoint<int, ProjectsData> {
  final GetProjectByIdFromDatabase _getProjectByIdFromDatabase;

  GetProjectById(this._getProjectByIdFromDatabase);

  @override
  Future<ProjectsData> request(int input) async {
    final results = await _getProjectByIdFromDatabase.request(input);
    final result = results.first;
    return projectFromDatabase(result);
  }
}
