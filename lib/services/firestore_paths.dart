class FirestorePaths {
  // Root collections
  static const String users = 'users';
  static const String vendors = 'vendors';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String drivers = 'drivers';
  static const String consultationRequests = 'consultation_requests';
  static const String adminNotifications = 'admin_notifications';

  // Documents
  static String userDoc(String uid) => '$users/$uid';
  static String vendorDoc(String vendorId) => '$vendors/$vendorId';
  static String driverDoc(String driverId) => '$drivers/$driverId';

  // Subcollections
  static String vendorProducts(String vendorId) => '$vendors/$vendorId/$products';
  static String vendorOrders(String vendorId) => '$vendors/$vendorId/$orders';

  // Collection group names
  static const String cgVendorOrders = 'orders';
  static const String cgVendorProducts = 'products';
}
