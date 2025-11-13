import 'package:financial_tracker/services/api_service.dart';
import 'package:flutter/material.dart';

class DayDropdown extends StatefulWidget {
  final ValueChanged<int> daysUpdated;

  const DayDropdown({
    super.key,
    required this.daysUpdated,
  });

  @override
  State<DayDropdown> createState() => _DayDropdownState();
}

class _DayDropdownState extends State<DayDropdown> {
  final List<int> _daysOptions = [30, 60, 90];
  int? _selectedDays = ApiService.interval;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: SizedBox(
        height: 40,
        child: DropdownButtonFormField<int>(
          initialValue: _selectedDays,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.onPrimary, 
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (int? newValue) {
            setState(() {
              _selectedDays = newValue;
              ApiService.setMyVariable(newValue!);
              widget.daysUpdated(newValue);
            });
          },
          items: _daysOptions.map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(
                'Last $value days',
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
          dropdownColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}