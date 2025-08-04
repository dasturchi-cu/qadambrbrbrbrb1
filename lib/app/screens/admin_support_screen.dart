import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({Key? key}) : super(key: key);

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _selectedFilter = 'all'; // all, open, in_progress, resolved
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Support Panel'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Barcha ticketlar')),
              const PopupMenuItem(value: 'open', child: Text('Ochiq ticketlar')),
              const PopupMenuItem(value: 'in_progress', child: Text('Jarayonda')),
              const PopupMenuItem(value: 'resolved', child: Text('Hal qilingan')),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('all', 'Barchasi'),
                const SizedBox(width: 8),
                _buildFilterChip('open', 'Ochiq'),
                const SizedBox(width: 8),
                _buildFilterChip('in_progress', 'Jarayonda'),
                const SizedBox(width: 8),
                _buildFilterChip('resolved', 'Hal qilingan'),
              ],
            ),
          ),
          
          // Support tickets list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getSupportTicketsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Xatolik: ${snapshot.error}'),
                  );
                }
                
                final tickets = snapshot.data?.docs ?? [];
                
                if (tickets.isEmpty) {
                  return const Center(
                    child: Text('Hech qanday ticket topilmadi'),
                  );
                }
                
                return ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index].data() as Map<String, dynamic>;
                    return _buildTicketCard(ticket, tickets[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade600,
    );
  }
  
  Stream<QuerySnapshot> _getSupportTicketsStream() {
    Query query = _firestore.collection('support_tickets')
        .orderBy('createdAt', descending: true);
    
    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }
    
    return query.snapshots();
  }
  
  Widget _buildTicketCard(Map<String, dynamic> ticket, String ticketId) {
    final status = ticket['status'] ?? 'open';
    final priority = ticket['priority'] ?? 'medium';
    final createdAt = ticket['createdAt'] as Timestamp?;
    
    Color statusColor = Colors.grey;
    switch (status) {
      case 'open':
        statusColor = Colors.red;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          ticket['title'] ?? 'Mavzusiz',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foydalanuvchi: ${ticket['userName'] ?? 'Noma\'lum'}'),
            Text('Kategoriya: ${ticket['category'] ?? 'Umumiy'}'),
            if (createdAt != null)
              Text('Sana: ${_formatDate(createdAt.toDate())}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(priority),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getPriorityText(priority),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getStatusText(status),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _openTicketChat(ticketId, ticket),
      ),
    );
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.new_releases;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'resolved':
        return Icons.check_circle;
      case 'closed':
        return Icons.close;
      default:
        return Icons.help;
    }
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
  
  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'YUQORI';
      case 'medium':
        return 'O\'RTA';
      case 'low':
        return 'PAST';
      default:
        return 'NOMA\'LUM';
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'OCHIQ';
      case 'in_progress':
        return 'JARAYONDA';
      case 'resolved':
        return 'HAL QILINGAN';
      case 'closed':
        return 'YOPIQ';
      default:
        return 'NOMA\'LUM';
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  void _openTicketChat(String ticketId, Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTicketChatScreen(
          ticketId: ticketId,
          ticket: ticket,
        ),
      ),
    );
  }
}

// Admin Ticket Chat Screen
class AdminTicketChatScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> ticket;
  
  const AdminTicketChatScreen({
    Key? key,
    required this.ticketId,
    required this.ticket,
  }) : super(key: key);

  @override
  State<AdminTicketChatScreen> createState() => _AdminTicketChatScreenState();
}

class _AdminTicketChatScreenState extends State<AdminTicketChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ticket['title'] ?? 'Support Chat'),
            Text(
              'Foydalanuvchi: ${widget.ticket['userName'] ?? 'Noma\'lum'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _updateTicketStatus(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'open', child: Text('Ochiq')),
              const PopupMenuItem(value: 'in_progress', child: Text('Jarayonda')),
              const PopupMenuItem(value: 'resolved', child: Text('Hal qilingan')),
              const PopupMenuItem(value: 'closed', child: Text('Yopiq')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Ticket info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muammo: ${widget.ticket['description'] ?? 'Tavsif yo\'q'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Status: ${_getStatusText(widget.ticket['status'] ?? 'open')}'),
                    const SizedBox(width: 16),
                    Text('Kategoriya: ${widget.ticket['category'] ?? 'Umumiy'}'),
                  ],
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('support_messages')
                  .where('ticketId', isEqualTo: widget.ticketId)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data?.docs ?? [];
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Javob yozing...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isAdmin = message['senderType'] == 'admin';
    final timestamp = message['timestamp'] as Timestamp?;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isAdmin ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isAdmin) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.blue.shade600 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'] ?? '',
                    style: TextStyle(
                      color: isAdmin ? Colors.white : Colors.black,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(timestamp.toDate()),
                      style: TextStyle(
                        fontSize: 10,
                        color: isAdmin ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.support_agent, size: 16),
            ),
          ],
        ],
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'OCHIQ';
      case 'in_progress':
        return 'JARAYONDA';
      case 'resolved':
        return 'HAL QILINGAN';
      case 'closed':
        return 'YOPIQ';
      default:
        return 'NOMA\'LUM';
    }
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    try {
      // Add message to collection
      await _firestore.collection('support_messages').add({
        'ticketId': widget.ticketId,
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Admin',
        'senderType': 'admin',
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      // Update ticket status and last message time
      await _firestore.collection('support_tickets').doc(widget.ticketId).update({
        'status': 'in_progress',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'assignedTo': currentUser.uid,
      });
      
      _messageController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Javob yuborildi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }
  
  Future<void> _updateTicketStatus(String status) async {
    try {
      await _firestore.collection('support_tickets').doc(widget.ticketId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status yangilandi: ${_getStatusText(status)}')),
      );
      
      setState(() {
        widget.ticket['status'] = status;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    }
  }
}
