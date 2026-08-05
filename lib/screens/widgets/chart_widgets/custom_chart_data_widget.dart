import 'dart:convert';

import 'package:hydrify/helpers/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/cubit/bottle/bottle_data_cubit.dart';
import 'package:hydrify/cubit/filter/filter_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/hydration_summary.dart';
import 'package:hydrify/screens/widgets/chart_widgets/column_chart_widget.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/sync_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomChartDataWidget extends StatefulWidget {
  const CustomChartDataWidget({super.key});

  @override
  State<CustomChartDataWidget> createState() => _CustomChartDataWidgetState();
}

class _CustomChartDataWidgetState extends State<CustomChartDataWidget>
    with AutomaticKeepAliveClientMixin {

  final ApiService _apiService = ApiService();

  // ── Cached-future bookkeeping ─────────────────────────────────────────────
  Future<List<dynamic>>? _cachedFuture;
  String _lastCacheKey = '';

  // SharedPreferences namespace for chart API cache
  static const String _cachePrefix = 'chart_summaries_';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    SyncBus.instance.addListener(_onSyncComplete);
  }

  @override
  void dispose() {
    SyncBus.instance.removeListener(_onSyncComplete);
    super.dispose();
  }

  /// Called whenever syncAll() succeeds. Clears the cache key so the next
  /// build triggers a fresh server fetch instead of reusing the old future.
  void _onSyncComplete() {
    if (!mounted) return;
    setState(() {
      _lastCacheKey = ''; // invalidate — forces new future on next build
    });
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  (DateTime start, DateTime end) _datesFor(FilterState filterState) {
    final current = filterState.currentDate;

    if (filterState.currentInterval == FilterInterval.weekly) {
      final weekStart = DateTime(
        current.year,
        current.month,
        current.day - (current.weekday - 1),
      );
      final weekEnd = weekStart.add(const Duration(days: 6));
      return (
        weekStart,
        DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59, 999999),
      );
    } else if (filterState.currentInterval == FilterInterval.monthly) {
      final start = DateTime(current.year, current.month, 1);
      final end = DateTime(current.year, current.month + 1, 1)
          .subtract(const Duration(microseconds: 1));
      return (start, end);
    } else if (filterState.currentInterval == FilterInterval.yearly) {
      final start = DateTime(current.year, 1, 1);
      final end = DateTime(current.year + 1, 1, 1)
          .subtract(const Duration(microseconds: 1));
      return (start, end);
    } else {
      final start = DateTime(current.year, current.month, current.day);
      final end = DateTime(
          current.year, current.month, current.day, 23, 59, 59, 999999);
      return (start, end);
    }
  }

  String _cacheKeyFor(FilterState filterState) {
    final (start, end) = _datesFor(filterState);
    return '${filterState.currentInterval}_'
        '${start.millisecondsSinceEpoch}_'
        '${end.millisecondsSinceEpoch}';
  }

  // ── Persistent (SharedPreferences) cache helpers ──────────────────────────

  /// Persist a successful server result so it can be shown when offline.
  Future<void> _saveToCache(
      String key, List<HydrationDaySummary> summaries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = summaries
          .map((s) => {
                'date': s.date.toIso8601String(),
                'dayIndex': s.dayIndex,
                'target': s.target,
                'consumed': s.consumed,
                'isPerfect': s.isPerfect,
                'deviceId': s.deviceId,
                'createdAt': s.createdAt.toIso8601String(),
                'updatedAt': s.updatedAt?.toIso8601String(),
              })
          .toList();
      await prefs.setString('$_cachePrefix$key', jsonEncode(jsonList));
      Console.log(
          tag: 'ChartWidget',
          value: 'Cache SAVED for key=$key (${summaries.length} items)');
    } catch (e) {
      Console.log(tag: 'ChartWidget', value: 'Cache save failed: $e');
    }
  }

  /// Read a previously persisted result. Returns null when nothing is cached.
  Future<List<HydrationDaySummary>?> _loadFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$key');
      if (raw == null) return null;

      final list = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(HydrationDaySummary.fromServerMap)
          .toList();

      Console.log(
          tag: 'ChartWidget',
          value: 'Cache HIT for key=$key (${list.length} items)');
      return list;
    } catch (e) {
      Console.log(tag: 'ChartWidget', value: 'Cache read failed: $e');
      return null;
    }
  }

  // ── Future management ─────────────────────────────────────────────────────

  Future<List<dynamic>> _buildFuture(
      FilterState filterState, BuildContext ctx) {
    final key = _cacheKeyFor(filterState);
    if (key == _lastCacheKey && _cachedFuture != null) {
      return _cachedFuture!;
    }

    final (startDate, endDate) = _datesFor(filterState);
    Console.log(
        tag: 'ChartWidget',
        value: 'Cache miss — rebuilding future [$key]  '
            'start=$startDate  end=$endDate');

    _lastCacheKey = key;
    _cachedFuture = Future.wait([
      _fetchSummaries(key, startDate, endDate, ctx),
      SharedPrefsHelper.getUserGoal(),
    ]);
    return _cachedFuture!;
  }

  /// Fetch order:
  ///   1. Server API  →  save to persistent cache
  ///   2. Persistent cache (offline / server error)
  ///   3. Local SQLite DB (last resort)
  Future<List<HydrationDaySummary>> _fetchSummaries(
    String cacheKey,
    DateTime startDate,
    DateTime endDate,
    BuildContext ctx,
  ) async {
    // ── 1. Try server ──────────────────────────────────────────────────────
    try {
      final userId = await SharedPrefsHelper.getUserId();

      if (userId != null && userId.isNotEmpty) {
        Console.log(
          tag: 'ChartWidget',
          value: 'Fetching summaries from SERVER for $startDate → $endDate',
        );

        final serverMaps =
            await _apiService.getDailySummaries(userId, startDate, endDate);

        if (serverMaps != null) {
          final summaries = serverMaps
              .map((m) => HydrationDaySummary.fromServerMap(m))
              .toList();

          Console.log(
            tag: 'ChartWidget',
            value: 'SERVER returned ${summaries.length} summaries — caching',
          );

          // Persist for offline use (fire-and-forget)
          _saveToCache(cacheKey, summaries);

          return summaries;
        }

        Console.log(
          tag: 'ChartWidget',
          value: 'SERVER returned null — trying persistent cache',
        );
      } else {
        Console.log(
          tag: 'ChartWidget',
          value: 'No userId — trying persistent cache',
        );
      }
    } catch (e) {
      Console.log(
        tag: 'ChartWidget',
        value: 'Server fetch failed ($e) — trying persistent cache',
      );
    }

    // ── 2. Persistent cache (shown when offline) ───────────────────────────
    final cached = await _loadFromCache(cacheKey);
    if (cached != null) {
      Console.log(
          tag: 'ChartWidget', value: 'Returning CACHED data (offline mode)');
      return cached;
    }

    // ── 3. Local SQLite fallback ───────────────────────────────────────────
    Console.log(
        tag: 'ChartWidget', value: 'No cache found — falling back to local DB');
    // ignore: use_build_context_synchronously
    return ctx
        .read<BottleDataCubit>()
        .getHydrationSummariesForRange(startDate, endDate);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.only(
          top: AppDimensions.defaultPadding.w,
          left: AppDimensions.defaultPadding.w,
          right: AppDimensions.defaultPadding.w,
          bottom: AppDimensions.dim30.h),
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.radius_4,
              color: AppColors.black.withAlpha((0.25 * 255).round()),
              offset: Offset(AppDimensions.dim2, AppDimensions.dim2),
            )
          ],
          borderRadius: BorderRadius.circular(AppDimensions.radius_15.r),
          border: Border.all(color: AppColors.greywith80, width: 1.w),
          color: AppColors.white),
      child: Column(
        children: [
          // ── Chart-type toggle ───────────────────────────────────────────
          Row(
            children: [
              Text(
                AppStrings.drinkCompletion,
                style: TextStyle(
                    color: AppColors.bluegray,
                    fontSize: AppFontStyles.fontSize_20,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontVariations: [AppFontStyles.boldFontVariation]),
              ),
            ],
          ),

          SizedBox(height: AppDimensions.dim10.h),

          // ── Chart area ──────────────────────────────────────────────────
          BlocBuilder<FilterCubit, FilterState>(
            buildWhen: (prev, next) =>
                _cacheKeyFor(prev) != _cacheKeyFor(next),
            builder: (context, filterState) {
              final future = _buildFuture(filterState, context);

              return FutureBuilder<List<dynamic>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        AppStrings.errorLoadingData,
                        style: TextStyle(
                          color: AppColors.redColor,
                          fontSize: AppFontStyles.fontSize_18.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData ||
                      (snapshot.data![0] as List<HydrationDaySummary>)
                          .isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.noDataAvailable,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: AppFontStyles.fontSize_18.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  final bottleData =
                      snapshot.data![0] as List<HydrationDaySummary>;
                  final userGoal = snapshot.data![1] as int?;

                  return FlColumnChartWidget(
                    key: ValueKey(
                        'col_${userGoal}_${filterState.currentInterval}'),
                    interval: filterState.currentInterval,
                    currentDate: filterState.currentDate,
                    bottleData: bottleData,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
