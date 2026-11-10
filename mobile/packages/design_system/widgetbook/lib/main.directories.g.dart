// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:design_system_widgetbook/use_cases/loading.dart'
    as _design_system_widgetbook_use_cases_loading;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'loading',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'AppShimmer',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'shimmer region',
            builder: _design_system_widgetbook_use_cases_loading.shimmerRegion,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'AppSkeleton',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'box',
            builder: _design_system_widgetbook_use_cases_loading.skeletonBox,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'circle',
            builder: _design_system_widgetbook_use_cases_loading.skeletonCircle,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'line',
            builder: _design_system_widgetbook_use_cases_loading.skeletonLine,
          ),
        ],
      ),
    ],
  ),
];
