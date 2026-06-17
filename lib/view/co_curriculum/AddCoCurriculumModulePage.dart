import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../provider/co_curriculum/CoCurriculumController.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import 'AdabClaimListPage.dart';

class AddCoCurriculumModulePage extends StatefulWidget {
  final String staff_id;

  const AddCoCurriculumModulePage({
    super.key,
    required this.staff_id,
  });

  @override
  State<AddCoCurriculumModulePage> createState() =>
      _AddCoCurriculumModulePageState();
}

class _AddCoCurriculumModulePageState extends State<AddCoCurriculumModulePage> {
  final TextEditingController moduleNameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController creditController = TextEditingController();

  DateTime? selectedModuleDate;

  @override
  void dispose() {
    moduleNameController.dispose();
    categoryController.dispose();
    creditController.dispose();
    super.dispose();
  }

  // This method opens date picker for Pusat ADAB to select module date.
  Future<void> selectModuleDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        selectedModuleDate = pickedDate;
      });
    }
  }

  // This method validates the form before adding a module.
  bool validateModuleForm() {
    if (moduleNameController.text.trim().isEmpty) {
      showMessage('Please enter module name.');
      return false;
    }

    if (categoryController.text.trim().isEmpty) {
      showMessage('Please enter module category.');
      return false;
    }

    if (creditController.text.trim().isEmpty) {
      showMessage('Please enter credit value.');
      return false;
    }

    if (int.tryParse(creditController.text.trim()) == null) {
      showMessage('Credit value must be a number.');
      return false;
    }

    if (selectedModuleDate == null) {
      showMessage('Please select module date.');
      return false;
    }

    return true;
  }

  // This method sends module information to the controller.
  Future<void> addModule() async {
    if (!validateModuleForm()) {
      return;
    }

    final controller = Provider.of<CoCurriculumController>(
      context,
      listen: false,
    );

    final message = await controller.addCoCurriculumModule(
      module_name: moduleNameController.text.trim(),
      module_category: categoryController.text.trim(),
      credit_value: int.parse(creditController.text.trim()),
      module_date: selectedModuleDate!,
      created_by: widget.staff_id,
    );

    if (!mounted) {
      return;
    }

    showMessage(message);

    if (message == 'Module added successfully.') {
      moduleNameController.clear();
      categoryController.clear();
      creditController.clear();

      setState(() {
        selectedModuleDate = null;
      });
    }
  }

  // This method displays message to the user.
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1F7A5C),
      ),
    );
  }

  // OOP METHOD: This method signs out Pusat ADAB staff and returns to login wrapper.
  Future<void> logoutUser(BuildContext context) async {
    final authService = AuthService();
    await authService.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  }

  // OOP METHOD: This method maps Pusat ADAB staff back to claim queue.
  void mapsToClaimQueue(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdabClaimListPage(staff_id: widget.staff_id)),
    );
  }

  // This method displays Pusat ADAB profile information.
  void displayProfileDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Pusat ADAB Profile',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('PusatAdab')
                .doc(widget.staff_id)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1F7A5C))),
                );
              }

              final data = snapshot.data?.data() ?? {};

              String readProfileValue(List<String> keys, String fallback) {
                for (final key in keys) {
                  final value = data[key];
                  if (value != null && value.toString().trim().isNotEmpty) {
                    return value.toString();
                  }
                }
                return fallback;
              }

              Widget item(String label, String value) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                      const SizedBox(height: 3),
                      Text(value, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Text(
                          'U',
                          style: TextStyle(
                            color: Color(0xFF1F7A5C),
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    item('staff_name', readProfileValue(['staff_name'], widget.staff_id)),
                    item('staff_email', readProfileValue(['staff_email'], widget.staff_id)),
                    item('department', readProfileValue(['department'], 'Pusat ADAB')),
                    item('role', readProfileValue(['role'], 'Pusat ADAB')),
                    item('status', readProfileValue(['status', 'account_status'], 'Active')),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF1F7A5C), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // OOP METHOD: This method shows staff actions from the top-right user button.
  void displayProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Menu',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person, color: Color(0xFF1F7A5C)),
                title: const Text('User Profile', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  displayProfileDialog();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fact_check, color: Color(0xFF1F7A5C)),
                title: const Text('Claim Queue', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  mapsToClaimQueue(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await logoutUser(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoCurriculumController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            ),
            backgroundColor: const Color(0xFF1F7A5C),
            elevation: 0,
            title: const Text(
              'Add Co-curriculum Module',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => displayProfileMenu(context),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Color(0xFF1F7A5C),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      displayHeaderCard(),
                      const SizedBox(height: 18),
                      displayModuleForm(),
                      const SizedBox(height: 22),
                      displayAddButton(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // This method displays header information for module management.
  Widget displayHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F7A5C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.add_circle_outline,
              color: Color(0xFF1F7A5C),
              size: 34,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Add a new co-curriculum module for students to register.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This method displays the add module form.
  Widget displayModuleForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Module Information',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          displayTextField(
            controller: moduleNameController,
            label: 'Module Name',
            hint: 'Example: Leadership Workshop',
            icon: Icons.school,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 14),
          displayTextField(
            controller: categoryController,
            label: 'Module Category',
            hint: 'Example: Leadership',
            icon: Icons.category,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 14),
          displayTextField(
            controller: creditController,
            label: 'Credit Value',
            hint: 'Example: 1',
            icon: Icons.star,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          displayDatePickerField(),
        ],
      ),
    );
  }

  // This method displays reusable text field.
  Widget displayTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF1F7A5C),
        ),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF1F7A5C),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // This method displays date picker field.
  Widget displayDatePickerField() {
    return InkWell(
      onTap: selectModuleDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: Color(0xFF1F7A5C),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedModuleDate == null
                    ? 'Select Module Date'
                    : 'Module Date: ${formatDate(selectedModuleDate!)}',
                style: TextStyle(
                  color: selectedModuleDate == null
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF111827),
                  fontWeight: selectedModuleDate == null
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This method displays add module button.
  Widget displayAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'Add Module',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: addModule,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F7A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // This method formats DateTime into readable date format.
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
