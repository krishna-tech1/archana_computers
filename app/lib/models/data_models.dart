// API-aligned data models (no mock/dummy data)

// ─── Logged-in user session ───────────────────────────────────────────────
class UserSession {
  final String id;
  final String email;
  final String name;
  final String role; // "admin" or "client"
  final String? clientId; // For clients, the backend returns this

  UserSession({required this.id, required this.email, required this.name, required this.role, this.clientId});

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      clientId: json['client_id'],
    );
  }
}

// ─── Client (admin view) ─────────────────────────────────────────────────
class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

// ─── Ticket ───────────────────────────────────────────────────────────────
// Backend status values: "new", "processing", "completed"
class Ticket {
  final String id;
  final String ticketNo; // Human-readable ticket number (e.g. TICK-123)
  final String title;
  final String type;
  final String remarks;
  final String status; // raw string from backend: "new" | "processing" | "completed"
  final String clientId;
  final String clientName;
  final String clientEmail;

  Ticket({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.type,
    required this.remarks,
    required this.status,
    required this.clientId,
    this.clientName = '',
    this.clientEmail = '',
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      ticketNo: json['ticket_no'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      remarks: json['remarks'] ?? '',
      status: json['status'] ?? 'new',
      clientId: json['client_id'] ?? '',
      clientName: json['client_name'] ?? '',
      clientEmail: json['client_email'] ?? '',
    );
  }

  // Convenience helpers for UI
  bool get isNew => status == 'new';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      default:
        return 'New';
    }
  }
}
