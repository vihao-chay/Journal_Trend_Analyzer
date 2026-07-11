import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/journal_model.dart';
import '../viewmodels/journals_viewmodel.dart';
import '../widgets/app_widgets.dart';
import 'detail_screens.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JournalsViewModel>(
      builder: (context, viewModel, child) {
        final journals = viewModel.topJournals;

        return ScreenScroll(
          onRefresh: () async {
            // Depending on the app flow, Dev 1/4 handles data fetching.
            // Assuming this triggers a refresh at the parent level.
          },
          children: [
            const ScreenHeader(
              title: 'Tạp chí',
              subtitle: 'Tạp chí nổi bật',
              badge: 'Toàn cục',
            ),
            const SizedBox(height: AppSpacing.medium),
            
            if (viewModel.isLoading)
              const SizedBox(
                height: 120,
                child: AppLoadingState(message: 'Đang xử lý dữ liệu tạp chí...'),
              )
            else if (viewModel.error != null)
              AppErrorState(message: viewModel.error!)
            else if (journals.isEmpty)
              const AppEmptyState(
                icon: Icons.library_books_outlined,
                title: 'Chưa có tạp chí',
                message: 'Không có dữ liệu tạp chí để hiển thị.',
              )
            else ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      icon: Icons.bar_chart,
                      title: 'Xếp hạng tạp chí theo số bài (Top 8)',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: _buildBarChart(journals.take(8).toList()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              _JournalList(journals: journals),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBarChart(List<JournalModel> journals) {
    final maxY = journals.isNotEmpty ? journals.first.worksCount.toDouble() * 1.2 : 10.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < journals.length) {
                  String name = journals[value.toInt()].displayName;
                  if (name.length > 12) {
                    name = '${name.substring(0, 10)}...';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 42,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: journals.asMap().entries.map((entry) {
          final index = entry.key;
          final journal = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: journal.worksCount.toDouble(),
                color: AppColors.primary,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _JournalList extends StatelessWidget {
  const _JournalList({required this.journals});

  final List<JournalModel> journals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          icon: Icons.library_books_outlined,
          title: 'Tất cả tạp chí',
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < journals.length; index++) ...[
          JournalCard(
            journal: journals[index],
            rank: index + 1,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => JournalDetailScreen(journal: journals[index]),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
