import 'package:flutter/material.dart';
import '../../models/consultation.dart';
import '../../services/service_locator.dart';

class ConsultationSettingsSheet extends StatefulWidget {
  const ConsultationSettingsSheet({super.key});

  @override
  State<ConsultationSettingsSheet> createState() => _ConsultationSettingsSheetState();
}

class _ConsultationSettingsSheetState extends State<ConsultationSettingsSheet> {
  final _chatCtrl = TextEditingController();
  final _callCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  bool _chatEnabled = false;
  bool _callEnabled = false;
  bool _videoEnabled = false;
  bool _saving = false;

  @override
  void dispose() {
    _chatCtrl.dispose();
    _callCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locator = ServiceLocator();
    return StreamBuilder<ConsultSettings>(
      stream: locator.watchConsultSettings(),
      builder: (context, snap) {
        final s = snap.data ?? const ConsultSettings();
        _chatCtrl.text = _chatCtrl.text.isEmpty ? s.chatPrice.toStringAsFixed(0) : _chatCtrl.text;
        _callCtrl.text = _callCtrl.text.isEmpty ? s.callPrice.toStringAsFixed(0) : _callCtrl.text;
        _videoCtrl.text = _videoCtrl.text.isEmpty ? s.videoPrice.toStringAsFixed(0) : _videoCtrl.text;
        _chatEnabled = snap.hasData ? s.chatEnabled : _chatEnabled;
        _callEnabled = snap.hasData ? s.callEnabled : _callEnabled;
        _videoEnabled = snap.hasData ? s.videoEnabled : _videoEnabled;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Pharmacist Consultation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Set your availability and rates (KES) for each option. These are shown to customers.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 12),
              _rowTile(
                title: 'Video Call',
                icon: Icons.videocam_outlined,
                controller: _videoCtrl,
                enabled: _videoEnabled,
                onChanged: (v) => setState(() => _videoEnabled = v),
              ),
              const SizedBox(height: 8),
              _rowTile(
                title: 'Phone Call',
                icon: Icons.call_outlined,
                controller: _callCtrl,
                enabled: _callEnabled,
                onChanged: (v) => setState(() => _callEnabled = v),
              ),
              const SizedBox(height: 8),
              _rowTile(
                title: 'Chat',
                icon: Icons.chat_bubble_outline,
                controller: _chatCtrl,
                enabled: _chatEnabled,
                onChanged: (v) => setState(() => _chatEnabled = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: _saving ? null : () async {
                    setState(() => _saving = true);
                    final settings = ConsultSettings(
                      chatEnabled: _chatEnabled,
                      callEnabled: _callEnabled,
                      videoEnabled: _videoEnabled,
                      chatPrice: double.tryParse(_chatCtrl.text) ?? 0,
                      callPrice: double.tryParse(_callCtrl.text) ?? 0,
                      videoPrice: double.tryParse(_videoCtrl.text) ?? 0,
                    );
                    try {
                      await locator.saveConsultSettings(settings);
                      if (mounted) Navigator.of(context).pop();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      setState(() => _saving = false);
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save settings'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _rowTile({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'KES',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Enabled'),
                    const SizedBox(width: 6),
                    Switch(value: enabled, onChanged: onChanged),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
