import 'package:backend/src/data/project/project.dart';

int groupLimitationFromSubscription(SubscriptionType subscriptionType) {
  switch (subscriptionType) {
    case SubscriptionType.complete:
      return 100;
    case SubscriptionType.starter:
      return 5;
    case SubscriptionType.none:
      return -1;
  }
  return 5;
}
