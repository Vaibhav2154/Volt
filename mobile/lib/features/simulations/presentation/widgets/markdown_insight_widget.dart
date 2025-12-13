import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_pallette.dart';

/// A widget that renders markdown text with custom styling,
/// specifically with green headings to match the app theme.
class MarkdownInsightWidget extends StatelessWidget {
  final String markdown;
  final EdgeInsets? padding;

  const MarkdownInsightWidget({
    super.key,
    required this.markdown,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: MarkdownBody(
        data: markdown,
        styleSheet: _buildMarkdownStyleSheet(theme),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      // Headings - all in green
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ColorPalette.green400,
        height: 1.3,
      ),
      h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
      
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: ColorPalette.green400,
        height: 1.3,
      ),
      h2Padding: const EdgeInsets.only(top: 14, bottom: 6),
      
      h3: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ColorPalette.green400,
        height: 1.3,
      ),
      h3Padding: const EdgeInsets.only(top: 12, bottom: 6),
      
      h4: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ColorPalette.green400,
        height: 1.3,
      ),
      h4Padding: const EdgeInsets.only(top: 10, bottom: 4),
      
      h5: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ColorPalette.green400,
        height: 1.3,
      ),
      h5Padding: const EdgeInsets.only(top: 8, bottom: 4),
      
      h6: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: ColorPalette.green400,
        height: 1.3,
      ),
      h6Padding: const EdgeInsets.only(top: 6, bottom: 4),
      
      // Body text
      p: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
        height: 1.6,
      ),
      pPadding: const EdgeInsets.only(bottom: 8),
      
      // Lists
      listBullet: TextStyle(
        fontSize: 14,
        color: ColorPalette.green400,
        fontWeight: FontWeight.bold,
      ),
      listIndent: 24.0,
      
      // Strong/Bold text - green to match headings
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: ColorPalette.green400,
      ),
      
      // Emphasis/Italic text
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurface,
      ),
      
      // Code blocks
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surface,
        color: ColorPalette.green300,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ColorPalette.green400.withOpacity(0.3),
          width: 1,
        ),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      
      // Links
      a: TextStyle(
        color: ColorPalette.green400,
        decoration: TextDecoration.underline,
      ),
      
      // Blockquotes
      blockquote: TextStyle(
        fontSize: 14,
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurface.withOpacity(0.8),
      ),
      blockquoteDecoration: BoxDecoration(
        color: ColorPalette.green400.withOpacity(0.1),
        border: Border(
          left: BorderSide(
            color: ColorPalette.green400,
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      
      // Horizontal rules
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: ColorPalette.green400.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}

