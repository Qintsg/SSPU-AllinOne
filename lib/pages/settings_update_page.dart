/* 清源应用更新任务页。 */

import '../design/qingyuan/qingyuan_ui.dart';
import '../services/app_update_service.dart';
import '../widgets/settings_update_section.dart';

class SettingsUpdatePage extends StatelessWidget {
  const SettingsUpdatePage({
    super.key,
    this.updateService,
    this.launchUrlOverride,
  });

  final AppUpdateService? updateService;
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  @override
  Widget build(BuildContext context) {
    return SettingsUpdateSection(
      updateService: updateService,
      launchUrlOverride: launchUrlOverride,
      taskPage: true,
    );
  }
}
