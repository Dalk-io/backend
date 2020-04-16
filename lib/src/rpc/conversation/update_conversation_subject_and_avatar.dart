import 'package:backend/src/databases/conversation/update_conversation_subject_and_avatar.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class UpdateConversationSubjectAndAvatar extends Endpoint<UpdateConversationSubjectAndAvatarParameters, void> {
  final UpdateConversationSubjectAndAvatarToDatabase _updateConversationSubjectAndAvatarToDatabase;

  UpdateConversationSubjectAndAvatar(this._updateConversationSubjectAndAvatarToDatabase);

  @override
  Future<void> request(UpdateConversationSubjectAndAvatarParameters input) async {
    await _updateConversationSubjectAndAvatarToDatabase.request(input);
  }
}
