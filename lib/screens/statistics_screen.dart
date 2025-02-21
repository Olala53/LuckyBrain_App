import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mind_up/models/game_result.dart';

class StatisticsScreen extends StatefulWidget {
  final String selectedLanguage;
  final bool isDarkMode;
  final bool isSoundEnabled;

  const StatisticsScreen({
    Key? key,
    required this.selectedLanguage,
    required this.isDarkMode,
    required this.isSoundEnabled,
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<Box<Map>> gameResultsBoxFuture;

  @override
  void initState() {
    super.initState();
    gameResultsBoxFuture = _initializeHive();
  }

  Future<Box<Map>> _initializeHive() async {
    await Hive.initFlutter();
    return await Hive.openBox<Map>('gameResults');
  }

  Widget _buildGameResultsTable(List<GameResult> results) {
    final filteredResults = results.where((result) => result.score > 0).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
          child: DataTable(
            columnSpacing: 20,
            dataRowHeight: 60,
            columns: [
              DataColumn(
                  label: Text(
                      widget.selectedLanguage == 'Polski' ? 'Gra' : 'Game',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black))),
              DataColumn(
                  label: Text(
                      widget.selectedLanguage == 'Polski' ? 'Wynik' : 'Score',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black))),
              DataColumn(
                  label: Text(
                      widget.selectedLanguage == 'Polski' ? 'Data' : 'Date',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black))),
            ],
            rows: filteredResults.map((result) {
              return DataRow(cells: [
                DataCell(Text(result.gameName,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold))),
                DataCell(Text(result.score.toString(),
                    style: TextStyle(
                        fontSize: 16,
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black))),
                DataCell(Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(result.date),
                    style: TextStyle(
                        fontSize: 16,
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<GameResult> results) {
    final scores = results.where((r) => r.score > 0).toList();

    return Column(
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: widget.isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              barGroups: scores.map((result) {
                return BarChartGroupData(
                  x: scores.indexOf(result),
                  barRods: [
                    BarChartRodData(
                      toY: result.score.toDouble(),
                      color: Colors.blue,
                      width: 30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < scores.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            scores[value.toInt()].gameName,
                            style: TextStyle(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black),
                          ),
                        );
                      }
                      return Text('');
                    },
                    reservedSize: 42,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black)),
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.selectedLanguage == 'Polski' ? 'Statystyki' : 'Statistics',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: widget.isDarkMode ? Colors.grey[850] : Colors.lightBlue[100],
        child: FutureBuilder<Box<Map>>(
          future: gameResultsBoxFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return Center(
                  child: Text(
                      widget.selectedLanguage == 'Polski'
                          ? 'Brak dostępnych danych'
                          : 'No data available',
                      style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black)));
            }

            final box = snapshot.data!;
            final results = box.values
                .map(
                    (map) => GameResult.fromMap(Map<String, dynamic>.from(map)))
                .toList();

            return ListView(
              padding: EdgeInsets.all(16),
              children: [
                Text(
                  widget.selectedLanguage == 'Polski'
                      ? 'Wyniki gier'
                      : 'Game Results',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black),
                ),
                SizedBox(height: 16),
                _buildGameResultsTable(results),
                SizedBox(height: 24),
                Text(
                  widget.selectedLanguage == 'Polski'
                      ? 'Wykres słupkowy'
                      : 'Bar chart',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black),
                ),
                SizedBox(height: 16),
                _buildBarChart(results),
              ],
            );
          },
        ),
      ),
    );
  }
}
