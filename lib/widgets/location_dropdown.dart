import 'package:flutter/material.dart';

class LocationDropdown extends StatefulWidget {
  final String selectedLocation;
  final Function(String) onLocationChanged;

  const LocationDropdown({
    super.key,
    required this.selectedLocation,
    required this.onLocationChanged,
  });

  @override
  State<LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends State<LocationDropdown> {
  final List<String> zimbabweCities = [
    'Harare',
    'Bulawayo',
    'Chitungwiza',
    'Mutare',
    'Gweru',
    'Kwekwe',
    'Kadoma',
    'Masvingo',
    'Chinhoyi',
    'Marondera',
    'Bindura',
    'Beitbridge',
    'Hwange',
    'Victoria Falls',
    'Chipinge',
    'Rusape',
    'Chegutu',
    'Norton',
    'Redcliff',
    'Chiredzi',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        onSelected: (String location) {
          widget.onLocationChanged(location);
        },
        itemBuilder: (BuildContext context) {
          return zimbabweCities.map((city) {
            return PopupMenuItem<String>(
              value: city,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: widget.selectedLocation == city
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      city,
                      style: TextStyle(
                        fontWeight: widget.selectedLocation == city
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: widget.selectedLocation == city
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (widget.selectedLocation == city)
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                widget.selectedLocation,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
