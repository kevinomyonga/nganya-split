import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nganya_split/home/cubit/cubit.dart';

class DailyReportCubit extends HydratedCubit<DailyReportState> {
  DailyReportCubit() : super(DailyReportState.initial());

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
  );

  void setThreshold(double amount) {
    emit(
      state.copyWith(
        ownerThreshold: amount,
        transactions: [
          ...state.transactions,
          'CONFIG: Owner threshold set to ${_currencyFormat.format(amount)}',
        ],
      ),
    );
  }

  void resetDay() {
    emit(
      DailyReportState.initial().copyWith(
        ownerThreshold: state.ownerThreshold,
        transactions: [
          'ADMIN: Day has been reset.',
          'CONFIG: Owner threshold is ${_currencyFormat.format(state.ownerThreshold)}',
        ],
      ),
    );
  }

  // This logic is now only called *after* the STK push is successful
  void addPassengerPayment(double amount) {
    final newPayment = amount;
    final newTotalCollected = state.totalCollected + newPayment;
    var newAmountSentToOwner = state.amountSentToOwner;
    var newDriverEarnings = state.driverEarnings;

    final newTransactions = <String>[
      ...state.transactions,
      'PASSENGER: +${_currencyFormat.format(amount)} received. (STK Confirmed)',
    ];

    if (state.amountSentToOwner >= state.ownerThreshold) {
      // All new funds go directly to the driver
      newDriverEarnings += newPayment;
      newTransactions.add(
        'DRIVER: Earned ${_currencyFormat.format(newPayment)}',
      );
    } else {
      // Owner still needs to be paid
      final amountStillOwedToOwner =
          state.ownerThreshold - state.amountSentToOwner;

      if (newPayment <= amountStillOwedToOwner) {
        // The entire payment goes to the owner's pile
        newAmountSentToOwner += newPayment;
        newTransactions.add(
          'OWNER: Sent ${_currencyFormat.format(newPayment)}',
        );
      } else {
        // This payment crosses the threshold
        final toOwner = amountStillOwedToOwner;
        final toDriver = newPayment - toOwner;

        newAmountSentToOwner += toOwner;
        newDriverEarnings += toDriver;

        newTransactions.add('OWNER: Sent ${_currencyFormat.format(toOwner)}');
        if (toDriver > 0) {
          newTransactions.add(
            'DRIVER: Earned ${_currencyFormat.format(toDriver)}',
          );
        }
      }
    }

    emit(
      state.copyWith(
        totalCollected: newTotalCollected,
        amountSentToOwner: newAmountSentToOwner,
        driverEarnings: newDriverEarnings,
        transactions: newTransactions,
      ),
    );
  }

  // --- Hydrated Bloc Storage Hooks (Unchanged) ---

  @override
  DailyReportState? fromJson(Map<String, dynamic> json) {
    try {
      return DailyReportState.fromJson(json);
    } catch (e) {
      debugPrint('Error loading state: $e');
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(DailyReportState state) {
    return state.toJson();
  }
}
