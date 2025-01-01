import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphWidget extends StatelessWidget {
  final String type;
  final String title;
  final Map<String, dynamic> data;

  const GraphWidget({
    super.key,
    required this.type,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (data['subtitle'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                data['subtitle'] as String,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: type == 'bar' ? _buildBarChart() : _buildLineChart(),
          ),
          if (data['caption'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                data['caption'] as String,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final names = List<String>.from(data['names'] ?? []);
    final values = List<String>.from(data['data1'] ?? []);
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: values.map((v) => double.parse(v)).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= names.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    names[value.toInt()],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          names.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: double.parse(values[index]),
                color: const Color(0xFFF7C325),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = (data['points'] as List).asMap().entries.map((entry) {
      final point = entry.value;
      return FlSpot(entry.key.toDouble(), point['value'].toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data['points'].length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data['points'][value.toInt()]['label'],
                    style: const TextStyle(
                      color: Color(0xFF28231A),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Color(0xFF28231A),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFF7C325),
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFF7C325).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
} 