import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';

/// Admin ticket details — NO chat. Admin can update ticket status.
class TicketDetailsPage extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailsPage({super.key, required this.ticket});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await ApiService().updateTicketStatus(widget.ticket.id, newStatus);
      if (mounted) {
        setState(() => _currentStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_labelFor(newStatus)}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cannot connect to server.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String _labelFor(String status) {
    switch (status) {
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      default:
        return 'New';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'processing':
        return Colors.orange[800]!;
      case 'completed':
        return Colors.green[800]!;
      default:
        return Colors.blue[800]!;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'processing':
        return Colors.orange[50]!;
      case 'completed':
        return Colors.green[50]!;
      default:
        return Colors.blue[50]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D1B3E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ticket Details',
            style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: _statusBg(_currentStatus), borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Text(_labelFor(_currentStatus),
                    style: TextStyle(
                        color: _statusColor(_currentStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ticket ID
            Text('#${widget.ticket.ticketNo}',
                style: TextStyle(
                    color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 12),

            // Main details card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.ticket.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.category_outlined, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(widget.ticket.type, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),
                  const Text('Remarks',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
                  const SizedBox(height: 8),
                  Text(
                    widget.ticket.remarks.isNotEmpty
                        ? widget.ticket.remarks
                        : 'No remarks provided.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Client info card
            if (widget.ticket.clientName.isNotEmpty) ...[
              const Text('Client Information',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildClientRow(Icons.person_outline, widget.ticket.clientName),
                    const SizedBox(height: 10),
                    _buildClientRow(Icons.email_outlined, widget.ticket.clientEmail),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Status update section
            const Text('Update Status',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
            const SizedBox(height: 16),

            // Move to Processing
            if (_currentStatus == 'new') ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _updateStatus('processing'),
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D1B3E)))
                      : const Icon(Icons.assignment_turned_in_outlined, size: 20),
                  label: const Text('Move to Processing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: const Color(0xFF0D1B3E),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Mark as Completed
            if (_currentStatus != 'completed') ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : () => _updateStatus('completed'),
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B3E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],

            if (_currentStatus == 'completed') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                    const SizedBox(width: 12),
                    Text('This ticket has been completed.',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Status timeline
            const Text('Status Timeline',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3E))),
            const SizedBox(height: 16),
            _buildStatusTimeline(_currentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
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
                            fontWeight: isDone ? FontWeight.bold : FontWeight.normal)),
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
  Widget _buildClientRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0D1B3E)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0D1B3E), fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
