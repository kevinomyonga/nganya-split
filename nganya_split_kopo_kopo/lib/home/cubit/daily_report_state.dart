import 'package:equatable/equatable.dart';

class DailyReportState extends Equatable {
  const DailyReportState({
    required this.ownerThreshold,
    required this.totalCollected,
    required this.amountSentToOwner,
    required this.driverEarnings,
    required this.transactions,
  });

  factory DailyReportState.initial() {
    return const DailyReportState(
      ownerThreshold: 5000,
      totalCollected: 0,
      amountSentToOwner: 0,
      driverEarnings: 0,
      transactions: [],
    );
  }

  factory DailyReportState.fromJson(Map<String, dynamic> json) {
    return DailyReportState(
      ownerThreshold: (json['ownerThreshold'] as num).toDouble(),
      totalCollected: (json['totalCollected'] as num).toDouble(),
      amountSentToOwner: (json['amountSentToOwner'] as num).toDouble(),
      driverEarnings: (json['driverEarnings'] as num).toDouble(),
      transactions: List<String>.from(json['transactions'] as List),
    );
  }
  final double ownerThreshold;
  final double totalCollected;
  final double amountSentToOwner;
  final double driverEarnings;
  final List<String> transactions;

  DailyReportState copyWith({
    double? ownerThreshold,
    double? totalCollected,
    double? amountSentToOwner,
    double? driverEarnings,
    List<String>? transactions,
  }) {
    return DailyReportState(
      ownerThreshold: ownerThreshold ?? this.ownerThreshold,
      totalCollected: totalCollected ?? this.totalCollected,
      amountSentToOwner: amountSentToOwner ?? this.amountSentToOwner,
      driverEarnings: driverEarnings ?? this.driverEarnings,
      transactions: transactions ?? this.transactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerThreshold': ownerThreshold,
      'totalCollected': totalCollected,
      'amountSentToOwner': amountSentToOwner,
      'driverEarnings': driverEarnings,
      'transactions': transactions,
    };
  }

  @override
  List<Object?> get props => [
    ownerThreshold,
    totalCollected,
    amountSentToOwner,
    driverEarnings,
    transactions,
  ];
}
