import 'package:flutter/material.dart';

class PantallaBotonSeleccionable extends StatefulWidget {
  @override
  _PantallaBotonSeleccionableState createState() => _PantallaBotonSeleccionableState();
}

class _PantallaBotonSeleccionableState extends State<PantallaBotonSeleccionable> {
  // Variable para controlar si el botón está seleccionado
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Cambia el estado del botón al presionarlo
            setState(() {
              _isSelected = !_isSelected;
            });
          },
          style: ElevatedButton.styleFrom(
            // Cambia el color según el estado
            backgroundColor: _isSelected ? Colors.green : Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Botón cuadrado
            ),
          ),
          child: Text('Seleccionar'),
        ),
      ),
    );
  }
}