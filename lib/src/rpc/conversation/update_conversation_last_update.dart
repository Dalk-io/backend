import 'package:backend/backend.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';

class UpdateConversationLastUpdate extends Endpoint<UpdateConversationLastUpdateParameters, void> {
  final UpdateConversationLastUpdateToDatabase _updateConversationLastUpdateToDatabase;

  UpdateConversationLastUpdate(this._updateConversationLastUpdateToDatabase);

  @override
  Future<void> request(UpdateConversationLastUpdateParameters input) async {
    await _updateConversationLastUpdateToDatabase.request(input);
  }
}
