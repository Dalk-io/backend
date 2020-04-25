import 'package:backend/src/databases/project/update_project.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/project/parameters.dart';

class UpdateProject extends Endpoint<UpdateProjectParameters, void> {
  final UpdateProjectToDatabase _updateProjectToDatabase;

  UpdateProject(this._updateProjectToDatabase);

  @override
  Future<void> request(UpdateProjectParameters input) async {
    await _updateProjectToDatabase.request(input);
  }
}
