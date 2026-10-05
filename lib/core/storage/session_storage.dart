import 'session_storage_stub.dart'
    if (dart.library.html) 'session_storage_web.dart'
    as impl;

class WebSessionStorage {
  static void setItem(String key, String value) {
    impl.WebSessionStorage.setItem(key, value);
  }

  static String? getItem(String key) {
    return impl.WebSessionStorage.getItem(key);
  }

  static void removeItem(String key) {
    impl.WebSessionStorage.removeItem(key);
  }

  static void clear() {
    impl.WebSessionStorage.clear();
  }
}
