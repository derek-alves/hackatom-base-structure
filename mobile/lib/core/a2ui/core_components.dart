import 'package:a2ui_flutter/a2ui_flutter.dart';

import 'components/action_checklist_card.dart';
import 'components/approval_confirmation_card.dart';
import 'components/dynamic_form_card.dart';
import 'components/info_list_card.dart';
import 'components/summary_kpi_card.dart';

const String appCatalogId =
    'https://hackathon-starter.dev/catalogs/app/v1/catalog.json';

final List<ComponentImplementation> coreComponents = [
  summaryKpiCardComponent,
  actionChecklistCardComponent,
  approvalConfirmationCardComponent,
  infoListCardComponent,
  dynamicFormCardComponent,
];
