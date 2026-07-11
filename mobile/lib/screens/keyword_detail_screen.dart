import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../firebase/analytics_helper.dart';
import '../viewmodels/keywords_viewmodel.dart';
import '../widgets/app_widgets.dart' hide LineChart;

class KeywordDetailScreen extends StatefulWidget {
  const KeywordDetailScreen({super.key, required this.keywordData});

  final KeywordData keywordData;

  @override
  State<KeywordDetailScreen> createState() => _KeywordDetailScreenState();
}

class _KeywordDetailScreenState extends State<KeywordDetailScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsHelper.logViewKeyword(widget.keywordData.keyword);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KeywordsViewModel>();
    final authors = viewModel.getTopAuthorsForKeyword(widget.keywordData.keyword);

    // Prepare data for line chart (publications per year)
    final Map<int, int> pubCountByYear = {};
    for (var pub in widget.keywordData.relatedPublications) {
      if (pub.publicationYear > 0) {
        pubCountByYear[pub.publicationYear] = (pubCountByYear[pub.publicationYear] ?? 0) + 1;
      }
    }
    
    final sortedYears = pubCountByYear.keys.toList()..sort();
    final List<FlSpot> chartSpots = [];
    if (sortedYears.isNotEmpty) {
      for (var year in sortedYears) {
        chartSpots.add(FlSpot(year.toDouble(), pubCountByYear[year]!.toDouble()));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: 'Từ khóa: ${widget.keywordData.keyword}', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.trending_up,
                  title: 'Xu hướng xuất bản qua các năm',
                ),
                const SizedBox(height: 24),
                if (chartSpots.isEmpty || chartSpots.length == 1)
                  const Center(child: Text('Không đủ dữ liệu năm để vẽ biểu đồ.'))
                else
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(), 
                                  style: const TextStyle(fontSize: 10)
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, 
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(), 
                                  style: const TextStyle(fontSize: 10)
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: AppColors.border)),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartSpots,
                            isCurved: true,
                            color: AppColors.accent,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.accent.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          const SectionTitle(
            icon: Icons.people,
            title: 'Tác giả hàng đầu đóng góp',
          ),
          const SizedBox(height: 12),
          if (authors.isEmpty)
            const Center(child: Text('Không tìm thấy tác giả.'))
          else
            ...authors.map((author) {
              final rank = authors.indexOf(author) + 1;
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text('#$rank', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(author.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${author.worksCount} bài báo liên quan đến "${widget.keywordData.keyword}"'),
                  trailing: const Icon(Icons.star, color: Colors.amber),
                ),
              );
            }),
        ],
      ),
    );
  }
}
