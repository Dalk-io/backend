import 'dart:convert';

import 'package:backend/src/models/project.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Middleware checkProjectExistMiddleware = (Handler handler) {
  return (request) {
    final authorizedProjects = (request.context['authorizedProjects'] as List).cast<Project>();
    final projectId = params(request, 'id');
    final project = authorizedProjects.firstWhere((project) => project.id == projectId, orElse: () => null);
    if (project == null) {
      return Response.notFound(json.encode({'message': 'Project $projectId not found'}));
    }
    return handler(request.change(context: {...request.context, 'project': project}));
  };
};
