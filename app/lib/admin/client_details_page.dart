import 'package:flutter/material.dart';
import '../models/data_models.dart';

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
