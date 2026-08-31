import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/api_service.dart';

import 'package:hydrify/helpers/water_consumption_data_helper.dart';
import 'package:hydrify/helpers/hydration_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hydrify/services/database_sync_service.dart';

class HomeWidgetService {
  // Constants for widget names and App Group ID
  static const String androidWidgetName = 'HomeWidgetProvider';
  static const String iOSWidgetName = 'SipnudgeWidget';
  // This needs to match the App Group ID created in Apple Developer Portal and Xcode
  static const String appGroupId = 'group.com.sipnudge.sipnudge'; 

  static Future<void> initialize() async {
    // Set the App Group ID for iOS
    await HomeWidget.setAppGroupId(appGroupId);

    // Process any background clicks recorded in the iOS widget App Group
    await processPendingWidgetLogs();

    // Register widget click listener for deep links (e.g. sipnudge://quick-add?type=coffee&amount=150)
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
    HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  /// Processes logs added interactively in the iOS Widget background
  static Future<void> processPendingWidgetLogs() async {
    try {
      final jsonString =
          await HomeWidget.getWidgetData<String>('pending_widget_logs_json');
      if (jsonString != null && jsonString.isNotEmpty && jsonString != '[]') {
        final dynamic parsed = jsonDecode(jsonString);
        if (parsed is List && parsed.isNotEmpty) {
          final dbHelper = DatabaseHelper();
          for (final item in parsed) {
            if (item is Map) {
              final drinkType = item['type'] as String? ?? 'Water';
              final amount = (item['amount'] as num?)?.toDouble() ?? 250.0;
              final timestampStr = item['timestamp'] as String?;
              final timestamp = timestampStr != null
                  ? (DateTime.tryParse(timestampStr) ?? DateTime.now())
                  : DateTime.now();

              final double coefficient =
                  DatabaseHelper.hydrationCoefficients[drinkType] ?? 1.0;
              final double effectiveWater = amount * coefficient;
              final serverId = item['server_id'] as String?;

              await SharedPrefsHelper.addPendingManualDelta(
                  effectiveWater.toInt());
              await dbHelper.insertHydrationLog(drinkType, amount, timestamp,
                  serverId: serverId);
              await dbHelper.updateHydrationDaySummary(effectiveWater);
            }
          }

          // Clear processed pending logs
          await HomeWidget.saveWidgetData<String>(
              'pending_widget_logs_json', '[]');

          DatabaseSyncService().syncAll();
          await updateWidgetData();
          Console.log(
              tag: "HomeWidget",
              value:
                  "Processed ${parsed.length} pending widget log(s) into SQLite DB.");
        }
      }
    } catch (e) {
      Console.log(
          tag: "HomeWidget", value: "Error processing pending widget logs: $e");
    }
  }

  static void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    Console.log(tag: "HomeWidget", value: "Received widget deep link: $uri");

    final host = uri.host;
    final typeParam = uri.queryParameters['type'];
    final amountParam = uri.queryParameters['amount'];

    if (host == 'quick-add' || uri.scheme == 'sipnudge') {
      if (typeParam != null) {
        final String drinkType =
            typeParam.toLowerCase() == 'coffee' ? 'Coffee' : 'Water';
        final double defaultAmt = drinkType == 'Coffee' ? 150 : 250;
        final double amount = amountParam != null
            ? (double.tryParse(amountParam) ?? defaultAmt)
            : defaultAmt;
        quickLogDrink(drinkType, amount: amount);
      }
    }
  }

  static Future<void> quickLogDrink(String drinkType, {double amount = 250}) async {
    try {
      final dbHelper = DatabaseHelper();
      final double coefficient =
          DatabaseHelper.hydrationCoefficients[drinkType] ?? 1.0;
      final double effectiveWater = amount * coefficient;

      await SharedPrefsHelper.addPendingManualDelta(effectiveWater.toInt());
      await dbHelper.insertHydrationLog(drinkType, amount, DateTime.now());
      await dbHelper.updateHydrationDaySummary(effectiveWater);

      DatabaseSyncService().syncAll();
      await updateWidgetData();

      Fluttertoast.showToast(
        msg: "Logged ${amount.toInt()}ml $drinkType from Widget! 💧",
      );
    } catch (e) {
      Console.log(tag: "HomeWidget", value: "Error in quickLogDrink: $e");
    }
  }

