import 'package:flutter/foundation.dart';
import '../services/db_service.dart';

/// Preset definition for a known Bangladeshi SMS provider. The [urlTemplate]
/// uses placeholders {phone}, {message}, {apikey}, {senderid} which
/// SmsService substitutes automatically before making the HTTP call.
class SmsProviderPreset {
  final String name;
  final String urlTemplate;
  final String method; // GET or POST
  final String note;
  const SmsProviderPreset({
    required this.name,
    required this.urlTemplate,
    this.method = 'GET',
    this.note = '',
  });
}

/// Stores pluggable configuration for SMS gateway & Payment gateway.
/// Any SMS provider (GP, Robi, Banglalink, BulkSMSBD, etc.) can be used
/// as long as they expose an HTTP API — user fills in the URL + API key
/// here and SmsService will call it generically. Known BD providers are
/// offered as ready-made presets that auto-fill the correct URL template.
class SettingsProvider extends ChangeNotifier {
  late final _box = DBService.box(DBService.settingsBox);

  /// Built-in presets for major Bangladeshi bulk-SMS providers.
  /// Custom/"Other" lets users type any provider's URL manually.
  static const List<SmsProviderPreset> smsPresets = [
    SmsProviderPreset(
      name: 'Custom / Other',
      urlTemplate: '',
      note: 'Manually enter any provider\'s API URL using the placeholders.',
    ),
    SmsProviderPreset(
      name: 'BulkSMSBD',
      urlTemplate:
          'http://bulksmsbd.net/api/smsapi?api_key={apikey}&type=text&number={phone}&senderid={senderid}&message={message}',
      note: 'bulksmsbd.net — Sender ID required.',
    ),
    SmsProviderPreset(
      name: 'Alpha SMS (sms.net.bd)',
      urlTemplate:
          'https://api.sms.net.bd/sendsms?api_key={apikey}&msg={message}&to={phone}',
      note: 'alpha.net.bd — Sender ID managed on provider dashboard.',
    ),
    SmsProviderPreset(
      name: 'MiM SMS',
      urlTemplate:
          'https://api.mimsms.com/api/SmsSending/SMS?UserName={senderid}&Apikey={apikey}&MobileNumber={phone}&CampaignId=&SenderName={senderid}&TransactionType=T&Message={message}',
      note: 'mimsms.com — check dashboard for exact param names.',
    ),
    SmsProviderPreset(
      name: 'SSL Wireless (SMS)',
      urlTemplate:
          'https://smsplus.sslwireless.com/api/v3/send-sms?api_token={apikey}&sid={senderid}&msisdn={phone}&sms={message}&csms_id=1',
      note: 'sslwireless.com — SID acts as sender id.',
    ),
    SmsProviderPreset(
      name: 'Grameenphone (GP) Business SMS',
      urlTemplate:
          'https://smsplus.grameenphone.com/api/sendsms?apikey={apikey}&senderid={senderid}&to={phone}&message={message}',
      note:
          'Exact endpoint provided by GP Business team upon corporate SMS contract — verify with your GP account manager.',
    ),
    SmsProviderPreset(
      name: 'Robi Corporate SMS',
      urlTemplate:
          'https://sms.robi.com.bd/api/send?apikey={apikey}&senderid={senderid}&to={phone}&msg={message}',
      note:
          'Endpoint provided by Robi corporate SMS team — verify with your Robi account manager.',
    ),
    SmsProviderPreset(
      name: 'Banglalink Corporate SMS',
      urlTemplate:
          'https://smsgw.banglalink.net/api/send?apikey={apikey}&senderid={senderid}&to={phone}&msg={message}',
      note:
          'Endpoint provided by Banglalink corporate SMS team — verify with your account manager.',
    ),
  ];

  // SMS Gateway settings
  String get smsProviderName => _box.get('smsProviderName', defaultValue: '');
  String get smsApiUrl => _box.get('smsApiUrl', defaultValue: '');
  String get smsApiKey => _box.get('smsApiKey', defaultValue: '');
  String get smsSenderId => _box.get('smsSenderId', defaultValue: '');

  // ---------------- Payment gateway: which one is active ----------------
  String get paymentGateway =>
      _box.get('paymentGateway', defaultValue: 'Demo (Sandbox)');
  bool get paymentLiveMode => _box.get('paymentLiveMode', defaultValue: false);

  // Legacy generic fields (kept for backward-compat with old data).
  String get paymentStoreId => _box.get('paymentStoreId', defaultValue: '');
  String get paymentApiKey => _box.get('paymentApiKey', defaultValue: '');

  // ---------------- SSLCommerz credentials ----------------
  String get sslStoreId => _box.get('sslStoreId', defaultValue: '');
  String get sslStorePasswd => _box.get('sslStorePasswd', defaultValue: '');

