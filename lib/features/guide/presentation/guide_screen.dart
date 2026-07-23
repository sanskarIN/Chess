import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/guide_catalog.dart';
import '../domain/guide_topic.dart';
import 'guide_localizations.dart';

final class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

final class _GuideScreenState extends State<GuideScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String query = _query.trim().toLowerCase();
    final List<GuideTopic> topics = GuideCatalog.topics
        .where((GuideTopic topic) {
          if (query.isEmpty) {
            return true;
          }
          return guideTopicTitle(
                strings,
                topic.id,
              ).toLowerCase().contains(query) ||
              guideTopicBody(strings, topic.id).toLowerCase().contains(query);
        })
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: Text(strings.guideTitle)),
      body: ListView(
        padding: DesignTokens.pagePadding(MediaQuery.sizeOf(context).width),
        children: <Widget>[
          Text(
            strings.guideSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesignTokens.space16),
          TextField(
            decoration: InputDecoration(
              labelText: strings.searchGuide,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: DesignTokens.space16),
          if (topics.isEmpty)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space24),
              child: Center(child: Text(strings.noSearchResults)),
            )
          else
            for (final GuideTopic topic in topics)
              Card(
                child: ExpansionTile(
                  leading: Icon(topic.icon),
                  title: Text(guideTopicTitle(strings, topic.id)),
                  childrenPadding: const EdgeInsetsDirectional.fromSTEB(
                    DesignTokens.space16,
                    0,
                    DesignTokens.space16,
                    DesignTokens.space16,
                  ),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[Text(guideTopicBody(strings, topic.id))],
                ),
              ),
        ],
      ),
    );
  }
}
