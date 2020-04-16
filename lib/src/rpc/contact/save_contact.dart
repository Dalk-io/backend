import 'package:backend/src/databases/contact/save_contact.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/contact/parameters.dart';

class SaveContact extends Endpoint<SaveContactParameters, void> {
  final SaveContactToDatabase _saveContactToDatabase;

  SaveContact(this._saveContactToDatabase);

  @override
  Future<void> request(SaveContactParameters input) async {
    await _saveContactToDatabase.request(input);
  }
}
