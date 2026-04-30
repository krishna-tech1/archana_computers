import 'package:flutter/material.dart';
import '../models/data_models.dart';
import 'raise_ticket_page.dart';
import 'client_ticket_details_page.dart';

class ClientTicketsPage extends StatefulWidget {
  final List<Ticket> tickets;
  final Future<void> Function() onRefresh;

  const ClientTicketsPage({
    super.key,
    required this.tickets,
    required this.onRefresh,
  });

  @override
  State<ClientTicketsPage> createState() => _ClientTicketsPageState();
}

class _ClientTicketsPageState extends State<ClientTicketsPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'New', 'Processing', 'Completed'];

  List<Ticket> get _filtered {
    return widget.tickets.where((t) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          // Filter Tabs
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
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF0D1B3E) : Colors.grey[600],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Ticket List
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: filtered.isEmpty
                  ? ListView(
                      // must be ListView so RefreshIndicator works even on empty
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No tickets found',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text("You haven't raised any tickets yet.",
                                  style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _buildTicketCard(filtered[i]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const RaiseTicketPage()));
          widget.onRefresh();
        },
        backgroundColor: const Color(0xFF0D1B3E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
        statusColor = const Color(0xFF0D1B3E);
        statusBg = const Color(0xFFE8EAF6);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClientTicketDetailsPage(ticket: ticket)),
      ),
      child: Container(
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
                    style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(ticket.statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(ticket.title,
                style: const TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(ticket.type, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 8),
            if (ticket.remarks.isNotEmpty)
              Text(ticket.remarks,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
