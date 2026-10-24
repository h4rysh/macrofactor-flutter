import 'package:intl/intl.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/expenditure_kalman_v4.dart';

/// Persisted record representing estimated energy expenditure and true trend weight.
class ExpenditureRecord {
  const ExpenditureRecord({
    required this.date,
    required this.expenditureKcal,
    required this.trendWeightKg,
    required this.variance,
    required this.confidence,
  });

  /// Calendar date string 'YYYY-MM-DD'.
  final String date;

  /// Estimated daily energy expenditure in kcal/day.
  final double expenditureKcal;

  /// Latent true trend weight in kg.
  final double trendWeightKg;

  /// Posterior expenditure variance P_EE.
  final double variance;

  /// Normalized confidence score [0.0, 1.0].
  final double confidence;

  Map<String, dynamic> toMap() => {
        'date': date,
        'expenditure_kcal': expenditureKcal,
        'trend_weight_kg': trendWeightKg,
        'variance': variance,
        'confidence': confidence,
      };

  factory ExpenditureRecord.fromRow(Row row) {
    return ExpenditureRecord(
      date: row['date'] as String,
      expenditureKcal: (row['expenditure_kcal'] as num).toDouble(),
      trendWeightKg: (row['trend_weight_kg'] as num).toDouble(),
      variance: (row['variance'] as num).toDouble(),
      confidence: (row['confidence'] as num).toDouble(),
    );
  }

  factory ExpenditureRecord.fromState(ExpenditureState state) {
    return ExpenditureRecord(
      date: DateFormat('yyyy-MM-dd').format(state.date),
      expenditureKcal: state.expenditureKcal,
      trendWeightKg: state.trendWeightKg,
      variance: state.variance,
      confidence: state.confidence,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenditureRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          expenditureKcal == other.expenditureKcal &&
          trendWeightKg == other.trendWeightKg &&
          variance == other.variance &&
          confidence == other.confidence;

  @override
  int get hashCode =>
      date.hashCode ^
      expenditureKcal.hashCode ^
      trendWeightKg.hashCode ^
      variance.hashCode ^
      confidence.hashCode;
}

/// Extension on [AppDatabase] providing persistence for daily expenditure history
/// and logging day completion flags.
extension AppDatabaseExpenditureExtension on AppDatabase {
  /// Saves a single expenditure record.
  void saveExpenditure(ExpenditureRecord record) =>
      expenditureDao.saveExpenditure(record);

  /// Atomically saves a batch of expenditure records inside a single SQLite transaction.
  void saveExpenditures(List<ExpenditureRecord> records) =>
      expenditureDao.saveExpenditures(records);

  /// Retrieves expenditure history ordered chronologically ascending.
  List<ExpenditureRecord> getExpenditureHistory({
    String? startDate,
    String? endDate,
  }) =>
      expenditureDao.getExpenditureHistory(
        startDate: startDate,
        endDate: endDate,
      );

  /// Retrieves the expenditure record for a specific date, or null if none saved.
  ExpenditureRecord? getExpenditureForDate(String date) =>
      expenditureDao.getExpenditureForDate(date);

  /// Retrieves the most recent expenditure record on or before [date].
  ExpenditureRecord? getLatestExpenditureBefore(String date) =>
      expenditureDao.getLatestExpenditureBefore(date);

  /// Deletes expenditure records on or after [date] during forward recomputation.
  void deleteExpendituresFrom(String date) =>
      expenditureDao.deleteExpendituresFrom(date);

  /// Sets whether the day was complete for food logging.
  void setDayComplete(String date, bool isComplete) =>
      expenditureDao.setDayComplete(date, isComplete);

  /// Checks whether a specific day is marked complete.
  /// If not recorded: past days default to true, today defaults to false.
  bool isDayComplete(String date) => expenditureDao.isDayComplete(date);

  /// Batch retrieves day completion flags, optionally bounded by [startDate, endDate].
  Map<String, bool> getDayCompletions({String? startDate, String? endDate}) =>
      expenditureDao.getDayCompletions(
        startDate: startDate,
        endDate: endDate,
      );
}
