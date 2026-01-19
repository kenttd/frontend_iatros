import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:iatros/src/features/add/models/create_user_medication.dart';
import 'package:iatros/src/features/add/models/duration.dart' as med_duration;
import 'package:iatros/src/features/add/presentation/add_dialog.dart';
import 'package:iatros/src/features/add/schedule.dart';
import 'package:iatros/src/features/settings/theme_cubit.dart';
import 'package:iatros/src/utils/api_client.dart';

class AddScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const AddScreen({super.key, required this.data});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  late TextEditingController nameController;
  late TextEditingController dosageController;
  late TextEditingController instructionsController;

  List<Schedule> schedules = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['name'] ?? '');
    dosageController = TextEditingController();
    instructionsController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    instructionsController.dispose();
    super.dispose();
  }

  Future<void> _addSchedule() async {
    final result = await showDialog<Schedule>(
      context: context,
      builder: (context) => const AddDialog(),
    );

    if (result != null) {
      setState(() {
        schedules.add(result);
      });
    }
  }

  void _removeSchedule(int index) {
    setState(() {
      schedules.removeAt(index);
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          endDate ??
          (startDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Future<void> _submitMedication() async {
    // Validation
    if (dosageController.text.isEmpty) {
      _showError('Please enter a dosage');
      return;
    }
    if (schedules.isEmpty) {
      _showError('Please add at least one schedule');
      return;
    }
    if (startDate == null) {
      _showError('Please select a start date');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Combine all schedule times into one schedule
      // For now, we'll use the first schedule's frequency type and combine times
      final allTimes = schedules.expand((s) => s.times).toList();
      final firstSchedule = schedules.first;

      final medication = CreateUserMedication(
        rxcui: widget.data['rxcui'] ?? '',
        medicationName: nameController.text,
        dosage: dosageController.text,
        instructions: instructionsController.text.isNotEmpty
            ? instructionsController.text
            : null,
        schedule: Schedule(
          frequencyType: firstSchedule.frequencyType,
          days: firstSchedule.days,
          times: allTimes,
        ),
        duration: med_duration.Duration(
          startDate: startDate!,
          endDate: endDate,
        ),
      );

      final apiClient = ApiClient();
      final response = await apiClient.post(
        '/medications',
        body: jsonEncode(medication.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          setState(() {
            isSubmitting = false;
          });
          // Use GoRouter to navigate back to home
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            context.go('/home');
          }
          return; // Exit early since we handled isSubmitting above
        }
      } else {
        _showError('Failed to add medication: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medicine')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Medication Details",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name (readonly from search)
                    FTextField(
                      controller: nameController,
                      enabled: false,
                      label: const Text("Medication Name"),
                    ),
                    const SizedBox(height: 15),

                    // Dosage
                    FTextField(
                      controller: dosageController,
                      clearable: (value) => value.text.isNotEmpty,
                      hint: 'e.g., 500mg, 1 tablet',
                      label: const Text("Dosage *"),
                    ),
                    const SizedBox(height: 15),

                    // Instructions
                    FTextField(
                      controller: instructionsController,
                      clearable: (value) => value.text.isNotEmpty,
                      hint: 'e.g., Take with food',
                      maxLines: 3,
                      label: const Text("Instructions (Optional)"),
                    ),
                    const SizedBox(height: 25),

                    // Duration Section
                    const Text(
                      "Duration",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: FButton(
                            // style: FButtonStyle.outline,
                            onPress: _selectStartDate,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                startDate == null
                                    ? 'Start Date *'
                                    : 'Start: ${_formatDate(startDate!)}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FButton(
                            // style: FButtonStyle.outline,
                            onPress: _selectEndDate,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                endDate == null
                                    ? 'End Date (Optional)'
                                    : 'End: ${_formatDate(endDate!)}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Schedules Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Schedules",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FButton(
                          onPress: _addSchedule,
                          prefix: const Icon(FIcons.plus),
                          child: const Text("Add Schedule"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (schedules.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          "You must add at least 1 schedule.",
                          style: TextStyle(color: Colors.orange),
                        ),
                      )
                    else
                      ...schedules.asMap().entries.map((entry) {
                        final index = entry.key;
                        final schedule = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(schedule.getDisplayText()),
                            subtitle: Text(
                              'Times: ${schedule.times.join(', ')}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeSchedule(index),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),

            // Submit Button
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: isSubmitting ? null : _submitMedication,
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Add Medication"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
