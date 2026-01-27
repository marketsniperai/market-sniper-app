import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:market_sniper_app/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:market_sniper_app/state/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart'; // Typography

import '../config/app_config.dart'; // Fix Path
import '../services/invite_service.dart'; // Invite Service

// ─────────────────────────────────────────────────────────────
//  DICCIONARIO DE IDIOMAS (simple, rápido)
// ─────────────────────────────────────────────────────────────
// Localized values removed in favor of AppLocalizations

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Estado
  bool _isAccepted = false;
  String _invitationCode = '';
  String? _inviteError;

  // Animación shimmer dorado
  late final AnimationController _shimmerController;

  // Colores centrales de la marca
  final Color _bgDeepVoid = AppColors.bgPrimary;
  final Color _neonCyan = AppColors.neonCyan; // centralized
  final Color _accentGold = AppColors.stateStale; // Approximate gold

  final Color _textWhite = AppColors.textPrimary;
  final Color _textGrey = AppColors.textSecondary;
  final Color _matteBlue = AppColors.textDisabled; // Approximate
  // Color _disabledGrey removed
  final Color _errorRed = AppColors.marketBear;

  // Helper traducción (Legacy wrapper for minimal refactor)
  // Maps old keys to new AppLocalizations keys.
  String t(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'slogan':
        return l10n.slogan;
      case 'terms_intro':
        return l10n.termsIntro;
      case 'terms_link':
        return l10n.termsLink;
      case 'btn_init':
        return l10n.btnInit;
      case 'legal_title':
        return l10n.legalTitle;
      case 'legal_close':
        return l10n.legalClose;
      case 'invitation_label':
        return l10n.invitationLabel;
      case 'invitation_hint':
        return l10n.invitationHint;
      case 'label_username':
        return l10n.labelUsername;
      case 'hint_username':
        return l10n.hintUsername;
      case 'label_password':
        return l10n.labelPassword;
      case 'hint_password':
        return l10n.hintPassword;
      default:
        return key;
    }
  }

  bool get _canInitialize =>
      _isAccepted &&
      (!AppConfig.inviteEnabled || _invitationCode.trim().isNotEmpty);

  // Idioma legible
  String _getLangName() {
    final lang =
        Provider.of<LocaleProvider>(context, listen: true).locale.languageCode;
    switch (lang) {
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'hi':
        return 'हिंदी';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }

  // Legal Logic P9
  String _legalText = "";
  String _activeLegalVersion = "unknown";
  bool _termsNeedAcceptance = false;

  // String get _baseUrl => AppConfig.apiBaseUrl; // REMOVED (Unused)

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Init Invite Service
    InviteService().init().then((_) {
      if (mounted) _loadPersistence();
    });
  }

  Future<void> _loadPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = InviteService().currentCode ?? '';

    // Check Legal
    await _checkLegalStatus(prefs);

    if (savedCode.isNotEmpty && mounted) {
      setState(() {
        _invitationCode = savedCode;
      });
    }
  }

  Future<void> _checkLegalStatus(SharedPreferences prefs) async {
    // Local Mode: Always check against bundled version in future,
    // but for now we assume "v1" is the active version.
    const String activeVersion = "v1-beta";

    setState(() => _activeLegalVersion = activeVersion);

    final localVer = prefs.getString('legal_accepted_version');
    if (localVer != activeVersion) {
      // New terms!
      setState(() {
        _termsNeedAcceptance = true;
        _isAccepted = false; // Reset
      });
      _fetchTerms();
    } else {
      // Already accepted match
      setState(() => _termsNeedAcceptance = false);
    }
  }

  Future<void> _fetchTerms() async {
    try {
      // Load local asset
      final text = await rootBundle.loadString('assets/legal/terms.md');
      setState(() {
        _legalText = text;
      });
    } catch (e) {
      setState(() => _legalText = "Terms available in assets/legal/terms.md");
    }
  }

  Future<bool> _logAcceptance() async {
    try {
      // Local Only Mode (Privacy First)
      final prefs = await SharedPreferences.getInstance();

      // Save Local Acceptance
      await prefs.setString('legal_accepted_version', _activeLegalVersion);
      await prefs.setInt(
          'terms_accept_last_utc', DateTime.now().millisecondsSinceEpoch);

      return true;
    } catch (e) {
      if (kDebugMode) print("Acceptance Log Failed: $e");
      return true;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // ⬇️ Entrar al sistema → vamos a /startup (pantalla 1)
  Future<void> _enterSystem() async {
    if (!_canInitialize) return;

    // VALIDATE INVITE
    if (AppConfig.inviteEnabled) {
      final success = await InviteService().submitCode(_invitationCode);
      if (!success) {
        setState(() {
          _inviteError = "Invalid Access Code";
        });
        return;
      } else {
        // Success -> Update UI to normalized
        setState(() {
          _invitationCode = InviteService().currentCode ?? _invitationCode;
        });
      }
    } else {
      // Just clear error if disabled
      setState(() => _inviteError = null);
    }

    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('terms_accept_count') ?? 0;
    await prefs.setInt('terms_accept_count', currentCount + 1);

    // P9: Log Acceptance & Integrity
    if (_termsNeedAcceptance) {
      final hash = _computeSimpleHash(_legalText);
      await InviteService().recordTermsAcceptance(hash);

      await _logAcceptance();
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/startup');
  }

  String _computeSimpleHash(String source) {
    var hash = 5381;
    for (var i = 0; i < source.length; i++) {
      hash = ((hash << 5) + hash) + source.codeUnitAt(i);
    }
    return hash.toString();
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.selectLanguage,
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildLangOption("English", "en"),
              _buildLangOption("Español", "es"),
              _buildLangOption("Português", "pt"),
              _buildLangOption("Hindi (हिंदी)", "hi"),
              _buildLangOption("中文 (Chinese)", "zh"),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangOption(String label, String code) {
    final currentLang =
        Provider.of<LocaleProvider>(context).locale.languageCode;
    final bool isActive = currentLang == code;
    return InkWell(
      onTap: () {
        Provider.of<LocaleProvider>(context, listen: false)
            .setLocale(Locale(code));
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isActive
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isActive ? _neonCyan : _textGrey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: _textWhite, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface1,
          title: Text(
            t('legal_title'),
            style: TextStyle(
              color: _textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              _legalText.isNotEmpty
                  ? _legalText
                  : (_activeLegalVersion == "unknown"
                      ? "Connecting to Legal Engine..."
                      : "Loading Terms $_activeLegalVersion..."),
              style: TextStyle(
                color: _textGrey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                t('legal_close'),
                style: TextStyle(color: _neonCyan),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final mediaQuery = MediaQuery.of(context);
    final clampedTextScale =
        mediaQuery.textScaleFactor.clamp(0.9, 1.1); // anti “letra gigante”
    final size = mediaQuery.size;
    final bool isShort = size.height < 720;

    final double titleFontSize = isShort ? 28 : 32;
    final double sloganFontSize = isShort ? 18 : 20;
    final double verticalGapTop = isShort ? 32 : 48;
    final double verticalGapBetween = isShort ? 18 : 24;

    return MediaQuery(
      data:
          mediaQuery.copyWith(textScaler: TextScaler.linear(clampedTextScale)),
      child: Scaffold(
        backgroundColor: _bgDeepVoid,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: verticalGapTop),

                    // ── LOGO + RAYA NEÓN ───────────────────────────────
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1600),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Column(
                            children: [
                              Text(
                                "MarketSniper\nAI",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.sora(
                                  // SORA Font (Institutional)
                                  color: _neonCyan,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  height: 1.05,
                                  shadows: [
                                    Shadow(
                                      color: _neonCyan.withOpacity(0.55),
                                      blurRadius: 18,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12), // Increased gap
                              Container(
                                height: 3,
                                width: 140, // Reduced width for elegance
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [
                                      _neonCyan.withOpacity(0.0),
                                      _neonCyan.withOpacity(0.9),
                                      _neonCyan.withOpacity(0.0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _neonCyan.withOpacity(0.7),
                                      blurRadius: 12,
                                      spreadRadius: -4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(
                        height: verticalGapBetween *
                            1.8), // Increased breathing room

                    // ── SLOGAN + SHIMMER DORADO FINO ───────────────────
                    _buildSloganWithShimmer(
                      sloganFontSize: sloganFontSize,
                      maxWidth: double.infinity,
                    ),

                    SizedBox(
                        height:
                            verticalGapBetween * 2.0), // Major section break

                    // ── VISUAL CREDENTIALS (UI ONLY) ───────────────────
                    // These fields are completely disconnected from logic.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t('label_username'),
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textPrimary.withOpacity(0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              color: _textGrey, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              enabled: true, // Visual only
                              style: TextStyle(color: _textWhite, fontSize: 16),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: t('hint_username'),
                                hintStyle: TextStyle(
                                  color: _textGrey.withOpacity(0.5),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              cursorColor: _neonCyan,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t('label_password'),
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.textPrimary.withOpacity(0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: _textGrey, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              obscureText: true, // Visual obscuring
                              enabled: true, // Visual only
                              style: TextStyle(color: _textWhite, fontSize: 16),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: t('hint_password'),
                                hintStyle: TextStyle(
                                  color: _textGrey.withOpacity(0.5),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              cursorColor: _neonCyan,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24), // Spacing before Founder Key

                    // ── INVITATION CODE FIELD ──────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t('invitation_label'),
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 12, // More discreet
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 52, // 48px+ touch target
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius:
                            BorderRadius.circular(12), // Slightly sharper
                        border: Border.all(color: AppColors.textPrimary.withOpacity(0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key_outlined, // More literal icon
                              color: _neonCyan,
                              size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller:
                                  TextEditingController(text: _invitationCode)
                                    ..selection = TextSelection.fromPosition(
                                        TextPosition(
                                            offset: _invitationCode.length)),
                              onChanged: (value) {
                                setState(() {
                                  _invitationCode = value;
                                  if (_inviteError != null) _inviteError = null;
                                });
                              },
                              style: TextStyle(
                                color: _textWhite,
                                fontSize: 16,
                                fontFamily: 'RobotoMono', // Monospace for keys
                                letterSpacing: 1.0,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: t('invitation_hint'),
                                hintStyle: TextStyle(
                                  color: _textGrey.withOpacity(0.5),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              cursorColor: _neonCyan,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_inviteError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _inviteError!,
                          style: TextStyle(
                              color: _errorRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // ── LANGUAGE SELECTOR ──────────────────────────────
                    GestureDetector(
                      onTap: _showLanguageSelector,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent, // Minimalist
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.textPrimary.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLangName(),
                              style: TextStyle(
                                color: _textGrey, // Dimmer
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down,
                                color: _textGrey, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── CHECKBOX + TERMS OF USE ────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _isAccepted,
                            activeColor: _neonCyan,
                            checkColor: _bgDeepVoid,
                            side: BorderSide(color: _textGrey, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                _isAccepted = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showLegalModal,
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: _textGrey,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(text: t('terms_intro')),
                                  TextSpan(
                                    text: t('terms_link'),
                                    style: TextStyle(
                                      color: _neonCyan.withOpacity(0.9),
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                          _neonCyan.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── BOTÓN PRINCIPAL ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _canInitialize ? _enterSystem : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canInitialize
                              ? _neonCyan
                              : AppColors.surface2,
                          disabledBackgroundColor: AppColors.surface2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: _canInitialize ? 8 : 0,
                          shadowColor: _neonCyan.withOpacity(0.4),
                        ),
                        child: Text(
                          t('btn_init'),
                          style: TextStyle(
                            color:
                                _canInitialize ? _bgDeepVoid : AppColors.textDisabled.withOpacity(0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0, // Wider tracking
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── FOOTER ─────────────────────────────────────────
                    Opacity(
                      opacity: 0.6,
                      child: Column(
                        children: [
                          Text(
                            "POWERED BY",
                            style: TextStyle(
                              color: _textGrey,
                              fontSize: 9,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "GLOBAL SNIPER HOLDINGS",
                            style: TextStyle(
                              color: _textWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SLOGAN CON SHIMMER DORADO FINO
  // ─────────────────────────────────────────────────────────────
  Widget _buildSloganWithShimmer({
    required double sloganFontSize,
    required double maxWidth,
  }) {
    final baseText = Text(
      t('slogan'),
      textAlign: TextAlign.center,
      maxLines: 3,
      style: TextStyle(
        color: _matteBlue,
        fontSize: sloganFontSize,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 1.1,
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Stack(
        alignment: Alignment.center,
        children: [
          baseText,
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                final double t = _shimmerController.value; // 0 → 1
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (Rect bounds) {
                    final double width = bounds.width;
                    final double start = (t * 1.8 - 0.4).clamp(0.0, 1.0);
                    final double end = (start + 0.10).clamp(0.0, 1.0);

                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        _accentGold.withOpacity(0.0),
                        _accentGold.withOpacity(0.55),
                        _accentGold.withOpacity(0.0),
                        Colors.transparent,
                      ],
                      stops: [
                        0.0,
                        start,
                        (start + end) / 2,
                        end,
                        1.0,
                      ],
                    ).createShader(
                      Rect.fromLTRB(0, 0, width, bounds.height),
                    );
                  },
                  child: child,
                );
              },
              child: Text(
                t('slogan'),
                textAlign: TextAlign.center,
                maxLines: 3,
                style: TextStyle(
                  color: _textWhite,
                  fontSize: sloganFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
