import 'package:backend/src/data/project/project.dart';

ProjectsData projectFromDatabase(List<dynamic> result) {
  final groupLimitation = result[10] as int;
  final production = _getProductionEnvironment(result);
  final development = ProjectEnvironmentData(result[5] as String, result[6] as String, webHook: result[7] as String, isSecure: result[8] as bool);
  return ProjectsData(development,
      subscriptionType: SubscriptionType.values[result[9] as int], production: production, groupLimitation: groupLimitation, id: result[0] as int);
}

ProjectEnvironmentData _getProductionEnvironment(List<dynamic> result) {
  if (result[1] == null) {
    return null;
  }
  return ProjectEnvironmentData(result[1] as String, result[2] as String, webHook: result[3] as String, isSecure: result[4] as bool);
}
