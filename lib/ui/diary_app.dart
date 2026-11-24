import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/diary_analysis.dart';
import '../domain/diary_entry.dart';
import 'diary_theme.dart';
import 'diary_view_model.dart';

class DiaryApp extends StatefulWidget {
  const DiaryApp({
    super.key,
    required this.viewModel,
    this.initialDarkTheme = true,
    this.onThemeChanged,
  });

  final DiaryViewModel viewModel;
  final bool initialDarkTheme;
  final ValueChanged<bool>? onThemeChanged;

  @override
  State<DiaryApp> createState() => _DiaryAppState();
}

class _DiaryAppState extends State<DiaryApp> {
  late bool _darkTheme = widget.initialDarkTheme;
  late final ThemeData _light = buildDiaryTheme(Brightness.light);
  late final ThemeData _dark = buildDiaryTheme(Brightness.dark);

  void _toggleTheme() {
    setState(() => _darkTheme = !_darkTheme);
    widget.onThemeChanged?.call(_darkTheme);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Diary',
    debugShowCheckedModeBanner: false,
    theme: _light,
    darkTheme: _dark,
    themeMode: _darkTheme ? ThemeMode.dark : ThemeMode.light,
    themeAnimationStyle: AnimationStyle.noAnimation,
    builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!,
      child: child!,
    ),
    home: DiaryHomePage(
      viewModel: widget.viewModel,
      onToggleTheme: _toggleTheme,
    ),
  );
}

