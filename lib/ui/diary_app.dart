import 'package:flutter/material.dart';

import '../domain/diary_analysis.dart';
import '../domain/diary_entry.dart';
import 'diary_view_model.dart';

const _accent = Color(0xFF576B5E);

class DiaryApp extends StatefulWidget {
  const DiaryApp({super.key, required this.viewModel});

  final DiaryViewModel viewModel;

  @override
  State<DiaryApp> createState() => _DiaryAppState();
}

class _DiaryAppState extends State<DiaryApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quietly',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: DiaryHomePage(
        viewModel: widget.viewModel,
        isDark: _themeMode == ThemeMode.dark,
        onThemeChanged: () => setState(
          () => _themeMode = _themeMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F7F4)
          : const Color(0xFF121412),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1C201D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: .45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({
    super.key,
    required this.viewModel,
    required this.isDark,
    required this.onThemeChanged,
  });

  final DiaryViewModel viewModel;
  final bool isDark;
  final VoidCallback onThemeChanged;

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  int? _ratingFilter;
  String? _personFilter;

  Future<void> _openFilters() async {
    final filter = await showModalBottomSheet<_DiaryFilter>(
      context: context,
      useSafeArea: true,
      builder: (_) => _FilterSheet(
        availablePeople: widget.viewModel.people,
        initialRating: _ratingFilter,
        initialPerson: _personFilter,
      ),
    );
    if (filter == null) return;
    setState(() {
      _ratingFilter = filter.rating;
      _personFilter = filter.person;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quietly',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Analysis',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnalysisPage(viewModel: widget.viewModel),
              ),
            ),
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: 'Filter entries',
            onPressed: _openFilters,
            icon: Icon(
              _ratingFilter != null || _personFilter != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
          ),
          IconButton(
            tooltip: widget.isDark ? 'Use light theme' : 'Use dark theme',
            onPressed: widget.onThemeChanged,
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final entries = widget.viewModel.entries.where((entry) {
            final matchesRating =
                _ratingFilter == null || entry.rating == _ratingFilter;
            final matchesPerson =
                _personFilter == null || entry.people.contains(_personFilter);
            return matchesRating && matchesPerson;
          }).toList();
          if (entries.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) =>
                _EntryCard(entry: entries[index], viewModel: widget.viewModel),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'New entry',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewEntryPage(viewModel: widget.viewModel),
          ),
        ),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New entry'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 46,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 18),
            Text(
              'Your story starts here',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Write down a thought, a moment, or simply how today felt.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.viewModel});

  final DiaryEntry entry;
  final DiaryViewModel viewModel;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Are you sure you want to delete “${entry.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await viewModel.remove(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EntryReadPage(entry: entry, viewModel: viewModel),
          ),
        ),
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(entry.mood.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatDate(entry.createdAt),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: Color(0xFF9A7A42),
                  ),
                  const SizedBox(width: 4),
                  Text('${entry.rating}/5 ${entry.rating.emoji}'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                entry.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                entry.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (entry.people.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: entry.people
                      .map(
                        (person) => Chip(
                          avatar: const Icon(Icons.person_outline, size: 16),
                          label: Text(person),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EntryReadPage extends StatefulWidget {
  const EntryReadPage({
    super.key,
    required this.entry,
    required this.viewModel,
  });

  final DiaryEntry entry;
  final DiaryViewModel viewModel;

  @override
  State<EntryReadPage> createState() => _EntryReadPageState();
}

class _EntryReadPageState extends State<EntryReadPage> {
  late DiaryEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NewEntryPage(viewModel: widget.viewModel, initialEntry: _entry),
      ),
    );
    if (!mounted) return;
    final updated = widget.viewModel.entries.firstWhere(
      (entry) => entry.id == _entry.id,
      orElse: () => _entry,
    );
    setState(() => _entry = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading'),
        actions: [
          IconButton(
            tooltip: 'Edit entry',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
        children: [
          Text(
            _formatDate(_entry.createdAt),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(_entry.mood.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Text(
                _entry.mood.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${_entry.rating}/5 ${_entry.rating.emoji}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _entry.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          SelectableText(
            _entry.body,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.65),
          ),
          if (_entry.people.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _SectionTitle('People'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _entry.people
                  .map(
                    (person) => Chip(
                      avatar: const Icon(Icons.person_outline, size: 16),
                      label: Text(person),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key, required this.viewModel});

  final DiaryViewModel viewModel;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  int? _days = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final allEntries = widget.viewModel.entries;
          if (allEntries.isEmpty) return const _EmptyState();
          final analysis = DiaryAnalysis(
            allEntries,
            now: DateTime.now(),
            days: _days,
          );
          final entries = analysis.entries;
          if (entries.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _PeriodPicker(
                    selected: _days,
                    onSelected: (days) => setState(() => _days = days),
                  ),
                ),
                const Expanded(
                  child: Center(child: Text('No entries in this period.')),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _PeriodPicker(
                selected: _days,
                onSelected: (days) => setState(() => _days = days),
              ),
              const SizedBox(height: 18),
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
                      value: '${analysis.averageRating.toStringAsFixed(1)} / 5',
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
              const _SectionTitle('Mood distribution'),
              const SizedBox(height: 10),
              _DistributionCard(
                rows: [
                  for (final mood in Mood.values)
                    if ((analysis.moodCounts[mood] ?? 0) > 0)
                      _DistributionRow(
                        label: '${mood.emoji} ${mood.label}',
                        count: analysis.moodCounts[mood]!,
                      ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Rating distribution'),
              const SizedBox(height: 10),
              _DistributionCard(
                rows: [
                  for (var rating = 1; rating <= 5; rating++)
                    _DistributionRow(
                      label: '$rating ${rating.emoji}',
                      count: analysis.ratingCounts[rating]!,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Writing habits'),
              const SizedBox(height: 10),
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
              const SizedBox(height: 24),
              const _SectionTitle('Days of the week'),
              const SizedBox(height: 10),
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
              const SizedBox(height: 24),
              const _SectionTitle('People and their impact'),
              const SizedBox(height: 10),
              if (analysis.people.isEmpty)
                const Text('Tag people in your entries to see them here.')
              else
                ...analysis.people.map(
                  (person) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(person.name.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(person.name),
                      subtitle: Text(
                        '${person.entryCount} ${person.entryCount == 1 ? 'entry' : 'entries'} · '
                        '${person.topMood?.emoji ?? ''} ${person.topMood?.label ?? ''}'
                        '${person.entryCount < 3 ? ' · Limited data' : ''}',
                      ),
                      trailing: Text(
                        '${person.averageRating.toStringAsFixed(1)}\n'
                        '${_signed(person.averageRating - analysis.averageRating)}',
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const _SectionTitle('Writing intensity'),
              const SizedBox(height: 10),
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
              const SizedBox(height: 24),
              const _SectionTitle('Most used words'),
              const SizedBox(height: 10),
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
                              Chip(label: Text('${word.word} · ${word.count}')),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final option in const [
        (7, '7 days'),
        (30, '30 days'),
        (90, '90 days'),
      ])
        ChoiceChip(
          label: Text(option.$2),
          selected: selected == option.$1,
          onSelected: (_) => onSelected(option.$1),
        ),
      ChoiceChip(
        label: const Text('All time'),
        selected: selected == null,
        onSelected: (_) => onSelected(null),
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
    return Card(
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: const Text('Period summary'),
        subtitle: Text(
          'You wrote ${analysis.entries.length} entries. Your average was '
          '${analysis.averageRating.toStringAsFixed(1)}/5'
          '${change == null ? '' : ' (${_signed(change)} vs previous period)'}; '
          'your most common mood was ${mood.key.emoji} ${mood.key.label}.',
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) => Card(
    child: SizedBox(
      height: 160,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final point in points)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Tooltip(
                    message:
                        '${_shortDate(point.date)} · ${point.averageRating.toStringAsFixed(1)}/5',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          point.averageRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: point.averageRating / 5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${point.date.day}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
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
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: max == 0 ? 0 : value / max,
            minHeight: 9,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 72, child: Text(trailing, textAlign: TextAlign.end)),
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
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: _SectionTitle('Filter entries')),
              TextButton(
                onPressed: () => Navigator.pop(context, const _DiaryFilter()),
                child: const Text('Clear'),
              ),
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
          const _SectionTitle('Day rating'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Any'),
                selected: _rating == null,
                onSelected: (_) => setState(() => _rating = null),
              ),
              for (var rating = 1; rating <= 5; rating++)
                FilterChip(
                  label: Text('$rating ${rating.emoji}'),
                  selected: _rating == rating,
                  onSelected: (_) => setState(() => _rating = rating),
                ),
            ],
          ),
          if (widget.availablePeople.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionTitle('Person'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Everyone'),
                  selected: _person == null,
                  onSelected: (_) => setState(() => _person = null),
                ),
                ...widget.availablePeople.map(
                  (person) => FilterChip(
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
  const NewEntryPage({super.key, required this.viewModel, this.initialEntry});

  final DiaryViewModel viewModel;
  final DiaryEntry? initialEntry;

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  final _bodyController = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    _bodyController.text = widget.initialEntry?.body ?? '';
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _finishEntry() async {
    if (_saving) return;
    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before saving.')),
      );
      return;
    }

    final details = await showModalBottomSheet<_EntryDetails>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EntryDetailsSheet(
        availablePeople: widget.viewModel.people,
        initialEntry: widget.initialEntry,
      ),
    );
    if (details == null || !mounted) return;

    setState(() => _saving = true);
    final existingEntry = widget.initialEntry;
    final entry = DiaryEntry(
      id: existingEntry?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: details.title,
      body: _bodyController.text.trim(),
      createdAt: existingEntry?.createdAt ?? DateTime.now(),
      mood: details.mood,
      rating: details.rating,
      people: details.people,
    );
    if (_isEditing) {
      await widget.viewModel.update(entry);
    } else {
      await widget.viewModel.add(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit entry' : 'New entry'),
        actions: [
          IconButton(
            tooltip: 'Save entry',
            onPressed: _saving ? null : _finishEntry,
            icon: const Icon(Icons.check),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: TextField(
          controller: _bodyController,
          autofocus: true,
          expands: true,
          maxLines: null,
          minLines: null,
          textCapitalization: TextCapitalization.sentences,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            hintText: 'Write freely…',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.fromLTRB(20, 12, 20, 20),
          ),
        ),
      ),
    );
  }
}

class _EntryDetailsSheet extends StatefulWidget {
  const _EntryDetailsSheet({required this.availablePeople, this.initialEntry});

  final List<String> availablePeople;
  final DiaryEntry? initialEntry;

  @override
  State<_EntryDetailsSheet> createState() => _EntryDetailsSheetState();
}

class _EntryDetailsSheetState extends State<_EntryDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _newPersonController = TextEditingController();
  late final List<String> _people = [...widget.availablePeople];
  final Set<String> _selectedPeople = {};
  late Mood _mood;
  late double _rating;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _titleController.text = entry?.title ?? '';
    _mood = entry?.mood ?? Mood.disappointed;
    _rating = (entry?.rating ?? 3).toDouble();
    _selectedPeople.addAll(entry?.people ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _EntryDetails(
        title: _titleController.text.trim(),
        mood: _mood,
        rating: _rating.round(),
        people: List.unmodifiable(_selectedPeople),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: _SectionTitle('Finish entry')),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Give today a name',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please add a title'
                    : null,
              ),
              const SizedBox(height: 24),
              const _SectionTitle('How do you feel?'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Mood.values
                    .map(
                      (mood) => ChoiceChip(
                        selected: _mood == mood,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _mood = mood),
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mood.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 3),
                            Text(mood.label),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: _SectionTitle('Day rating')),
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
              const _SectionTitle('People'),
              if (_people.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _people
                      .map(
                        (person) => FilterChip(
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
    );
  }
}

class _EntryDetails {
  const _EntryDetails({
    required this.title,
    required this.mood,
    required this.rating,
    required this.people,
  });

  final String title;
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