  // ---------------- bKash Tokenized Checkout credentials ----------------
  String get bkashAppKey => _box.get('bkashAppKey', defaultValue: '');
  String get bkashAppSecret => _box.get('bkashAppSecret', defaultValue: '');
  String get bkashUsername => _box.get('bkashUsername', defaultValue: '');
  String get bkashPassword => _box.get('bkashPassword', defaultValue: '');

  // ---------------- Nagad credentials ----------------
  String get nagadMerchantId => _box.get('nagadMerchantId', defaultValue: '');
  String get nagadPublicKey => _box.get('nagadPublicKey', defaultValue: '');
  String get nagadPrivateKey => _box.get('nagadPrivateKey', defaultValue: '');

  // Coaching center info (used on receipts)
  String get centerName =>
      _box.get('centerName', defaultValue: 'My Coaching Center');
  String get centerPhone => _box.get('centerPhone', defaultValue: '');
  String get centerAddress => _box.get('centerAddress', defaultValue: '');

  // ---------------- General app behavior settings ----------------
  /// Default value for the "Give money receipt now?" switch when collecting
  /// a new payment. Previously hardcoded to `true`; now configurable.
  bool get defaultGiveReceiptNow =>
      _box.get('defaultGiveReceiptNow', defaultValue: true);

  /// Default payment method pre-selected on the Collect Payment screen.
  String get defaultPaymentMethod =>
      _box.get('defaultPaymentMethod', defaultValue: 'Cash');

  /// Whether call/SMS quick-action buttons are shown next to guardian phone
  /// numbers throughout the app.
  bool get enableQuickCallSms =>
      _box.get('enableQuickCallSms', defaultValue: true);

  Future<void> saveGeneralSettings({
    required bool defaultGiveReceiptNow,
    required String defaultPaymentMethod,
    required bool enableQuickCallSms,
  }) async {
    await _box.put('defaultGiveReceiptNow', defaultGiveReceiptNow);
    await _box.put('defaultPaymentMethod', defaultPaymentMethod);
    await _box.put('enableQuickCallSms', enableQuickCallSms);
    notifyListeners();
  }

  // ---------------- Custom Expense Categories ----------------
  /// Built-in default categories - always available even if the user has
  /// never added any custom ones.
  static const List<String> defaultExpenseCategories = [
    'Rent',
    'Salary',
    'Utility',
    'Stationery',
    'Marketing',
    'Maintenance',
    'Other',
  ];

  /// User-added custom categories, stored on top of the built-in defaults.
  List<String> get customExpenseCategories =>
      (_box.get('customExpenseCategories', defaultValue: <dynamic>[]) as List)
          .map((e) => e.toString())
          .toList();

  /// Full list shown in the Add/Edit Expense dropdown: defaults + any
  /// custom ones the user has added, without duplicates.
  List<String> get allExpenseCategories {
    final combined = [
      ...defaultExpenseCategories,
      ...customExpenseCategories,
    ];
    final seen = <String>{};
    return combined.where((c) => seen.add(c)).toList();
  }

  Future<void> addCustomExpenseCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    final existing = customExpenseCategories;
    if (allExpenseCategories.contains(trimmed)) return; // no duplicates
    existing.add(trimmed);
    await _box.put('customExpenseCategories', existing);
    notifyListeners();
  }

  Future<void> saveSmsSettings({
    required String providerName,
    required String apiUrl,
    required String apiKey,
    required String senderId,
  }) async {
    await _box.put('smsProviderName', providerName);
    await _box.put('smsApiUrl', apiUrl);
    await _box.put('smsApiKey', apiKey);
    await _box.put('smsSenderId', senderId);
    notifyListeners();
  }

  Future<void> savePaymentGatewayChoice({
    required String gateway,
    required bool liveMode,
  }) async {
    await _box.put('paymentGateway', gateway);
    await _box.put('paymentLiveMode', liveMode);
    notifyListeners();
  }

  Future<void> saveSslCommerzSettings({
    required String storeId,
    required String storePasswd,
  }) async {
    await _box.put('sslStoreId', storeId);
    await _box.put('sslStorePasswd', storePasswd);
    notifyListeners();
  }

  Future<void> saveBkashSettings({
    required String appKey,
    required String appSecret,
    required String username,
    required String password,
  }) async {
    await _box.put('bkashAppKey', appKey);
    await _box.put('bkashAppSecret', appSecret);
    await _box.put('bkashUsername', username);
    await _box.put('bkashPassword', password);
    notifyListeners();
  }

  Future<void> saveNagadSettings({
    required String merchantId,
    required String publicKey,
    required String privateKey,
  }) async {
    await _box.put('nagadMerchantId', merchantId);
    await _box.put('nagadPublicKey', publicKey);
    await _box.put('nagadPrivateKey', privateKey);
    notifyListeners();
  }

  Future<void> saveCenterInfo({
    required String name,
    required String phone,
    required String address,
  }) async {
    await _box.put('centerName', name);
    await _box.put('centerPhone', phone);
    await _box.put('centerAddress', address);
    notifyListeners();
  }
}
