import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../widgets/double_back_exit.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';

import '../product_view_page.dart';
import 'client_tickets_page.dart';
import 'raise_ticket_page.dart';
import 'client_ticket_details_page.dart';

class ClientHome extends StatefulWidget {
  final UserSession session;
  const ClientHome({super.key, required this.session});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int _currentIndex = 0;
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
      _showError(e.message);
    } on DioException catch (_) {
      _showError('Cannot connect to server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAccountPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: Dialog(
              alignment: Alignment.topRight,
              insetPadding: const EdgeInsets.only(top: 60, right: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 20,
              shadowColor: Colors.black26,
              child: Container(
                width: 220, // More compact width
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 40,
                      color: Color(0xFF0D1B3E),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.session.email,
                        style: const TextStyle(
                          color: Color(0xFF0D1B3E),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: ctx,
                          builder: (confirmCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              'Are you sure you want to log out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmCtx),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(
                                    confirmCtx,
                                  ); // Close confirm dialog
                                  Navigator.of(ctx).pop(); // Close popup
                                  await ApiService().logout();
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const ProductViewPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 16,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int get _activeCount => _tickets
      .where((t) => t.status == 'new' || t.status == 'processing')
      .length;
  int get _completedCount =>
      _tickets.where((t) => t.status == 'completed').length;

  @override
  Widget build(BuildContext context) {
    return DoubleBackToExit(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Archana Computers',
            style: TextStyle(
              color: Color(0xFF0D1B3E),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: _showAccountPopup,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  child: Text(
                    widget.session.name.isNotEmpty
                        ? widget.session.name[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Color(0xFF0D1B3E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _currentIndex == 0
            ? _buildHomeContent()
            : ClientTicketsPage(tickets: _tickets, onRefresh: _fetchTickets),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0D1B3E),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              label: 'Tickets',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _fetchTickets,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service Dashboard',
                style: TextStyle(
                  color: Color(0xFF0D1B3E),
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome back to your support portal',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.assignment_outlined,
                            iconBg: const Color(0xFFE8EAF6),
                            iconColor: const Color(0xFF0D1B3E),
                            value: _activeCount.toString(),
                            label: 'Active Tickets',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle_outline,
                            iconBg: const Color(0xFFE8F5E9),
                            iconColor: Colors.green,
                            value: _completedCount.toString(),
                            label: 'Completed',
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RaiseTicketPage(),
                      ),
                    );
                    _fetchTickets(); // refresh anyway
                    if (result == true) {
                      setState(
                        () => _currentIndex = 1,
                      ); // Redirect to Tickets tab
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Raise Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Recent Tickets',
                style: TextStyle(
                  color: Color(0xFF0D1B3E),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_tickets.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Your ticket updates will appear here.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                )
              else
                ..._tickets
                    .take(3)
                    .map(
                      (t) => InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientTicketDetailsPage(ticket: t),
                          ),
                        ),
                        child: _buildRecentTicketCard(t),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTicketCard(Ticket ticket) {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: const TextStyle(
                    color: Color(0xFF0D1B3E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.type,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ticket.statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0D1B3E),
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}
