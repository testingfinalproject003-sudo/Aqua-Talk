import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';


class PhoneContactService {

  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }


  Future<List<Contact>> getContacts() async {
    final contacts = await FlutterContacts.getAll(
      
    );
    return contacts;
  }
}