import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/data/models/derived_models.dart';
import 'package:expense_tracker/data/models/models.dart';
import 'package:expense_tracker/presentation/widgets/amount_text.dart';
import 'package:expense_tracker/presentation/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable transaction tile with category icon, account badge, and swipe dismiss.
class TransactionTile extends StatelessWidget {
  final TransactionWithDetails item;
  final VoidCallback? onTap;
  final DismissDirectionCallback? onDismissed;

  const TransactionTile({
    super.key,
    required this.item,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final t = item.transaction;
    final cat = item.category;
    final catColor = parseHexColor(cat.colorHex);
    final isIncome = t.type == TransactionType.income;
    final dateStr = DateFormat('h:mm a').format(t.date);

    final tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
            color: catColor,
            size: 24,
          ),
        ),
        title: Text(
          t.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 6),
              Text(
                item.account.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 6),
              const Text('•', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (t.receiptPath != null) ...[
              IconButton(
                icon: const Icon(Icons.receipt_rounded, size: 20, color: Colors.blueAccent),
                tooltip: 'View Receipt',
                onPressed: () => _showReceiptDialog(context, t.receiptPath!, t.title),
              ),
              const SizedBox(width: 2),
            ],
            AmountText(
              amountMinor: t.amountMinor,
              isIncome: isIncome,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );

    if (onDismissed != null) {
      return Dismissible(
        key: Key(t.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.expense,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
        ),
        onDismissed: onDismissed,
        child: tile,
      );
    }

    return tile;
  }

  void _showReceiptDialog(BuildContext context, String receiptPath, String title) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Receipt: $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      receiptPath.split(RegExp(r'[\\/]')).last,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'File path:\n$receiptPath',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
