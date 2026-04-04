import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const TransactionCard({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCashIn = transaction.type == TransactionType.cashIn;
    final color = isCashIn ? AppTheme.accentColor : AppTheme.errorColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title, 
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: Color(0xFF1F2937)
                    )
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        transaction.formattedDate, 
                        style: TextStyle(color: Colors.grey[400], fontSize: 12)
                      ),
                      if (transaction.isSynced == 1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.cloud_done_rounded, size: 12, color: Colors.blueAccent),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCashIn ? '+' : '-'} ${transaction.formattedAmount}',
                  style: TextStyle(
                    color: color, 
                    fontWeight: FontWeight.w700, 
                    fontSize: 18,
                    letterSpacing: -0.5
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (transaction.attachmentPath != null)
                      const Icon(Icons.attach_file, size: 14, color: Colors.blueAccent),
                    if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.description_outlined, size: 14, color: Colors.grey),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
