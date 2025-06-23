import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chreosis_app/services/Api_currency_service.dart';

void main() {
  setUpAll(() async {
    await dotenv.load();
  });

  final service = ApiCurrencyService();

  group('ApiCurrencyService - Métodos principales', () {
    test('validateApiKey debe validar la API key correctamente', () async {
      final isValid = await service.validateApiKey();
      print('🔑 API Key válida: $isValid');
      expect(isValid, isTrue, reason: 'La API key debe ser válida');
    });

    test('getExchangeRates debe obtener tasas reales de la API', () async {
      try {
        final rates = await service.getExchangeRates('USD');
        print('Tasas obtenidas: ${rates.length} monedas');
        print('USD→DOP: ${rates['DOP']} | USD→EUR: ${rates['EUR']}');
        expect(rates, isNotEmpty);
        expect(rates.containsKey('USD'), isTrue);
        expect(rates.containsKey('DOP'), isTrue);
        expect(rates.containsKey('EUR'), isTrue);
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          print('⚠️ Test omitido - plugins no disponibles en tests unitarios');
          return;
        }
        rethrow;
      }
    });

    test('convertCurrency debe convertir USD→DOP correctamente', () async {
      try {
        final result = await service.convertCurrency(
          amount: 100,
          fromCurrency: 'USD',
          toCurrency: 'DOP',
        );
        print('💱 100 USD = ${service.formatCurrency(result, 'DOP')}');
        expect(result, greaterThan(0));
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          print('⚠️ Test omitido - plugins no disponibles en tests unitarios');
          return;
        }
        rethrow;
      }
    });

    test('convertCurrency debe convertir EUR→DOP correctamente', () async {
      try {
        final result = await service.convertCurrency(
          amount: 50,
          fromCurrency: 'EUR',
          toCurrency: 'DOP',
        );
        print('💱 50 EUR = ${service.formatCurrency(result, 'DOP')}');
        expect(result, greaterThan(0));
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          print('⚠️ Test omitido - plugins no disponibles en tests unitarios');
          return;
        }
        rethrow;
      }
    });

    test(
      'convertCurrency debe retornar el mismo monto si las monedas son iguales',
      () async {
        try {
          final result = await service.convertCurrency(
            amount: 123.45,
            fromCurrency: 'USD',
            toCurrency: 'USD',
          );
          expect(result, equals(123.45));
        } catch (e) {
          if (e.toString().contains('MissingPluginException')) {
            print(
              '⚠️ Test omitido - plugins no disponibles en tests unitarios',
            );
            return;
          }
          rethrow;
        }
      },
    );

    test('convertCurrency debe lanzar excepción con moneda inválida', () async {
      try {
        await service.convertCurrency(
          amount: 100,
          fromCurrency: 'USD',
          toCurrency: 'INVALID',
        );
        fail('Debería haber lanzado una excepción');
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          print('⚠️ Test omitido - plugins no disponibles en tests unitarios');
          return;
        }
        expect(e, isA<Exception>());
      }
    });

    test('getCacheInfo debe retornar información del cache', () async {
      try {
        final info = await service.getCacheInfo();
        print('Cache info: $info');
        expect(info, isA<Map<String, dynamic>>());
        expect(info.containsKey('hasCache'), isTrue);
        expect(info.containsKey('isValid'), isTrue);
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          print('⚠️ Test omitido - plugins no disponibles en tests unitarios');
          return;
        }
        rethrow;
      }
    });

    test('clearCache debe limpiar el cache sin errores', () async {
      try {
        await service.clearCache();
        final info = await service.getCacheInfo();
        print('Cache después de limpiar: $info');
        expect(info['hasCache'], isFalse);
      } catch (e) {
        if (e.toString().contains('MissingPluginException')) {
          print('⚠️ Test omitido - plugins no disponibles en tests unitarios');
          return;
        }
        rethrow;
      }
    });

    test(
      'getSupportedCurrencies debe retornar lista de monedas soportadas',
      () {
        final currencies = service.getSupportedCurrencies();
        print('Monedas soportadas: ${currencies.length}');
        expect(currencies, isNotEmpty);
        expect(currencies, contains('USD'));
        expect(currencies, contains('DOP'));
        expect(currencies, contains('EUR'));
      },
    );

    test('formatCurrency debe formatear correctamente', () {
      expect(service.formatCurrency(1234.56, 'USD'), equals('\$1234.56'));
      expect(service.formatCurrency(1234.56, 'EUR'), equals('€1234.56'));
      expect(service.formatCurrency(1234.56, 'DOP'), equals('RD\$1234.56'));
      expect(service.formatCurrency(0, 'USD'), equals('\$0.00'));
      expect(service.formatCurrency(-50, 'USD'), equals('\$-50.00'));
      expect(service.formatCurrency(1234.56, 'XYZ'), equals('XYZ1234.56'));
    });
  });

  group('ExchangeRate API Direct Test', () {
    test('should connect to ExchangeRate API directly', () async {
      final apiKey = dotenv.env['ExchangeRateAPI'];
      expect(apiKey, isNotNull);
      expect(apiKey!.isNotEmpty, isTrue);

      print('API Key: ${apiKey.substring(0, 8)}...');

      final url = 'https://v6.exchangerate-api.com/v6/$apiKey/latest/USD';
      print('Testing URL: $url');

      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'ChreosisApp/1.0',
              },
            )
            .timeout(const Duration(seconds: 10));

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');

        expect(response.statusCode, 200);

        final data = json.decode(response.body);
        print('Parsed JSON: $data');

        // Verificar estructura de respuesta
        expect(data['result'], isNotNull);
        expect(data['base_code'], isNotNull);
        expect(data['conversion_rates'], isNotNull);

        print('Result: ${data['result']}');
        print('Base Code: ${data['base_code']}');
        print(
          'Conversion Rates Keys: ${data['conversion_rates'].keys.toList()}',
        );

        // Verificar tasas específicas
        final rates = data['conversion_rates'];
        if (rates['DOP'] != null) {
          print(
            'USD -> DOP rate: ${rates['DOP']} (type: ${rates['DOP'].runtimeType})',
          );
        }
        if (rates['EUR'] != null) {
          print(
            'USD -> EUR rate: ${rates['EUR']} (type: ${rates['EUR'].runtimeType})',
          );
        }
      } catch (e) {
        print('Error testing API: $e');
        fail('API test failed: $e');
      }
    });

    test('should test DOP as base currency', () async {
      final apiKey = dotenv.env['ExchangeRateAPI'];
      final url = 'https://v6.exchangerate-api.com/v6/$apiKey/latest/DOP';
      print('Testing DOP base URL: $url');

      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'ChreosisApp/1.0',
              },
            )
            .timeout(const Duration(seconds: 10));

        print('DOP Response Status: ${response.statusCode}');
        print('DOP Response Body: ${response.body}');

        expect(response.statusCode, 200);

        final data = json.decode(response.body);
        print('DOP Parsed JSON: $data');

        // Verificar estructura de respuesta
        expect(data['result'], isNotNull);
        expect(data['base_code'], equals('DOP'));
        expect(data['conversion_rates'], isNotNull);

        final rates = data['conversion_rates'];
        print('DOP Conversion Rates:');
        rates.forEach((currency, rate) {
          print('  $currency: $rate (type: ${rate.runtimeType})');
        });
      } catch (e) {
        print('Error testing DOP API: $e');
        fail('DOP API test failed: $e');
      }
    });
  });
}
