import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';
import 'ticket_details_page.dart';

class TicketsListPage extends StatefulWidget {
  const TicketsListPage({super.key});

  @override
  State<TicketsListPage> createState() => _TicketsListPageState();
}

class _TicketsListPageState extends State<TicketsListPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'New', 'Processing', 'Completed'];
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await ApiService().getTickets();
      if (mounted) setState(() => _tickets = tickets);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot connect to server.'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Ticket> get _filtered {
    return _tickets.where((t) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'New') return t.status == 'new';
      if (_selectedFilter == 'Processing') return t.status == 'processing';
      if (_selectedFilter == 'Completed') return t.status == 'completed';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 45,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(filter,
                          style: TextStyle(
                              color: isSelected ? const Color(0xFF0D1B3E) : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Title and count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ticket Management',
                  style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 20)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Text('${filtered.length} total',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No tickets found',
                              style: TextStyle(
                                  color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchTickets,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildTicketCard(filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
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
        statusColor = Colors.blue[800]!;
        statusBg = Colors.blue[50]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${ticket.ticketNo}',
                  style: TextStyle(
                      color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(ticket.statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(ticket.title,
              style: const TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 4),
          Text(ticket.type, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          if (ticket.clientName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(ticket.clientName,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TicketDetailsPage(ticket: ticket)),
                  );
                  _fetchTickets(); // refresh after status update
                },
                child: Row(
                  children: [
                    const Text('View details',
                        style: TextStyle(
                            color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0D1B3E)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
