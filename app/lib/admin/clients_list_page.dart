import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/data_models.dart';
import '../services/api_service.dart';
import 'client_details_page.dart';

class ClientsListPage extends StatefulWidget {
  const ClientsListPage({super.key});

  @override
  State<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends State<ClientsListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Client> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
    setState(() => _isLoading = true);
    try {
      final clients = await ApiService().getClients();
      if (mounted) setState(() => _clients = clients);
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

  List<Client> get _filteredClients => _clients
      .where((c) =>
          c.name.toLowerCase().contains(_searchQuery) ||
          c.email.toLowerCase().contains(_searchQuery))
      .toList();

  void _navigateToDetails(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailsPage(
          client: client,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search clients...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),

        // Title and count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Client Directory',
                  style: TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold, fontSize: 20)),
              Text('${clients.length} total', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : clients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No clients found',
                              style: TextStyle(
                                  color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchClients,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: clients.length,
                        itemBuilder: (_, i) => _buildClientCard(clients[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildClientCard(Client client) {
    return GestureDetector(
      onTap: () => _navigateToDetails(client),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0D1B3E).withValues(alpha: 0.05),
              radius: 24,
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                style: const TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(color: Color(0xFF0D1B3E), fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    client.email,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
