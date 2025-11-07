import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:k2_connect_flutter/k2_connect_flutter.dart';
import 'package:nganya_split/home/cubit/cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nganya Split'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Day',
            onPressed: () {
              // Show confirmation dialog before resetting
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Day?'),
                  content: const Text(
                    'Are you sure you want to reset all earnings for the day?',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    TextButton(
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        context.read<DailyReportCubit>().resetDay();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<DailyReportCubit, DailyReportState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Owner Config Section (Unchanged) ---
                _ThresholdConfig(
                  initialThreshold: state.ownerThreshold,
                  onSetThreshold: (amount) {
                    context.read<DailyReportCubit>().setThreshold(amount);
                  },
                ),
                const SizedBox(height: 24),

                // --- Driver Dashboard Section (Unchanged) ---
                Text(
                  'Driver Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _DriverDashboard(state: state),
                const SizedBox(height: 24),

                // --- Driver Actions Section (MODIFIED) ---
                Text(
                  'Live Passenger Payment',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _DriverActions(
                  onAddPayment: (amount) {
                    // --- MODIFIED ---
                    // This now calls the dialog first
                    _showPhoneInputDialog(context, amount);
                    // --- END MODIFIED ---
                  },
                ),
                const SizedBox(height: 24),

                // --- Transaction Log Section (Unchanged) ---
                Text(
                  'Transaction Log',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _TransactionLogs(transactions: state.transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- NEW ---
  // This method shows a dialog to get the passenger's phone number
  // and then triggers the STK push.
  void _showPhoneInputDialog(BuildContext context, double amount) {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false, // Don't allow closing while loading
      builder: (dialogContext) {
        // Use a StatefulWidget to manage loading state *inside* the dialog
        return StatefulBuilder(
          builder: (context, setState) {
            var isLoading = false;
            String? errorMessage;

            return AlertDialog(
              title: Text('Initiate Payment: KES $amount'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Enter passenger's phone number to send STK Push. (Use Sandbox number, e.g., 0700000000)",
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone (e.g., 07... or 254...)',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        // Very basic validation for demo
                        if (value.length < 10) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text('Sending STK Push... Check phone.'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    if (!isLoading) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null // Disable button while loading
                      : () async {
                          if (formKey.currentState!.validate()) {
                            // 1. Start loading
                            setState(() {
                              isLoading = true;
                              errorMessage = null;
                            });

                            // 2. Call the API
                            final success = await _sendStkPush(
                              phone: phoneController.text,
                              amount: amount,
                            );

                            // 3. Handle response
                            if (success) {
                              // It worked! Close dialog and update cubit
                              Navigator.of(dialogContext).pop();
                              // Call the original cubit logic
                              // We use 'context' (from HomePage) not 'dialogContext'
                              context
                                  .read<DailyReportCubit>()
                                  .addPassengerPayment(amount);

                              // Show success snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'STK Push Sent! Check phone to approve.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // It failed. Stop loading and show error
                              setState(() {
                                isLoading = false;
                                errorMessage =
                                    'Failed to send STK Push. Check logs or API keys.';
                              });
                            }
                          }
                        },
                  child: const Text('Send Push'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _sendStkPush({
    required String phone,
    required double amount,
  }) async {
    try {
      // 1. Get access token
      final tokenService = K2ConnectFlutter.tokenService();

      final tokenResponse = await tokenService.requestAccessToken();
      print('TOKEN: $tokenResponse');
      final accessToken = tokenResponse.accessToken;

      // 2. Build STK request
      final stkRequest = StkPushRequest(
        tillNumber: 'K12345', // ✅ replace with YOUR TILL
        subscriber: Subscriber(
          phoneNumber: phone.startsWith('0')
              ? '254${phone.substring(1)}'
              : phone,
        ),
        amount: Amount(
          value: amount.toStringAsFixed(2),
        ),
        callbackUrl: 'https://kevinomyonga.com',
        accessToken: accessToken,
        metadata: {
          'source': 'nganya-split',
          'amount': amount,
        },
      );

      // 3. Make request
      final stkService = K2ConnectFlutter.stkService();

      final locationUrl = await stkService.requestPayment(
        stkPushRequest: stkRequest,
      );

      print('✅ STK push initiated. Status URL: $locationUrl');
      return true;
    } catch (e) {
      print('❌ STK error: $e');
      return false;
    }
  }

  // --- END NEW ---
}

// --- UI Helper Widgets (All Unchanged) ---

class _ThresholdConfig extends StatefulWidget {
  const _ThresholdConfig({
    required this.initialThreshold,
    required this.onSetThreshold,
  });
  final double initialThreshold;
  final ValueChanged<double> onSetThreshold;

  @override
  State<_ThresholdConfig> createState() => _ThresholdConfigState();
}

class _ThresholdConfigState extends State<_ThresholdConfig> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialThreshold.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant _ThresholdConfig oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This ensures if the state is reset, the text field updates.
    final currentText = _controller.text;
    final stateValue = widget.initialThreshold.toStringAsFixed(0);
    if (currentText != stateValue) {
      _controller.text = stateValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_controller.text);
    if (amount != null && amount > 0) {
      widget.onSetThreshold(amount);
      FocusScope.of(context).unfocus(); // Hide keyboard
    } else {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Owner Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Owner's Daily Threshold (KES)",
                prefixText: 'KES ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Set Threshold'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverDashboard extends StatelessWidget {
  const _DriverDashboard({required this.state});
  final DailyReportState state;

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'en_KE', symbol: 'KES ');
    final percentToOwner =
        (state.ownerThreshold == 0.0
                ? 0.0
                : (state.amountSentToOwner / state.ownerThreshold))
            .clamp(0.0, 1.0);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _DashboardCard(
          title: 'Total Collected',
          value: format.format(state.totalCollected),
          icon: Icons.paid,
          iconColor: Colors.blue,
        ),
        _DashboardCard(
          title: "Driver's Earnings",
          value: format.format(state.driverEarnings),
          icon: Icons.wallet,
          iconColor: Colors.green,
        ),
        _DashboardCard(
          title: 'Sent to Owner',
          value: format.format(state.amountSentToOwner),
          icon: Icons.business,
          iconColor: Colors.purple,
          subtitle: 'Goal: ${format.format(state.ownerThreshold)}',
          // Add a progress bar!
          progress: percentToOwner,
        ),
        _DashboardCard(
          title: 'Remaining for Owner',
          value: format.format(
            (state.ownerThreshold - state.amountSentToOwner).clamp(
              0,
              double.infinity,
            ),
          ),
          icon: Icons.hourglass_bottom,
          iconColor: Colors.orange,
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  // Value between 0.0 and 1.0

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.progress,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.copyWith(color: Colors.white54),
              ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                color: iconColor,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DriverActions extends StatelessWidget {
  const _DriverActions({required this.onAddPayment});
  final ValueChanged<double> onAddPayment;

  @override
  Widget build(BuildContext context) {
    // This widget just passes the amount up.
    // The HomePage handles the logic of showing the dialog.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => onAddPayment(50),
          icon: const Icon(Icons.add),
          label: const Text('Add KES 50'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => onAddPayment(100),
          icon: const Icon(Icons.add),
          label: const Text('Add KES 100'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade800,
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
      ],
    );
  }
}

class _TransactionLogs extends StatelessWidget {
  const _TransactionLogs({required this.transactions});
  final List<String> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions yet.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // This is so the list shows the latest transaction at the top
    final reversedList = transactions.reversed.toList();

    return Card(
      child: Container(
        height: 300, // Fixed height for the log area
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: reversedList.length,
          itemBuilder: (context, index) {
            final log = reversedList[index];
            var icon = Icons.info_outline;
            var color = Colors.white;

            // Added STK Confirmed visual
            if (log.startsWith('PASSENGER')) {
              icon = Icons.person_add;
              color = Colors.blue.shade300;
              if (log.contains('STK Confirmed')) {
                icon = Icons.check_circle;
                color = Colors.green.shade300;
              }
            } else if (log.startsWith('OWNER')) {
              icon = Icons.business;
              color = Colors.purple.shade300;
            } else if (log.startsWith('DRIVER')) {
              icon = Icons.wallet;
              color = Colors.green.shade300;
            } else if (log.startsWith('CONFIG') || log.startsWith('ADMIN')) {
              icon = Icons.settings;
              color = Colors.orange.shade300;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      log,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
