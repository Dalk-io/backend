import 'package:backend/src/models/project.dart';
import 'package:shelf/shelf.dart';

//  todo(kleak): remove this when we have project in database
Middleware addAuthorizedProjectMiddleware(List<Project> authorizedProjects) {
  return (Handler handler) {
    return (request) async {
      return handler(request.change(context: {...request.context, 'authorizedProjects': authorizedProjects}));
    };
  };
}
