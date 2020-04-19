import 'dart:convert';

import 'package:backend/src/rpc/project/get_project_by_key.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Middleware checkProjectExistMiddleware(GetProjectByKey getProjectByKey) => (Handler handler) {
      return (request) async {
        final projectId = params(request, 'id');
        final project = await getProjectByKey.request(projectId);
        if (project == null) {
          return Response.notFound(json.encode({'message': 'Project $projectId not found'}));
        }
        return handler(
          request.change(
            context: {
              ...request.context,
              'projectInformations': projectId == project.production.key ? project.production : project.development,
            },
          ),
        );
      };
    };
