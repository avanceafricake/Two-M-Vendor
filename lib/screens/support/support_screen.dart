import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill subject and message')));
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _sending = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support request sent')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Describe your issue', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.send),
                label: _sending ? const Text('Sending...') : const Text('Send'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
