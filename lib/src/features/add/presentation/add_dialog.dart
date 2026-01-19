import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:iatros/src/features/add/models/frequency_type.dart';
import 'package:iatros/src/features/add/schedule.dart';
import 'package:iatros/src/features/settings/theme_cubit.dart';

class AddDialog extends StatefulWidget {
  const AddDialog({super.key});

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  final timeController = FTimePickerController(initial: FTime.now());
  FrequencyType selectedFrequency = FrequencyType.DAILY;
  
  // Day selection state
  final Map<String, bool> selectedDays = {
    'MONDAY': false,
    'TUESDAY': false,
    'WEDNESDAY': false,
    'THURSDAY': false,
    'FRIDAY': false,
    'SATURDAY': false,
    'SUNDAY': false,
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: context.read<ThemeCubit>().getCurrentThemeName(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final theme = snapshot.data!;

        return AlertDialog(
          backgroundColor:
              theme == "yellow_dark" ? Colors.black : Colors.white,
          title: const Text('Add Schedule'),
          content: SizedBox(
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Frequency Type",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Frequency Type Selector
                  ...FrequencyType.values.map((type) {
                    return RadioListTile<FrequencyType>(
                      title: Text(type.displayName),
                      value: type,
                      groupValue: selectedFrequency,
                      onChanged: (FrequencyType? value) {
                        if (value != null) {
                          setState(() {
                            selectedFrequency = value;
                          });
                        }
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  
                  // Day Selection - Only show for SPECIFIC_DAYS
                  if (selectedFrequency == FrequencyType.SPECIFIC_DAYS) ...[
                    const Text(
                      "Select Days",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...selectedDays.keys.map((day) {
                      return CheckboxListTile(
                        title: Text(_formatDayName(day)),
                        value: selectedDays[day],
                        onChanged: (bool? value) {
                          setState(() {
                            selectedDays[day] = value ?? false;
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                  ],
                  
                  // Time Picker
                  const Text(
                    "Select Time",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: FTimePicker(
                      hour24: true,
                      controller: timeController,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  // style: FButtonStyle.outline,
                  onPress: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FButton(
                  onPress: () {
                    // Validate and create Schedule object
                    if (selectedFrequency == FrequencyType.SPECIFIC_DAYS) {
                      final hasSelectedDays = selectedDays.values.any((v) => v);
                      if (!hasSelectedDays) {
                        // Show error - must select at least one day
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select at least one day'),
                          ),
                        );
                        return;
                      }
                    }

                    // Get selected days list
                    final days = selectedFrequency == FrequencyType.SPECIFIC_DAYS
                        ? selectedDays.entries
                            .where((entry) => entry.value)
                            .map((entry) => entry.key)
                            .toList()
                        : null;

                    // Format time as HH:mm
                    final time = timeController.value;
                    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                    // Create schedule object
                    final schedule = Schedule(
                      frequencyType: selectedFrequency,
                      days: days,
                      times: [timeStr],
                    );

                    // Return schedule to parent
                    Navigator.of(context).pop(schedule);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDayName(String day) {
    return day.substring(0, 1) + day.substring(1).toLowerCase();
  }
}
