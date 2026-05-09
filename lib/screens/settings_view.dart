import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../providers/app_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _nameController;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: context.read<AppProvider>().username);
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    }).catchError((Object e) {
      debugPrint('SettingsView: PackageInfo failed ($e).');
      if (mounted) setState(() => _appVersion = '—');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _showExportDialog() async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(S.settingsExportTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(S.settingsExportMessage,
            style: const TextStyle(
                fontSize: 14, height: 1.6, color: Colors.black87)),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(S.settingsExportSave),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(S.settingsExportCancel,
                    style: const TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ],
      ),
    );

    if (action != 'save' || !mounted) return;

    final provider = context.read<AppProvider>();
    final json = provider.buildJson();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/smakolist_export.json');
    await file.writeAsString(json, encoding: utf8);
    await Share.shareXFiles([XFile(file.path)], text: 'Smakolist Export');
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _showImportDialog() async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(S.settingsImportTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(S.settingsImportMessage,
            style: const TextStyle(
                fontSize: 14, height: 1.6, color: Colors.black87)),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('choose'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(S.settingsImportChoose),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(S.settingsImportCancel,
                    style: const TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ],
      ),
    );

    if (action != 'choose' || !mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    String raw;
    try {
      final bytes = result.files.first.bytes;
      if (bytes != null) {
        raw = utf8.decode(bytes);
      } else {
        final path = result.files.first.path;
        if (path == null) return;
        raw = await File(path).readAsString(encoding: utf8);
      }
    } catch (_) {
      if (!mounted) return;
      await _showSimpleDialog(
        S.settingsImportErrorTitle,
        S.settingsImportErrorMessage,
        S.settingsImportErrorBtn,
      );
      return;
    }

    if (!mounted) return;
    final err = context.read<AppProvider>().importJson(raw);
    if (err != null) {
      await _showSimpleDialog(
        S.settingsImportErrorTitle,
        '$err\n\n${S.settingsImportErrorMessage}',
        S.settingsImportErrorBtn,
      );
    } else {
      await _showSimpleDialog(
        S.settingsImportDoneTitle,
        S.settingsImportDoneMessage,
        S.settingsImportDoneBtn,
      );
    }
  }

  // ── Clear data ────────────────────────────────────────────────────────────

  Future<void> _showClearDialog() async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(S.settingsClearTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(S.settingsClearMessage,
            style: const TextStyle(
                fontSize: 14, height: 1.6, color: Colors.black87)),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(S.settingsClearExport),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop('erase'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(S.settingsClearErase),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(S.settingsClearCancel,
                    style: const TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == 'export') {
      final provider = context.read<AppProvider>();
      final json = provider.buildJson();
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/smakolist_export.json');
        await file.writeAsString(json, encoding: utf8);
        await Share.shareXFiles([XFile(file.path)], text: 'Smakolist Export');
      } catch (_) {
        if (!mounted) return;
        return;
      }
      if (!mounted) return;
      await provider.clearAllData();
    } else if (action == 'erase') {
      await context.read<AppProvider>().clearAllData();
    } else {
      return;
    }

    if (!mounted) return;
    await _showSimpleDialog(
      S.settingsClearDoneTitle,
      S.settingsClearDoneMessage,
      S.settingsClearDoneBtn,
    );
  }

  Future<void> _showSimpleDialog(
      String title, String message, String btn) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(message,
            style: const TextStyle(
                fontSize: 14, height: 1.6, color: Colors.black87)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(btn),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.settingsTitle,
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              // Username
              _SectionLabel(S.settingsNameLabel),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                decoration: InputDecoration(
                  hintText: S.settingsNameHint,
                  hintStyle: const TextStyle(color: Colors.black38),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  counterStyle: const TextStyle(
                    fontFamily: 'FixelText',
                    fontSize: 11,
                    color: Colors.black38,
                  ),
                ),
                onChanged: (v) =>
                    context.read<AppProvider>().setUsername(v.trim()),
              ),
              const SizedBox(height: 24),
              // Reminders
              _SectionLabel(S.settingsSectionReminders),
              const SizedBox(height: 8),
              _ReminderBlock(
                label: S.settingsReminderBreakfast,
                timeHint: S.slotTimeBreakfast,
                config: provider.breakfastReminder,
                onToggle: (enabled) => context
                    .read<AppProvider>()
                    .setBreakfastReminder(
                        provider.breakfastReminder.copyWith(enabled: enabled)),
                onTimeChanged: (time) => context
                    .read<AppProvider>()
                    .setBreakfastReminder(
                        provider.breakfastReminder.copyWith(time: time)),
              ),
              const SizedBox(height: 8),
              _ReminderBlock(
                label: S.settingsReminderLunch,
                timeHint: S.slotTimeLunch,
                config: provider.lunchReminder,
                onToggle: (enabled) => context
                    .read<AppProvider>()
                    .setLunchReminder(
                        provider.lunchReminder.copyWith(enabled: enabled)),
                onTimeChanged: (time) => context
                    .read<AppProvider>()
                    .setLunchReminder(
                        provider.lunchReminder.copyWith(time: time)),
              ),
              const SizedBox(height: 8),
              _ReminderBlock(
                label: S.settingsReminderDinner,
                timeHint: S.slotTimeDinner,
                config: provider.dinnerReminder,
                onToggle: (enabled) => context
                    .read<AppProvider>()
                    .setDinnerReminder(
                        provider.dinnerReminder.copyWith(enabled: enabled)),
                onTimeChanged: (time) => context
                    .read<AppProvider>()
                    .setDinnerReminder(
                        provider.dinnerReminder.copyWith(time: time)),
              ),
              const SizedBox(height: 24),
              // Data section
              _SectionLabel(S.settingsSectionData),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.download_outlined,
                label: S.settingsExportBtn,
                onTap: _showExportDialog,
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.upload_outlined,
                label: S.settingsImportBtn,
                onTap: _showImportDialog,
              ),
              const SizedBox(height: 8),
              _ActionRow(
                icon: Icons.delete_outline,
                label: S.settingsClearBtn,
                onTap: _showClearDialog,
              ),
              const SizedBox(height: 32),
              // App info
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/smakolist-logo.png',
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Смаколист',
                      style: TextStyle(
                        fontFamily: 'FixelText',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.appTagline,
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Версія $_appVersion',
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontSize: 13,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '© 2026 Denys Skvortsov',
                      style: TextStyle(
                        fontFamily: 'FixelText',
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'FixelText',
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 1.2,
        color: Colors.black54,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'FixelText',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderBlock extends StatelessWidget {
  final String label;
  final String timeHint;
  final ReminderConfig config;
  final void Function(bool) onToggle;
  final void Function(TimeOfDay) onTimeChanged;

  const _ReminderBlock({
    required this.label,
    required this.timeHint,
    required this.config,
    required this.onToggle,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'FixelText',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeHint,
                        style: const TextStyle(
                          fontFamily: 'FixelText',
                          fontSize: 14,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: config.enabled,
                  onChanged: onToggle,
                  activeThumbColor: Colors.black,
                  activeTrackColor: Colors.black38,
                ),
              ],
            ),
          ),
          if (config.enabled) ...[
            Container(height: 2, color: Colors.black),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: config.time,
                  builder: (ctx, child) => MediaQuery(
                    data: MediaQuery.of(ctx)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
                if (picked != null) onTimeChanged(picked);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(
                      S.settingsReminderTimeLabel,
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${config.time.hour.toString().padLeft(2, '0')}:${config.time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontFamily: 'FixelText',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
