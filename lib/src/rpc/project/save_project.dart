import 'package:backend/src/databases/project/save_project.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/models/project.dart';

class SaveProject extends Endpoint<Project, int> {
  final SaveProjectToDatabase _saveProjectToDatabase;

  SaveProject(this._saveProjectToDatabase);

  @override
  Future<int> request(Project input) async {
    final results = await _saveProjectToDatabase.request(input);
    return results.first.first as int;
  }
}
