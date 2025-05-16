// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:chreosis_app/models/datos_transaccion.dart';
import 'package:intl/intl.dart';

class GptService {
  final String apiKey = dotenv.env['api_key'] ?? '';


  Future<DatosTransaccion> enviarTranscripcion(String transcripcion) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';
    final hoy = DateTime.now();
    final fechaFormateada = DateFormat('dd-MM-yyyy').format(hoy);
    final diaSemana = DateFormat('EEEE', 'es').format(hoy);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'user', 'content':"""Extrae de este texto: $transcripcion monto, categoria, descripcion, metodo de pago y fecha, tipoTransaccion. La fecha actual es: $fechaFormateada, dia de la semana: $diaSemana.
        En el caso de que no se encuentre una fecha explícita en el texto, debes usar la fecha actual mencionada más arriba. Sin embargo, si el usuario menciona cosas como "ayer", "domingo pasado", "el 16 de este mes", "el viernes", etc., debes calcular restando o sumando dias a la fecha actual mencionada más arriba, devolver la fecha exacta correspondiente, 
        usando como base la fecha actual mencionada más arriba.
        La fecha en la respuesta debe estar siempre en formato DD-MM-YYYY.
        Los métodos de pago posibles son: Efectivo, Tarjeta de Crédito, Tarjeta de Débito, Transferencia. Si no se menciona ninguno de esos métodos, el valor debe estar vacío ("")
        no uses acentos ni caracteres especiales en la respuesta.
        los tipoTransaccion posibles son 'gasto' o 'ingreso'
        La respuesta me la vas a dar en este formato:
          {
            "monto": "",
            "categoria": "",
            "descripcion": "",
            "metodoPago": "",
            "tipoTransaccion":"",
            "fecha": ""
          }
          .""" }
      ],
      'temperature': 0.7,
    });

    final response = await http.post(Uri.parse(endpoint), headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'];
      // Extraer solo el JSON de la respuesta (elimina texto adicional si existe)
      String jsonString = reply;
      // Decodificar el JSON
      final Map<String, dynamic> datosMap = jsonDecode(jsonString);
      final datos = DatosTransaccion.fromJson(datosMap);
      return datos;
    } else {
      throw Exception('Error al comunicarse con la API de OpenAI: ${response.body}');
    }
  }
}
