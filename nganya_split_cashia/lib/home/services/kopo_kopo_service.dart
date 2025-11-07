/*
 * KOPO KOPO HACKATHON API SERVICE
 *
 * WARNING: INSECURE. DO NOT USE IN PRODUCTION.
 * This file contains secret keys and is only for a sandbox demo.
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class KopoKopoService {
  // --- 1. PASTE YOUR SANDBOX KEYS HERE ---
  final String _clientId = 'YOUR_CLIENT_ID';
  final String _clientSecret = 'YOUR_CLIENT_SECRET';
  final String _apiKey = 'YOUR_API_KEY';
  final String _tillNumber =
      'YOUR_SANDBOX_TILL_NUMBER'; // The till you are paying to

  final String _authUrl = 'https://sandbox.kopokopo.com/oauth/token';
  final String _stkUrl =
      'https://sandbox.kopokopo.com/api/v1/incoming_payments';

  // This is a dummy URL. The API requires it, but for the demo,
  // we don't need to listen to it.
  final String _callbackUrl = 'https://example.com/kopo_kopo_callback';

  String? _authToken; // We can cache the token for a bit

  // --- 2. GET AUTH TOKEN ---
  // This gets the Bearer token needed to make API calls
  Future<String?> _getAuthToken() async {
    // If we have a token, return it (hacky caching)
    // In a real app, you'd check for expiry
    if (_authToken != null) {
      return _authToken;
    }

    debugPrint('Getting new Kopo Kopo Auth Token...');

    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'grant_type': 'client_credentials',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _authToken = data['access_token'] as String?;
        debugPrint('Token acquired!');
        return _authToken;
      } else {
        debugPrint(
          'Error getting auth token: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Exception in _getAuthToken: $e');
      return null;
    }
  }

  // --- 3. INITIATE THE STK PUSH ---
  // This is the main function you'll call from the UI
  Future<bool> initiateStkPush({
    required String passengerPhone,
    required double amount,
  }) async {
    // Format phone to 254...
    var formattedPhone = passengerPhone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '254${formattedPhone.substring(1)}';
    } else if (formattedPhone.startsWith('+')) {
      formattedPhone = formattedPhone.substring(1);
    }

    // 1. Get auth token
    final token = await _getAuthToken();
    if (token == null) {
      debugPrint('Could not get auth token, aborting STK push.');
      return false;
    }

    // 2. Build the payment request body
    final body = <String, dynamic>{
      'payment_channel': 'M-PESA STK Push',
      'till_number': _tillNumber,
      'first_name': 'Hackathon', // Demo data
      'last_name': 'Passenger', // Demo data
      'phone_number': formattedPhone,
      'amount': amount.toStringAsFixed(0), // Kopo Kopo expects a string integer
      'currency': 'KES',
      'email': 'test@example.com', // Demo data
      'callback_url': _callbackUrl,
      'metadata': {'notes': 'Matatu Hackathon Demo', 'app_version': '1.0.0'},
    };

    debugPrint('Sending STK Push to $formattedPhone for KES $amount...');

    // 3. Make the API call
    try {
      final response = await http.post(
        Uri.parse(_stkUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Api-Key': _apiKey, // Specific to Kopo Kopo
        },
        body: json.encode(body),
      );

      // Kopo Kopo returns a 201 (Created) on a *successful request*
      // This does NOT mean the payment is complete, only that the STK push
      // was successfully *initiated*. For the hackathon, this is success!
      if (response.statusCode == 201) {
        debugPrint('STK Push initiated successfully!');
        debugPrint('Check the phone $passengerPhone for the prompt.');
        return true;
      } else {
        debugPrint(
          'Error initiating STK Push: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Exception in initiateStkPush: $e');
      return false;
    }
  }
}
