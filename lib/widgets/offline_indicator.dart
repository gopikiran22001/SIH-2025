import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';

class OfflineIndicator extends StatefulWidget {
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  bool _isSyncing = false;
  final _syncService = OfflineSyncService();

  @override
  void initState() {
    super.initState();
    _checkStatus();
    // Check status periodically
    Future.delayed(const Duration(seconds: 1), _checkStatus);
  }

  void _checkStatus() {
    if (mounted) {
      setState(() {
        _isOnline = _syncService.isOnline;
      });
    }
    // Schedule next check
    Future.delayed(const Duration(seconds: 5), _checkStatus);
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await _syncService.syncNow();
      _checkStatus();
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isOnline)
          GestureDetector(
            onTap: _isSyncing ? null : _syncNow,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSyncing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _isSyncing 
                        ? 'Syncing data...' 
                        : 'Offline - Tap to sync when online',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}