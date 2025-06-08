import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import 'services/auth_service.dart';
import 'homepage.dart';

class DriverInfo extends StatefulWidget {
  final String userType;
  final String email;
  final String phone;
  final String fullName;
  final String dob;
  final String password;
  final File? profilePicture;

  const DriverInfo({
    super.key,
    required this.userType,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.dob,
    required this.password,
    required this.profilePicture,
  });

  @override
  State<DriverInfo> createState() => _DriverInfoState();
}

class _DriverInfoState extends State<DriverInfo> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _zoneController = TextEditingController();
  String? _selectedDriverType;
  String? _selectedVehicleType;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSubmitting = false;
  final bool _showSuccessAnimation = false;

  // متغيرات للصور
  File? _photoVehicule;
  File? _photoPermis;
  File? _photoCarteGrise;
  File? _photoAssurance;
  File? _photoVignette;
  File? _photoCarteMunicipale;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedDriverType = widget.userType;
    _requestPermissions();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    _adresseController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
    await Permission.storage.request();
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          switch (type) {
            case 'vehicule':
              _photoVehicule = File(image.path);
              break;
            case 'permis':
              _photoPermis = File(image.path);
              break;
            case 'carte_grise':
              _photoCarteGrise = File(image.path);
              break;
            case 'assurance':
              _photoAssurance = File(image.path);
              break;
            case 'vignette':
              _photoVignette = File(image.path);
              break;
            case 'carte_municipale':
              _photoCarteMunicipale = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      _showErrorDialog('error_image_pick'.tr());
    }
  }

  void _showImagePickerDialog(String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('choose_image_source'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('camera'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('gallery'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, type);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('error'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  bool _isWithinWorkingHours() {
    if (_startTime == null || _endTime == null) return false;
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes < startMinutes) {
      // الفترة تمتد لليوم التالي
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submitDriverInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDriverType == null) {
      _showErrorDialog('driver_type_required'.tr());
      return;
    }
    if (_selectedVehicleType == null) {
      _showErrorDialog('vehicle_type_required'.tr());
      return;
    }
    if (_zoneController.text.isEmpty) {
      _showErrorDialog('coverage_zone_required'.tr());
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showErrorDialog('working_hours_required'.tr());
      return;
    }
    if (_photoVehicule == null ||
        _photoPermis == null ||
        _photoCarteGrise == null ||
        _photoAssurance == null ||
        _photoVignette == null ||
        _photoCarteMunicipale == null) {
      _showErrorDialog('all_photos_required'.tr());
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final authService = AuthService();
      final result = await authService.registerDriver(
        userType: _selectedDriverType!,
        email: widget.email,
        phone: widget.phone,
        fullName: widget.fullName,
        dob: widget.dob,
        password: widget.password,
        adresse: _adresseController.text,
        matriculeVehicule: _matriculeController.text,
        typeVehicule: _selectedVehicleType!,
        zoneCouverture: _zoneController.text,
        startTime: _startTime!.format(context),
        endTime: _endTime!.format(context),
        profilePicture: widget.profilePicture,
        photoVehicule: _photoVehicule!,
        photoPermis: _photoPermis!,
        photoCarteGrise: _photoCarteGrise!,
        photoAssurance: _photoAssurance!,
        photoVignette: _photoVignette!,
        photoCarteMunicipale: _photoCarteMunicipale!,
      );
      setState(() {
        _isSubmitting = false;
      });
      if (result['statusCode'] == 201 || result['statusCode'] == 200) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              titlePadding: const EdgeInsets.only(top: 24),
              title: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFF2F9C95),
                    child:
                        Icon(Icons.check_circle, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'driver_registration_thank_you_title'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF2F9C95),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'driver_registration_thank_you_message'.tr(),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F9C95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const HomePage()),
                          (route) => false,
                        );
                      },
                      label: Text(
                        'ok'.tr(),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        _showErrorDialog(
          result['data']['message'] ?? 'error_completing_registration'.tr(),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog('${'error_completing_registration'.tr()}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final vehicleTypes = _selectedDriverType == 'Livreur'
        ? ['Moto', 'Camionnette']
        : ['Voiture', 'Camion'];
    const themeColor = Color(0xFF2F9C95);
    return Scaffold(
      backgroundColor: themeColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.025),
              child: Center(
                child: Image.asset(
                  'assets/images/Tawssil@logo.png',
                  width: screenWidth * 0.22,
                  height: screenWidth * 0.22,
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: _showSuccessAnimation
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animations/success.json',
                              width: screenWidth * 0.5,
                              height: screenWidth * 0.5,
                              repeat: false,
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Text(
                              'registration_completed'.tr(),
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.01),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      'complete_driver_info'.tr(),
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.06,
                                        fontWeight: FontWeight.bold,
                                        color: themeColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  // معلومات أساسية
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.04),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'personal_info'.tr(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenWidth * 0.045,
                                              color: themeColor,
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.01),
                                          Row(
                                            children: [
                                              const Icon(Icons.person,
                                                  color: themeColor),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  widget.fullName,
                                                  style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.042),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.015),
                                          TextFormField(
                                            controller: _adresseController,
                                            decoration: InputDecoration(
                                              labelText: 'adresse'.tr(),
                                              prefixIcon: const Icon(
                                                  Icons.location_on,
                                                  color: themeColor),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'adresse_required'.tr();
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.015),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              if (constraints.maxWidth < 400) {
                                                // شاشة صغيرة: كل Dropdown في سطر منفصل
                                                return Column(
                                                  children: [
                                                    _buildDriverTypeDropdown(),
                                                    const SizedBox(height: 10),
                                                    _buildVehicleTypeDropdown(
                                                        vehicleTypes),
                                                  ],
                                                );
                                              } else {
                                                // شاشة كبيرة: صفين بجانب بعض
                                                return Row(
                                                  children: [
                                                    Flexible(
                                                        child:
                                                            _buildDriverTypeDropdown()),
                                                    SizedBox(
                                                        width:
                                                            screenWidth * 0.04),
                                                    Flexible(
                                                        child:
                                                            _buildVehicleTypeDropdown(
                                                                vehicleTypes)),
                                                  ],
                                                );
                                              }
                                            },
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.015),
                                          TextFormField(
                                            controller: _zoneController,
                                            decoration: InputDecoration(
                                              labelText: 'zone_couverture'.tr(),
                                              prefixIcon: const Icon(Icons.map,
                                                  color: themeColor),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'coverage_zone_required'
                                                    .tr();
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.015),
                                          TextFormField(
                                            controller: _matriculeController,
                                            decoration: InputDecoration(
                                              labelText: 'vehicle_plate'.tr(),
                                              prefixIcon: const Icon(
                                                  Icons.confirmation_number,
                                                  color: themeColor),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'vehicle_plate_required'
                                                    .tr();
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  // أوقات العمل
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.04),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'working_hours_required'.tr(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenWidth * 0.045,
                                              color: themeColor,
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.01),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () =>
                                                      _selectTime(true),
                                                  child: InputDecorator(
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'start_time'.tr(),
                                                      prefixIcon: const Icon(
                                                          Icons.access_time,
                                                          color: themeColor),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _startTime != null
                                                          ? _startTime!
                                                              .format(context)
                                                          : 'select_time'.tr(),
                                                      style: TextStyle(
                                                          fontSize:
                                                              screenWidth *
                                                                  0.042),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                  width: screenWidth * 0.04),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () =>
                                                      _selectTime(false),
                                                  child: InputDecorator(
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'end_time'.tr(),
                                                      prefixIcon: const Icon(
                                                          Icons.access_time,
                                                          color: themeColor),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _endTime != null
                                                          ? _endTime!
                                                              .format(context)
                                                          : 'select_time'.tr(),
                                                      style: TextStyle(
                                                          fontSize:
                                                              screenWidth *
                                                                  0.042),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.015),
                                          Row(
                                            children: [
                                              Icon(Icons.circle,
                                                  color: _isWithinWorkingHours()
                                                      ? Colors.green
                                                      : Colors.red,
                                                  size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                _isWithinWorkingHours()
                                                    ? 'available'.tr()
                                                    : 'unavailable'.tr(),
                                                style: TextStyle(
                                                  color: _isWithinWorkingHours()
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: screenWidth * 0.045,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  // صور الوثائق
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.04),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'all_photos_required'.tr(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: screenWidth * 0.045,
                                              color: themeColor,
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.01),
                                          _buildImagePicker(
                                              'vehicle_photo'.tr(),
                                              'vehicule',
                                              _photoVehicule,
                                              screenWidth),
                                          _buildImagePicker(
                                              'license_photo'.tr(),
                                              'permis',
                                              _photoPermis,
                                              screenWidth),
                                          _buildImagePicker(
                                              'registration_card'.tr(),
                                              'carte_grise',
                                              _photoCarteGrise,
                                              screenWidth),
                                          _buildImagePicker(
                                              'insurance_photo'.tr(),
                                              'assurance',
                                              _photoAssurance,
                                              screenWidth),
                                          _buildImagePicker(
                                              'sticker_photo'.tr(),
                                              'vignette',
                                              _photoVignette,
                                              screenWidth),
                                          _buildImagePicker(
                                              'municipal_card'.tr(),
                                              'carte_municipale',
                                              _photoCarteMunicipale,
                                              screenWidth),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.03),
                                  if (_isSubmitting)
                                    const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2F9C95),
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _submitDriverInfo,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: themeColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'complete_registration'.tr(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.048,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: screenHeight * 0.03),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(
      String title, String type, File? image, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        InkWell(
          onTap: () => _showImagePickerDialog(type),
          child: Container(
            width: double.infinity,
            height: screenWidth * 0.35,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: screenWidth * 0.11,
                          color: Colors.grey,
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Text(
                          'add_photo'.tr(),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        SizedBox(height: screenWidth * 0.04),
      ],
    );
  }

  Widget _buildDriverTypeDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedDriverType,
      items: const [
        DropdownMenuItem(value: 'Livreur', child: Text('Livreur')),
        DropdownMenuItem(value: 'Chauffeur', child: Text('Chauffeur')),
      ],
      onChanged: (val) {
        setState(() {
          _selectedDriverType = val;
          _selectedVehicleType = null;
        });
      },
      decoration: InputDecoration(
        labelText: 'driver_type'.tr(),
        prefixIcon: const Icon(Icons.badge, color: Color(0xFF2F9C95), size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) => value == null ? 'driver_type_required'.tr() : null,
    );
  }

  Widget _buildVehicleTypeDropdown(List<String> vehicleTypes) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedVehicleType,
      items: vehicleTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedVehicleType = val;
        });
      },
      decoration: InputDecoration(
        labelText: 'type_vehicule'.tr(),
        prefixIcon: const Icon(Icons.directions_car,
            color: Color(0xFF2F9C95), size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) => value == null ? 'vehicle_type_required'.tr() : null,
    );
  }
}
