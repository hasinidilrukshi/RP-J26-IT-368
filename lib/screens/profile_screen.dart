import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/profile_store.dart';
import '../widgets/primary_button.dart';

/// Optional details, filled in ONCE (e.g. when the tourist installs the app).
/// They are attached to every SOS automatically – never asked in an emergency.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _p = ProfileStore.instance;
  late final _name = TextEditingController(text: _p.name);
  late final _phone = TextEditingController(text: _p.phone);
  late final _country = TextEditingController(text: _p.nationality);
  late final _contact = TextEditingController(text: _p.emergencyContact);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _country.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _p.save(
      name: _name.text,
      phone: _phone.text,
      nationality: _country.text,
      emergencyContact: _contact.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved on this phone')));
    Navigator.pop(context);
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        textCapitalization: type == null
            ? TextCapitalization.words
            : TextCapitalization.none,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My details (optional)')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Fill this in once. It is sent with your SOS so responders can '
            'call you back – you will never be asked during an emergency.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          _field(_name, 'Your name', Icons.person_rounded),
          _field(_phone, 'Your phone (e.g. +94 77 123 4567)',
              Icons.phone_rounded,
              type: TextInputType.phone),
          _field(_country, 'Nationality', Icons.flag_rounded),
          _field(_contact, 'Emergency contact phone (family / friend)',
              Icons.contact_phone_rounded,
              type: TextInputType.phone),
          const Text(
            'Your emergency contact gets your GPS location by SMS when you tap '
            '"Send to my contact" after an SOS.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Save',
            icon: Icons.save_rounded,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
