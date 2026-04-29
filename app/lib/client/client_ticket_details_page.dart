import 'package:flutter/material.dart';
import '../models/data_models.dart';

/// Client ticket details — NO chat. Shows ticket info and a simple status badge.
class ClientTicketDetailsPage extends StatelessWidget {
  final Ticket ticket;
  const ClientTicketDetailsPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    switch (ticket.status) {
      case 'processing':
        statusColor = Colors.orange[800]!;
        statusBg = Colors.orange[50]!;
        break;
      case 'completed':
        statusColor = Colors.green[800]!;
        statusBg = Colors.green[50]!;
        break;
      default:
        statusColor = const Color(0xFF0D1B3E);
        statusBg = const Color(0xFFE8EAF6);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D1B3E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ticket Details',
          style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Text(ticket.statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket ID
            Text('#${ticket.ticketNo}',
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 12),

            // Main card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
                  const SizedBox(height: 8),
                  _infoRow(Icons.category_outlined, ticket.type),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),
                  const Text('Remarks',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
                  const SizedBox(height: 8),
                  Text(
                    ticket.remarks.isNotEmpty ? ticket.remarks : 'No remarks provided.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status timeline
            const Text('Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
            const SizedBox(height: 16),
            _statusTimeline(ticket.status),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _statusTimeline(String status) {
    final steps = ['New', 'Processing', 'Completed'];
    final statusMap = {'new': 0, 'processing': 1, 'completed': 2};
    final currentStep = statusMap[status] ?? 0;

    return Row(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final label = entry.value;
        final isDone = idx <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF0D1B3E) : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        idx < currentStep
                            ? Icons.check
                            : idx == currentStep
                                ? Icons.circle
                                : Icons.radio_button_unchecked,
                        color: isDone ? Colors.white : Colors.grey[400],
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDone ? const Color(0xFF0D1B3E) : Colors.grey[400],
                          fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                        )),
                  ],
                ),
              ),
              if (idx < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22),
                    color: idx < currentStep ? const Color(0xFF0D1B3E) : Colors.grey[200],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
