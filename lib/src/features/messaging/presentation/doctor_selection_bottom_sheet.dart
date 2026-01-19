import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/conversations_bloc.dart';
import '../bloc/conversations_event.dart';
import '../bloc/conversations_state.dart';

class DoctorSelectionBottomSheet extends StatelessWidget {
  const DoctorSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationsBloc, ConversationsState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Select a Doctor',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a doctor to start a conversation',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Doctor list
              Expanded(child: _buildDoctorList(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoctorList(BuildContext context, ConversationsState state) {
    if (state.doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading doctors...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: state.doctors.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final doctor = state.doctors[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.medical_services, color: Colors.blue),
          ),
          title: Text(
            doctor.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (doctor.specialty != null)
                Text(
                  doctor.specialty!,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              if (doctor.hospitalClinicName != null)
                Text(
                  doctor.hospitalClinicName!,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            context.read<ConversationsBloc>().add(
              StartNewConversation(doctor.id),
            );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
