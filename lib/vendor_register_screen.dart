import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:stitches_africa_local/controllers/auth_controller.dart';
import 'package:stitches_africa_local/login_screen.dart';
import 'package:stitches_africa_local/services/category_service.dart';

class VendorRegisterScreen extends StatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  State<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends State<VendorRegisterScreen> {
  int _currentStep = 0;

  File? _logoFile;

  // Categories
  List<Map<String, dynamic>> categoryData = [];
  bool isLoadingCategories = true;
  List<String> selectedCategories = [];

  // Location
  String? latitude;
  String? longitude;
  String? address;
  bool _isGettingLocation = false;
  final locationController = TextEditingController();

  // BVN
  bool _isBvnVerified = false;
  bool _isVerifyingBvn = false;
  final _bvnController = TextEditingController();

  String? dob;
  String? gender;
  String? bvnEmail;
  bool useBvnEmail = true;

  // Form
  final _formKey = GlobalKey<FormState>();
  final _brandNameController = TextEditingController();
  String? fullName;
  String? email;
  String? password;
  String? brandName;
  String? phone;

  @override
  void initState() {
    super.initState();
    _currentStep = 0; 
    _fetchCategories();
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    locationController.dispose();
    _bvnController.dispose();
    super.dispose();
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
          setState(() => _isGettingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
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

  void _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  Future<void> _verifyBVN(AuthController controller) async {
    if (_bvnController.text.isEmpty || _bvnController.text.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid 11-digit BVN")),
      );
      return;
    }

    setState(() => _isVerifyingBvn = true);

    try {
      final result = await controller.verifyBVN(_bvnController.text);
      if (result != null) {
        setState(() {
          _isBvnVerified = true;
          fullName = result["fullName"] ?? "";
          bvnEmail = result["email"] ?? "";
          email = bvnEmail;
          dob = result["dob"] ?? "";
          gender = result["gender"] ?? "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("BVN verified successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isVerifyingBvn = false);
    }
  }

  void _nextStep(AuthController controller) async {
    if (_currentStep == 0) {
      if (_logoFile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please upload a logo")));
        return;
      }
      if (_brandNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your brand name")),
        );
        return;
      } else {
        brandName = _brandNameController.text.trim(); // ✅ always set
      }
    }

    if (_currentStep == 1 && selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one category")),
      );
      return;
    }

    if (_currentStep == 2 && locationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please set your location")));
      return;
    }

    if (_currentStep == 3) {
      if (!_isBvnVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verify BVN before registering.")),
        );
        return;
      }

      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        if (useBvnEmail) email = bvnEmail;

        try {
          await controller.registerVendor(
            fullName: fullName!,
            email: email!,
            password: password!,
            brandName: brandName!,
            phone: phone!,
            bvn: _bvnController.text.trim(),
            image: _logoFile?.path, // ✅ path will be uploaded in AuthService
            latitude: latitude != null ? double.parse(latitude!) : null,
            longitude: longitude != null ? double.parse(longitude!) : null,
            address: address,
            category: selectedCategories,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vendor registration successful!")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }

    if (_currentStep < 3) setState(() => _currentStep++);
  }

  Widget _buildLogoStep() {
    return Center(
      child: Column(
        children: [
          Image.asset("images/Stitches Africa Logo-06.png", height: 140),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _pickLogo,
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _logoFile != null ? FileImage(_logoFile!) : null,
              child: _logoFile == null
                  ? const Icon(Icons.add_a_photo, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          const Text("Upload your logo"),
          const SizedBox(height: 20),
          SizedBox(
            width: 300,
            child: TextFormField(
              controller: _brandNameController,
              decoration: const InputDecoration(labelText: "Brand Name"),
              validator: (val) => val!.isEmpty ? "Enter your brand name" : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep() {
    if (isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    List<String> categoryList = categoryData
        .map((c) => c["categoryName"]?.toString() ?? "")
        .where((name) => name.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset("images/Stitches Africa Logo-06.png", height: 140),
        const SizedBox(height: 20),
        const Text(
          "Select your category preferences",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: categoryList.map((cat) {
              return CheckboxListTile(
                title: Text(cat),
                value: selectedCategories.contains(cat),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedCategories.add(cat);
                    } else {
                      selectedCategories.remove(cat);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Center(
      child: Column(
        children: [
          Image.asset("images/Stitches Africa Logo-06.png", height: 140),
          const SizedBox(height: 20),
          const Text(
            "Set your location",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 300,
            child: TextField(
              controller: locationController,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFormStep(AuthController controller) {
    return Center(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Image.asset("images/Stitches Africa Logo-06.png", height: 140),
              const SizedBox(height: 20),
              const Text(
                "Create your account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // BVN field
              SizedBox(
                width: 300,
                child: TextFormField(
                  controller: _bvnController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "BVN"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: _isVerifyingBvn
                      ? null
                      : () => _verifyBVN(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isVerifyingBvn
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verify BVN",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              if (_isBvnVerified) ...[
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    initialValue: fullName,
                    decoration: const InputDecoration(labelText: "Full Name"),
                    validator: (val) =>
                        val!.isEmpty ? "Enter your full name" : null,
                    onSaved: (val) => fullName = val,
                  ),
                ),
                const SizedBox(height: 12),

                CheckboxListTile(
                  value: useBvnEmail,
                  onChanged: (val) => setState(() => useBvnEmail = val ?? true),
                  title: const Text("Use BVN email"),
                ),
                if (!useBvnEmail)
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Preferred Email",
                      ),
                      validator: (val) =>
                          val!.contains("@") ? null : "Enter a valid email",
                      onSaved: (val) => email = val,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        Text("Using BVN Email: $bvnEmail"),
                        Text("Email will be set to: $bvnEmail"),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                // Password
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return "Password required";
                      if (val.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                    onSaved: (val) => password = val,
                  ),
                ),
                const SizedBox(height: 12),
                // Phone
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Phone number is required";
                      }
                      if (val.length < 10) {
                        return "Phone number must be at least 10 digits";
                      }
                      return null;
                    },
                    onSaved: (val) => phone = val,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: const Text(
                  "Already have an account? Sign in",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: Consumer<AuthController>(
        builder: (context, controller, _) {
          final steps = [
            _buildLogoStep(),
            _buildCategoryStep(),
            _buildLocationStep(),
            _buildFormStep(controller),
          ];

          return Scaffold(
            appBar: AppBar(
              title: const Text("Register"),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, "/home"),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.person, color: Colors.black),
                  label: const Text(
                    "Sign In",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentStep < steps.length
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: steps[_currentStep],
                    )
                  : const Center(child: Text("Invalid step")),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: (_currentStep == 3 && !_isBvnVerified)
                    ? null
                    : () => _nextStep(controller),
                child: Text(
                  _currentStep == steps.length - 1 ? "Register" : "Next",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
