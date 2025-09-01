import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nigerian_states_and_lga/nigerian_states_and_lga.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

import 'services/category_service.dart';
import 'services/ad_service.dart';
import 'models/ad.dart';

class SellFormScreen extends StatefulWidget {
  const SellFormScreen({super.key});

  @override
  State<SellFormScreen> createState() => _SellFormScreenState();
}

class _SellFormScreenState extends State<SellFormScreen> {
  final String paystackPublicKey =
      "sk_test_d00968ec82bfd142dfff9eb049f2dda9b73bb096";

  final Map<String, int> paystackPlans = {
    "TOP": 11999,
    "EXCLUSIVE": 19999,
    "BOOST": 29999,
  };

  int _currentStep = 0;

  // Category data
  List<Map<String, dynamic>> categoryData = [];
  List<String> selectedCategories = [];
  bool isLoadingCategories = true;

  // States and LGA
  String? _selectedState;
  String? _selectedArea;
  List<String> areaList = [];
  String? selectedCategory;
  // Image picker
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  // Location
  String? latitude;
  String? longitude;
  String? address;
  bool _isGettingLocation = false;
  final TextEditingController locationController = TextEditingController();

  // Step 2 controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedPromo;

  String? _userBrand; // brand from user local storage

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _loadUserBrand();
  }

  Future<void> _loadUserBrand() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("user");
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        _userBrand = userMap["brandName"]; // brand saved in user
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await CategoryService().getCategories();
      setState(() {
        categoryData = data;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        categoryData = [
          {"id": "1", "categoryName": "BESPOKE"},
          {"id": "2", "categoryName": "READY TO WEAR"},
          {"id": "3", "categoryName": "FABRIC STORE OWNER"},
        ];
        isLoadingCategories = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading categories: $e")));
    }
  }

  Future<void> _getUserLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled.")),
        );
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission denied.")),
          );
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission permanently denied."),
          ),
        );
        setState(() => _isGettingLocation = false);
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      String fullAddress = "";
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        fullAddress =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }

      setState(() {
        latitude = pos.latitude.toString();
        longitude = pos.longitude.toString();
        address = fullAddress;
        locationController.text = fullAddress;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching location: $e")));
    }
  }

  // Update latitude/longitude if user manually edits
  void _onLocationChanged(String value) {
    setState(() {
      address = value;
      latitude = null;
      longitude = null;
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  bool _isStep1Valid() {
    return selectedCategory != null &&
        _selectedImages.isNotEmpty &&
        (address != null && address!.isNotEmpty);
  }

  bool _isStep2Valid() {
    return _titleController.text.isNotEmpty &&
        _genderController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _selectedState != null &&
        _selectedArea != null;
  }

  String _mapPromoToEnum(String? promo) {
    switch (promo) {
      case "TOP":
        return "TOP";
      case "EXCLUSIVE (14 days)":
        return "EXCLUSIVE";
      case "BOOST (30 days)":
        return "BOOST";
      default:
        return "NONE";
    }
  }

  Future<String> _saveAd(String userId, String promoType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) throw Exception("User not logged in");

      final adService = AdService(
        baseUrl: "https://stictches-africa-api-local.vercel.app/api",
        token: token,
      );

      final ad = await adService.createAd(
        categoryName: selectedCategory!,
        promoType: promoType,
        title: _titleController.text,
        brand: _userBrand ?? "UNKNOWN",
        gender: _genderController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        phone: _phoneController.text,
        latitude: latitude != null ? double.parse(latitude!) : null,
        longitude: longitude != null ? double.parse(longitude!) : null,
        address: address,
        images: _selectedImages,
      );

      return ad.id.toString(); // ✅ return adId
    } catch (e) {
      throw Exception("Failed to save ad: $e");
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0 && _isStep1Valid()) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1 && _isStep2Valid()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString("user");
        if (userJson == null) throw Exception("No logged in user found");

        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = User.fromJson(userMap);

        final userId = user.id;
        final email = user.email;
        final promoType = _mapPromoToEnum(_selectedPromo);
        if (promoType == "NONE") {
          await _saveAd(userId, promoType);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ad posted successfully!")),
          );
          Navigator.pushNamed(context, "/home");
        } else {
          final amount = paystackPlans[promoType];
          if (amount == null) throw Exception("Invalid plan selected");

          // ✅ First create ad to get adId
          final adId = await _saveAd(userId, promoType);
          final reference =
              "${userId}_${adId}_${promoType}_${DateTime.now().millisecondsSinceEpoch}";

          PayWithPayStack().now(
            context: context,
            secretKey: paystackPublicKey,
            customerEmail: email,
            reference: reference,
            amount: amount.toDouble(),
            currency: "NGN",
            callbackUrl:
                "https://stictches-africa-api-local.vercel.app/api/paystack/callback",
            transactionCompleted: (response) async {
              if (response.status == "success") {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Payment successful, Ad promoted!"),
                  ),
                );
                Navigator.pushNamed(context, "/home");
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Payment failed: ${response.message}"),
                  ),
                );
              }
            },
            transactionNotCompleted: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Transaction cancelled: $error")),
              );
            },
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Ad", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("images/Stitches Africa Logo-06.png", height: 80),
                  const SizedBox(height: 20),
                  _currentStep == 0 ? _step1() : _step2(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: (_currentStep == 0 ? _isStep1Valid() : _isStep2Valid())
              ? _nextStep
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(
            _currentStep == 0 ? "Next" : "Post Ad",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // --- Step 1 ---
  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _label("Select Category*"),
        if (isLoadingCategories)
          const Center(child: CircularProgressIndicator())
        else
          ...categoryData.map((c) {
            final category = c["categoryName"]?.toString() ?? "";
            if (category.isEmpty) return const SizedBox.shrink();
            return RadioListTile<String>(
              title: Text(category),
              value: category,
              groupValue: selectedCategory,
              onChanged: (val) {
                setState(() {
                  selectedCategory = val;
                });
              },
            );
          }),
        const SizedBox(height: 12),
        TextField(
          controller: locationController,
          readOnly: false,
          onChanged: _onLocationChanged,
          decoration: InputDecoration(
            labelText: "Your location",
            border: const OutlineInputBorder(),
            suffixIcon: _isGettingLocation
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getUserLocation,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        _label("Add Photos*"),
        InkWell(
          onTap: _pickImages,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.image, color: Colors.grey),
                SizedBox(width: 8),
                Text("Tap to select images"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _selectedImages.length,
            ),
          ),
      ],
    );
  }

  // --- Step 2 ---
  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Title*"),
        _inputField(_titleController),
        const SizedBox(height: 12),
        _label("Gender*"),
        _inputField(_genderController),
        const SizedBox(height: 12),
        _label("State*"),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: NigerianStatesAndLGA.allStates
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          value: _selectedState,
          onChanged: (val) {
            setState(() {
              _selectedState = val;
              _selectedArea = null;
              areaList = val != null
                  ? NigerianStatesAndLGA.getStateLGAs(val)
                  : [];
            });
          },
        ),
        const SizedBox(height: 12),
        _label("Area (LGA)*"),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: areaList
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          value: _selectedArea,
          onChanged: (val) => setState(() => _selectedArea = val),
        ),
        const SizedBox(height: 12),
        _label("Description*"),
        _inputField(_descriptionController, maxLines: 3),
        const SizedBox(height: 12),
        _label("Price*"),
        _inputField(_priceController),
        const SizedBox(height: 12),
        _label("Your phone number*"),
        _inputField(_phoneController),
        const SizedBox(height: 20),
        _label("Promote your Brand"),
        const SizedBox(height: 10),
        _promoOptions(),
      ],
    );
  }

  Widget _promoOptions() {
    return Column(
      children: [
        _promoCard("No promo", "Free"),
        const SizedBox(height: 10),
        _promoCard("TOP", "₦ 11,999", subtitle: "7 days"),
        const SizedBox(height: 10),
        _promoCard("EXCLUSIVE (14 days)", "₦ 19,999"),
        const SizedBox(height: 10),
        _promoCard("BOOST (30 days)", "₦ 29,999"),
      ],
    );
  }

  Widget _promoCard(String title, String price, {String? subtitle}) {
    bool isSelected = _selectedPromo == title;
    return InkWell(
      onTap: () => setState(() => _selectedPromo = title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _inputField(
    TextEditingController controller, {
    String hint = "",
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(hint),
      onChanged: (_) => setState(() {}),
    );
  }

  InputDecoration _inputDecoration([String hint = ""]) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
