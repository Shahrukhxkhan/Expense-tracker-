import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/models/models.dart';
import 'package:expense_tracker/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/presentation/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Color> _availableColors = [
    Colors.redAccent,
    Colors.deepOrange,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.deepPurple,
    Colors.pink,
    Colors.blueGrey,
    Colors.brown,
  ];

  static const List<IconData> _availableIcons = [
    Icons.fastfood_rounded,
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.directions_car_rounded,
    Icons.directions_bus_rounded,
    Icons.local_gas_station_rounded,
    Icons.home_rounded,
    Icons.apartment_rounded,
    Icons.electric_bolt_rounded,
    Icons.water_drop_rounded,
    Icons.wifi_rounded,
    Icons.movie_rounded,
    Icons.sports_esports_rounded,
    Icons.fitness_center_rounded,
    Icons.medical_services_rounded,
    Icons.school_rounded,
    Icons.flight_rounded,
    Icons.work_rounded,
    Icons.account_balance_rounded,
    Icons.savings_rounded,
    Icons.trending_up_rounded,
    Icons.laptop_chromebook_rounded,
    Icons.card_giftcard_rounded,
    Icons.receipt_long_rounded,
    Icons.payments_rounded,
    Icons.loyalty_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses', icon: Icon(Icons.arrow_upward_rounded, size: 18)),
            Tab(text: 'Income', icon: Icon(Icons.arrow_downward_rounded, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryDialog(
          context,
          initialType: _tabController.index == 0
              ? TransactionType.expense
              : TransactionType.income,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(TransactionType.expense),
          _buildCategoryList(TransactionType.income),
        ],
      ),
    );
  }

  Widget _buildCategoryList(TransactionType type) {
    final categoriesAsync = ref.watch(categoriesProvider(type));

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No ${type.name} categories found.'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final color = parseHexColor(cat.colorHex);
            final icon = IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons');

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(icon, color: color, size: 22),
                ),
                title: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      tooltip: 'Edit Category',
                      onPressed: () => _openCategoryDialog(context, existingCategory: cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.expense),
                      tooltip: 'Delete Category',
                      onPressed: () => _confirmDelete(cat),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading categories: $err')),
    );
  }

  Future<void> _openCategoryDialog(
    BuildContext context, {
    TransactionType? initialType,
    Category? existingCategory,
  }) async {
    final isEditing = existingCategory != null;
    final nameController = TextEditingController(text: existingCategory?.name ?? '');
    var selectedType = existingCategory?.type ?? (initialType ?? TransactionType.expense);
    var selectedColor = existingCategory != null
        ? parseHexColor(existingCategory.colorHex)
        : _availableColors.first;
    var selectedIcon = existingCategory != null
        ? IconData(existingCategory.iconCodePoint, fontFamily: 'MaterialIcons')
        : _availableIcons.first;

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (dialogCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 16,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Edit Category' : 'Create Category',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Type Selection (if creating)
                      if (!isEditing) ...[
                        SegmentedButton<TransactionType>(
                          segments: const [
                            ButtonSegment(
                              value: TransactionType.expense,
                              label: Text('Expense'),
                              icon: Icon(Icons.arrow_upward_rounded),
                            ),
                            ButtonSegment(
                              value: TransactionType.income,
                              label: Text('Income'),
                              icon: Icon(Icons.arrow_downward_rounded),
                            ),
                          ],
                          selected: {selectedType},
                          onSelectionChanged: (val) {
                            setSheetState(() => selectedType = val.first);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Category Name
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Category Name',
                          hintText: 'e.g. Subscriptions, Freelancing',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Color Picker
                      const Text('Theme Color', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableColors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, idx) {
                            final c = _availableColors[idx];
                            final isSel = c.value == selectedColor.value;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedColor = c),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? Colors.white : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSel
                                      ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6)]
                                      : null,
                                ),
                                child: isSel
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Icon Picker
                      const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableIcons.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, idx) {
                            final icon = _availableIcons[idx];
                            final isSel = icon.codePoint == selectedIcon.codePoint;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedIcon = icon),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSel ? selectedColor.withValues(alpha: 0.2) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel ? selectedColor : Colors.grey.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: isSel ? selectedColor : Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final hex = '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                            final repo = ref.read(expenseRepositoryProvider);

                            if (isEditing) {
                              final updated = existingCategory.copyWith(
                                name: nameController.text.trim(),
                                colorHex: hex,
                                iconCodePoint: selectedIcon.codePoint,
                              );
                              await repo.updateCategory(updated);
                            } else {
                              final newCat = Category(
                                id: const Uuid().v4(),
                                name: nameController.text.trim(),
                                type: selectedType,
                                iconCodePoint: selectedIcon.codePoint,
                                colorHex: hex,
                                createdAt: DateTime.now(),
                              );
                              await repo.insertCategory(newCat);
                            }

                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          },
                          child: Text(isEditing ? 'Save Changes' : 'Create Category'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${cat.name}"?'),
        content: const Text(
          'Transactions using this category may be affected. Are you sure you want to delete this category?',
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => ctx.pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(expenseRepositoryProvider).deleteCategory(cat.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot delete category: $e')),
          );
        }
      }
    }
  }
}
