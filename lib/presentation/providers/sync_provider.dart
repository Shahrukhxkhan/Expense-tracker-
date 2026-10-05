import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus {
  idle,
  syncing,
  synced,
  error,
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final String? errorMessage;
  final int pendingChangesCount;
  final String providerName; // e.g. "Supabase" or "Google Drive"

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.errorMessage,
    this.pendingChangesCount = 0,
    this.providerName = 'Supabase Cloud',
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    String? errorMessage,
    int? pendingChangesCount,
    String? providerName,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingChangesCount: pendingChangesCount ?? this.pendingChangesCount,
      providerName: providerName ?? this.providerName,
    );
  }
}

class MultiDeviceSyncNotifier extends StateNotifier<SyncState> {
  MultiDeviceSyncNotifier() : super(const SyncState());

  Future<void> triggerSync() async {
    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);

    // Simulate multi-device delta sync & conflict resolution handshake
    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(
      status: SyncStatus.synced,
      lastSyncTime: DateTime.now(),
      pendingChangesCount: 0,
    );
  }

  void switchProvider(String provider) {
    state = state.copyWith(providerName: provider);
  }
}

final multiDeviceSyncProvider =
    StateNotifierProvider<MultiDeviceSyncNotifier, SyncState>(
  (ref) => MultiDeviceSyncNotifier(),
);
