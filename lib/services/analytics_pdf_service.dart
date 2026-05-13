import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AnalyticsPdfService {
  // Brand colors
  var color1 = Color(0x20BEDCFF);
  static const _blue = PdfColor.fromInt(0x20E0F3FF);
  static const _darkBlue = PdfColor.fromInt(0x20BEDCFF);
  static const _steelBlue = PdfColor.fromInt(0xFF5D7B91);
  static const _lightBlue = PdfColor.fromInt(0xFFEBF2FE);
  static const _green = PdfColor.fromInt(0xFF16A34A);
  static const _lightGrey = PdfColor.fromInt(0xFFF1F5F9);
  static const _textDark = PdfColor.fromInt(0xFF0F172A);
  static const _textMuted = PdfColor.fromInt(0xFF4D758B);
  static const _white = PdfColors.white;
  static const _divider = PdfColor.fromInt(0xFFE2E8F0);

  /// Entry point — generates the PDF and opens the system share sheet.
  static Future<void> generateAndShare({
    required Map<String, dynamic> analyticsData,
    required int year,
    required int? month,
    String userEmail = 'User',
  }) async {
    final pdf = pw.Document(
      title: 'SipNudge Hydration Report',
      author: 'SipNudge',
    );

    // Load custom fonts
    final fontData =
        await rootBundle.load('assets/fonts/Urbanist-VariableFont_wght.ttf');
    final ttf = pw.Font.ttf(fontData);
    final boldFontData =
        await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf');
    final boldTtf = pw.Font.ttf(boldFontData);

    // Load Logo
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/sipnudgelogo1.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      print('Error loading logo: $e');
    }

    final monthlyIntake =
        analyticsData['monthlyIntake'] as Map<String, dynamic>?;
    final weeklyDist =
        analyticsData['weeklyDistribution'] as List<dynamic>? ?? [];
    final habitConsistency =
        analyticsData['habitConsistency'] as Map<String, dynamic>?;
    final eliteInsights =
        analyticsData['eliteSmartInsights'] as Map<String, dynamic>?;
    final historicalTrends =
        analyticsData['historicalTrends'] as Map<String, dynamic>?;

    final periodLabel =
        month != null ? '${_monthName(month)} $year' : 'Year $year';
    final generatedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        header: (context) {
          if (context.pageNumber > 1) return pw.SizedBox();
          return _buildHeader(ttf, boldTtf, periodLabel, userEmail, logoImage);
        },
        footer: (context) => _buildFooter(ttf, generatedDate, context),
        build: (context) => [
          pw.SizedBox(height: 10),
          // ── Summary Row
          _buildSummaryRow(monthlyIntake, ttf, boldTtf),
          pw.SizedBox(height: 15),
          // ── Distribution Graph
          if (weeklyDist.isNotEmpty) ...[
            _buildSectionTitle(
                month != null
                    ? 'Weekly Distribution'
                    : 'Quarterly Distribution',
                boldTtf),
            pw.SizedBox(height: 8),
            _buildDistributionChart(weeklyDist, ttf, boldTtf),
            pw.SizedBox(height: 15),
          ],
          // ── Habit Consistency
          if (habitConsistency != null) ...[
            _buildSectionTitle('Habit Consistency', boldTtf),
            pw.SizedBox(height: 6),
            _buildHabitCard(habitConsistency, ttf, boldTtf),
            pw.SizedBox(height: 15),
          ],
          // ── Quarterly Breakdown (Only for Yearly)
          if (month == null && weeklyDist.isNotEmpty) ...[
            _buildSectionTitle('Quarterly Breakdown', boldTtf),
            pw.SizedBox(height: 8),
            _buildQuarterlyBreakdown(weeklyDist, ttf, boldTtf),
            pw.SizedBox(height: 15),
          ],
          // ── Historical Trends

          if (month != null && historicalTrends != null) ...[
            _buildSectionTitle('Historical Trends (Last 30 Days)', boldTtf),
            pw.SizedBox(height: 6),
            _buildHistoricalCard(historicalTrends, ttf, boldTtf),
          ],
        ],
      ),
    );

    final Uint8List pdfBytes = await pdf.save();
    final safeMonth =
        month != null ? '_${month.toString().padLeft(2, '0')}' : '';
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'sipnudge_hydration_${year}$safeMonth.pdf',
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(pw.Font ttf, pw.Font boldTtf,
      String periodLabel, String userEmail, pw.ImageProvider? logo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [_darkBlue, _blue],
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
            ),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logo != null)
                    pw.Image(logo, height: 28)
                  else
                    pw.Text(
                      'SipNudge',
                      style: pw.TextStyle(
                        font: boldTtf,
                        fontSize: 22,
                        color: PdfColors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Hydration Analytics Report',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    periodLabel,
                    style: pw.TextStyle(
                      font: boldTtf,
                      fontSize: 13,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    userEmail,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(
      pw.Font ttf, String generatedDate, pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: _divider, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by SipNudge • $generatedDate',
              style: pw.TextStyle(font: ttf, fontSize: 8, color: _textMuted),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: ttf, fontSize: 8, color: _textMuted),
            ),
          ],
        ),
      ],
    );
  }

  // ── Summary Row (Intake KPIs) ─────────────────────────────────────────────
  static pw.Widget _buildSummaryRow(
      Map<String, dynamic>? data, pw.Font ttf, pw.Font boldTtf) {
    final totalIntake = data?['totalIntake']?.toString() ?? '0.0';
    final target = data?['target']?.toString() ?? '0.0';
    final offSlot = data?['offSlot']?.toString() ?? '0.00';
    final percentage = (data?['percentage'] ?? 0).toString();

    return pw.Row(
      children: [
        _kpiCard('Total Intake', '${totalIntake}L', ttf, boldTtf),
        pw.SizedBox(width: 10),
        _kpiCard('Target', '${target}L', ttf, boldTtf),
        pw.SizedBox(width: 10),
        _kpiCard('Goal %', '$percentage%', ttf, boldTtf, highlight: false),
        pw.SizedBox(width: 10),
        _kpiCard('Off-Slot', '${offSlot}L', ttf, boldTtf),
      ],
    );
  }

  static pw.Widget _kpiCard(
      String label, String value, pw.Font ttf, pw.Font boldTtf,
      {bool highlight = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: highlight ? _blue : _lightBlue,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: boldTtf,
                fontSize: 9,
                color: highlight ? _white : _textMuted,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: boldTtf,
                fontSize: 18,
                color: highlight ? _white : _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Distribution Chart ──────────────────────────────────────────────────
  static pw.Widget _buildDistributionChart(
      List<dynamic> dist, pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      height: 180,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis.fromStrings(
            dist.map((d) => d['label'].toString()).toList(),
            textStyle: pw.TextStyle(font: ttf, fontSize: 8, color: _textMuted),
            marginStart: 15,
          ),
          yAxis: pw.FixedAxis(
            () {
              double maxVal = 2.0;
              for (var d in dist) {
                final s = double.tryParse(d['scheduled'].toString()) ?? 0.0;
                final o = double.tryParse(d['offSlot'].toString()) ?? 0.0;
                if (s > maxVal) maxVal = s;
                if (o > maxVal) maxVal = o;
              }
              final double maxY = (maxVal * 1.15).ceilToDouble();
              final double step =
                  (maxY / 5).ceilToDouble() > 0 ? (maxY / 5).ceilToDouble() : 1.0;
              return List.generate(6, (i) => i * step);
            }(),
            textStyle: pw.TextStyle(font: ttf, fontSize: 8, color: _textMuted),
          ),
        ),
        datasets: [
          pw.BarDataSet(
            color: _darkBlue,
            legend: 'Scheduled',
            width: 12,
            data: dist.asMap().entries.map((e) {
              final v = double.tryParse(e.value['scheduled'].toString()) ?? 0.0;
              return pw.PointChartValue(e.key.toDouble(), v);
            }).toList(),
          ),
          pw.BarDataSet(
            color: _blue,
            legend: 'Off-slot',
            width: 12,
            offset: 14,
            data: dist.asMap().entries.map((e) {
              final v = double.tryParse(e.value['offSlot'].toString()) ?? 0.0;
              return pw.PointChartValue(e.key.toDouble(), v);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Weekly Distribution Table (Keeping as fallback or secondary view) ──────
  static pw.Widget _buildWeeklyTable(
      List<dynamic> dist, pw.Font ttf, pw.Font boldTtf) {
    final headers = ['Label', 'Scheduled', 'Off-Slot'];
    final rows = dist
        .map((w) => [
              w['label'].toString(),
              '${w['scheduled']}L',
              '${w['offSlot']}L',
            ])
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(font: boldTtf, fontSize: 10, color: _white),
      headerDecoration: const pw.BoxDecoration(color: _blue),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: pw.TextStyle(font: ttf, fontSize: 10, color: _textDark),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
      },
      rowDecoration: const pw.BoxDecoration(color: _white),
      oddRowDecoration: const pw.BoxDecoration(color: _lightGrey),
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  // ── Habit Consistency ─────────────────────────────────────────────────────
  static pw.Widget _buildHabitCard(
      Map<String, dynamic> habit, pw.Font ttf, pw.Font boldTtf) {
    final efficiency = habit['efficiency']?.toString() ?? '0';
    final streak = habit['streak']?.toString() ?? '0';
    final insight = habit['insight'] as String? ?? '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Consistency',
                        style: pw.TextStyle(
                            font: ttf, fontSize: 9, color: _textMuted)),
                    pw.SizedBox(height: 3),
                    pw.Text('$efficiency%',
                        style: pw.TextStyle(
                            font: boldTtf, fontSize: 24, color: _textDark)),
                  ],
                ),
              ),
              pw.Container(
                width: 1,
                height: 40,
                color: _divider,
                margin: const pw.EdgeInsets.symmetric(horizontal: 16),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Peak Streak',
                        style: pw.TextStyle(
                            font: ttf, fontSize: 9, color: _textMuted)),
                    pw.SizedBox(height: 3),
                    pw.Text('$streak days',
                        style: pw.TextStyle(
                            font: boldTtf, fontSize: 24, color: _textDark)),
                  ],
                ),
              ),
            ],
          ),
          if (insight.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Divider(color: _divider, thickness: 0.5),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFEFF6FF),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      insight,
                      style: pw.TextStyle(
                          font: ttf, fontSize: 10, color: _steelBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Elite Smart Insights ──────────────────────────────────────────────────
  static pw.Widget _buildEliteInsightsCard(
      Map<String, dynamic> insights, pw.Font ttf, pw.Font boldTtf) {
    final title = insights['title'] as String? ?? 'Keep Going!';
    final description = insights['description'] as String? ?? '';
    final optimalWindow = insights['optimalWindow'] as String? ?? '--:--';

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_blue, _darkBlue],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '⚡ Elite Smart Insights',
            style: pw.TextStyle(font: boldTtf, fontSize: 12, color: _white),
          ),
          pw.SizedBox(height: 8),
          pw.RichText(
            text: pw.TextSpan(
              style: pw.TextStyle(font: ttf, fontSize: 10, color: _white),
              children: [
                pw.TextSpan(text: 'Your hydration consistency is '),
                pw.TextSpan(
                  text: title,
                  style: pw.TextStyle(
                    font: boldTtf,
                    fontSize: 10,
                    color: _white,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                if (description.isNotEmpty)
                  pw.TextSpan(text: '.\n$description'),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0x1AFFFFFF),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '🕐 Optimal Window: $optimalWindow',
                  style:
                      pw.TextStyle(font: boldTtf, fontSize: 10, color: _white),
                ),
                pw.Text(
                  '↑ Trending Up',
                  style: pw.TextStyle(font: ttf, fontSize: 9, color: _white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Historical Trends ─────────────────────────────────────────────────────
  static pw.Widget _buildHistoricalCard(
      Map<String, dynamic> trends, pw.Font ttf, pw.Font boldTtf) {
    final avgDaily = trends['averageDaily']?.toString() ?? '0.0';
    final peakStreak = trends['peakStreak']?.toString() ?? '0';

    return pw.Row(
      children: [
        pw.Expanded(
          child: _trendTile('Average Daily', '${avgDaily}L',
              'Based on last 30 days', ttf, boldTtf),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _trendTile('Peak Streak', '$peakStreak days',
              'Consecutive days reaching goal', ttf, boldTtf),
        ),
      ],
    );
  }

  static pw.Widget _trendTile(String title, String value, String subtitle,
      pw.Font ttf, pw.Font boldTtf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _divider, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(font: boldTtf, fontSize: 10, color: _steelBlue)),
          pw.SizedBox(height: 6),
          pw.Text(value,
              style:
                  pw.TextStyle(font: boldTtf, fontSize: 20, color: _textDark)),
          pw.SizedBox(height: 4),
          pw.Text(subtitle,
              style: pw.TextStyle(font: ttf, fontSize: 8, color: _textMuted)),
        ],
      ),
    );
  }

  // ── Section Title ─────────────────────────────────────────────────────────
  static pw.Widget _buildSectionTitle(String title, pw.Font boldTtf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: boldTtf, fontSize: 12, color: _steelBlue),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, width: 32, color: _blue),
      ],
    );
  }

  // ── Quarterly Breakdown ───────────────────────────────────────────────────
  static pw.Widget _buildQuarterlyBreakdown(
      List<dynamic> distribution, pw.Font ttf, pw.Font boldTtf) {
    return pw.Column(
      children: List.generate(distribution.length, (index) {
        final qData = distribution[index];
        final double target =
            double.tryParse(qData['target'].toString()) ?? 0.0;
        final double scheduled =
            double.tryParse(qData['scheduled'].toString()) ?? 0.0;
        final double offSlot =
            double.tryParse(qData['offSlot'].toString()) ?? 0.0;
        final double consumed = scheduled + offSlot;
        final double percent =
            target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

        return _buildQuarterlyItem(index, consumed, percent, ttf, boldTtf);
      }),
    );
  }

  static pw.Widget _buildQuarterlyItem(int quarterNumber, double consumed,
      double percent, pw.Font ttf, pw.Font boldTtf) {
    String quarterTitle;
    String monthRange;
    switch (quarterNumber) {
      case 0:
        quarterTitle = "First Quarter";
        monthRange = "January to March";
        break;
      case 1:
        quarterTitle = "Second Quarter";
        monthRange = "April to June";
        break;
      case 2:
        quarterTitle = "Third Quarter";
        monthRange = "July to September";
        break;
      case 3:
        quarterTitle = "Fourth Quarter";
        monthRange = "October to December";
        break;
      default:
        quarterTitle = "Quarter ${quarterNumber + 1}";
        monthRange = "";
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _lightGrey,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(quarterTitle,
                  style: pw.TextStyle(
                      font: boldTtf, fontSize: 11, color: _textDark)),
              pw.Text(monthRange,
                  style:
                      pw.TextStyle(font: ttf, fontSize: 9, color: _textMuted)),
            ],
          ),
          pw.Row(
            children: [
              pw.Text("${(percent * 100).toStringAsFixed(0)}%",
                  style:
                      pw.TextStyle(font: boldTtf, fontSize: 12, color: _blue)),
              pw.SizedBox(width: 25),
              pw.Text("${consumed.toStringAsFixed(1)}L",
                  style: pw.TextStyle(
                      font: boldTtf, fontSize: 12, color: _textDark)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  static String _monthName(int month) {
    const months = [
      '',
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
      'December'
    ];
    return months[month.clamp(1, 12)];
  }
}
