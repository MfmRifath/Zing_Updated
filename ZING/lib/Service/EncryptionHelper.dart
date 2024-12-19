import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  final encrypt.Key key;
  final encrypt.IV iv;
  late encrypt.Encrypter encrypter;

  EncryptionHelper(String keyString)
      : key = encrypt.Key.fromUtf8(keyString),
        iv = encrypt.IV.fromLength(16) {
    encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  String encryptMessage(String message) {
    final encrypted = encrypter.encrypt(message, iv: iv);
    return encrypted.base64;
  }

  String decryptMessage(String encryptedMessage) {
    final decrypted = encrypter.decrypt64(encryptedMessage, iv: iv);
    return decrypted;
  }
}
