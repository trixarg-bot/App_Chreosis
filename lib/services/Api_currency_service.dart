import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiCurrencyService {
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';
  static const String _cacheKey = 'currency_rates_cache';
  static const String _cacheTimestampKey = 'currency_rates_timestamp';
  static const Duration _cacheValidDuration = Duration(hours: 1);

  // Obtener la API key desde variables de entorno
  String get _apiKey => dotenv.env['ExchangeRateAPI'] ?? '';

  /// Obtiene las tasas de cambio desde la API o cache
  Future<Map<String, double>> getExchangeRates(String baseCurrency) async {
    try {
      // Verificar conectividad (saltar en tests)
      if (!_isTestEnvironment() && !await _hasInternetConnection()) {
        throw Exception('Sin conexión a internet');
      }

      // Verificar si tenemos cache válido
      final cachedRates = await _getCachedRates();
      if (cachedRates != null) {
        return cachedRates;
      }

      // Obtener tasas desde la API
      final rates = await _fetchRatesFromAPI(baseCurrency);

      // Guardar en cache
      await _saveRatesToCache(rates);

      return rates;
    } catch (e) {
      // Si falla la API, intentar usar cache expirado como fallback
      final cachedRates = await _getCachedRates(ignoreExpiration: true);
      if (cachedRates != null) {
        return cachedRates;
      }
      throw Exception('Error al obtener tasas de cambio: $e');
    }
  }

  /// Convierte un monto entre dos monedas
  Future<double> convertCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    try {
      // Si las monedas son iguales, retornar el mismo monto
      if (fromCurrency == toCurrency) {
        return amount;
      }

      // Obtener tasas de cambio
      final rates = await getExchangeRates(fromCurrency);

      // Obtener la tasa de conversión
      final rate = rates[toCurrency];
      if (rate == null) {
        throw Exception('Tasa de cambio no disponible para $toCurrency');
      }

      // Calcular conversión
      return amount * rate;
    } catch (e) {
      throw Exception('Error en conversión de moneda: $e');
    }
  }

  /// Obtiene tasas de cambio desde la API
  Future<Map<String, double>> _fetchRatesFromAPI(String baseCurrency) async {
    final url = '$_baseUrl/$_apiKey/latest/$baseCurrency';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Verificar si la respuesta es exitosa
      if (data['result'] == 'success') {
        final conversionRates =
            data['conversion_rates'] as Map<String, dynamic>;

        // Convertir a Map<String, double>
        return conversionRates.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      } else {
        throw Exception(
          'Error en la API: ${data['error-type'] ?? 'Error desconocido'}',
        );
      }
    } else {
      throw Exception('Error HTTP: ${response.statusCode}');
    }
  }

  /// Verifica si hay conexión a internet
  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Obtiene tasas de cache
  Future<Map<String, double>?> _getCachedRates({
    bool ignoreExpiration = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final ratesJson = prefs.getString(_cacheKey);
      final timestampString = prefs.getString(_cacheTimestampKey);

      if (ratesJson == null || timestampString == null) {
        return null;
      }

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();

      // Verificar si el cache es válido (menos de 1 hora)
      if (!ignoreExpiration &&
          now.difference(timestamp) > _cacheValidDuration) {
        return null; // Cache expirado
      }

      final ratesMap = json.decode(ratesJson) as Map<String, dynamic>;
      return ratesMap.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Guarda tasas en cache
  Future<void> _saveRatesToCache(Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_cacheKey, json.encode(rates));
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Si falla el cache, no es crítico, solo log
      print('Error al guardar cache: $e');
    }
  }

  /// Limpia el cache de tasas
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      print('Error al limpiar cache: $e');
    }
  }

  /// Obtiene información sobre el estado del cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final timestampString = prefs.getString(_cacheTimestampKey);
      final hasRates = prefs.containsKey(_cacheKey);

      if (timestampString == null || !hasRates) {
        return {
          'hasCache': false,
          'isValid': false,
          'lastUpdate': null,
          'age': null,
        };
      }

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final age = now.difference(timestamp);
      final isValid = age <= _cacheValidDuration;

      return {
        'hasCache': true,
        'isValid': isValid,
        'lastUpdate': timestamp.toIso8601String(),
        'age': age.inMinutes,
      };
    } catch (e) {
      return {
        'hasCache': false,
        'isValid': false,
        'lastUpdate': null,
        'age': null,
        'error': e.toString(),
      };
    }
  }

  /// Verifica si la API key es válida
  Future<bool> validateApiKey() async {
    try {
      if (_apiKey.isEmpty) {
        return false;
      }

      final url = '$_baseUrl/$_apiKey/latest/USD';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'] == 'success';
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si estamos en un entorno de testing
  bool _isTestEnvironment() {
    // Detectar si estamos en un entorno de testing
    try {
      // En tests, Flutter.testWidgetsFlutterBinding está disponible
      return const bool.fromEnvironment('dart.vm.product') == false &&
          const bool.fromEnvironment('FLUTTER_TEST') == true;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene las monedas soportadas (basado en la documentación)
  List<String> getSupportedCurrencies() {
    return [
      'USD', 'EUR', 'GBP', 'DOP', 'CAD', 'MXN', // Monedas principales
      'JPY', 'AUD', 'CHF', 'CNY', 'INR', 'BRL', // Otras monedas populares
      'KRW', 'RUB', 'ZAR', 'SEK', 'NOK', 'DKK', // Más monedas
      'PLN', 'CZK', 'HUF', 'RON', 'BGN', 'HRK', // Monedas europeas
      'TRY', 'ILS', 'AED', 'SAR', 'QAR', 'KWD', // Monedas del Medio Oriente
      'SGD', 'HKD', 'TWD', 'THB', 'MYR', 'IDR', // Monedas asiáticas
      'PHP', 'VND', 'NGN', 'EGP', 'KES', 'GHS', // Monedas africanas
    ];
  }

  /// Formatea un monto con el símbolo de la moneda
  String formatCurrency(double amount, String currencyCode) {
    // Mapeo de símbolos de monedas
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'DOP': 'RD\$',
      'CAD': 'C\$',
      'MXN': '\$',
      'JPY': '¥',
      'AUD': 'A\$',
      'CHF': 'CHF',
      'CNY': '¥',
      'INR': '₹',
      'BRL': 'R\$',
    };

    final symbol = symbols[currencyCode] ?? currencyCode;
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
