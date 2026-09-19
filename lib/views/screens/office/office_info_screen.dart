import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/office_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class OfficeInfoScreen extends StatefulWidget {
  const OfficeInfoScreen({super.key});

  @override
  State<OfficeInfoScreen> createState() => _OfficeInfoScreenState();
}

class _OfficeInfoScreenState extends State<OfficeInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final officeCtrl = Get.put(OfficeController());
  final auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _loadOfficeData();
  }

  void _loadOfficeData() {
    // If controller is still loading, it will update via Obx in UI
    final office = officeCtrl.office.value;
    if (office != null) {
      _nameCtrl.text = office.name;
      _phoneCtrl.text = office.phone ?? '';
      _addressCtrl.text = office.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'معلومات المكتب',
        showNotification: false,
      ),
      body: Obx(() {
        if (officeCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Sync fields if they were loaded after initState
        final office = officeCtrl.office.value;
        if (office != null && _nameCtrl.text.isEmpty) {
           _nameCtrl.text = office.name;
           _phoneCtrl.text = office.phone ?? '';
           _addressCtrl.text = office.address ?? '';
        }

        final user = auth.currentUser.value;
        final canMutate = user == null || user.canMutateOfficeContent;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.business, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),

                // حقول المعلومات
                _buildField(
                  controller: _nameCtrl,
                  label: 'اسم المحامي',
                  icon: Icons.person_outline,
                  readOnly: !canMutate,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _phoneCtrl,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  readOnly: !canMutate,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _addressCtrl,
                  label: 'العنوان',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  readOnly: !canMutate,
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 24),

                // زر الحفظ
                if (canMutate)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: officeCtrl.isUpdating.value
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                officeCtrl.updateOffice(
                                  name: _nameCtrl.text.trim(),
                                  phone: _phoneCtrl.text.trim(),
                                  address: _addressCtrl.text.trim(),
                                );
                              }
                            },
                      child: officeCtrl.isUpdating.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('حفظ التعديلات'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
        fillColor: readOnly ? Colors.grey[100] : null,
        filled: readOnly,
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
    );
  }
}
