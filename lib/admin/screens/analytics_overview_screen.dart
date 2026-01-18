import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_service.dart';
import 'package:socially_app/utils/constants/colors.dart';

class AnalyticsOverviewScreen extends StatelessWidget {
  const AnalyticsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminService adminService = AdminService();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: mobileBackgroundColor, // Updated to app background
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.02),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.transparent),
          ),
        ),
        centerTitle: true,
        title: Text(
          "ANALYTICS ENGINE",
          style: GoogleFonts.orbitron(
            color: primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 3,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildAmbientGlows(),
          StreamBuilder<Map<String, dynamic>>(
            stream: adminService.getAnalyticsStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: mainPurpleColor, // Updated color
                    strokeWidth: 2,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: primaryColor),
                  ),
                );
              }

              final data = snapshot.data ?? {};

              // --- Safety Data Conversion ---
              Map<String, double> ageGroups = {};
              if (data['age_demographics'] != null) {
                (data['age_demographics'] as Map).forEach(
                  (k, v) => ageGroups[k.toString()] = v.toDouble(),
                );
              }

              Map<String, double> weeklyGrowth = {};
              if (data['weekly_growth'] != null) {
                (data['weekly_growth'] as Map).forEach(
                  (k, v) => weeklyGrowth[k.toString()] = v.toDouble(),
                );
              }

              double totalUsers = ageGroups.values.fold(
                0.0,
                (sum, item) => sum + item,
              );

              return SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildGlassCard(
                        title: "User Growth (Weekly)",
                        child: _buildMainLineChart(weeklyGrowth),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatTile(
                              "TOTAL USERS",
                              data['dau']?.toString() ?? "0",
                              Icons.people_alt_rounded,
                              mainPurpleColor, // Main theme color
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildStatTile(
                              "ENGAGEMENT",
                              data['engagement_rate'] ?? "0%",
                              Icons.bolt_rounded,
                              mainYellowColor, // High engagement color
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGlassCard(
                        title: "Age Distribution",
                        child: _buildProfessionalPieChart(
                          ageGroups,
                          totalUsers,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlows() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: _buildBlurOrb(250, mainPurpleColor.withOpacity(0.12)),
        ),
        Positioned(
          bottom: 0,
          left: -50,
          child: _buildBlurOrb(200, mainOrangeColor.withOpacity(0.08)),
        ),
      ],
    );
  }

  Widget _buildMainLineChart(Map<String, double> weeklyData) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<FlSpot> spots = [];

    for (int i = 0; i < days.length; i++) {
      spots.add(FlSpot(i.toDouble(), weeklyData[days[i]] ?? 0.0));
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: primaryColor.withOpacity(0.05), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        days[index],
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: secondaryColor, fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [
                  mainPurpleColor,
                  mainOrangeColor,
                ], // Using app gradient
              ),
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    mainPurpleColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalPieChart(
    Map<String, double> ageGroups,
    double total,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total.toInt().toString(),
                    style: GoogleFonts.poppins(
                      color: primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "TOTAL",
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 75,
                  sections: ageGroups.entries.map((entry) {
                    final percentage = total > 0
                        ? (entry.value / total) * 100
                        : 0;
                    return PieChartSectionData(
                      value: entry.value <= 0 ? 0.01 : entry.value,
                      title: percentage > 10
                          ? '${percentage.toStringAsFixed(0)}%'
                          : '',
                      radius: 22,
                      color: _getAgeGroupColor(entry.key),
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: ageGroups.keys
              .map((key) => _buildLegend(key, _getAgeGroupColor(key)))
              .toList(),
        ),
      ],
    );
  }

  // --- UI Helpers ---
  Widget _buildBlurOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)],
    ),
  );

  Widget _buildGlassCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: primaryColor.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: secondaryColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAgeGroupColor(String group) {
    switch (group) {
      case '18-24':
        return mainPurpleColor; // Unified with app theme
      case '25-34':
        return mainOrangeColor;
      case '35-50':
        return mainYellowColor;
      case '50+':
        return const Color(0xFF10B981); // Emerald green for senior group
      default:
        return secondaryColor;
    }
  }

  Widget _buildLegend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: secondaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
