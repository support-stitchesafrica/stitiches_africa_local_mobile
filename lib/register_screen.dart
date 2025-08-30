import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:stitches_africa_local/controllers/auth_controller.dart';
import 'package:stitches_africa_local/login_screen.dart';
import 'package:stitches_africa_local/services/category_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;

  // Category data
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

  // BVN
  bool _isBvnVerified = false;
  bool _isVerifyingBvn = false;
  final _bvnController = TextEditingController();

  // BVN details
  String? dob;
  String? gender;
  String? bvnEmail;
  bool useBvnEmail = true; // default checked

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
          const SnackBar(content: Text("Location permanently denied.")),
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
      if (selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select at least one category")),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (locationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please provide your location")),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (!_isBvnVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verify BVN before registering.")),
        );
        return;
      }

      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        try {
          await controller.register(
            fullName: fullName!,
            email: useBvnEmail ? (bvnEmail ?? "") : email!,
            password: password!,
            bvn: _bvnController.text.trim(),
            phone: "", // Add required phone parameter
            category: selectedCategories.join(", "), // Convert list to string
            gender: gender ?? '',
            latitude: latitude != null ? double.parse(latitude!) : null,
            longitude: longitude != null ? double.parse(longitude!) : null,
            address: address,
            userType: "CUSTOMER", // <-- add this
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration successful!")),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
        return;
      }
    }

    setState(() => _currentStep++);
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Center(
          child: Image.asset("images/Stitches Africa Logo-08.png", height: 80),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    if (isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    List<String> categoryList = categoryData
        .map((c) => c["category"] as String)
        .toList();

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLogo(),
            const Text(
              "Select your fashion categories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...categoryList.map(
              (c) => CheckboxListTile(
                title: Text(c),
                value: selectedCategories.contains(c),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      selectedCategories.add(c);
                    } else {
                      selectedCategories.remove(c);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLogo(),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep(AuthController controller) {
    return Center(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLogo(),
              const Text(
                "Create your account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

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
                    child: Text("Using BVN Email: $bvnEmail"),
                  ),
                const SizedBox(height: 12),

                SizedBox(
                  width: 300,
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: (val) => val!.length < 6
                        ? "Password must be at least 6 characters"
                        : null,
                    onSaved: (val) => password = val,
                  ),
                ),
                const SizedBox(height: 20),
              ],

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
            _buildPreferencesStep(),
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
                  : steps[_currentStep],
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: (_currentStep == 2 && !_isBvnVerified)
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
