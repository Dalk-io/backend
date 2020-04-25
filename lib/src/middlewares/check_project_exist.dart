import 'dart:convert';

import 'package:backend/src/rpc/project/get_project_by_key.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Middleware checkProjectExistMiddleware(GetProjectByKey getProjectByKey) => (Handler handler) {
      final logger = Logger('checkProjectExistMiddleware');
      return (request) async {
        final projectKey = params(request, 'projectKey');
        final project = await getProjectByKey.request(projectKey);
        if (project == null) {
          logger.warning('Project $projectKey not found');
          return Response.notFound(json.encode({'message': 'Project $projectKey not found'}));
        }
        return handler(
          request.change(
            context: {
              ...request.context,
              'projectEnvironment': projectKey == project.development.key ? project.development : project.production,
            },
          ),
        );
      };
    };
