import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/hydration_entry.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/api_service.dart';

class HomeWidgetService {
  // Constants for widget names and App Group ID
  static const String androidWidgetName = 'HomeWidgetProvider';
  static const String iOSWidgetName = 'SipnudgeWidget';
  // This needs to match the App Group ID created in Apple Developer Portal and Xcode
  static const String appGroupId = 'group.com.sipnudge.sipnudge'; 

  static Future<void> initialize() async {
    // Set the App Group ID for iOS
    await HomeWidget.setAppGroupId(appGroupId);
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
        final rangeStart = DateTime(today.year, today.month, today.day);
        final rangeEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
        final summaries = await ApiService().getDailySummaries(userId, rangeStart, rangeEnd);
        if (summaries != null && summaries.isNotEmpty) {
          // Find today's summary by matching the year, month, and day in local time
          Map<String, dynamic>? todaySummary;
          for (final summary in summaries) {
            final dateStr = summary['date'] as String?;
            if (dateStr != null) {
              final parsedDate = DateTime.tryParse(dateStr)?.toLocal();
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

    // Save data to be read by the native widgets
    await HomeWidget.saveWidgetData<int>('current_intake', currentIntake);
    await HomeWidget.saveWidgetData<int>('daily_goal', dailyGoal);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    await HomeWidget.saveWidgetData<String>('last_update_date', todayStr);

    // Calculate and save upcoming slot data
    try {
      final dbHelper = DatabaseHelper();
      final slots = await dbHelper.getAllSlots();
      if (slots.isNotEmpty) {
        // Save all slots as a JSON string for dynamic calculations in widget when app is closed
        final List<Map<String, dynamic>> slotsJsonList = slots.map((entry) {
          final tod = entry.startTime;
          return {
            'label': entry.slot.label,
            'hour': tod.hour,
            'minute': tod.minute,
            'target': entry.amount.round(),
          };
        }).toList();
        final slotsJson = jsonEncode(slotsJsonList);
        await HomeWidget.saveWidgetData<String>('all_slots_json', slotsJson);

        final streak = await dbHelper.getConsistencyStreak();
        await HomeWidget.saveWidgetData<int>('streak', streak);

        final now = DateTime.now();
        final nowMinutes = now.hour * 60 + now.minute;

        // Sort by start time
        slots.sort((a, b) {
          final aMin = a.startTime.hour * 60 + a.startTime.minute;
          final bMin = b.startTime.hour * 60 + b.startTime.minute;
          return aMin.compareTo(bMin);
        });

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
            value: "Widget upcoming slot: ${upcomingEntry.slot.label} at $timeStr, target: ${upcomingEntry.amount.round()} ml");
      }
    } catch (e) {
      Console.log(tag: "HomeWidget", value: "Error updating widget data with upcoming slot: $e");
    }
    
    // Trigger an update for both platforms
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }
}
