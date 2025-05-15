import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GptService {
  final String apiKey = dotenv.env['api_key'] ?? '';


  Future<String> enviarTranscripcion(String transcripcion) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'user', 'content': 'Hola por favor dime el motivo de la transacción, la categoría y el monto, esta es la descripción: de la transacción: $transcripcion' }
      ],
      'temperature': 0.7,
    });

    final response = await http.post(Uri.parse(endpoint), headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'];
      return reply.trim();
    } else {
      throw Exception('Error al comunicarse con la API de OpenAI: ${response.body}');
    }
  }
}
