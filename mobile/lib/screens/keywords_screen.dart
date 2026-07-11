import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../viewmodels/keywords_viewmodel.dart';
import '../widgets/app_widgets.dart';
import 'keyword_detail_screen.dart';

class KeywordsScreen extends StatelessWidget {
  const KeywordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KeywordsViewModel>(
      builder: (context, viewModel, child) {
        final keywords = viewModel.topKeywords;

        return ScreenScroll(
          onRefresh: () async {
            // Parent handles fetching, we assume data is pushed to ViewModel
          },
          children: [
            const ScreenHeader(
              title: 'Từ khóa',
              subtitle: 'Phân tích từ khóa',
              badge: 'Xu hướng',
            ),
            const SizedBox(height: AppSpacing.medium),

            if (viewModel.isLoading)
              const SizedBox(
                height: 120,
                child: AppLoadingState(message: 'Đang xử lý dữ liệu từ khóa...'),
              )
            else if (viewModel.error != null)
              AppErrorState(message: viewModel.error!)
            else if (keywords.isEmpty)
              const AppEmptyState(
                icon: Icons.tag,
                title: 'Chưa có từ khóa',
                message: 'Không có dữ liệu từ khóa để hiển thị.',
              )
            else ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      icon: Icons.tag,
                      title: 'Từ khóa phổ biến nhất',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: keywords.take(20).map((k) {
                        return ActionChip(
                          label: Text('${k.keyword} (${k.count})'),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => KeywordDetailScreen(keywordData: k),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              _KeywordList(keywords: keywords),
            ],
          ],
        );
      },
    );
  }
}

class _KeywordList extends StatelessWidget {
  const _KeywordList({required this.keywords});

  final List<KeywordData> keywords;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          icon: Icons.list,
          title: 'Tất cả từ khóa',
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < keywords.length; index++) ...[
          Card(
            margin: EdgeInsets.zero,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.tag, color: Colors.white, size: 18),
              ),
              title: Text(
                keywords[index].keyword, 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              subtitle: Text(
                'Bài báo: ${keywords[index].count} | Trích dẫn: ${keywords[index].totalCitations}'
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KeywordDetailScreen(keywordData: keywords[index]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
