import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class RaiseTicketPage extends StatefulWidget {
  const RaiseTicketPage({super.key});

  @override
  State<RaiseTicketPage> createState() => _RaiseTicketPageState();
}

class _RaiseTicketPageState extends State<RaiseTicketPage> {
  final _titleController = TextEditingController();
  final _remarksController = TextEditingController();
  String? _selectedType;
  bool _isLoading = false;

  final List<String> _ticketTypes = [
    'Software Issue',
    'Hardware Issue',
    'Network Issue',
    'General Inquiry',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final remarks = _remarksController.text.trim();

    if (title.isEmpty || _selectedType == null || remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Please fill all required fields'),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService().createTicket(
        title: title,
        type: _selectedType!,
        remarks: remarks,
      );
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      _showSuccessDialog();
      
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot connect to server.'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ticket Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0D1B3E)),
            ),
            const SizedBox(height: 12),
            Text(
              'Your ticket has been raised successfully. Our team will review it soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context, true); // Back to home with success signal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D1B3E), size: 18),
          ),
        ),
        title: const Text(
          'Raise New Ticket',
          style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
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
              child: Text(
                "Describe the technical issue you're facing. Our team will assist you shortly.",
                style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5, fontWeight: FontWeight.w400),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _label('Issue Title'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    enabled: !_isLoading,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D1B3E)),
                    decoration: _inputDecoration('Briefly describe the problem'),
                  ),
                  const SizedBox(height: 24),

                  // Type
                  _label('Issue Category'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D1B3E)),
                    items: _ticketTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: _isLoading ? null : (v) => setState(() => _selectedType = v),
                    decoration: _inputDecoration('Select category'),
                  ),
                  const SizedBox(height: 24),

                  // Remarks
                  _label('Additional Remarks'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _remarksController,
                    maxLines: 5,
                    enabled: !_isLoading,
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF0D1B3E)),
                    decoration: _inputDecoration('Provide more details...'),
                  ),
                  const SizedBox(height: 32),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B3E).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0D1B3E).withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 22, color: Color(0xFF0D1B3E)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Response Time',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0D1B3E))),
                              const SizedBox(height: 6),
                              Text(
                                'Standard support hours are 9:00 AM to 6:00 PM. Tickets raised outside these hours will be addressed on the next business day.',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D1B3E),
                        foregroundColor: Colors.white,
                        shadowColor: const Color(0xFF0D1B3E).withValues(alpha: 0.3),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 20),
                                SizedBox(width: 12),
                                Text('Submit Ticket',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D1B3E), width: 2)),
      );
}
