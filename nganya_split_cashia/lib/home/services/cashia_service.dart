import 'dart:convert';
import 'package:http/http.dart' as http;

class CashiaService {
  // Cashia API Key
  static const String apiKey = 'YOUR_CASHIA_API_KEY';

  static const String baseUrl = 'http://pre-prod.cashia.com/api';

  /// Sends an STK Push using Cashia API
  static Future<bool> sendStkPush({
    required String phone,
    required double amount,
  }) async {
    final url = Uri.parse('$baseUrl/mpesa/stkpush');

    // Ensure 254 format
    final formattedPhone = phone.startsWith('0')
        ? '254${phone.substring(1)}'
        : phone;

    final body = {
      'phoneNumber': formattedPhone,
      'amount': amount.toInt(), // Cashia expects int
      'reference': 'NganyaSplit',
      'callbackUrl': 'https://kevinomyonga.com/cashia-callback',
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('CASHIA STK RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        return true; // STK successfully sent
      } else {
        print('Cashia error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Cashia STK Error: $e');
      return false;
    }
  }
}
