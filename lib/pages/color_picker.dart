import 'package:flutter/material.dart';
import 'package:pdfrx_poc/marker.dart';
import 'package:pdfrx_poc/pages/mainPage.dart';

class ColorPickerBottomSheet extends StatefulWidget {
  final Color initialColor;
  final double initialOpacity;
  final Function(Color color, double opacity) onColorSelected;

  const ColorPickerBottomSheet({
    Key? key,
    this.initialColor = Colors.red,
    this.initialOpacity = 1.0,
    required this.onColorSelected,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    Color initialColor = Colors.red,
    double initialOpacity = 1.0,
    required Function(Color color, double opacity) onColorSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ColorPickerBottomSheet(
        initialColor: initialColor,
        initialOpacity: initialOpacity,
        onColorSelected: onColorSelected,
      ),
    );
  }

   // New static method for opening thickness sheet
  static Future<void> showThicknessSheet({
    required BuildContext context,
    required Color lineColor,
    double initialThickness = 2.0,
    required Function(double thickness) onThicknessSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LineThicknessSheet(
        lineColor: lineColor,
        initialThickness: initialThickness,
        onThicknessSelected: onThicknessSelected,
      ),
    );
  }


    // New static method for opening highlights sheet
  static Future<void> showhighlightSheet({
    required BuildContext context,
    required Map<int,List<Marker>> marks,

    required Function(Map<int,List<Marker>> marks) onUpdateHighlight,
    required Function(int page,Marker mark) onHighlightTap
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MarkerSheet(
        onHighlightTap: onHighlightTap,
        marks: marks,
        onUpdateHighlight: onUpdateHighlight,
      ),
    );
  }

  @override
  State<ColorPickerBottomSheet> createState() => _ColorPickerBottomSheetState();
}

class _ColorPickerBottomSheetState extends State<ColorPickerBottomSheet> {
  late Color _selectedColor;
  late double _opacity;

  // Predefined colors
  final List<Color> _colors = [
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
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _opacity = widget.initialOpacity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and done button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Colors',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Apply opacity to the selected color
                  final colorWithOpacity = _selectedColor.withOpacity(_opacity);
                  widget.onColorSelected(colorWithOpacity, _opacity);
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grid of color options
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 34),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = _colors[index]);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colors[index],
                      borderRadius: BorderRadius.circular(8),
                      border: _selectedColor == _colors[index]
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              thumbColor: Colors.white,
              trackHeight: 14,
              thumbSize: const WidgetStatePropertyAll(
                Size(10, 10),
              ),
              activeTrackColor: _selectedColor.withOpacity(_opacity),
              inactiveTrackColor: _selectedColor.withOpacity(_opacity),
              overlayColor: _selectedColor.withOpacity(_opacity),
            ),
            child: Slider(
              value: _opacity,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                setState(() => _opacity = value);
              },
            ),
          )
       
        ],
      ),
    );
  }
}



class MarkerSheet extends StatefulWidget {
  final Map<int, List<Marker>> marks;
  final Function(Map<int,List<Marker>> marks) onUpdateHighlight;
  final Function(int page,Marker mark) onHighlightTap;
  const MarkerSheet({super.key, required this.marks, required this.onUpdateHighlight,required this.onHighlightTap});

  @override
  State<MarkerSheet> createState() => _MarkerSheetState();
}

class _MarkerSheetState extends State<MarkerSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and done button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Highlights',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                onPressed: () {
                  widget.onUpdateHighlight(widget.marks);
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          SizedBox(
            height: 200,
            width: double.maxFinite,
            child:
            PageView.builder(
              itemCount: widget.marks.length,
              itemBuilder: (context, index) {
                final key = widget.marks.keys.elementAt(index);
                final markers = widget.marks[key]??[];

               return  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                  Text('Page $key',style: TextStyle(color: Colors.white),),
                    const SizedBox(height: 8),
                             
                                // List of markers
                   ListView.builder(
                                 shrinkWrap: true,
                                 itemCount: markers.length,
                                 itemBuilder: (context, index) {

                                  final title = 'Highlight ${index + 1}';
                         
                    return ListTile(
                      titleAlignment: ListTileTitleAlignment.center,
                      title: Text(title,style: TextStyle(color: Colors.white,fontSize: 14),),
                      trailing: IconButton(onPressed: (){
                        widget.marks[key]?.removeAt(index);
                        setState(() {
                          
                        });
                      }, icon: Icon(Icons.delete,color: Colors.white,)),
                     
                      onTap: () {
                       widget.onHighlightTap(key, markers[index]);
                      },
                    );
                                 },
                               ),
                 ],
               );
               
              },
             )
            
          ),

          // Add your content here
        ],
      ),
    );
  }
}

class _LineThicknessSheet extends StatefulWidget {
  final double initialThickness;
  final Color lineColor;
  final Function(double thickness) onThicknessSelected;

  const _LineThicknessSheet({
    Key? key,
    required this.lineColor,
    this.initialThickness = 2.0,
    required this.onThicknessSelected,
  }) : super(key: key);

  @override
  State<_LineThicknessSheet> createState() => _LineThicknessSheetState();
}

class _LineThicknessSheetState extends State<_LineThicknessSheet> {
  late double _selectedThickness;

  // Predefined thicknesses
  final List<double> _thicknesses = [
    1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0, 16.0
  ];

  @override
  void initState() {
    super.initState();
    _selectedThickness = widget.initialThickness;
    // Find the closest thickness in our predefined list if not exact
    if (!_thicknesses.contains(_selectedThickness)) {
      _selectedThickness = _thicknesses.reduce((a, b) => 
        (a - _selectedThickness).abs() < (b - _selectedThickness).abs() ? a : b);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: bgColor, // Using the same background color
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and done button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Line Thickness',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                onPressed: () {
                  widget.onThicknessSelected(_selectedThickness);
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Horizontal scrollable thickness options
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _thicknesses.length,
              itemBuilder: (context, index) {
                final thickness = _thicknesses[index];
                final isSelected = thickness == _selectedThickness;
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedThickness = thickness);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: Center(
                      child: Container(
                        height: thickness,
                        width: 40,
                        decoration: BoxDecoration(
                          color: widget.lineColor,
                          borderRadius: BorderRadius.circular(thickness / 2),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          
          // Custom thickness slider
          const Padding(
            padding: EdgeInsets.only(left: 8.0, top: 8.0),
            child: Text(
              'Custom',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          
          SliderTheme(
            data: SliderThemeData(
              thumbColor: Colors.white,
              trackHeight: 4,
              activeTrackColor: widget.lineColor,
              inactiveTrackColor: Colors.grey.withOpacity(0.3),
            ),
            child: Slider(
              value: _selectedThickness,
              min: 0.5,
              max: 20.0,
              divisions: 39, // 0.5 step increments
              label: _selectedThickness.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _selectedThickness = value);
              },
            ),
          ),
          
          // Preview of selected thickness
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Container(
                  height: _selectedThickness,
                  width: 80,
                  decoration: BoxDecoration(
                    color: widget.lineColor,
                    borderRadius: BorderRadius.circular(_selectedThickness / 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}