// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:design_system_widgetbook/use_cases/app_button.dart'
    as _design_system_widgetbook_use_cases_app_button;
import 'package:design_system_widgetbook/use_cases/app_card.dart'
    as _design_system_widgetbook_use_cases_app_card;
import 'package:design_system_widgetbook/use_cases/app_chip.dart'
    as _design_system_widgetbook_use_cases_app_chip;
import 'package:design_system_widgetbook/use_cases/app_list_tile.dart'
    as _design_system_widgetbook_use_cases_app_list_tile;
import 'package:design_system_widgetbook/use_cases/app_text_field.dart'
    as _design_system_widgetbook_use_cases_app_text_field;
import 'package:design_system_widgetbook/use_cases/loading.dart'
    as _design_system_widgetbook_use_cases_loading;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'components',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'app_button',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppButton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'destructive',
                builder: _design_system_widgetbook_use_cases_app_button
                    .buttonDestructive,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'primary',
                builder: _design_system_widgetbook_use_cases_app_button
                    .buttonPrimary,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'secondary',
                builder: _design_system_widgetbook_use_cases_app_button
                    .buttonSecondary,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'sizes',
                builder:
                    _design_system_widgetbook_use_cases_app_button.buttonSizes,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'skeleton',
                builder: _design_system_widgetbook_use_cases_app_button
                    .buttonSkeleton,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'tertiary',
                builder: _design_system_widgetbook_use_cases_app_button
                    .buttonTertiary,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with icons',
                builder:
                    _design_system_widgetbook_use_cases_app_button.buttonIcons,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'app_card',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'elevated',
                builder:
                    _design_system_widgetbook_use_cases_app_card.cardElevated,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'filled',
                builder:
                    _design_system_widgetbook_use_cases_app_card.cardFilled,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'outlined',
                builder:
                    _design_system_widgetbook_use_cases_app_card.cardOutlined,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'skeleton',
                builder:
                    _design_system_widgetbook_use_cases_app_card.cardSkeleton,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'app_chip',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppChip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'all statuses',
                builder:
                    _design_system_widgetbook_use_cases_app_chip.chipStatuses,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'assist',
                builder:
                    _design_system_widgetbook_use_cases_app_chip.chipAssist,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'filter',
                builder:
                    _design_system_widgetbook_use_cases_app_chip.chipFilter,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'input',
                builder: _design_system_widgetbook_use_cases_app_chip.chipInput,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'skeleton',
                builder:
                    _design_system_widgetbook_use_cases_app_chip.chipSkeleton,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'status',
                builder:
                    _design_system_widgetbook_use_cases_app_chip.chipStatus,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'app_list_tile',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppListTile',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'checkbox',
                builder: _design_system_widgetbook_use_cases_app_list_tile
                    .listTileCheckbox,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'navigation',
                builder: _design_system_widgetbook_use_cases_app_list_tile
                    .listTileNavigation,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'skeleton',
                builder: _design_system_widgetbook_use_cases_app_list_tile
                    .listTileSkeleton,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'standard',
                builder: _design_system_widgetbook_use_cases_app_list_tile
                    .listTileStandard,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'app_text_field',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppTextField',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'date',
                builder: _design_system_widgetbook_use_cases_app_text_field
                    .textFieldDate,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder: _design_system_widgetbook_use_cases_app_text_field
                    .textFieldDefault,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'multiline',
                builder: _design_system_widgetbook_use_cases_app_text_field
                    .textFieldMultiline,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'number',
                builder: _design_system_widgetbook_use_cases_app_text_field
                    .textFieldNumber,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'prefix and suffix',
                builder: _design_system_widgetbook_use_cases_app_text_field
                    .textFieldIcons,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'select',
                builder: _design_system_widgetbook_use_cases_app_text_field
                    .textFieldSelect,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'sizes',
                builder: _design_system_widgetbook_use_cases_app_text_field
                    .textFieldSizes,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'skeleton',
                builder: _design_system_widgetbook_use_cases_app_text_field
                    .textFieldSkeleton,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
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
