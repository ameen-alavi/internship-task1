import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../providers/enquiry_provider.dart';

class EnquiryPaginationBar extends StatelessWidget {
  final EnquiryProvider provider;

  const EnquiryPaginationBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = ResponsiveHelper.isMobile(context);

    final totalCount = provider.totalCount;
    final currentPage = provider.currentPage;
    final pageSize = provider.pageSize;
    final totalPages = provider.totalPages;

    final startItem = totalCount == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final endItem = min(currentPage * pageSize, totalCount);

    final pageInfoText = totalCount == 0
        ? 'No enquiries'
        : 'Showing $startItem–$endItem of $totalCount enquiries';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC),
        borderRadius: AppDimensions.roundedMedium,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pageInfoText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPageSizeDropdown(isDark),
                  ],
                ),
                const SizedBox(height: 8),
                _buildNavigationButtons(
                  context,
                  isDark,
                  currentPage,
                  totalPages,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Info label
                Expanded(
                  child: Text(
                    pageInfoText,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),

                // Controls: Page size selector + Page navigation
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPageSizeDropdown(isDark),
                    const SizedBox(width: 16),
                    _buildNavigationButtons(
                      context,
                      isDark,
                      currentPage,
                      totalPages,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPageSizeDropdown(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rows:',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 6),
        DropdownButton<int>(
          value: provider.pageSize,
          underline: const SizedBox.shrink(),
          isDense: true,
          items: const [
            DropdownMenuItem(value: 5, child: Text('5')),
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
          ],
          onChanged: (val) {
            if (val != null) {
              provider.setPageSize(val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    bool isDark,
    int currentPage,
    int totalPages,
  ) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: provider.hasPreviousPage
                ? () => provider.previousPage()
                : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 16),
            label: const Text('Prev', style: TextStyle(fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Page $currentPage of $totalPages',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: provider.hasNextPage ? () => provider.nextPage() : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 16),
            label: const Text('Next', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
