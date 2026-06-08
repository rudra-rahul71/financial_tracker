import 'package:flutter/material.dart';

enum DateFilterType {
  rollingDays,
  calendarMonth,
}

class DateFilter {
  final DateFilterType type;
  final int value; // number of days for rolling, or month offset for calendar month
  final bool isHeader;
  final String? headerText;
  final bool isDivider;

  const DateFilter.rolling(this.value)
      : type = DateFilterType.rollingDays,
        isHeader = false,
        isDivider = false,
        headerText = null;

  const DateFilter.month(this.value)
      : type = DateFilterType.calendarMonth,
        isHeader = false,
        isDivider = false,
        headerText = null;

  const DateFilter.header(this.headerText)
      : type = DateFilterType.rollingDays,
        value = -1,
        isHeader = true,
        isDivider = false;

  const DateFilter.divider(int id)
      : type = DateFilterType.rollingDays,
        value = -1 - id,
        isHeader = false,
        isDivider = true,
        headerText = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value &&
          isHeader == other.isHeader &&
          isDivider == other.isDivider &&
          headerText == other.headerText;

  @override
  int get hashCode =>
      type.hashCode ^
      value.hashCode ^
      isHeader.hashCode ^
      isDivider.hashCode ^
      headerText.hashCode;

  String getLabel() {
    if (isHeader) return headerText ?? '';
    if (isDivider) return '';
    if (type == DateFilterType.rollingDays) {
      return 'Last $value Days';
    } else {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month - value, 1);
      const List<String> monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthStr = monthNames[date.month - 1];
      final yearStr = date.year.toString();
      if (value == 0) return '$monthStr $yearStr (This Month)';
      if (value == 1) return '$monthStr $yearStr (Last Month)';
      return '$monthStr $yearStr';
    }
  }

  DateTimeRange getDateTimeRange() {
    final now = DateTime.now();
    if (type == DateFilterType.rollingDays) {
      final startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: value));
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      return DateTimeRange(start: startDate, end: endDate);
    } else {
      final startDate = DateTime(now.year, now.month - value, 1);
      final nextMonthStart = DateTime(now.year, now.month - value + 1, 1);
      final endDate = nextMonthStart.subtract(const Duration(milliseconds: 1));
      return DateTimeRange(start: startDate, end: endDate);
    }
  }
}

class DateFilterDropdown extends StatefulWidget {
  final DateFilter initialFilter;
  final ValueChanged<DateFilter> filterUpdated;

  const DateFilterDropdown({
    super.key,
    required this.initialFilter,
    required this.filterUpdated,
  });

  @override
  State<DateFilterDropdown> createState() => _DateFilterDropdownState();
}

class _DateFilterDropdownState extends State<DateFilterDropdown> {
  final List<DateFilter> _filterItems = const [
    DateFilter.header('CALENDAR MONTHS'),
    DateFilter.month(0),
    DateFilter.month(1),
    DateFilter.month(2),
    DateFilter.divider(1),
    DateFilter.header('ROLLING RANGES'),
    DateFilter.rolling(30),
    DateFilter.rolling(60),
    DateFilter.rolling(90),
  ];

  late DateFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant DateFilterDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _selectedFilter = widget.initialFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback if initialFilter is not in list
    if (!_filterItems.contains(_selectedFilter)) {
      _selectedFilter = const DateFilter.rolling(30);
    }

    return IntrinsicWidth(
      child: SizedBox(
        height: 40,
        child: DropdownButtonFormField<DateFilter>(
          key: ValueKey(_selectedFilter),
          initialValue: _selectedFilter,
          isExpanded: false,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.onPrimary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (DateFilter? newValue) {
            if (newValue != null && newValue != _selectedFilter) {
              setState(() {
                _selectedFilter = newValue;
              });
              widget.filterUpdated(newValue);
            }
          },
          selectedItemBuilder: (BuildContext context) {
            return _filterItems.map((item) {
              if (item.isHeader || item.isDivider) {
                return const SizedBox.shrink();
              }
              return Text(
                item.getLabel(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              );
            }).toList();
          },
          items: _filterItems.map<DropdownMenuItem<DateFilter>>((DateFilter filter) {
            if (filter.isHeader) {
              return DropdownMenuItem<DateFilter>(
                value: filter,
                enabled: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
                  child: Text(
                    filter.getLabel(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              );
            } else if (filter.isDivider) {
              return DropdownMenuItem<DateFilter>(
                value: filter,
                enabled: false,
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              );
            } else {
              return DropdownMenuItem<DateFilter>(
                value: filter,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.0),
                  child: Text(
                    filter.getLabel(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                  ),
                ),
              );
            }
          }).toList(),
          dropdownColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
