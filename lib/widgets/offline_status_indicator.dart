import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/offline_sync_manager.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class OfflineStatusIndicator extends StatefulWidget {
  const OfflineStatusIndicator({super.key});

  @override
  State<OfflineStatusIndicator> createState() => _OfflineStatusIndicatorState();
}

class _OfflineStatusIndicatorState extends State<OfflineStatusIndicator> {
  final _syncManager = OfflineSyncManager();
  late Future<int> _pendingSyncCount;

  @override
  void initState() {
    super.initState();
    _pendingSyncCount = _syncManager.getPendingSyncCount();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_syncManager.isOnline) _buildOfflineBanner(),
        if (_syncManager.isOnline && _syncManager.isSyncing)
          _buildSyncingBanner(),
        FutureBuilder<int>(
          future: _pendingSyncCount,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data! > 0) {
              return _buildPendingSyncBanner(snapshot.data!);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.warning,
        border: Border(bottom: BorderSide(color: Colors.orange, width: 2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'You are offline - Changes saved locally',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _syncManager.syncPendingData,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.refresh, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.info,
        border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Syncing changes...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSyncBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.blue,
        border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count change${count > 1 ? 's' : ''} pending sync',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
