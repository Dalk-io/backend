import 'dart:convert';

import 'package:backend/src/rpc/project/get_project_by_key.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Middleware checkProjectExistMiddleware(GetProjectByKey getProjectByKey) => (Handler handler) {
      final logger = Logger('checkProjectExistMiddleware');
      return (request) async {
        final projectId = params(request, 'id');
        logger.info(projectId);
        final project = await getProjectByKey.request(projectId);
        logger.info(project);
        if (project == null) {
          return Response.notFound(json.encode({'message': 'Project $projectId not found'}));
        }
        return handler(
          request.change(
            context: {
              ...request.context,
              'projectInformations': projectId == project.development.key ? project.development : project.production,
            },
          ),
        );
      };
    };
