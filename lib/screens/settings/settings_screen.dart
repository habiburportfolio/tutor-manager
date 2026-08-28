import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/settings_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/homework_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/backup_service.dart';
import '../../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final settings = context.read<SettingsProvider>();

  late final _centerNameCtrl = TextEditingController(text: settings.centerName);
  late final _centerPhoneCtrl = TextEditingController(
    text: settings.centerPhone,
  );
  late final _centerAddressCtrl = TextEditingController(
    text: settings.centerAddress,
  );

  // SMS
  late String _smsPresetName = SettingsProvider.smsPresets
      .map((p) => p.name)
      .contains(settings.smsProviderName)
      ? settings.smsProviderName
      : 'Custom / Other';
  late final _smsUrlCtrl = TextEditingController(text: settings.smsApiUrl);
  late final _smsKeyCtrl = TextEditingController(text: settings.smsApiKey);
  late final _smsSenderCtrl = TextEditingController(text: settings.smsSenderId);

  // Payment gateway toggle
  late bool _liveMode = settings.paymentLiveMode;

  // General app-behavior settings
  late bool _defaultGiveReceiptNow = settings.defaultGiveReceiptNow;
  late String _defaultPaymentMethod = settings.defaultPaymentMethod;
  late bool _enableQuickCallSms = settings.enableQuickCallSms;
  bool _backupInProgress = false;
  bool _restoreInProgress = false;

  static const _paymentMethodOptions = [
    'Cash',
    'bKash',
    'Nagad',
    'Rocket',
    'Bank',
    'Card',
  ];

  // SSLCommerz
  late final _sslStoreIdCtrl = TextEditingController(text: settings.sslStoreId);
  late final _sslStorePasswdCtrl = TextEditingController(
    text: settings.sslStorePasswd,
  );

  // bKash
  late final _bkashAppKeyCtrl = TextEditingController(
    text: settings.bkashAppKey,
  );
  late final _bkashAppSecretCtrl = TextEditingController(
    text: settings.bkashAppSecret,
  );
  late final _bkashUsernameCtrl = TextEditingController(
    text: settings.bkashUsername,
  );
  late final _bkashPasswordCtrl = TextEditingController(
    text: settings.bkashPassword,
  );

  // Nagad
  late final _nagadMerchantIdCtrl = TextEditingController(
    text: settings.nagadMerchantId,
  );
  late final _nagadPublicKeyCtrl = TextEditingController(
    text: settings.nagadPublicKey,
  );
  late final _nagadPrivateKeyCtrl = TextEditingController(
    text: settings.nagadPrivateKey,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Coaching Center Info'),
          Row(
            children: [
              if (settings.customLogoBase64.isNotEmpty)
                Image.memory(
                  base64Decode(settings.customLogoBase64),
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                )
              else
                Image.asset('assets/logo.png', width: 50, height: 50, fit: BoxFit.contain),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    final base64Str = base64Encode(bytes);
                    await settings.saveCustomLogo(base64Str);
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('Change Logo'),
              ),
              if (settings.customLogoBase64.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => settings.saveCustomLogo(''),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _centerNameCtrl,
            decoration: const InputDecoration(labelText: 'Center Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _centerPhoneCtrl,
            decoration: const InputDecoration(labelText: 'Center Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _centerAddressCtrl,
            decoration: const InputDecoration(labelText: 'Center Address'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await settings.saveCenterInfo(
                name: _centerNameCtrl.text.trim(),
                phone: _centerPhoneCtrl.text.trim(),
                address: _centerAddressCtrl.text.trim(),
              );
              _toast('Center info saved');
            },
            child: const Text('Save Center Info'),
          ),
          const Divider(height: 32),
          _sectionHeader('General'),
          const Text(
            'Configure default behavior for the app\'s main features.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Consumer<LanguageProvider>(
            builder: (context, langProv, child) {
              return DropdownButtonFormField<String>(
                initialValue: langProv.currentLang,
                decoration: InputDecoration(labelText: langProv.t('language')),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    langProv.setLanguage(v);
                  }
                },
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _paymentMethodOptions.contains(_defaultPaymentMethod)
                ? _defaultPaymentMethod
                : 'Cash',
            decoration: const InputDecoration(
              labelText: 'Default Payment Method',
            ),
            items: _paymentMethodOptions
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) =>
                setState(() => _defaultPaymentMethod = v ?? 'Cash'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _defaultGiveReceiptNow,
            onChanged: (v) => setState(() => _defaultGiveReceiptNow = v),
            title: const Text('Give receipt immediately by default'),
            subtitle: const Text(
              'Default state of "Give money receipt now?" when collecting a new payment.',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enableQuickCallSms,
            onChanged: (v) => setState(() => _enableQuickCallSms = v),
            title: const Text('Show quick Call / SMS buttons'),
            subtitle: const Text(
              'Show call & SMS shortcuts next to guardian phone numbers on student pages.',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await settings.saveGeneralSettings(
                defaultGiveReceiptNow: _defaultGiveReceiptNow,
                defaultPaymentMethod: _defaultPaymentMethod,
                enableQuickCallSms: _enableQuickCallSms,
              );
              _toast('General settings saved');
            },
            child: const Text('Save General Settings'),
          ),
          const Divider(height: 32),
          _sectionHeader('SMS Gateway'),
          const Text(
            'Pick a known Bangladeshi provider preset (auto-fills the API URL) or choose "Custom / Other" to enter any provider\'s HTTP API URL manually using placeholders {phone}, {message}, {apikey}, {senderid}.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _smsPresetName,
            decoration: const InputDecoration(labelText: 'SMS Provider'),
            items: SettingsProvider.smsPresets
                .map(
                  (p) => DropdownMenuItem(value: p.name, child: Text(p.name)),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _smsPresetName = v;
                final preset = SettingsProvider.smsPresets.firstWhere(
                  (p) => p.name == v,
                );
                if (preset.urlTemplate.isNotEmpty) {
                  _smsUrlCtrl.text = preset.urlTemplate;
                }
              });
            },
          ),
          Builder(
            builder: (_) {
              final preset = SettingsProvider.smsPresets.firstWhere(
                (p) => p.name == _smsPresetName,
                orElse: () => SettingsProvider.smsPresets.first,
              );
              if (preset.note.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  preset.note,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _smsUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'API URL',
              hintText:
                  'https://provider.com/api?key={apikey}&to={phone}&msg={message}',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _smsKeyCtrl,
            decoration: const InputDecoration(labelText: 'API Key'),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _smsSenderCtrl,
            decoration: const InputDecoration(
              labelText: 'Sender ID (optional)',
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await settings.saveSmsSettings(
                providerName: _smsPresetName,
                apiUrl: _smsUrlCtrl.text.trim(),
                apiKey: _smsKeyCtrl.text.trim(),
                senderId: _smsSenderCtrl.text.trim(),
              );
              _toast('SMS settings saved');
            },
            child: const Text('Save SMS Settings'),
          ),
          const Divider(height: 32),
          _sectionHeader('Online Payment Gateways (Live)'),
          const Text(
            'Fill in real merchant credentials for each gateway you want active. All configured gateways are usable simultaneously as payment method options on the Collect Payment screen.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _liveMode,
            onChanged: (v) => setState(() => _liveMode = v),
            title: const Text('Enable Live Mode'),
            subtitle: const Text(
              'Off = Sandbox endpoints. On = Production endpoints (real money).',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          _gatewayCard(
            title: 'SSLCommerz',
            color: kAccentGreen,
            children: [
              TextField(
                controller: _sslStoreIdCtrl,
                decoration: const InputDecoration(labelText: 'Store ID'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sslStorePasswdCtrl,
                decoration: const InputDecoration(labelText: 'Store Password'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await settings.saveSslCommerzSettings(
                    storeId: _sslStoreIdCtrl.text.trim(),
                    storePasswd: _sslStorePasswdCtrl.text.trim(),
                  );
                  await settings.savePaymentGatewayChoice(
                    gateway: settings.paymentGateway,
                    liveMode: _liveMode,
                  );
                  _toast('SSLCommerz settings saved');
                },
                child: const Text('Save SSLCommerz'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _gatewayCard(
            title: 'bKash',
            color: kAccentOrange,
            children: [
              TextField(
                controller: _bkashAppKeyCtrl,
                decoration: const InputDecoration(labelText: 'App Key'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bkashAppSecretCtrl,
                decoration: const InputDecoration(labelText: 'App Secret'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bkashUsernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bkashPasswordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await settings.saveBkashSettings(
                    appKey: _bkashAppKeyCtrl.text.trim(),
                    appSecret: _bkashAppSecretCtrl.text.trim(),
                    username: _bkashUsernameCtrl.text.trim(),
                    password: _bkashPasswordCtrl.text.trim(),
                  );
                  await settings.savePaymentGatewayChoice(
                    gateway: settings.paymentGateway,
                    liveMode: _liveMode,
                  );
                  _toast('bKash settings saved');
                },
                child: const Text('Save bKash'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _gatewayCard(
            title: 'Nagad',
            color: kAccentRed,
            children: [
              TextField(
                controller: _nagadMerchantIdCtrl,
                decoration: const InputDecoration(labelText: 'Merchant ID'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nagadPublicKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nagad Public Key (PEM body)',
                ),
                maxLines: 3,
                obscureText: false,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nagadPrivateKeyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merchant Private Key (PEM body)',
                ),
                maxLines: 3,
                obscureText: true,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await settings.saveNagadSettings(
                    merchantId: _nagadMerchantIdCtrl.text.trim(),
                    publicKey: _nagadPublicKeyCtrl.text.trim(),
                    privateKey: _nagadPrivateKeyCtrl.text.trim(),
                  );
                  await settings.savePaymentGatewayChoice(
                    gateway: settings.paymentGateway,
                    liveMode: _liveMode,
                  );
                  _toast('Nagad settings saved');
                },
                child: const Text('Save Nagad'),
              ),
            ],
          ),
          const Divider(height: 32),
          _sectionHeader('Backup & Restore'),
          const Text(
            'Export all app data (students, classes, payments, expenses, '
            'homework, settings) as a single backup file. You can upload it '
            'to Google Drive (or any other app) via the share sheet, and '
            'restore it later on this or another device without losing any '
            'existing data already saved on the device.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _backupInProgress ? null : _backupToGoogleDrive,
            icon: _backupInProgress
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.backup_outlined),
            label: const Text('Backup All Data to Google Drive'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _restoreInProgress ? null : _restoreFromBackup,
            icon: _restoreInProgress
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restore_outlined),
            label: const Text('Restore From Backup File'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _backupToGoogleDrive() async {
    setState(() => _backupInProgress = true);
    try {
      final fileName = await BackupService.backupToGoogleDrive();
      if (mounted) {
        _toast('Backup file ready: $fileName');
      }
    } catch (e) {
      if (mounted) _toastError('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _backupInProgress = false);
    }
  }

  Future<void> _restoreFromBackup() async {
    setState(() => _restoreInProgress = true);
    try {
      final summary = await BackupService.pickAndRestoreBackup();
      if (summary == null) {
        if (mounted) setState(() => _restoreInProgress = false);
        return;
      }
      if (mounted) {
        // Reload all providers so the UI reflects restored data immediately.
        context.read<AcademicProvider>().reload();
        context.read<StudentProvider>().reload();
        context.read<FinanceProvider>().reload();
        context.read<HomeworkProvider>().reload();
        context.read<MeetingProvider>().reload();
        final details = summary.entries
            .map((e) => '${BackupService.boxLabel(e.key)}: ${e.value}')
            .join(', ');
        _showRestoreSummary(details);
      }
    } catch (e) {
      if (mounted) _toastError('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _restoreInProgress = false);
    }
  }

  void _showRestoreSummary(String details) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Complete'),
        content: Text('Records restored -\n$details'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _gatewayCard({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: kPrimary,
      ),
    ),
  );

  void _toast(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kAccentGreen));
  }

  void _toastError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kAccentRed));
  }
}
