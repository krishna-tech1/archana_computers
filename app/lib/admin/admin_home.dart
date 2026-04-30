import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/data_models.dart';
import '../widgets/double_back_exit.dart';
import '../login_page.dart';
import '../services/api_service.dart';
import 'add_client_page.dart';
import 'clients_list_page.dart';
import 'tickets_list_page.dart';
import 'ticket_details_page.dart';

class AdminHome extends StatefulWidget {
  final UserSession session;
  const AdminHome({super.key, required this.session});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  // Home tab data
  List<Ticket> _recentTickets = [];
  int _clientCount = 0;
  bool _isLoading = true;

  final List<String> _titles = ['Archana Computers', 'Client Directory', 'Ticket Management'];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService().getTickets(),
        ApiService().getClients(),
      ]);
      if (mounted) {
        setState(() {
          _recentTickets = (results[0] as List<Ticket>).take(3).toList();
          _clientCount = (results[1] as List<Client>).length;
        });
      }
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
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 20,
              shadowColor: Colors.black26,
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    const Icon(Icons.account_circle_outlined, size: 40, color: Color(0xFF0D1B3E)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: const Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(confirmCtx),
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(confirmCtx); // Close confirm dialog
                                  Navigator.of(ctx).pop(); // Close popup
                                  await ApiService().logout();
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const LoginPage()),
                                    (route) => false,
                                  );
                                },
                                child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                            Icon(Icons.logout_rounded, size: 16, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w800, fontSize: 13),
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

  @override
  Widget build(BuildContext context) {
    return DoubleBackToExit(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _titles[_currentIndex],
            style: const TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: _showAccountPopup,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  child: Text(
                    widget.session.email.isNotEmpty ? widget.session.email[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _buildBody(),
        // FAB only on Clients tab
        floatingActionButton: _currentIndex == 1
            ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const AddClientPage()));
                  // Refresh home data after adding client
                  _loadHomeData();
                },
                backgroundColor: const Color(0xFF0D1B3E),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0D1B3E),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clients'),
            BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Tickets'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return const ClientsListPage();
      case 2:
        return const TicketsListPage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final newCount = _recentTickets.where((t) => t.status == 'new').length;

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const Text('System Overview',
                  style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 24),

              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  : Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                              icon: Icons.confirmation_number_outlined,
                              iconColor: Colors.green,
                              label: 'New Tickets',
                              value: newCount.toString()),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                              icon: Icons.people_outline,
                              iconColor: Colors.blue,
                              label: 'Total Clients',
                              value: _clientCount.toString()),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _currentIndex = 1),
                  icon: const Icon(Icons.people_outline, color: Colors.white),
                  label: const Text('Manage Clients'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Tickets',
                      style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 18)),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: const Text('View all', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_recentTickets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Text('No tickets yet.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ),
                )
              else
                ..._recentTickets.map((t) => _buildTicketCard(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    Color statusColor;
    Color statusBg;
    switch (ticket.status) {
      case 'processing':
        statusColor = Colors.blue[800]!;
        statusBg = Colors.blue[50]!;
        break;
      case 'completed':
        statusColor = Colors.green[800]!;
        statusBg = Colors.green[50]!;
        break;
      default:
        statusColor = Colors.orange[800]!;
        statusBg = Colors.orange[50]!;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TicketDetailsPage(ticket: ticket)),
        );
        _loadHomeData(); // Refresh on return
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(color: Colors.grey.shade50),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${ticket.ticketNo}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    ticket.statusLabel.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ticket.title,
              style: const TextStyle(
                color: Color(0xFF0D1B3E),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.category_rounded, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  ticket.type,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
