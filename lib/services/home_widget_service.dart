import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/api_service.dart';

import 'package:hydrify/helpers/water_consumption_data_helper.dart';
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

    // Register widget click listener for deep links (e.g. sipnudge://quick-add?type=coffee)
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
    HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  static void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    Console.log(tag: "HomeWidget", value: "Received widget deep link: $uri");

    final host = uri.host;
    final typeParam = uri.queryParameters['type'];

    if (host == 'quick-add' || uri.scheme == 'sipnudge') {
      if (typeParam != null) {
        final String drinkType =
            typeParam.toLowerCase() == 'coffee' ? 'Coffee' : 'Water';
        quickLogDrink(drinkType, amount: 250);
      }
    }
  }

  static Future<void> quickLogDrink(String drinkType, {double amount = 250}) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.insertHydrationLog(drinkType, amount, DateTime.now());

      final double coefficient =
          DatabaseHelper.hydrationCoefficients[drinkType] ?? 1.0;
      final double effectiveWater = amount * coefficient;

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
      
      // 1. Fetch battery from local database
      int battery = 0;
      try {
        final db = await dbHelper.database;
        final List<Map<String, dynamic>> maps = await db.query(
          'bottle_data',
          orderBy: 'timestamp DESC',
          limit: 1,
        );
        if (maps.isNotEmpty) {
          battery = maps.first['battery'] as int? ?? 0;
        }
      } catch (e) {
        Console.log(tag: "HomeWidget", value: "Error fetching battery from database: $e");
      }
      await HomeWidget.saveWidgetData<int>('battery', battery);

      final slots = await dbHelper.getAllSlots();
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

        if (upcomingEntry == null) {
          upcomingEntry = slots.first;
        }

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
