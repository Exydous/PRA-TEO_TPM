import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_keys.dart';

class CurrencyService {
  static const String _baseUrl = "https://api.freecurrencyapi.com/v1/latest";

  Future<double> getExchangeRate(String targetCurrency) async {
    try {
      final response = await http.get(Uri.parse(
          "$_baseUrl?apikey=${ApiKeys.currencyApiKey}&base_currencies=USD&currencies=$targetCurrency"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'][targetCurrency].toDouble();
      }
      return 15500.0; // Fallback jika API error
    } catch (e) {
      return 15500.0; // Fallback jika tidak ada internet
    }
  }
}