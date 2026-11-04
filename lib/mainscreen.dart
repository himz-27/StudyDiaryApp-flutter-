import 'package:flutter/material.dart';

import 'study_database.dart';
import 'studyform.dart';

/// Shows saved study logs and it opens the form for a new or edited log.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const int _pageSize = 10;

  List<Map<String, Object?>> _logs = [];
  bool _isLoading = true;
  bool _loadFailed = false;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    // Load existing logs as soon as the main screen appears.
    _loadLogs();
  }

  // Read one page from SQLite and update the list or show an error state.
  Future<void> _loadLogs({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _currentPage = page;
    });

    try {
      final logCount = await StudyDatabase.instance.getLogCount();
      final totalPages = (logCount / _pageSize).ceil().clamp(1, 1 << 31);
      // If the last page became empty, move to the nearest valid page.
      final targetPage = page.clamp(1, totalPages);
      final logs = await StudyDatabase.instance.getLogs(
        limit: _pageSize,
        offset: (targetPage - 1) * _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
        _currentPage = targetPage;
        _totalPages = totalPages;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openNewLogPage() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (context) => const StudyFormPage()),
    );
    // The form returns true only after a successful insert.
    if (saved == true) await _loadLogs(page: 1);
  }

  Future<void> _openEditPage(Map<String, Object?> log) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => StudyFormPage(existingLog: log),
      ),
    );
    // Stay on the same page after editing so the person keeps their place.
    if (saved == true) await _loadLogs(page: _currentPage);
  }

  Future<void> _confirmDeleteLog(Map<String, Object?> log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete study log?'),
        content: const Text('This study log will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final deleted = await StudyDatabase.instance.deleteLog(log['id'] as int);
      if (!mounted) return;
      await _loadLogs(page: _currentPage);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            deleted > 0
                ? 'Study log deleted successfully'
                : 'Study log could not be deleted',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete study log')),
      );
    }
  }

  Future<void> _showLogDetails(Map<String, Object?> log) async {
    final createdAt = DateTime.tryParse(log['created_at'] as String);
    final formattedDate = createdAt == null
        ? log['created_at'] as String
        : createdAt.toLocal().toString().split('.').first;
    final notes = log['notes'] as String;

    // The dialog returns true when the person taps Edit.
    final wantsEdit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log['title'] as String),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Subject', log['subject'] as String),
              _detailRow('Study method', log['activity'] as String),
              _detailRow('Time spent', '${log['minutes']} minutes'),
              _detailRow('Understanding', '${log['understanding']} / 5'),
              _detailRow('Notes', notes.isEmpty ? 'No notes' : notes),
              _detailRow('Created', formattedDate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
    if (wantsEdit == true && mounted) await _openEditPage(log);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  
  // Low understanding is red so struggling subjects are easy to spot.
  Color _understandingColor(int understanding) {
    if (understanding <= 2) return Colors.red;
    if (understanding == 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyDiary'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            tooltip: 'Refresh study logs',
            onPressed: _isLoading ? null : () => _loadLogs(page: _currentPage),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildPaginationControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewLogPage,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaginationControls() {
    // Both buttons stay disabled while loading, on an error, or with no records.
    final hasRecords = !_isLoading && !_loadFailed && _logs.isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous page',
              onPressed: hasRecords && _currentPage > 1
                  ? () => _loadLogs(page: _currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Page $_currentPage of $_totalPages'),
            IconButton(
              tooltip: 'Next page',
              onPressed: hasRecords && _currentPage < _totalPages
                  ? () => _loadLogs(page: _currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load study logs.'),
            TextButton(
              onPressed: () => _loadLogs(page: _currentPage),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No study logs yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text('Tap + to log your first study session.'),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Tap to view or edit  •  Long-press to delete',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              final understanding = (log['understanding'] as num).toInt();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  onTap: () => _showLogDetails(log),
                  onLongPress: () => _confirmDeleteLog(log),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: _understandingColor(understanding),
                    foregroundColor: Colors.white,
                    child: Text(
                      '$understanding',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    log['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${log['subject']} • ${log['activity']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${log['minutes']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('min', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}