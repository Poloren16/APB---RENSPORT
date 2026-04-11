import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Booking',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ─────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.primary, width: 2.5),
                ),
                tabs: const [
                  Tab(text: 'Daftar Pesanan'),
                  Tab(text: 'Riwayat Transaksi'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search Bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: _selectedTab == 0
                              ? 'Cari Nama Booking'
                              : 'Cari Transaksi',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildIconButton(Icons.tune_rounded),
                  const SizedBox(width: 8),
                  _buildIconButton(Icons.filter_list_rounded),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab Content ──────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmptyState(
                    message: 'Belum ada daftar pesanan untukmu.',
                  ),
                  _buildEmptyState(
                    message: 'Belum ada riwayat transaksi untukmu.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }

  Widget _buildEmptyState({required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _SportyEmptyIllustration(),
            const SizedBox(height: 28),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data akan muncul di sini ketika tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Buat Booking'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Sporty Empty State Illustration with float animation
// ─────────────────────────────────────────────────────────────────────────────

class _SportyEmptyIllustration extends StatefulWidget {
  const _SportyEmptyIllustration();

  @override
  State<_SportyEmptyIllustration> createState() =>
      _SportyEmptyIllustrationState();
}

class _SportyEmptyIllustrationState extends State<_SportyEmptyIllustration>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shadowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _pulseAnimation]),
      builder: (context, _) {
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing background glow
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.10),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating illustration image
              Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: Image.asset(
                  'assets/images/leaf.png',
                  width: 190,
                  height: 190,
                  fit: BoxFit.contain,
                ),
              ),

              // Dynamic shadow
              Positioned(
                bottom: 6,
                child: Transform.scale(
                  scaleX: _shadowAnimation.value,
                  child: Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
