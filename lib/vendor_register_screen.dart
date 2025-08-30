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

  // Form
  final _formKey = GlobalKey<FormState>();
  String? fullName;
  String? email;
  String? password;
  String? brandName;
  String? phone;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await CategoryService().getCategories();
      setState(() {
        categoryData = data;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => isLoadingCategories = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading categories: $e")),
      );
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

      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location: $e")),
      );
    }
  }

  void _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _logoFile = File(picked.path);
      });
    }
  }

  void _nextStep(AuthController controller) async {
    if (_currentStep == 0) {
      if (_logoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload a logo")),
        );
        return;
      }
      if (brandName == null || brandName!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your brand name")),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select at least one category")),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (locationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please set your location")),
        );
        return;
      }
    } else if (_currentStep == 3) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        try {
          // Send selected category names to backend
          await controller.registerVendor(
            fullName: fullName!,
            email: email!,
            password: password!,
            brandName: brandName!,
            phone: phone!,
            logo: _logoFile?.path,
            userType: "VENDOR",
            latitude: latitude != null ? double.parse(latitude!) : null,
            longitude: longitude != null ? double.parse(longitude!) : null,
            address: address,
            category: selectedCategories, // <-- changed here
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vendor registration successful!")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
        return;
      }
    }

    setState(() {
      _currentStep++;
    });
  }

  Widget _buildLogoStep() {
    return Center(
      child: Column(
        children: [
          Image.asset("images/Stitches Africa Logo-08.png", height: 140),
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
              decoration: const InputDecoration(labelText: "Brand Name"),
              validator: (val) =>
                  val!.isEmpty ? "Enter your brand name" : null,
              onChanged: (val) => brandName = val,
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
        .map((c) => c["name"])
        .where((name) => name != null)
        .map((name) => name.toString())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset("images/Stitches Africa Logo-08.png", height: 140),
        const SizedBox(height: 20),
        const Text("Select your category preferences",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          Image.asset("images/Stitches Africa Logo-08.png", height: 140),
          const SizedBox(height: 20),
          const Text("Set your location",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Image.asset("images/Stitches Africa Logo-08.png", height: 140),
            const SizedBox(height: 20),
            const Text("Create your account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: "Full Name"),
              validator: (val) =>
                  val!.isEmpty ? "Enter your full name" : null,
              onSaved: (val) => fullName = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: "Email"),
              validator: (val) =>
                  val!.contains("@") ? null : "Enter a valid email",
              onSaved: (val) => email = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
              validator: (val) => val!.length < 6
                  ? "Password must be at least 6 characters"
                  : null,
              onSaved: (val) => password = val,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: "Phone Number"),
              keyboardType: TextInputType.phone,
              validator: (val) =>
                  val!.isEmpty ? "Enter your phone number" : null,
              onSaved: (val) => phone = val,
            ),
          ],
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
              title: const Text("Vendor Register"),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: steps[_currentStep],
                    ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () => _nextStep(controller),
                child: Text(
                    _currentStep == steps.length - 1 ? "Register" : "Next"),
              ),
            ),
          );
        },
      ),
    );
  }
}
