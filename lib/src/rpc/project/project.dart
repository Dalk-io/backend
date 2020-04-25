import 'package:backend/backend.dart';
import 'package:backend/src/rpc/project/save_project.dart';

class ProjectRpcs {
  final GetProjectByKey getProjectByKey;
  final SaveProject saveProject;
  final GetProjectById getProjectById;
  final UpdateProject updateProject;

  ProjectRpcs(this.getProjectByKey, this.saveProject, this.getProjectById, this.updateProject);
}
