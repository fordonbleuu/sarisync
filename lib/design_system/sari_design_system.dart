import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SariColors {
  static const Color primaryGreen = Color(0xFF1565C0);
  static const Color primaryGreenLight = Color(0xFF1976D2);
  static const Color primaryGreenDark = Color(0xFF0D47A1);

  static const Color secondaryNavy = Color(0xFF1E293B);
  static const Color secondarySlate = Color(0xFF475569);
  static const Color secondaryLight = Color(0xFF64748B);

  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentAmberLight = Color(0xFFFBBF24);

  static const Color accentCrimson = Color(0xFFDC2626);
  static const Color accentCrimsonLight = Color(0xFFF87171);

  static const Color accentMint = Color(0xFF34D399);
  static const Color accentMintLight = Color(0xFF6EE7B7);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);

  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);
}

class SariGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [SariColors.primaryGreen, SariColors.primaryGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryHorizontal = LinearGradient(
    colors: [SariColors.primaryGreen, SariColors.primaryGreenDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryVertical = LinearGradient(
    colors: [SariColors.primaryGreen, SariColors.primaryGreenDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient primaryWithOpacity(double opacity) {
    return LinearGradient(
      colors: [
        SariColors.primaryGreen.withValues(alpha: opacity),
        SariColors.primaryGreenDark.withValues(alpha: opacity),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const LinearGradient accentGold = LinearGradient(
    colors: [SariColors.accentAmber, SariColors.accentAmberLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient success = LinearGradient(
    colors: [SariColors.success, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient error = LinearGradient(
    colors: [SariColors.error, Color(0xFF991B1B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient surfaceOverlay(Color baseColor, {double intensity = 0.03}) {
    return LinearGradient(
      colors: [
        baseColor,
        baseColor.withValues(alpha: 1.0 - intensity),
        baseColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
    );
  }

  static BoxDecoration primaryCardDecoration({
    double borderRadius = 16,
    double blurRadius = 20,
    double opacity = 0.3,
  }) {
    return BoxDecoration(
      gradient: primary,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: SariColors.primaryGreen.withValues(alpha: opacity),
          blurRadius: blurRadius,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static const LinearGradient appBar = LinearGradient(
    colors: [SariColors.backgroundWhite, Color(0xFFF0F7FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 1.0],
  );

  static const LinearGradient appBarPrimary = LinearGradient(
    colors: [SariColors.primaryGreen, SariColors.primaryGreenDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceLight = LinearGradient(
    colors: [SariColors.backgroundWhite, Color(0xFFF8FAFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHover = LinearGradient(
    colors: [SariColors.backgroundWhite, Color(0xFFF0F7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardSubtle = LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF0F7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceSubtle = LinearGradient(
    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonPrimary = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonWarning = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonError = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class SariTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SariColors.primaryGreen,
        brightness: Brightness.light,
        primary: SariColors.primaryGreen,
        secondary: SariColors.secondaryNavy,
        tertiary: SariColors.accentAmber,
        surface: SariColors.backgroundWhite,
        error: SariColors.error,
      ),
      scaffoldBackgroundColor: SariColors.backgroundLight,
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      cardTheme: _buildCardThemeData(),
      floatingActionButtonTheme: _buildFabTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      chipTheme: _buildChipTheme(),
      dividerTheme: const DividerThemeData(
        color: SariColors.divider,
        thickness: 1,
      ),
      bottomNavigationBarTheme: _buildBottomNavTheme(),
    );
  }

  static TextTheme _buildTextTheme() {
    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: SariColors.textPrimary,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: SariColors.textPrimary,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: SariColors.textPrimary,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: SariColors.textPrimary,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: SariColors.textPrimary,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: SariColors.textPrimary,
        height: 1.4,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: SariColors.textPrimary,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SariColors.textPrimary,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: SariColors.textSecondary,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: SariColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: SariColors.textPrimary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: SariColors.textSecondary,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SariColors.textPrimary,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: SariColors.textSecondary,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: SariColors.textTertiary,
        height: 1.4,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: SariColors.primaryGreen,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: SariColors.primaryGreen,
      ),
      iconTheme: const IconThemeData(
        color: SariColors.primaryGreen,
        size: 24,
      ),
    );
  }

  static CardThemeData _buildCardThemeData() {
    return CardThemeData(
      elevation: 0,
      color: SariColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: SariColors.divider, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme() {
    return FloatingActionButtonThemeData(
      backgroundColor: SariColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      extendedTextStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SariColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SariColors.primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: SariColors.primaryGreen, width: 1.5),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: SariColors.backgroundWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SariColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SariColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SariColors.primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: SariColors.error),
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: SariColors.textSecondary,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: SariColors.textTertiary,
      ),
    );
  }

  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: SariColors.backgroundLight,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: SariColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: const BorderSide(color: SariColors.divider),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: SariColors.backgroundWhite,
      selectedItemColor: SariColors.primaryGreen,
      unselectedItemColor: SariColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class SariStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? subtitle;
  final double? trendPercentage;
  final bool isPositiveTrend;
  final bool useGradient;
  final LinearGradient? gradient;

  const SariStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.subtitle,
    this.trendPercentage,
    this.isPositiveTrend = true,
    this.useGradient = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = backgroundColor ?? SariColors.backgroundWhite;
    final accentColor = iconColor ?? SariColors.primaryGreen;
    final effectiveGradient = gradient ?? SariGradients.cardHover;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: useGradient ? null : cardColor,
        gradient: useGradient ? effectiveGradient : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SariColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const Spacer(),
              if (trendPercentage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositiveTrend
                        ? SariColors.success.withValues(alpha: 0.12)
                        : SariColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isPositiveTrend ? SariColors.success : SariColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trendPercentage!.abs().toStringAsFixed(1)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isPositiveTrend ? SariColors.success : SariColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: SariColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: SariColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: SariColors.textTertiary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class SariProductTile extends StatelessWidget {
  final String productName;
  final String category;
  final double sellingPrice;
  final double costPrice;
  final int stockQuantity;
  final int minStockAlert;
  final String? imagePath;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SariProductTile({
    super.key,
    required this.productName,
    required this.category,
    required this.sellingPrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.minStockAlert,
    this.imagePath,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color get _stockStatusColor {
    if (stockQuantity == 0) {
      return SariColors.error;
    } else if (stockQuantity <= minStockAlert) {
      return SariColors.warning;
    }
    return SariColors.success;
  }

  String get _stockStatusLabel {
    if (stockQuantity == 0) {
      return 'OUT';
    } else if (stockQuantity <= minStockAlert) {
      return 'LOW';
    }
    return 'IN';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = stockQuantity <= minStockAlert;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: SariGradients.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowStock
              ? (_stockStatusColor.withValues(alpha: 0.3))
              : SariColors.divider,
          width: isLowStock ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: SariColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SariColors.divider),
                  ),
                  child: imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.inventory_2_outlined,
                              color: SariColors.textTertiary,
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: SariColors.textTertiary,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _stockStatusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _stockStatusLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _stockStatusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: SariColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: _buildPriceChip('Cost', costPrice, SariColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: _buildPriceChip('Sell', sellingPrice, SariColors.primaryGreen, isPrimary: true),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: SariColors.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$stockQuantity',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: SariColors.primaryGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChip(String label, double price, Color color, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? SariColors.primaryGreen.withValues(alpha: 0.1)
            : SariColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₱${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? SariColors.primaryGreen : SariColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SariTransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime dateTime;
  final double amount;
  final bool isPositive;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const SariTransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dateTime,
    required this.amount,
    required this.isPositive,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  String get _formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = isPositive ? SariColors.success : SariColors.error;
    final displayIcon = icon ?? (isPositive ? Icons.arrow_upward : Icons.arrow_downward);
    final displayIconColor = iconColor ?? amountColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: SariGradients.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SariColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: displayIconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    displayIcon,
                    color: displayIconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: SariColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${isPositive ? '+' : '-'}₱${amount.abs().toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedDate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: SariColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SariActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool useGradient;

  const SariActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.useGradient = true,
  });

  LinearGradient? get _effectiveGradient {
    if (!isPrimary || !useGradient) return null;
    if (backgroundColor != null) {
      final bg = backgroundColor!;
      final r = bg.r, g = bg.g, b = bg.b;
      final darker = Color.from(alpha: bg.a, red: r * 0.6, green: g * 0.6, blue: b * 0.6);
      return LinearGradient(
        colors: [bg, darker],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
    }
    return SariGradients.buttonPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fgColor = isPrimary
        ? (foregroundColor ?? Colors.white)
        : (foregroundColor ?? SariColors.primaryGreen);
    final borderColor = isPrimary
        ? Colors.transparent
        : (foregroundColor ?? SariColors.primaryGreen);

    final buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        if (!isLoading)
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );

    if (isPrimary) {
      return SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: _effectiveGradient ?? SariGradients.buttonPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: SariColors.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: fgColor,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: buttonContent,
          ),
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(48, 48),
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: buttonContent,
      ),
    );
  }
}

class SariUiShowcase extends StatelessWidget {
  const SariUiShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: SariColors.backgroundLight,
      appBar: AppBar(
        title: const Text('SariSync Design System'),
        backgroundColor: SariColors.backgroundWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stat Cards',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SariStatCard(
                    title: 'Total Sales',
                    value: '₱12,450.00',
                    icon: Icons.point_of_sale,
                    iconColor: SariColors.primaryGreen,
                    trendPercentage: 12.5,
                    isPositiveTrend: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SariStatCard(
                    title: 'Active Debts',
                    value: '₱3,200.00',
                    icon: Icons.account_balance_wallet,
                    iconColor: SariColors.error,
                    subtitle: '5 customers',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SariStatCard(
                    title: 'Net Profit',
                    value: '₱4,890.00',
                    icon: Icons.trending_up,
                    iconColor: SariColors.success,
                    trendPercentage: 8.2,
                    isPositiveTrend: true,
                    backgroundColor: SariColors.success.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SariStatCard(
                    title: 'Low Stock',
                    value: '8 items',
                    icon: Icons.warning_amber,
                    iconColor: SariColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Product Tiles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SariProductTile(
              productName: 'Milo Choco Drink',
              category: 'Beverages',
              sellingPrice: 25.00,
              costPrice: 18.50,
              stockQuantity: 45,
              minStockAlert: 10,
            ),
            SariProductTile(
              productName: 'Lucky Me! Pancit Canton',
              category: 'Food',
              sellingPrice: 15.00,
              costPrice: 10.00,
              stockQuantity: 8,
              minStockAlert: 15,
            ),
            SariProductTile(
              productName: 'Alaska Milk 250ml',
              category: 'Beverages',
              sellingPrice: 18.00,
              costPrice: 14.00,
              stockQuantity: 0,
              minStockAlert: 20,
            ),
            const SizedBox(height: 32),
            Text(
              'Transaction Tiles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SariTransactionTile(
              title: 'Milo Choco Drink x3',
              subtitle: 'POS Sale',
              dateTime: now.subtract(const Duration(minutes: 5)),
              amount: 75.00,
              isPositive: true,
              icon: Icons.shopping_cart,
            ),
            SariTransactionTile(
              title: 'Payment - Juan Dela Cruz',
              subtitle: 'Debt Payment',
              dateTime: now.subtract(const Duration(hours: 2)),
              amount: 150.00,
              isPositive: true,
              icon: Icons.payments,
              iconColor: SariColors.success,
            ),
            SariTransactionTile(
              title: 'Electric Bill',
              subtitle: 'Expense',
              dateTime: now.subtract(const Duration(hours: 5)),
              amount: 450.00,
              isPositive: false,
              icon: Icons.receipt_long,
              iconColor: SariColors.error,
            ),
            const SizedBox(height: 32),
            Text(
              'Action Buttons',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SariActionButton(
                    label: 'Checkout',
                    icon: Icons.shopping_cart_checkout,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SariActionButton(
                    label: 'Add Product',
                    icon: Icons.add_box,
                    onPressed: () {},
                    isPrimary: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SariActionButton(
              label: 'Record Expense',
              icon: Icons.money_off,
              onPressed: () {},
              isFullWidth: true,
              backgroundColor: SariColors.error,
            ),
            const SizedBox(height: 12),
            SariActionButton(
              label: 'Processing...',
              icon: Icons.save,
              onPressed: () {},
              isLoading: true,
              isFullWidth: true,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SariColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SariColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color Palette',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildColorChip('Primary Green', SariColors.primaryGreen),
                      _buildColorChip('Navy', SariColors.secondaryNavy),
                      _buildColorChip('Amber', SariColors.accentAmber),
                      _buildColorChip('Crimson', SariColors.accentCrimson),
                      _buildColorChip('Mint', SariColors.accentMint),
                      _buildColorChip('Success', SariColors.success),
                      _buildColorChip('Warning', SariColors.warning),
                      _buildColorChip('Error', SariColors.error),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SariColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}