import 'package:flutter/material.dart';
import '../../models/vendor.dart';
import '../../services/auth_service.dart';
import '../onboarding/complete_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  
  BusinessType _selectedBusinessType = BusinessType.store;
  String? _selectedCategoryKey; // fashion, food, cosmetics, grocery, pharmacy
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Fallback mapping for category if user didn’t pick explicitly
      String? categoryKey = _selectedCategoryKey;
      if (categoryKey == null) {
        switch (_selectedBusinessType) {
          case BusinessType.restaurant:
            categoryKey = 'food';
            break;
          case BusinessType.pharmacy:
            categoryKey = 'pharmacy';
            break;
          case BusinessType.store:
            categoryKey = 'grocery';
            break;
        }
      }

      await AuthService.instance.registerVendorWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        businessType: _selectedBusinessType,
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        businessDescription: _businessDescriptionController.text.trim(),
        categoryKey: categoryKey,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Widget _buildBusinessTypeCard(BusinessType type, IconData icon, String title, String subtitle) {
    final isSelected = _selectedBusinessType == type;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() {
          _selectedBusinessType = type;
          // If user hasn’t chosen a category, pick a sensible default based on type
          if (_selectedCategoryKey == null) {
            switch (type) {
              case BusinessType.restaurant:
                _selectedCategoryKey = 'food';
                break;
              case BusinessType.pharmacy:
                _selectedCategoryKey = 'pharmacy';
                break;
              case BusinessType.store:
                _selectedCategoryKey = 'grocery';
                break;
            }
          }
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Theme.of(context).colorScheme.primary : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label, IconData icon) {
    final selected = _selectedCategoryKey == key;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedCategoryKey = key);
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ScaleTransition(
          scale: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter a password';
                              }
                              if (value!.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Business Type',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildBusinessTypeCard(
                    BusinessType.store,
                    Icons.store,
                    'General Store',
                    'Sell various products and merchandise',
                  ),
                  _buildBusinessTypeCard(
                    BusinessType.restaurant,
                    Icons.restaurant,
                    'Restaurant',
                    'Serve food and beverages to customers',
                  ),
                  _buildBusinessTypeCard(
                    BusinessType.pharmacy,
                    Icons.local_pharmacy,
                    'Pharmacy',
                    'Provide medications and health products',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Business Category (theme)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildCategoryChip('fashion', 'Fashion', Icons.checkroom),
                      _buildCategoryChip('food', 'Food', Icons.restaurant),
                      _buildCategoryChip('cosmetics', 'Cosmetics', Icons.brush),
                      _buildCategoryChip('grocery', 'Grocery', Icons.shopping_basket),
                      _buildCategoryChip('pharmacy', 'Pharmacy', Icons.local_pharmacy),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Business Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _businessNameController,
                            decoration: InputDecoration(
                              labelText: 'Business Name',
                              prefixIcon: const Icon(Icons.business_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your business name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _businessAddressController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Business Address',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your business address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _businessDescriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Business Description',
                              prefixIcon: const Icon(Icons.description_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter a business description';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}