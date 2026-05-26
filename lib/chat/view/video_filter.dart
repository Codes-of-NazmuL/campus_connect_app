import 'package:flutter/material.dart';

class VideoFilter {
  final String name;
  final ColorFilter? colorFilter;
  final Color previewColor;

  const VideoFilter({
    required this.name,
    this.colorFilter,
    required this.previewColor,
  });
}

class VideoFilters {
  static const List<VideoFilter> presets = [
    VideoFilter(
      name: 'None',
      colorFilter: null,
      previewColor: Colors.transparent,
    ),
    VideoFilter(
      name: 'Grayscale',
      colorFilter: ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]),
      previewColor: Colors.grey,
    ),
    VideoFilter(
      name: 'Sepia',
      colorFilter: ColorFilter.matrix(<double>[
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0,     0,     0,     1, 0,
      ]),
      previewColor: Color(0xFFC4A882),
    ),
    VideoFilter(
      name: 'Warm',
      colorFilter: ColorFilter.matrix(<double>[
        1.2, 0,   0,   0, 10,
        0,   1.0, 0,   0, 0,
        0,   0,   0.8, 0, -10,
        0,   0,   0,   1, 0,
      ]),
      previewColor: Color(0xFFFF9E6D),
    ),
    VideoFilter(
      name: 'Cool',
      colorFilter: ColorFilter.matrix(<double>[
        0.8, 0,   0,   0, -10,
        0,   1.0, 0,   0, 0,
        0,   0,   1.2, 0, 10,
        0,   0,   0,   1, 0,
      ]),
      previewColor: Color(0xFF6DB4FF),
    ),
    VideoFilter(
      name: 'Vintage',
      colorFilter: ColorFilter.matrix(<double>[
        0.9, 0.1, 0.1, 0, 5,
        0.1, 0.8, 0.1, 0, 5,
        0.1, 0.1, 0.7, 0, -5,
        0,   0,   0,   0.95, 0,
      ]),
      previewColor: Color(0xFFBCA88A),
    ),
    VideoFilter(
      name: 'Night',
      colorFilter: ColorFilter.matrix(<double>[
        0.2, 0.1, 0,   0, 0,
        0.1, 0.8, 0.1, 0, 5,
        0,   0.1, 0.3, 0, 0,
        0,   0,   0,   1, 0,
      ]),
      previewColor: Color(0xFF2ECC71),
    ),
  ];
}

class FilterPickerSheet extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onFilterSelected;

  const FilterPickerSheet({
    super.key,
    required this.selectedIndex,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xDD1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Video Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: VideoFilters.presets.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final filter = VideoFilters.presets[index];
                final isSelected = index == selectedIndex;
                return GestureDetector(
                  onTap: () => onFilterSelected(index),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filter.previewColor == Colors.transparent
                              ? Colors.white12
                              : filter.previewColor,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white24,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: filter.previewColor == Colors.transparent
                            ? const Icon(Icons.block, color: Colors.white38, size: 20)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        filter.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
