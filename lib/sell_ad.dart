import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/category_service.dart';
import 'services/ad_service.dart';
import 'models/ad.dart';
import 'package:nigerian_states_and_lga/nigerian_states_and_lga.dart';
import 'package:pay_with_paystack/pay_with_paystack.dart';

class SellFormScreen extends StatefulWidget {
  const SellFormScreen({super.key});

  @override
  State<SellFormScreen> createState() => _SellFormScreenState();
}

class _SellFormScreenState extends State<SellFormScreen> {


// ✅ Paystack public key
  final String paystackPublicKey = "pk_test_37eba43300c473e8c80690177c32daf9302f82e6"; // replace with your key

  // Map promoType → amount in Kobo
  final Map<String, int> paystackPlans = {
    "TOP": 1199900, // ₦11,999 → in Kobo
    "Exclusive": 1999900, // ₦19,999
    "Boost": 2999900, // ₦29,999
  };
  int _currentStep = 0;

  // dropdown data
  List<String> stateList = [];
  List<String> areaList = [];
  String? _selectedState;
  String? _selectedArea;

  List<Map<String, dynamic>> categoryData = [];
  bool isLoadingCategories = true;

  // User selections
  String? selectedCategory;
  String? selectedSubcategory;

  // Step 1 values

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];

  String? latitude;
  String? longitude;
  String? address;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Step 2 controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _collectionController = TextEditingController();
  final TextEditingController _scentController = TextEditingController();
  final TextEditingController _formulationController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final locationController = TextEditingController();

  // Promo selection
  String? _selectedPromo; // "No promo", "TOP", "Boost Premium promo"

  Future<void> _fetchCategories() async {
    try {
      final data = await CategoryService().getCategoriesWithSubcategories();
      setState(() {
        categoryData = data;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => isLoadingCategories = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading categories: $e")));
    }
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

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
        locationController.text =
            address ?? "${pos.latitude}, ${pos.longitude}";
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching location: $e")));
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  bool _isStep1Valid() {
    return selectedCategory != null &&
        selectedSubcategory != null &&
        _selectedImages.isNotEmpty;
  }

  bool _isStep2Valid() {
    return _titleController.text.isNotEmpty &&
        _brandController.text.isNotEmpty &&
        _genderController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _selectedState != null &&
        _selectedArea != null &&
        _selectedImages.isNotEmpty;
  }

  String _mapPromoToEnum(String? promo) {
    switch (promo) {
      case "TOP":
        return "TOP";
      case "Exclusive (14 days)":
        return "Exclusive";
      case "Boost (30 days)":
        return "Boost";
      default:
        return "NONE";
    }
  }

 Future<void> _saveAd(String userId, String promoType) async {
    final ad = Ad(
      id: "",
      userId: userId,
      category: selectedCategory!,
      subCategory: selectedSubcategory!,
      state: _selectedState!,
      area: _selectedArea!,
      images: _selectedImages.map((f) => f.path).toList(),
      title: _titleController.text,
      brand: _brandController.text,
      gender: _genderController.text,
      collection: _collectionController.text,
      scent: _scentController.text,
      formulation: _formulationController.text,
      volume: _volumeController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      phone: _phoneController.text,
      latitude: latitude != null ? double.tryParse(latitude!) : null,
      longitude: longitude != null ? double.tryParse(longitude!) : null,
      address: address ?? "",
      createdAt: DateTime.now(),
      promoType: promoType,
    );

    final adService = AdService(
      baseUrl: "https://stictches-africa-api-local.vercel.app/api",
    );
    await adService.createAd(ad);
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
      final userId = userMap["id"] as String;
      final email = userMap["email"] as String;

      final promoType = _mapPromoToEnum(_selectedPromo);

      if (promoType == "NONE") {
        // 🚀 Free plan → Save directly
        await _saveAd(userId, promoType);
      } else {
        // 💳 Paid plan → Checkout with Paystack
        final amount = paystackPlans[promoType];
        if (amount == null) throw Exception("Invalid plan selected");

        PayWithPayStack().now(
          context: context,
          secretKey: paystackPublicKey, // ⚠️ should be PUBLIC KEY for client-side
          customerEmail: email,
          reference: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount.toDouble(), // in Kobo
          currency: "NGN",
          callbackUrl: "https://stictches-africa-api-local.vercel.app/api/paystack/callback", // ✅ REQUIRED
          transactionCompleted: (response) async {
            if (response.status == true) {
              await _saveAd(userId, promoType);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Payment successful, Ad posted!")),
              );
              Navigator.pushNamed(context, "/home");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment failed: ${response.message}")),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
 
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Ad", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pushNamed(context, "/home");
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _currentStep == 0 ? _step1() : _step2(),
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
          child: Text(_currentStep == 0 ? "Next" : "Post Ad"),
        ),
      ),
    );
  }

  Widget _step1() {
    List<String> categoryList = categoryData
        .map((c) => c["category"] as String)
        .toList();
    List<String> subcategoriesForSelected = selectedCategory != null
        ? categoryData
              .firstWhere(
                (c) => c["category"] == selectedCategory,
              )["subcategories"]
              .cast<String>()
        : [];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Category",
              border: OutlineInputBorder(),
            ),
            items: categoryList
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            value: selectedCategory,
            onChanged: (val) {
              setState(() {
                selectedCategory = val;
                selectedSubcategory = null;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: "Subcategory",
              border: OutlineInputBorder(),
            ),
            items: subcategoriesForSelected
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            value: selectedSubcategory,
            onChanged: (val) => setState(() => selectedSubcategory = val),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationController,
            readOnly: true,
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
      ),
    );
  }

 Widget _step2() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Title*"),
        _inputField(_titleController),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _inputField(_genderController, hint: "Gender*")),
            const SizedBox(width: 12),
            Expanded(child: _inputField(_brandController, hint: "Brand*")),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _inputField(_collectionController, hint: "Collection"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                _scentController,
                hint: "Perfume Type/Scent",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ✅ Fixed: State Dropdown
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
                  ? NigerianStatesAndLGA.getStateLGAs(val) // ✅ correct method
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

        Row(
          children: [
            Expanded(
              child: _inputField(_formulationController, hint: "Formulation"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(_volumeController, hint: "Volume (ml)"),
            ),
          ],
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
    ),
  );
}

  Widget _promoOptions() {
    return Column(
      children: [
        _promoCard("No promo", "Free"),
        const SizedBox(height: 10),
        _promoCard("TOP", "₦ 11,999", subtitle: "7 days"),
        const SizedBox(height: 10),
        _promoCard("Exclusive (14 days)", "₦ 19,999"),
        const SizedBox(height: 10),
        _promoCard("Boost (30 days)", "₦ 29,999"),
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
