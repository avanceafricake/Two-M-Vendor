import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'auth_service.dart';
import 'repositories/vendor_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/analytics_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/wallet_repository.dart';
import 'repositories/consultation_repository.dart';
import '../models/consultation.dart';

/// Service Locator for managing Firebase services and repositories
/// 
/// This class provides a centralized way to access all services and repositories
/// in the application. It follows the singleton pattern and provides lazy initialization.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Firebase instances
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  late final FirebaseStorage _storage;

  // Service instances
  late final AuthService _authService;

  // Repository instances
  late final VendorRepository _vendorRepository;
  late final ProductRepository _productRepository;
  late final OrderRepository _orderRepository;
  late final AnalyticsRepository _analyticsRepository;
  late final CustomerRepository _customerRepository;
  late final WalletRepository _walletRepository;
  late final ConsultationRepository _consultationRepository;

  bool _initialized = false;

  /// Initialize all services and repositories
  /// Call this once in main() after Firebase.initializeApp()
  void initialize() {
    if (_initialized) return;

    // Initialize Firebase instances
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _storage = FirebaseStorage.instance;

    // Initialize services
    _authService = AuthService.instance;

    // Initialize repositories
    _vendorRepository = VendorRepository(_firestore);
    _productRepository = ProductRepository(_firestore);
    _orderRepository = OrderRepository(_firestore);
    _analyticsRepository = AnalyticsRepository(_firestore);
    _customerRepository = CustomerRepository(_firestore);
    _walletRepository = WalletRepository(_firestore);
    _consultationRepository = ConsultationRepository(_firestore);

    _initialized = true;
  }

  /// Get Firebase Firestore instance
  FirebaseFirestore get firestore {
    _ensureInitialized();
    return _firestore;
  }

  /// Get Firebase Auth instance
  FirebaseAuth get auth {
    _ensureInitialized();
    return _auth;
  }

  /// Get Firebase Storage instance
  FirebaseStorage get storage {
    _ensureInitialized();
    return _storage;
  }

  /// Get AuthService instance
  AuthService get authService {
    _ensureInitialized();
    return _authService;
  }

  /// Get VendorRepository instance
  VendorRepository get vendorRepository {
    _ensureInitialized();
    return _vendorRepository;
  }

  /// Get ProductRepository instance
  ProductRepository get productRepository {
    _ensureInitialized();
    return _productRepository;
  }

  /// Get OrderRepository instance
  OrderRepository get orderRepository {
    _ensureInitialized();
    return _orderRepository;
  }

  /// Get AnalyticsRepository instance
  AnalyticsRepository get analyticsRepository {
    _ensureInitialized();
    return _analyticsRepository;
  }

  /// Get CustomerRepository instance
  CustomerRepository get customerRepository {
    _ensureInitialized();
    return _customerRepository;
  }

  WalletRepository get walletRepository {
    _ensureInitialized();
    return _walletRepository;
  }

  ConsultationRepository get consultationRepository {
    _ensureInitialized();
    return _consultationRepository;
  }

  /// Ensure the service locator is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'ServiceLocator not initialized. Call ServiceLocator().initialize() first.',
      );
    }
  }

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user ID (throws if not authenticated)
  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return user.uid;
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Dispose of all services (call this when app is destroyed)
  void dispose() {
    // Firebase instances are managed by Firebase SDK
    _initialized = false;
  }
}

/// Extension methods for easy access to services
extension ServiceLocatorExtension on ServiceLocator {
  /// Quick access to common operations
  
  /// Get current vendor data
  Future<dynamic> getCurrentVendor() async {
    if (!isAuthenticated) return null;
    return await vendorRepository.getById(currentUserId);
  }

  /// Watch current vendor data
  Stream<dynamic> watchCurrentVendor() {
    if (!isAuthenticated) return Stream.value(null);
    return vendorRepository.watch(currentUserId);
  }

  /// Get vendor's orders
  Stream<List<dynamic>> watchVendorOrders({dynamic status}) {
    if (!isAuthenticated) return Stream.value([]);
    return orderRepository.watchByVendor(
      vendorId: currentUserId,
      status: status,
    );
  }

  /// Get vendor's products
  Stream<List<dynamic>> watchVendorProducts({
    String? category,
    bool? isAvailable,
  }) {
    if (!isAuthenticated) return Stream.value([]);
    return productRepository.watchByVendor(
      vendorId: currentUserId,
      category: category,
      isAvailable: isAvailable,
    );
  }

  /// Update analytics for current vendor
  Future<void> updateCurrentVendorAnalytics() async {
    if (!isAuthenticated) return;
    await analyticsRepository.updateAnalytics(currentUserId);
  }

  /// Consultation helpers
  Stream<ConsultSettings> watchConsultSettings() {
    if (!isAuthenticated) return Stream.value(const ConsultSettings());
    return consultationRepository.watchSettings(currentUserId);
  }

  Future<void> saveConsultSettings(ConsultSettings settings) async {
    if (!isAuthenticated) return;
    await consultationRepository.saveSettings(currentUserId, settings);
  }

  Stream<List<ConsultRequest>> watchConsultRequests() {
    if (!isAuthenticated) return Stream.value(const <ConsultRequest>[]);
    return consultationRepository.watchRequests(currentUserId).map((e) => e);
  }

  Future<void> setConsultRequestStatus(String id, ConsultStatus status) async {
    await consultationRepository.updateRequestStatus(id, status);
  }
}