import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/databases/project/update_project.dart';
import 'package:backend/src/endpoint.dart';

class UpdateProject extends Endpoint<ProjectsData, void> {
  final UpdateProjectToDatabase _updateProjectToDatabase;

  UpdateProject(this._updateProjectToDatabase);

  @override
  Future<void> request(ProjectsData input) async {
    await _updateProjectToDatabase.request(input);
  }
}
