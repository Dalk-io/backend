import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/databases/project/save_project.dart';
import 'package:backend/src/endpoint.dart';

class SaveProject extends Endpoint<ProjectsData, int> {
  final SaveProjectToDatabase _saveProjectToDatabase;

  SaveProject(this._saveProjectToDatabase);

  @override
  Future<int> request(ProjectsData input) async {
    final results = await _saveProjectToDatabase.request(input);
    return results.first.first as int;
  }
}
