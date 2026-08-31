import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/device_other_data.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:intl/intl.dart';

import '../helpers/database_helper.dart';

/// A simple page that queries the last 30 days of hydration_day_summaries
/// and displays them in a table format: Date | Target (ml) | Consumed (ml) | %
/// Also displays device configuration & slot schedules received via otherDataUUID (6E40000C).
class Hydration30DayPage extends StatefulWidget {
  const Hydration30DayPage({super.key});

  @override
  State<Hydration30DayPage> createState() => _Hydration30DayPageState();
}

class _Hydration30DayPageState extends State<Hydration30DayPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');
  final DateFormat _dateTimeFmt = DateFormat('yyyy-MM-dd HH:mm:ss');
  final DateFormat _timeFmt = DateFormat('hh:mm a');

  bool _loading = true;
  List<HydrationDaySummary> _rows = [];

  double waterGoal = 0;

  @override
  void initState() {
    super.initState();
    _loadLast30Days();
    getWaterGoal();
    context.read<BleCubit>().readOtherData();
  }

  Future<void> getWaterGoal() async {
    waterGoal = (await SharedPrefsHelper.getUserGoal() ?? 0).toDouble();
  }

  Future<void> _loadLast30Days() async {
    setState(() {
      _loading = true;
    });

    final List<HydrationDaySummary> fetchedAll =
        await _dbHelper.getHydrationSummariesForRange();

    fetchedAll.sort((a, b) => a.date.compareTo(b.date));

    final int takeCount = fetchedAll.length >= 30 ? 30 : fetchedAll.length;
    final List<HydrationDaySummary> latest = fetchedAll.isEmpty
        ? <HydrationDaySummary>[]
        : fetchedAll.sublist(fetchedAll.length - takeCount, fetchedAll.length);

    if (!mounted) return;
    setState(() {
      _rows = latest;
      _loading = false;
    });
  }

  Future<void> _onRefresh() async {
    await _loadLast30Days();
    if (mounted) {
      await context.read<BleCubit>().readOtherData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BleCubit, BleState>(
      listener: (context, state) {
        if (state.parsed30DaysList.isEmpty) {
          _loadLast30Days();
        }
      },
      child: BlocBuilder<BleCubit, BleState>(
        builder: (context, state) {
          final displayRows = state.parsed30DaysList.isNotEmpty
              ? state.parsed30DaysList
              : _rows;

          final otherData = state.parsedOtherData ??
              (state.otherData != null &&
                      state.otherData.toString().trim().isNotEmpty
                  ? DeviceOtherData.fromString(state.otherData.toString())
                  : null);

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('30-Day Hydration History'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _exportCsv,
                  tooltip: 'Export CSV',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _onRefresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            body: (_loading && state.parsed30DaysList.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bottle data: ${state.bottleData}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Current TS : ${state.ts == null ? "--" : _dateTimeFmt.format(state.ts!.toLocal())}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Slot data: ${state.slotData}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hydration data: ${state.historyData}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Other data (6E40000C): ${state.otherData ?? "--"}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                          if (otherData != null &&
                              (otherData.version != null ||
                                  otherData.hwVersion != null ||
                                  otherData.programmedAt != null ||
                                  otherData.slots.isNotEmpty)) ...[
                            const SizedBox(height: 12),
                            Card(
                              elevation: 2,
                              color: const Color(0xFFF8FAFC),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Device Config & Slots (Other Data)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            otherData.version != null
                                                ? (otherData.version!
                                                        .startsWith('v')
                                                    ? otherData.version!
                                                    : 'v${otherData.version}')
                                                : 'v1.0.0',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'HW Version: ${otherData.hwVersion != null ? "HW ${otherData.hwVersion}" : "--"}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    Text(
                                      'Programmed At: ${otherData.programmedAtDateTime != null ? DateFormat('dd MMM yyyy, hh:mm a').format(otherData.programmedAtDateTime!) : (otherData.programmedAt?.toString() ?? "--")}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Slots Schedule:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    () {
                                      final displaySlots =
                                          otherData.slots.isNotEmpty
                                              ? otherData.slots
                                              : (state.otherData != null
                                                  ? DeviceOtherData.fromString(
                                                          state.otherData
                                                              .toString())
                                                      .slots
                                                  : <DeviceSlotSchedule>[]);
                                      if (displaySlots.isEmpty) {
                                        return const Text(
                                            'No slots in payload');
                                      }
                                      return Table(
                                        columnWidths: const {
                                          0: FlexColumnWidth(0.6),
                                          1: FlexColumnWidth(1.8),
                                          2: FlexColumnWidth(1.4),
                                          3: FlexColumnWidth(1.4),
                                        },
                                        border: TableBorder.all(
                                          color: Colors.grey.shade300,
                                          width: 0.5,
                                        ),
                                        children: [
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                            ),
                                            children: const [
                                              Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Text('#',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12)),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Text('Name',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12)),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Text('Start',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12)),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Text('End',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12)),
                                              ),
                                            ],
                                          ),
                                          ...displaySlots.map((s) {
                                            final startStr = s.startDateTime !=
                                                    null
                                                ? _timeFmt
                                                    .format(s.startDateTime!)
                                                : (s.start > 0
                                                    ? s.start.toString()
                                                    : '--');
                                            final endStr = s.endDateTime != null
                                                ? _timeFmt
                                                    .format(s.endDateTime!)
                                                : (s.end > 0
                                                    ? s.end.toString()
                                                    : '--');
                                            return TableRow(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text('${s.index}',
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text(s.name,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text(startStr,
                                                      style: const TextStyle(
                                                          fontSize: 11)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6.0),
                                                  child: Text(endStr,
                                                      style: const TextStyle(
                                                          fontSize: 11)),
                                                ),
                                              ],
                                            );
                                          }),
                                        ],
                                      );
                                    }(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date | Target (ml) | Consumed (ml) | %',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
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
                                      TableRow(
                                        decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withValues(alpha: 0.02)),
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text('Date',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text('Target',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text('Consumed',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text('%',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      ...displayRows.map((r) {
                                        final pct = waterGoal > 0
                                            ? ((r.consumed / waterGoal) * 100)
                                                .clamp(0, 999)
                                                .toDouble()
                                            : 0.0;
                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child:
                                                  Text(_dateFmt.format(r.date)),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  r.target.toStringAsFixed(0)),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(r.consumed
                                                  .toStringAsFixed(0)),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(r.target > 0
                                                  ? '${pct.toStringAsFixed(0)}%'
                                                  : '-'),
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _exportCsv() async {
    final sb = StringBuffer();
    sb.writeln('date,target,consumed,percent');
    for (final r in _rows) {
      final pct = r.target > 0
          ? ((r.consumed / r.target) * 100).clamp(0, 999).toDouble()
          : 0.0;
      sb.writeln(
          '${_dateFmt.format(r.date)},${r.target.toStringAsFixed(0)},${r.consumed.toStringAsFixed(0)},${r.target > 0 ? pct.toStringAsFixed(0) : ''}');
    }

    // ignore: avoid_print
    print(sb.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('CSV exported to console (developer debug).')));
  }
}
