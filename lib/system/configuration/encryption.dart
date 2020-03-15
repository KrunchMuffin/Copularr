import 'package:encrypt/encrypt.dart';
import 'package:copularr/core.dart';
import 'package:copularr/system.dart';

class Encryption {
    Encryption._();

    static String encryptData(String encryptionKey, String data) {
        try {
            String _key = (encryptionKey+encryptionKey).padRight(32, '0').substring(0, 32);
            Key key = Key.fromUtf8(_key);
            IV iv = IV.fromLength(16);
            final _encrypter = Encrypter(AES(key));
            final _encrypted = _encrypter.encrypt(data, iv: iv).base64;
            return _encrypted;
        } catch (e) {
            Logger.error('package:copularr/configuration/encryption.dart', 'encryptData', 'Encryption error', e, StackTrace.current);
        }
        return Constants.ENCRYPTION_FAILURE;
    }

    static String decryptData(String decryptionKey, String data) {
        try {
            String _key = (decryptionKey+decryptionKey).padRight(32, '0').substring(0, 32);
            Key key = Key.fromUtf8(_key);
            IV iv = IV.fromLength(16);
            final _encrypter = Encrypter(AES(key));
            return _encrypter.decrypt64(data, iv: iv);
        } catch (e) {
            Logger.error('package:copularr/configuration/encryption.dart', 'decryptData', 'Decryption error', e, StackTrace.current);
        }
        return Constants.ENCRYPTION_FAILURE;
    }
}
