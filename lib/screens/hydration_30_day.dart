import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:intl/intl.dart';

import '../helpers/database_helper.dart';

/// A simple page that queries the last 30 days of hydration_day_summaries
/// and displays them in a table format: Date | Target (ml) | Consumed (ml) | %
///
/// Dependencies:
/// - intl (for DateFormat) -> add to pubspec.yaml if not present
///
class Hydration30DayPage extends StatefulWidget {
  const Hydration30DayPage({super.key});

  @override
  _Hydration30DayPageState createState() => _Hydration30DayPageState();
}

class _Hydration30DayPageState extends State<Hydration30DayPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  bool _loading = true;
  List<HydrationDaySummary> _rows = [];

  double waterGoal = 0;

  @override
  void initState() {
    super.initState();
    _loadLast30Days();
    getWaterGoal();
  }

  Future<void> getWaterGoal() async {
    waterGoal = (await SharedPrefsHelper.getUserGoal() ?? 0).toDouble();
  }

  Future<void> _loadLast30Days() async {
    setState(() {
      _loading = true;
    });

    // get all rows (may be 0..N)
    final List<HydrationDaySummary> fetchedAll =
        await _dbHelper.getHydrationSummariesForRange();

    // sort by date ascending (just in case)
    fetchedAll.sort((a, b) => a.date.compareTo(b.date));

    // take the last 30 rows (most recent). If fewer than 30, take all available.
    final int takeCount = fetchedAll.length >= 30 ? 30 : fetchedAll.length;
    final List<HydrationDaySummary> latest = fetchedAll.isEmpty
        ? <HydrationDaySummary>[]
        : fetchedAll.sublist(fetchedAll.length - takeCount, fetchedAll.length);

    // If you want the UI newest->oldest use reversed order, else keep as ascending
    // Here we keep ascending (oldest -> newest). If you prefer newest first, uncomment below:
    // latest = latest.reversed.toList();

    // Assign directly — no null-bangs, no checks
    if (!mounted) return;
    setState(() {
      _rows = latest;
      _loading = false;
    });
  }

  Future<void> _onRefresh() async => _loadLast30Days();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BleCubit, BleState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('30-Day Hydration History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _onRefresh,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bottle data: ${state.bottleData}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Current TS : ${state.ts == null ? "--" : DateFormat('yyyy-MM-dd HH:mm:ss').format(state.ts!.toLocal())}",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Slot data: ${state.slotData}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hydration data: ${state.historyData}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Date | Target (ml) | Consumed (ml) | %',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(1),
                                3: FlexColumnWidth(1),
                              },
                              border: TableBorder.symmetric(
                                inside: const BorderSide(
                                    width: 0.5, color: Colors.grey),
                                outside: const BorderSide(
                                    width: 0.5, color: Colors.grey),
                              ),
                              children: [
                                // header row
                                TableRow(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.02)),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Date',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Target',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Consumed',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('%',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                // data rows
                                ..._rows.map((r) {
                                  final pct = waterGoal > 0
                                      ? ((r.consumed / waterGoal) * 100)
                                          .clamp(0, 999)
                                          .toDouble()
                                      : 0.0;
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(_dateFmt.format(r.date)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child:
                                            Text(waterGoal.toStringAsFixed(0)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child:
                                            Text(r.consumed.toStringAsFixed(0)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(r.target > 0
                                            ? '${pct.toStringAsFixed(0)}%'
                                            : '-'),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    // Simple CSV exporter — you can replace with share/save logic
    final sb = StringBuffer();
    sb.writeln('date,target,consumed,percent');
    for (final r in _rows) {
      final pct = r.target > 0
          ? ((r.consumed / r.target) * 100).clamp(0, 999).toDouble()
          : 0.0;
      sb.writeln(
          '${_dateFmt.format(r.date)},${r.target.toStringAsFixed(0)},${r.consumed.toStringAsFixed(0)},${r.target > 0 ? pct.toStringAsFixed(0) : ''}');
    }

    // For now just print the CSV to log. Integrate with path_provider + share to save file.
    // Example: final file = await File('${(await getTemporaryDirectory()).path}/hydration_30days.csv').writeAsString(sb.toString());
    // then Share.shareFiles([file.path]);

    // DEBUG: print
    // ignore: avoid_print
    print(sb.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('CSV exported to console (developer debug).')));
  }
}
