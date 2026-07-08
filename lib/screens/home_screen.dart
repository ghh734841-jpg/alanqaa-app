import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/orders_repository.dart';
import '../theme/app_theme.dart';
import 'new_order_screen.dart';
import 'orders_list_screen.dart';
import 'admin_dashboard_screen.dart';

enum _Role { client, admin }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _repo = OrdersRepository();

  _Role _role = _Role.client;
  int _clientTab = 0; // 0 = طلب جديد, 1 = طلباتي
  bool _isAdminPhone = false;
  bool _checkingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _auth.checkIsAdmin();
    if (mounted) {
      setState(() {
        _isAdminPhone = isAdmin;
        _checkingAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _drawer(),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_checkingAdmin) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }

    if (_role == _Role.admin) {
      return StreamBuilder<List<Order>>(
        stream: _repo.watchAllOrders(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.teal));
          }
          final orders = snap.data ?? [];
          return AdminDashboardScreen(
            orders: orders,
            onStatusChange: (id, s) => _repo.updateStatus(id, s),
            onSetPrice: (id, p) => _repo.setPrice(id, p),
            onTogglePayment: (id, field) {
              final current = orders.firstWhere((o) => o.id == id);
              final currentValue = field == 'depositPaid' ? current.depositPaid : current.fullyPaid;
              _repo.togglePayment(id, field, !currentValue);
            },
            onSetEstimatedDays: (id, days) => _repo.setEstimatedDays(id, days),
          );
        },
      );
    }

    // العميل
    final phone = _auth.currentPhone ?? '';
    return _clientTab == 0
        ? NewOrderScreen(
            repository: _repo,
            customerPhone: phone,
            onSubmitted: () => setState(() => _clientTab = 1),
          )
        : StreamBuilder<List<Order>>(
            stream: _repo.watchMyOrders(phone),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.teal));
              }
              return OrdersListScreen(orders: snap.data ?? []);
            },
          );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                  icon: const Icon(Icons.menu, color: AppColors.textMuted),
                ),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('شركة العنقاء للمقاولات',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    Text('إدارة طلبات تصنيع المطابخ',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (_isAdminPhone) _roleSwitch(),
            ],
          ),
          if (_role == _Role.client) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _clientTabButton('طلب جديد', 0)),
                const SizedBox(width: 10),
                Expanded(child: _clientTabButton('طلباتي', 1)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleSwitch() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleButton('عميل', Icons.storefront_outlined, _Role.client),
          _roleButton('مدير', Icons.shield_outlined, _Role.admin),
        ],
      ),
    );
  }

  Widget _roleButton(String label, IconData icon, _Role role) {
    final active = _role == role;
    return InkWell(
      onTap: () => setState(() => _role = role),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? AppColors.bgDeep : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.bgDeep : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _clientTabButton(String label, int index) {
    final active = _clientTab == index;
    return InkWell(
      onTap: () => setState(() => _clientTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.teal.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.teal : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: active ? AppColors.teal : AppColors.textMuted)),
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('شركة العنقاء للمقاولات',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(_auth.currentPhone ?? '',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  if (_isAdminPhone) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('حساب مدير',
                          style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            const Spacer(),
            const Divider(color: AppColors.border, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.red),
              title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.of(context).pop();
                await _auth.signOut();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
