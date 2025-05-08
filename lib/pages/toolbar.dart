import 'package:flutter/material.dart';

class ToolBar extends StatefulWidget {
  final Function(Color) onColorChanged;
  final Function(double) onHeightChanged;
  final Function(double) onOpacityChanged;

  const ToolBar({
    super.key, 
    required this.onColorChanged,
    required this.onHeightChanged,
    required this.onOpacityChanged,
  });

  @override
  State<ToolBar> createState() => _ToolBarState();
}

class _ToolBarState extends State<ToolBar> {
  // Default values
  Color _selectedColor = Colors.blue;
  double _height = 2.0;
  double _opacity = 1.0;
  bool _isColorPaletteOpen = false;

  // Flutter Material color palette
  final List<Color> _colorPalette = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color selector
          Row(
            children: [
              const Icon(Icons.color_lens, size: 20),
              const SizedBox(width: 8),
              const Text('Color:'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isColorPaletteOpen = !_isColorPaletteOpen;
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          
          // Color palette
          if (_isColorPaletteOpen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorPalette.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        _isColorPaletteOpen = false;
                      });
                      widget.onColorChanged(color);
                    },
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _selectedColor == color
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(),

          // Height slider
          Row(
            children: [
              const Icon(Icons.height, size: 20),
              const SizedBox(width: 8),
              const Text('Height:'),
              Expanded(
                child: Slider(
                  value: _height,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  label: _height.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _height = value;
                    });
                    widget.onHeightChanged(value);
                  },
                ),
              ),
              Text(_height.toStringAsFixed(1)),
            ],
          ),

          const Divider(),

          // Opacity slider
          Row(
            children: [
              const Icon(Icons.opacity, size: 20),
              const SizedBox(width: 8),
              const Text('Opacity:'),
              Expanded(
                child: Slider(
                  value: _opacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: (_opacity * 100).toStringAsFixed(0) + '%',
                  onChanged: (value) {
                    setState(() {
                      _opacity = value;
                    });
                    widget.onOpacityChanged(value);
                  },
                ),
              ),
              Text('${(_opacity * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }
}