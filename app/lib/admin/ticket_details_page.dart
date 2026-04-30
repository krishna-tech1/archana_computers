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
      // If jumping from New directly to Completed, we must go through Processing
      // to satisfy the backend's strict state machine logic.
      if (_currentStatus == 'new' && newStatus == 'completed') {
        await ApiService().updateTicketStatus(widget.ticket.id, 'processing');
        await ApiService().updateTicketStatus(widget.ticket.id, 'completed');
      } else {
        await ApiService().updateTicketStatus(widget.ticket.id, newStatus);
      }

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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D1B3E), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text('Ticket Details',
            style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _statusBg(_currentStatus),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor(_currentStatus).withValues(alpha: 0.1)),
              ),
              child: Center(
                child: Text(_labelFor(_currentStatus).toUpperCase(),
                    style: TextStyle(
                        color: _statusColor(_currentStatus),
                        fontSize: 10,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B3E).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TICKET #${widget.ticket.ticketNo}',
                      style: const TextStyle(
                        color: Color(0xFF0D1B3E),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.ticket.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D1B3E),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.category_rounded, size: 16, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.ticket.type,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Remarks Section
                  _buildSectionTitle('Issue Description'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.ticket.remarks.isNotEmpty ? widget.ticket.remarks : 'No additional remarks provided.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Client info section
                  if (widget.ticket.clientName.isNotEmpty) ...[
                    _buildSectionTitle('Client Information'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B3E),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D1B3E).withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildClientRow(Icons.person_rounded, 'Client Name', widget.ticket.clientName),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: Colors.white12, height: 1),
                          ),
                          _buildClientRow(Icons.email_rounded, 'Email Address', widget.ticket.clientEmail),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Timeline Section
                  _buildSectionTitle('Progress Timeline'),
                  const SizedBox(height: 16),
                  _buildStatusTimeline(_currentStatus),

                  const SizedBox(height: 40),

                  // Action Buttons
                  if (_currentStatus != 'completed') ...[
                    if (_currentStatus == 'new') ...[
                      _buildActionButton(
                        onPressed: () => _updateStatus('processing'),
                        label: 'Start Processing',
                        icon: Icons.play_arrow_rounded,
                        color: const Color(0xFF0D1B3E),
                        isPrimary: false,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildActionButton(
                      onPressed: () => _updateStatus('completed'),
                      label: 'Mark as Completed',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green.shade600,
                      isPrimary: true,
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.verified_rounded, color: Colors.green.shade600, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Task Completed Successfully',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required Color color,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.white,
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: isPrimary ? 4 : 0,
          shadowColor: color.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(color: color.withValues(alpha: 0.2), width: 2),
          ),
        ),
        child: _isUpdating
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: isPrimary ? Colors.white : color,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    final steps = ['New', 'Processing', 'Completed'];
    final statusMap = {'new': 0, 'processing': 1, 'completed': 2};
    final currentStep = statusMap[status] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final isDone = idx <= currentStep;
          final isLast = idx == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? const Color(0xFF0D1B3E) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone ? const Color(0xFF0D1B3E) : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        idx < currentStep ? Icons.check : Icons.circle,
                        color: isDone ? Colors.white : Colors.grey.shade300,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[idx],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
                        color: isDone ? const Color(0xFF0D1B3E) : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Divider(
                        color: idx < currentStep ? const Color(0xFF0D1B3E) : Colors.grey.shade200,
                        thickness: 3,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildClientRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
