import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ProfileUpdateSheets {
  static final UserService _userService = UserService();
  static final ImagePicker _picker = ImagePicker();

  // Helper for black button style
  static ButtonStyle get _blackButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    textStyle: const TextStyle(color: Colors.white),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // Helper for black text
  static TextStyle get _blackTextStyle => const TextStyle(color: Colors.black);

  // Helper for bold black text
  static TextStyle get _blackBoldTextStyle =>
      const TextStyle(color: Colors.black, fontWeight: FontWeight.bold);

  // Helper for black radio/checkbox
  static Color get _activeColor => Colors.black;

  // Update Style Bottom Sheet (Single Choice)
  static Future<void> showStyleUpdateSheet(
    BuildContext context,
    List<String>? currentStyle,
    Function(User) onUpdate,
  ) async {
    final List<String> styles = [
      "Casual",
      "Formal",
      "Streetwear",
      "Traditional",
    ];

    // Only one style can be selected
    String? selectedStyle = (currentStyle != null && currentStyle.isNotEmpty)
        ? currentStyle.first
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        top: false,
        bottom: true,
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Style Preference',
                      style: _blackBoldTextStyle.copyWith(fontSize: 18),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select your preferred style:',
                  style: _blackTextStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: styles.map((style) {
                      final isSelected = selectedStyle == style;
                      return ChoiceChip(
                        label: Text(
                          style,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.black,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        checkmarkColor: isSelected
                            ? Colors.white
                            : Colors.black,
                        side: BorderSide(color: Colors.black, width: 1),
                        onSelected: (selected) {
                          setState(() {
                            selectedStyle = selected ? style : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: _blackButtonStyle,
                    onPressed: selectedStyle == null
                        ? null
                        : () async {
                            print('selectedStyle: $selectedStyle');
                            try {
                              final updatedUser = await _userService
                                  .updateProfile({
                                    'style': [selectedStyle],
                                  });
                              if (updatedUser != null) {
                                onUpdate(updatedUser);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Style updated successfully!',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              print('error: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update style: $e'),
                                ),
                              );
                            }
                          },
                    child: const Text('Update Style'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Update Price Range Bottom Sheet
  static Future<void> showPriceRangeUpdateSheet(
    BuildContext context,
    String? currentPriceRange,
    Function(User) onUpdate,
  ) async {
    final List<String> priceRanges = ["Low", "Medium", "High", "Luxury"];

    String? selectedPriceRange = currentPriceRange;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        top: false,
        bottom: true,
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Price Range',
                      style: _blackBoldTextStyle.copyWith(fontSize: 18),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select your preferred price range:',
                  style: _blackTextStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...priceRanges.map(
                  (range) => RadioListTile<String>(
                    title: Text(range, style: _blackTextStyle),
                    value: range,
                    groupValue: selectedPriceRange,
                    activeColor: _activeColor,
                    onChanged: (value) {
                      setState(() {
                        selectedPriceRange = value;
                      });
                    },
                    tileColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: _blackButtonStyle,
                    onPressed: selectedPriceRange == null
                        ? null
                        : () async {
                            try {
                              final updatedUser = await _userService
                                  .updateProfile({
                                    'priceRange': selectedPriceRange,
                                  });
                              if (updatedUser != null) {
                                onUpdate(updatedUser);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Price range updated successfully!',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update price range: $e',
                                  ),
                                ),
                              );
                            }
                          },
                    child: const Text('Update Price Range'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Update Profile Image Bottom Sheet
  static Future<void> showImageUpdateSheet(
    BuildContext context,
    String? currentImage,
    Function(User) onUpdate,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Update Profile Image',
                    style: _blackBoldTextStyle.copyWith(fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: _blackButtonStyle,
                      onPressed: () async {
                        try {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            await _handleImageUpload(context, image, onUpdate);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to pick image: $e')),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                      ),
                      label: const Text('Choose from Gallery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: _blackButtonStyle,
                      onPressed: () async {
                        try {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            await _handleImageUpload(context, image, onUpdate);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to capture image: $e'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text('Take Photo'),
                    ),
                  ),
                ],
              ),
              if (currentImage != null && currentImage.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final updatedUser = await _userService.updateProfile({
                          'image': null, // Remove image
                        });
                        if (updatedUser != null) {
                          onUpdate(updatedUser);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile image removed!'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove image: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Remove Current Image'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to handle image upload and profile update
  static Future<void> _handleImageUpload(
    BuildContext context,
    XFile imageFile,
    Function(User) onUpdate,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Pass the file path directly to updateProfile
      // The backend will handle the file upload and conversion to URL
      final updatedUser = await _userService.updateProfile({
        'image': imageFile.path,
      });

      // Close loading dialog
      Navigator.pop(context);

      if (updatedUser != null) {
        // Update the UI and close the bottom sheet
        onUpdate(updatedUser);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile with new image'),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  // Update Personal Info Bottom Sheet (DOB and Gender)
  static Future<void> showPersonalInfoUpdateSheet(
    BuildContext context,
    String? currentDob,
    String? currentGender,
    Function(User) onUpdate,
  ) async {
    final List<String> genders = ["Male", "Female", "Other"];

    String? selectedGender = currentGender;
    int? selectedYear;
    int? selectedMonth;

    // Parse current DOB if it exists
    if (currentDob != null && currentDob.isNotEmpty) {
      try {
        final parts = currentDob.split('-');
        if (parts.length >= 2) {
          selectedYear = int.tryParse(parts[0]);
          selectedMonth = int.tryParse(parts[1]);
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        top: false,
        bottom: true,
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Personal Info',
                      style: _blackBoldTextStyle.copyWith(fontSize: 18),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date of Birth Section
                Text(
                  'Date of Birth (Year-Month):',
                  style: _blackTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedYear,
                        items: List.generate(50, (index) {
                          final year = DateTime.now().year - 50 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: _blackTextStyle,
                            ),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            selectedYear = value;
                          });
                        },
                        dropdownColor: Colors.white,
                        style: _blackTextStyle,
                        iconEnabledColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedMonth,
                        items: List.generate(12, (index) {
                          final month = index + 1;
                          return DropdownMenuItem(
                            value: month,
                            child: Text(
                              month.toString().padLeft(2, '0'),
                              style: _blackTextStyle,
                            ),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = value;
                          });
                        },
                        dropdownColor: Colors.white,
                        style: _blackTextStyle,
                        iconEnabledColor: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Gender Section
                Text(
                  'Gender:',
                  style: _blackTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...genders.map(
                  (gender) => RadioListTile<String>(
                    title: Text(gender, style: _blackTextStyle),
                    value: gender,
                    groupValue: selectedGender,
                    activeColor: _activeColor,
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                    tileColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: _blackButtonStyle,
                    onPressed:
                        (selectedYear == null ||
                            selectedMonth == null ||
                            selectedGender == null)
                        ? null
                        : () async {
                            try {
                              final dobString =
                                  '${selectedYear}-${selectedMonth.toString().padLeft(2, '0')}';
                              final updatedUser = await _userService
                                  .updateProfile({
                                    'dob': dobString,
                                    'gender': selectedGender,
                                  });
                              if (updatedUser != null) {
                                onUpdate(updatedUser);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Personal info updated successfully!',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update personal info: $e',
                                  ),
                                ),
                              );
                            }
                          },
                    child: const Text('Update Personal Info'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
