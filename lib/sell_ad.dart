import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/category_service.dart';

class SellFormScreen extends StatefulWidget {
  const SellFormScreen({super.key});

  @override
  State<SellFormScreen> createState() => _SellFormScreenState();
}

class _SellFormScreenState extends State<SellFormScreen> {
  int _currentStep = 0;
  final CategoryService _categoryService = CategoryService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? error;

  // Step 1 values
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedState;
  String? _selectedArea;
  List<File> _selectedImages = [];

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

  // Promo selection
  String? _selectedPromo; // "No promo", "TOP", "Boost Premium promo"

  // Dummy data
  final Map<String, List<String>> categories = {
    "Fragrances": ["Perfume", "Cologne", "Body Mist"],
    "Electronics": ["Phones", "Laptops", "Accessories"]
  };

  final Map<String, List<String>> states = {
    "Lagos": ["Ikeja", "Surulere", "Lekki"],
    "Abuja": ["Garki", "Wuse", "Maitama"]
  };

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    setState(() {
      _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
    });
    }

  bool _isStep1Valid() {
    return _selectedCategory != null &&
        _selectedSubCategory != null &&
        _selectedState != null &&
        _selectedArea != null &&
        _selectedImages.isNotEmpty;
  }

  bool _isStep2Valid() {
    return _titleController.text.isNotEmpty &&
        _brandController.text.isNotEmpty &&
        _genderController.text.isNotEmpty &&
        _collectionController.text.isNotEmpty &&
        _scentController.text.isNotEmpty &&
        _formulationController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  void _nextStep() {
    if (_currentStep == 0 && _isStep1Valid()) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1 && _isStep2Valid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Ad posted successfully with promo: ${_selectedPromo ?? 'No promo'}")),
      );
      Navigator.pushNamed(context, "/home");
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("Category*"),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: categories.keys
                .map<DropdownMenuItem<String>>(
                    (cat) => DropdownMenuItem<String>(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedCategory = val;
                _selectedSubCategory = null; // Reset subcategory
              });
            },
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 16),
          _label("Subcategory*"),
          DropdownButtonFormField<String>(
            value: _selectedSubCategory,
            items: (_selectedCategory != null
                    ? categories[_selectedCategory]!
                    : [])
                .map<DropdownMenuItem<String>>(
                    (sub) => DropdownMenuItem<String>(value: sub, child: Text(sub)))
                .toList(),
            onChanged: (val) => setState(() => _selectedSubCategory = val),
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 16),
          _label("Select Location*"),
          DropdownButtonFormField<String>(
            value: _selectedState,
            items: states.keys
                .map<DropdownMenuItem<String>>(
                    (state) => DropdownMenuItem<String>(value: state, child: Text(state)))
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedState = val;
                _selectedArea = null;
              });
            },
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 16),
          _label("Area*"),
          DropdownButtonFormField<String>(
            value: _selectedArea,
            items: (_selectedState != null ? states[_selectedState]! : [])
                .map<DropdownMenuItem<String>>(
                    (area) => DropdownMenuItem<String>(value: area, child: Text(area)))
                .toList(),
            onChanged: (val) => setState(() => _selectedArea = val),
            decoration: _inputDecoration(),
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
          const Text("First image will be used as title image",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImages[index],
                      width: 100, height: 100, fit: BoxFit.cover),
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
              Expanded(child: _inputField(_collectionController, hint: "Collection")),
              const SizedBox(width: 12),
              Expanded(child: _inputField(_scentController, hint: "Perfume Type/Scent")),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _inputField(_formulationController, hint: "Formulation")),
              const SizedBox(width: 12),
              Expanded(child: _inputField(_volumeController, hint: "Volume (ml)")),
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
          _label("Promote your ad"),
          const SizedBox(height: 10),
          _promoOptions(),
        ],
      ),
    );
  }

  Widget _promoOptions() {
    return Column(
      children: [
        _promoCard("No promo", "free"),
        const SizedBox(height: 10),
        _promoCard("TOP", "₦ 3,499", subtitle: "7 days or 20 days"),
        const SizedBox(height: 10),
        _promoCard("Boost Premium promo", "₦ 31,999", subtitle: "1 month"),
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
                Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            Text(price,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _inputField(TextEditingController controller,
      {String hint = "", int maxLines = 1}) {
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