class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.child, this.maxWidth = 880});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class _PageBar extends StatelessWidget implements PreferredSizeWidget {
  const _PageBar({
    required this.title,
    this.leading,
    this.actions = const [],
    this.maxWidth = 880,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Size get preferredSize => const Size.fromHeight(61);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: 0,
    title: _ContentWidth(
      maxWidth: maxWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ...actions,
          ],
        ),
      ),
    ),
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, thickness: 1),
    ),
  );
}

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({
    super.key,
    required this.viewModel,
    required this.onToggleTheme,
  });

  final DiaryViewModel viewModel;
  final VoidCallback onToggleTheme;

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: EntryCategory.values.length,
    vsync: this,
  );
  final _filters = <EntryCategory, _DiaryFilter>{};

  EntryCategory get _category => EntryCategory.values[_tabs.index];

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openFilters(EntryCategory category) async {
    final currentFilter = _filters[category];
    final filter = await showDiaryPanel<_DiaryFilter>(
      context,
      _FilterSheet(
        availablePeople: widget.viewModel.peopleIn(category),
        initialRating: currentFilter?.rating,
        initialPerson: currentFilter?.person,
      ),
    );
    if (mounted && filter != null) setState(() => _filters[category] = filter);
  }

  void _openAnalysis() {
    final category = _category;
    Navigator.of(context).push(
      diaryPageRoute(
        context,
        (_) => AnalysisPage(viewModel: widget.viewModel, category: category),
      ),
    );
  }

  Future<void> _openNewEntry() async {
    final initialCategory = _category;
    final category = await Navigator.of(context).push(
      diaryPageRoute<EntryCategory>(
        context,
        (_) => NewEntryPage(
          viewModel: widget.viewModel,
          initialCategory: initialCategory,
        ),
      ),
    );
    if (mounted && category != null) {
      _tabs.animateTo(
        category.index,
        duration: diaryAnimation(context).duration,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final width =
        MediaQuery.sizeOf(context).width -
        MediaQuery.paddingOf(context).horizontal;
    final wide = width >= 520;
    final compact = width < 360;
    final largeLabels = MediaQuery.textScalerOf(context).scale(12) > 16;
    return Scaffold(
      appBar: _PageBar(
        title: 'Diary',
        leading: compact
            ? null
            : SizedBox.square(
                dimension: 34,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: scheme.surfaceContainer,
                    shape: diaryControlShape,
                  ),
                  child: const Icon(Icons.auto_stories_outlined, size: 18),
                ),
              ),
        actions: [
          if (wide && !largeLabels)
            Tooltip(
              message: 'Analysis',
              child: TextButton.icon(
                onPressed: _openAnalysis,
                icon: const Icon(Icons.insights_outlined),
                label: const Text('Analysis'),
              ),
            )
          else
            IconButton(
              tooltip: 'Analysis',
              onPressed: _openAnalysis,
              icon: const Icon(Icons.insights_outlined),
            ),
          IconButton(
            tooltip: dark ? 'Use light theme' : 'Use dark theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
          if (width < 300 || (width < 440 && largeLabels))
            IconButton.filled(
              tooltip: 'New entry',
              style: theme.filledButtonTheme.style,
              onPressed: _openNewEntry,
              icon: const Icon(Icons.add),
            )
          else
            FilledButton.icon(
              onPressed: _openNewEntry,
              icon: const Icon(Icons.add),
              label: const Text('New entry'),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(text: 'Diary'),
                    Tab(text: 'Note'),
                  ],
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, _) => TabBarView(
                    controller: _tabs,
                    children: [
                      for (final category in EntryCategory.values)
                        _buildCategory(context, category),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(BuildContext context, EntryCategory category) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filter = _filters[category] ?? const _DiaryFilter();
    final hasFilters = filter.rating != null || filter.person != null;
    final entries = widget.viewModel.entriesIn(category).where((entry) {
      return (filter.rating == null || entry.rating == filter.rating) &&
          (filter.person == null || entry.people.contains(filter.person));
    }).toList();
    final text = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Entries', style: text.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      entries.length == 1
                          ? '1 entry'
                          : '${entries.length} entries',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Filter entries',
                child: OutlinedButton.icon(
                  style: hasFilters
                      ? OutlinedButton.styleFrom(
                          backgroundColor: scheme.surfaceContainerHigh,
                        )
                      : null,
                  onPressed: () => _openFilters(category),
                  icon: Icon(hasFilters ? Icons.tune : Icons.tune_outlined),
                  label: const Text('Filter'),
                ),
              ),
            ],
          ),
        ),
        if (hasFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (filter.rating case final rating?)
                  Chip(label: Text('Rating: $rating / 5')),
                if (filter.person case final person?)
                  Chip(
                    avatar: const Icon(Icons.person_outline, size: 14),
                    label: Text(person),
                  ),
                TextButton(
                  onPressed: () => setState(() => _filters.remove(category)),
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          ),
        Expanded(
          child: entries.isEmpty
              ? _EmptyState(filtered: hasFilters, category: category)
              : ListView.separated(
                  key: PageStorageKey(category),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => _EntryCard(
                    key: ValueKey(entries[index].id),
                    entry: entries[index],
                    viewModel: widget.viewModel,
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.filtered = false,
    this.analysis = false,
    this.category = EntryCategory.diary,
  });

  final bool filtered;
  final bool analysis;
  final EntryCategory category;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDream = category == EntryCategory.dream;
    final title = filtered
        ? 'No matching entries'
        : analysis
        ? 'No entries to analyze'
        : isDream
        ? 'No dreams yet'
        : 'Your story starts here';
    final message = filtered
        ? 'Change or clear your filters to see more entries.'
        : analysis
        ? 'Your writing patterns will appear here once you add an entry.'
        : isDream
        ? 'Write down a dream you remember.'
        : 'Write down a thought, a moment, or how today felt.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filtered
                        ? Icons.tune_outlined
                        : analysis
                        ? Icons.insights_outlined
                        : Icons.auto_stories_outlined,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _EntryAction { edit, delete }

class _EntryCard extends StatefulWidget {
  const _EntryCard({super.key, required this.entry, required this.viewModel});

  final DiaryEntry entry;
  final DiaryViewModel viewModel;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _focused = false;

  Future<void> _confirmDelete() async {
    final entry = widget.entry;
    final viewModel = widget.viewModel;
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: diaryAnimation(context),
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('“${entry.title}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await viewModel.remove(entry.id);
  }

  void _openEntry() => Navigator.of(context).push(
    diaryPageRoute(
      context,
      (_) =>
          NewEntryPage(viewModel: widget.viewModel, initialEntry: widget.entry),
    ),
  );

  void _selectAction(_EntryAction action) {
    switch (action) {
      case _EntryAction.edit:
        _openEntry();
      case _EntryAction.delete:
        _confirmDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    return Card(
      shape: _focused
          ? diaryCardShape.copyWith(
              side: BorderSide(color: scheme.primary, width: 2),
            )
          : null,
      child: Stack(
        children: [
          InkWell(
            onTap: _openEntry,
            onLongPress: _confirmDelete,
            onFocusChange: (focused) => setState(() => _focused = focused),
            hoverColor: scheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Row(
                      children: [
                        _MoodMark(mood: entry.mood),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDate(entry.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RatingMark(rating: entry.rating),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(entry.title, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    entry.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (entry.people.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _PeopleTags(people: entry.people),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: PopupMenuButton<_EntryAction>(
              tooltip: 'Entry actions',
              icon: const Icon(Icons.more_horiz),
              position: PopupMenuPosition.under,
              popUpAnimationStyle: diaryAnimation(context),
              onSelected: _selectAction,
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: _EntryAction.edit,
                  height: 42,
                  child: _MenuLabel(icon: Icons.edit_outlined, label: 'Edit'),
                ),
                PopupMenuItem(
                  value: _EntryAction.delete,
                  height: 42,
                  child: _MenuLabel(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: scheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: color)),
    ],
  );
}

class _MoodMark extends StatelessWidget {
  const _MoodMark({required this.mood});

  final Mood mood;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: mood.label,
    child: SizedBox.square(
      dimension: 28,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: diaryControlShape,
        ),
        child: Center(
          child: Text(mood.emoji, style: const TextStyle(fontSize: 16)),
        ),
      ),
    ),
  );
}

class _RatingMark extends StatelessWidget {
  const _RatingMark({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.star_rounded,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFDFC18B)
            : const Color(0xFF85602E),
      ),
      const SizedBox(width: 4),
      Text('$rating/5', style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _PeopleTags extends StatelessWidget {
  const _PeopleTags({required this.people});

  final List<String> people;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final person in people)
        Chip(
          avatar: Icon(
            Icons.person_outline,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          label: Text(person, overflow: TextOverflow.ellipsis),
        ),
    ],
  );
}

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({
    super.key,
    required this.viewModel,
    this.category = EntryCategory.diary,
  });

  final DiaryViewModel viewModel;
  final EntryCategory category;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  int? _days = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _PageBar(title: 'Analysis', leading: BackButton()),
      body: SafeArea(
        top: false,
        child: _ContentWidth(
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              final allEntries = widget.viewModel.entriesIn(widget.category);
              if (allEntries.isEmpty) return const _EmptyState(analysis: true);
              final analysis = DiaryAnalysis(
                allEntries,
                now: DateTime.now(),
                days: _days,
              );
              final entries = analysis.entries;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _PeriodPicker(
                    selected: _days,
                    onSelected: (days) => setState(() => _days = days),
                  ),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No entries in this period.'),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Entries',
                            value: '${entries.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Average rating',
                            value:
                                '${analysis.averageRating.toStringAsFixed(1)} / 5',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(analysis: analysis),
                    const SizedBox(height: 24),
                    const _SectionTitle('Rating trend'),
                    const SizedBox(height: 10),
                    _TrendChart(points: analysis.trend),
                    const SizedBox(height: 24),
                    _AnalysisPair(
                      first: _AnalysisSection(
                        title: 'Mood distribution',
                        child: _DistributionCard(
                          rows: [
                            for (final mood in Mood.values)
                              if ((analysis.moodCounts[mood] ?? 0) > 0)
                                _DistributionRow(
                                  label: '${mood.emoji} ${mood.label}',
                                  count: analysis.moodCounts[mood]!,
                                ),
                          ],
                        ),
                      ),
                      second: _AnalysisSection(
                        title: 'Rating distribution',
                        child: _DistributionCard(
                          rows: [
                            for (var rating = 1; rating <= 5; rating++)
                              _DistributionRow(
                                label: '$rating ${rating.emoji}',
                                count: analysis.ratingCounts[rating]!,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Writing habits'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Wrap(
                          spacing: 28,
                          runSpacing: 18,
                          children: [
                            _SmallStat(
                              'Current streak',
                              '${analysis.currentStreak} days',
                            ),
                            _SmallStat(
                              'Longest streak',
                              '${analysis.longestStreak} days',
                            ),
                            _SmallStat(
                              'Days this month',
                              '${analysis.daysWrittenThisMonth}',
                            ),
                            _SmallStat(
                              'Most active day',
                              analysis.mostActiveWeekday == null
                                  ? '—'
                                  : _weekdayName(analysis.mostActiveWeekday!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Days of the week'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            for (final day in analysis.weekdays)
                              _MetricBar(
                                label: _weekdayName(day.weekday),
                                value: day.averageRating,
                                max: 5,
                                trailing: day.entryCount == 0
                                    ? 'No data'
                                    : '${day.averageRating.toStringAsFixed(1)} · ${day.entryCount}',
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('People and their impact'),
                    const SizedBox(height: 8),
                    if (analysis.people.isEmpty)
                      const Text('Tag people in your entries to see them here.')
                    else
                      ...analysis.people.map(
                        (person) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_outline),

                            title: Text(person.name),
                            subtitle: Text(
                              '${person.entryCount} ${person.entryCount == 1 ? 'entry' : 'entries'} · '
                              '${person.topMood?.emoji ?? ''} ${person.topMood?.label ?? ''}'
                              '${person.entryCount < 3 ? ' · Limited data' : ''}',
                            ),
                            trailing: Text(
                              '${person.averageRating.toStringAsFixed(1)}\n'
                              '${_signed(person.averageRating - analysis.averageRating)}',
                              style: Theme.of(context).textTheme.labelMedium,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Writing intensity'),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.notes_outlined),
                            title: const Text('Average entry length'),
                            subtitle: Text(
                              '${analysis.averageWordCount.toStringAsFixed(0)} words'
                              '${analysis.wordCountChange == null ? '' : ' · ${_signed(analysis.wordCountChange!)} vs previous period'}',
                            ),
                          ),
                          if (analysis.longestEntry case final entry?)
                            ListTile(
                              leading: const Icon(Icons.article_outlined),
                              title: const Text('Longest entry'),
                              subtitle: Text(entry.title),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Most used words'),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: analysis.topWords.isEmpty
                            ? const Text(
                                'Write a little more to see recurring words.',
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final word in analysis.topWords)
                                    Chip(
                                      label: Text(
                                        '${word.word} · ${word.count}',
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnalysisPair extends StatelessWidget {
  const _AnalysisPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 560
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 20), second],
          ),
  );
}

class _AnalysisSection extends StatelessWidget {
  const _AnalysisSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_SectionTitle(title), const SizedBox(height: 8), child],
  );
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      for (final option in const [
        (7, '7 days'),
        (30, '30 days'),
        (90, '90 days'),
        (null, 'All time'),
      ])
        ChoiceChip(
          label: Text(option.$2),
          selected: selected == option.$1,
          chipAnimationStyle: _chipMotion(context),
          onSelected: (_) => onSelected(option.$1),
        ),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analysis});

  final DiaryAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final mood = analysis.moodCounts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final change = analysis.ratingChange;
    final count = analysis.entries.length;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: const Text('Period summary'),
        subtitle: Text(
          'You wrote $count ${count == 1 ? 'entry' : 'entries'}. Your average was '
          '${analysis.averageRating.toStringAsFixed(1)}/5'
          '${change == null ? '' : ' (${_signed(change)} vs previous period)'}. '
          'Your most common mood was ${mood.key.emoji} ${mood.key.label}.',
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = theme.textTheme.labelSmall;
    final labelSize = MediaQuery.textScalerOf(
      context,
    ).scale(label?.fontSize ?? 11);
    final slotWidth = math.max(42.0, labelSize * 4);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chart = SizedBox(
              width: math.max(constraints.maxWidth, slotWidth * points.length),
              height: 92 + labelSize * 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final point in points)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${_shortDate(point.date)} · ${point.averageRating.toStringAsFixed(1)}/5',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              point.averageRating.toStringAsFixed(1),
                              style: label,
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: point.averageRating / 5,
                                child: SizedBox(
                                  width: 24,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: scheme.tertiary,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _shortDate(point.date),
                              style: label?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
            if (slotWidth * points.length <= constraints.maxWidth) return chart;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chart,
            );
          },
        ),
      ),
    );
  }
}

class _DistributionRow {
  const _DistributionRow({required this.label, required this.count});

  final String label;
  final int count;
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.rows});

  final List<_DistributionRow> rows;

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (sum, row) => sum + row.count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (final row in rows)
              _MetricBar(
                label: row.label,
                value: row.count.toDouble(),
                max: total.toDouble(),
                trailing:
                    '${row.count} · ${total == 0 ? 0 : (row.count / total * 100).round()}%',
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.max,
    required this.trailing,
  });

  final String label;
  final double value;
  final double max;
  final String trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: max == 0 ? 0 : value / max,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 66,
          child: Text(
            trailing,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    ),
  );
}

class _SmallStat extends StatelessWidget {
  const _SmallStat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.availablePeople,
    required this.initialRating,
    required this.initialPerson,
  });

  final List<String> availablePeople;
  final int? initialRating;
  final String? initialPerson;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int? _rating = widget.initialRating;
  late String? _person = widget.initialPerson;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('Filter entries')),
              TextButton(
                onPressed: () => Navigator.pop(context, const _DiaryFilter()),
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  _DiaryFilter(rating: _rating, person: _person),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _FieldLabel('Day rating'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                chipAnimationStyle: _chipMotion(context),
                label: const Text('Any'),
                selected: _rating == null,
                onSelected: (_) => setState(() => _rating = null),
              ),
              for (var rating = 1; rating <= 5; rating++)
                FilterChip(
                  chipAnimationStyle: _chipMotion(context),
                  label: Text('$rating ${rating.emoji}'),
                  selected: _rating == rating,
                  onSelected: (_) => setState(() => _rating = rating),
                ),
            ],
          ),
          if (widget.availablePeople.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _FieldLabel('Person'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  chipAnimationStyle: _chipMotion(context),
                  label: const Text('Everyone'),
                  selected: _person == null,
                  onSelected: (_) => setState(() => _person = null),
                ),
                ...widget.availablePeople.map(
                  (person) => FilterChip(
                    chipAnimationStyle: _chipMotion(context),
                    label: Text(person),
                    selected: _person == person,
                    onSelected: (_) => setState(() => _person = person),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DiaryFilter {
  const _DiaryFilter({this.rating, this.person});

  final int? rating;
  final String? person;
}

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({
    super.key,
    required this.viewModel,
    this.initialEntry,
    this.initialCategory = EntryCategory.diary,
  });

  final DiaryViewModel viewModel;
  final DiaryEntry? initialEntry;
  final EntryCategory initialCategory;

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  late final _titleController = TextEditingController(
    text: widget.initialEntry?.title,
  );
  late final _bodyController = TextEditingController(
    text: widget.initialEntry?.body,
  );
  late _EntryDetails _details = _EntryDetails(
    mood: widget.initialEntry?.mood ?? Mood.disappointed,
    rating: widget.initialEntry?.rating ?? 3,
    people: widget.initialEntry?.people ?? const [],
  );
  late EntryCategory _category =
      widget.initialEntry?.category ?? widget.initialCategory;
  bool _saving = false;

  bool get _isEditing => widget.initialEntry != null;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _finishEntry() async {
    FocusScope.of(context).unfocus();
    final details = await showDiaryPanel<_EntryDetails>(
      context,
      _EntryDetailsSheet(
        availablePeople: widget.viewModel.people,
        initialDetails: _details,
      ),
      bottomSheet: true,
    );
    if (details == null || !mounted) return;
    _details = details;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (!_formKey.currentState!.validate()) {
      (title.isEmpty ? _titleFocus : _bodyFocus).requestFocus();
      return;
    }

    setState(() => _saving = true);
    final existingEntry = widget.initialEntry;
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: existingEntry?.id ?? now.microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: existingEntry?.createdAt ?? now,
      mood: details.mood,
      rating: details.rating,
      people: details.people,
      category: _category,
    );
    if (_isEditing) {
      await widget.viewModel.update(entry);
    } else {
      await widget.viewModel.add(entry);
    }
    if (mounted) Navigator.pop(context, _category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bodyBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return Scaffold(
      appBar: _PageBar(
        title: _isEditing ? 'Edit entry' : 'New entry',
        maxWidth: 740,
        leading: const BackButton(),
        actions: [
          IconButton.filled(
            tooltip: 'Entry details',
            onPressed: _saving ? null : _finishEntry,
            style: theme.filledButtonTheme.style,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _ContentWidth(
          maxWidth: 740,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              child: SizedBox(
                height: math.max(240, constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isEditing) ...[
                          SegmentedButton<EntryCategory>(
                            style: const ButtonStyle(
                              shape: WidgetStatePropertyAll(diaryControlShape),
                            ),
                            segments: const [
                              ButtonSegment(
                                value: EntryCategory.diary,
                                label: Text('Diary'),
                              ),
                              ButtonSegment(
                                value: EntryCategory.dream,
                                label: Text('Dream'),
                              ),
                            ],
                            selected: {_category},
                            showSelectedIcon: false,
                            onSelectionChanged: _saving
                                ? null
                                : (selection) => setState(
                                    () => _category = selection.single,
                                  ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextFormField(
                          controller: _titleController,
                          focusNode: _titleFocus,
                          autofocus: !_isEditing,
                          readOnly: _saving,
                          style: theme.textTheme.titleLarge,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: _bodyFocus.requestFocus,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (value) => value!.trim().isEmpty
                              ? 'Please add a title'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _bodyController,
                            focusNode: _bodyFocus,
                            readOnly: _saving,
                            expands: true,
                            maxLines: null,
                            style: theme.textTheme.bodyLarge,
                            textCapitalization: TextCapitalization.sentences,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: 'Write freely…',
                              fillColor: scheme.surface,
                              contentPadding: const EdgeInsets.all(16),
                              enabledBorder: bodyBorder,
                              focusedBorder: bodyBorder.copyWith(
                                borderSide: BorderSide(
                                  color: scheme.outline,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) => value!.trim().isEmpty
                                ? 'Write something before saving.'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryDetailsSheet extends StatefulWidget {
  const _EntryDetailsSheet({
    required this.availablePeople,
    required this.initialDetails,
  });

  final List<String> availablePeople;
  final _EntryDetails initialDetails;

  @override
  State<_EntryDetailsSheet> createState() => _EntryDetailsSheetState();
}

class _EntryDetailsSheetState extends State<_EntryDetailsSheet> {
  final _newPersonController = TextEditingController();
  late final List<String> _people = {
    ...widget.availablePeople,
    ...widget.initialDetails.people,
  }.toList();
  late final Set<String> _selectedPeople = widget.initialDetails.people.toSet();
  late Mood _mood = widget.initialDetails.mood;
  late double _rating = widget.initialDetails.rating.toDouble();

  @override
  void dispose() {
    _newPersonController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _newPersonController.text.trim();
    final existing = _people.firstWhere(
      (person) => person.toLowerCase() == name.toLowerCase(),
      orElse: () => '',
    );
    if (name.isEmpty) return;
    setState(() {
      if (existing.isEmpty) _people.add(name);
      _selectedPeople.add(existing.isEmpty ? name : existing);
      _newPersonController.clear();
    });
  }

  void _save() {
    Navigator.pop(
      context,
      _EntryDetails(
        mood: _mood,
        rating: _rating.round(),
        people: List.unmodifiable(_selectedPeople),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              const Expanded(child: _SectionTitle('Entry details')),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Mood'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: Mood.values
                      .map(
                        (mood) => ChoiceChip(
                          selected: _mood == mood,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _mood = mood),
                          chipAnimationStyle: _chipMotion(context),
                          label: Text('${mood.emoji} ${mood.label}'),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: _FieldLabel('Day rating')),
                    Text(
                      '${_rating.round()} / 5 ${_rating.round().emoji}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _rating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _rating.round().toString(),
                  onChanged: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: 14),
                const _FieldLabel('People'),
                if (_people.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _people
                        .map(
                          (person) => FilterChip(
                            chipAnimationStyle: _chipMotion(context),
                            label: Text(person),
                            selected: _selectedPeople.contains(person),
                            onSelected: (selected) => setState(
                              () => selected
                                  ? _selectedPeople.add(person)
                                  : _selectedPeople.remove(person),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _newPersonController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addPerson(),
                  decoration: InputDecoration(
                    hintText: 'Add person',
                    suffixIcon: IconButton(
                      tooltip: 'Add person',
                      onPressed: _addPerson,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryDetails {
  const _EntryDetails({
    required this.mood,
    required this.rating,
    required this.people,
  });

  final Mood mood;
  final int rating;
  final List<String> people;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: .45,
    ),
  );
}

ChipAnimationStyle _chipMotion(BuildContext context) {
  final animation = diaryAnimation(context);
  return ChipAnimationStyle(
    selectAnimation: animation,
    enableAnimation: animation,
    avatarDrawerAnimation: animation,
    deleteDrawerAnimation: animation,
  );
}

extension on Mood {
  String get emoji =>
      const ['😞', '🤒', '😔', '😠', '😰', '😴', '😐', '😌', '😊', '🤩'][index];

  String get label => const [
    'Disappointed',
    'Sick',
    'Depressed',
    'Angry',
    'Anxious',
    'Tired',
    'Neutral',
    'Calm',
    'Happy',
    'Excited',
  ][index];
}

extension on int {
  String get emoji => const ['😞', '🙁', '😐', '🙂', '😊'][this - 1];
}

String _formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final year = date.year == DateTime.now().year ? '' : ', ${date.year}';
  return '${months[date.month - 1]} ${date.day}$year';
}

String _shortDate(DateTime date) => '${date.day}/${date.month}';

String _signed(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}';

String _weekdayName(int weekday) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][weekday - 1];