  static Future<void> updateWidgetData() async {
    int currentIntake = 0;
    int dailyGoal = 2500;

    final dbHelper = DatabaseHelper();
    final today = DateTime.now();

    // Fetch initial dailyGoal and currentIntake from local database if available
    try {
      final localGoal = await dbHelper.getDailyWaterGoal(today);
      if (localGoal != null) {
        dailyGoal = localGoal;
      } else {
        final prefGoal = await SharedPrefsHelper.getWaterGoal();
        if (prefGoal != null) {
          dailyGoal = prefGoal;
        }
      }
      
      final todaySummary = await dbHelper.getSummaryForDate(today);
      if (todaySummary != null) {
        currentIntake = todaySummary.consumed.round();
        dailyGoal = todaySummary.target.round();
      }
    } catch (e) {
      Console.log(tag: "HomeWidget", value: "Error fetching dailyGoal from local database: $e");
    }

    // Try fetching from API exclusively
    try {
      final userId = await SharedPrefsHelper.getUserId();
      if (userId != null) {
        // Save user_id to the App Group so the native widget extension can read it in the background
        await HomeWidget.saveWidgetData<String>('user_id', userId);
        final rangeStart = DateTime.utc(today.year, today.month, today.day);
        final rangeEnd = DateTime.utc(today.year, today.month, today.day, 23, 59, 59);
        final summaries = await ApiService().getDailySummaries(userId, rangeStart, rangeEnd);
        if (summaries != null && summaries.isNotEmpty) {
          // Find today's summary by matching the year, month, and day in local time
          Map<String, dynamic>? todaySummary;
          for (final summary in summaries) {
            final dateStr = summary['date'] as String?;
            if (dateStr != null) {
              DateTime? parsedDate;
              try {
                final datePart = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
                parsedDate = DateTime.parse(datePart);
              } catch (_) {}
              if (parsedDate != null &&
                  parsedDate.year == today.year &&
                  parsedDate.month == today.month &&
                  parsedDate.day == today.day) {
                todaySummary = summary;
                break;
              }
            }
          }

          // Fallback to the latest summary in the range if no exact match is found
          todaySummary ??= summaries.last;

          currentIntake = (todaySummary['consumed'] as num?)?.round() ?? currentIntake;
          dailyGoal = (todaySummary['target'] as num?)?.round() ?? dailyGoal;
        }
      }
    } catch (e) {
      Console.log(tag: "HomeWidget", value: "Error fetching summaries from API: $e");
    }

    int coffeeIntake = 0;
    try {
      final dbHelper = DatabaseHelper();
      coffeeIntake = await dbHelper.getTodayCoffeeIntake();
    } catch (e) {
      Console.log(tag: "HomeWidget", value: "Error fetching coffee intake: $e");
    }

    // Save data to be read by the native widgets
    await HomeWidget.saveWidgetData<int>('current_intake', currentIntake);
    await HomeWidget.saveWidgetData<int>('daily_goal', dailyGoal);
    await HomeWidget.saveWidgetData<int>('coffee_intake', coffeeIntake);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await HomeWidget.saveWidgetData<String>('last_update_date', todayStr);

    // Calculate and save upcoming slot data and battery
    try {
      final dbHelper = DatabaseHelper();
      
      // 1. Fetch battery from local database / cached state
      int battery = 0;
      try {
        final db = await dbHelper.database;
        final List<Map<String, dynamic>> maps = await db.query(
          'bottle_data',
          where: 'battery > 0',
          orderBy: 'timestamp DESC',
          limit: 1,
        );
        if (maps.isNotEmpty) {
          battery = maps.first['battery'] as int? ?? 0;
        }
      } catch (e) {
        Console.log(tag: "HomeWidget", value: "Error fetching battery from database: $e");
      }

      if (battery <= 0) {
        battery = (await SharedPrefsHelper.getLastKnownBattery()) ?? 0;
      }

      if (battery > 0) {
        await SharedPrefsHelper.setLastKnownBattery(battery);
        await HomeWidget.saveWidgetData<int>('battery', battery);
      }

      var slots = await dbHelper.getAllSlots();
      if (slots.isEmpty) {
        slots = HydrationHelper.generateHydrationSlots(dailyGoal.toDouble());
      }
      if (slots.isNotEmpty) {
        // Save all slots as a JSON string for dynamic calculations in widget when app is closed
        final List<Map<String, dynamic>> slotsJsonList = slots.map((entry) {
          final start = entry.startTime;
          final end = entry.endTime;
          return {
            'label': entry.slot.label,
            'hour': start.hour,
            'minute': start.minute,
            'endHour': end.hour,
            'endMinute': end.minute,
            'target': entry.amount.round(),
          };
        }).toList();
        final slotsJson = jsonEncode(slotsJsonList);
        await HomeWidget.saveWidgetData<String>('all_slots_json', slotsJson);

        final streak = await dbHelper.getConsistencyStreak();
        await HomeWidget.saveWidgetData<int>('streak', streak);

        final now = DateTime.now();
        final nowMinutes = now.hour * 60 + now.minute;

        // 2. Compute expected cumulative target at current time
        final double expectedPercent =
            WaterConsumptionCalculator.calculateExpectedPercentage(
          slots,
          dailyGoal.toDouble(),
        );
        final double expectedCumulative =
            (expectedPercent / 100.0) * dailyGoal.toDouble();
        await HomeWidget.saveWidgetData<int>('expected_cumulative_target', expectedCumulative.round());
        await HomeWidget.saveWidgetData<double>('expected_percent', expectedPercent);

        HydrationEntry? upcomingEntry;
        for (final entry in slots) {
          final startMin = entry.startTime.hour * 60 + entry.startTime.minute;
          if (startMin > nowMinutes) {
            upcomingEntry = entry;
            break;
          }
        }

        upcomingEntry ??= slots.first;

        final tod = upcomingEntry.startTime;
        final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
        final minute = tod.minute.toString().padLeft(2, '0');
        final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
        final timeStr = "$hour:$minute $period";

        await HomeWidget.saveWidgetData<String>('upcoming_slot_name', upcomingEntry.slot.label);
        await HomeWidget.saveWidgetData<int>('upcoming_slot_target', upcomingEntry.amount.round());
        await HomeWidget.saveWidgetData<String>('upcoming_slot_time', timeStr);
        Console.log(
            tag: "HomeWidget",
            value: "Widget upcoming slot: ${upcomingEntry.slot.label} at $timeStr, target: ${upcomingEntry.amount.round()} ml, expectedCumulative: $expectedCumulative ml, expectedPercent: $expectedPercent%");
      }
    } catch (e) {
      Console.log(tag: "HomeWidget", value: "Error updating widget data: $e");
    }
    
    // Trigger an update for both platforms
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }
}
