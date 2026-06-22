import 'package:flutter/material.dart';
import '../data/constants.dart';
import '../data/article.dart';

class ArticleTemplate extends StatelessWidget {
  final Article article;
  const ArticleTemplate({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    return Container(
      margin: const EdgeInsets.only(bottom: KConstants.spacingLarge),
      decoration: KDecoration.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                article.imageUrl!,
                height: width >= 1200 ? 500 : width >= 1000 ? 400 : width >= 768 ? 300 : width >= 492 ? 250 : 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(KConstants.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title, style: KTextStyle.cardTitleText),
                const SizedBox(height: KConstants.spacingSmall),
                Text(article.subtitle, style: KTextStyle.cardSubtitleText),
                const SizedBox(height: KConstants.spacingMedium),
                Text(
                  article.body,
                  style: KTextStyle.cardBodyText,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
