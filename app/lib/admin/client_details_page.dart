import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';

class ClientDetailsPage extends StatelessWidget {
  final Client client;

  const ClientDetailsPage({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D1B3E), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Client Details',
            style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF0D1B3E).withValues(alpha: 0.05),
                    child: Text(
                      client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    client.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E)),
                  ),
                  Text(
                    client.email,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details Section
            _sectionTitle('Information'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_outline, 'Full Name', client.name),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, 'Email Address', client.email),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone_outlined, 'Phone Number', client.phone),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on_outlined, 'Address', client.address),

            const SizedBox(height: 32),
            _sectionTitle('Account Security'),
            const SizedBox(height: 16),
            _ResetPasswordWidget(clientId: client.id),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.2),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: const TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordWidget extends StatefulWidget {
  final String clientId;
  const _ResetPasswordWidget({required this.clientId});

  @override
  State<_ResetPasswordWidget> createState() => _ResetPasswordWidgetState();
}

class _ResetPasswordWidgetState extends State<_ResetPasswordWidget> {
  String? _newPassword;
  bool _isResetting = false;

  Future<void> _resetPassword() async {
    setState(() => _isResetting = true);
    try {
      final newPassword = await ApiService().resetClientPassword(widget.clientId);
      if (mounted) {
        setState(() {
          _newPassword = newPassword;
          _isResetting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResetting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting password: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_newPassword != null) {
      Clipboard.setData(ClipboardData(text: _newPassword!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password copied to clipboard'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isResetting ? null : _resetPassword,
            icon: _isResetting 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_reset),
            label: const Text('Reset Account Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D1B3E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (_newPassword != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NEW PASSWORD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 4),
                      Text(_newPassword!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E), letterSpacing: 1.5)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, color: Colors.green),
                  tooltip: 'Copy password',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
