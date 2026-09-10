import 'package:aura_stylist_ai/core/permissions/app_permission.dart';
import 'package:aura_stylist_ai/core/permissions/permission_gateway.dart';

class FakePermissionGateway implements PermissionGateway {
  FakePermissionGateway({AppPermissionState initialStatus = AppPermissionState.denied})
      : _status = initialStatus;

  AppPermissionState _status;
  bool openSettingsCalled = false;

  /// What `request()` will resolve the status to — lets tests simulate the
  /// user granting, denying, or permanently denying the OS prompt.
  AppPermissionState? nextRequestResult;

  @override
  Future<AppPermissionState> checkStatus(AppPermission permission) async => _status;

  @override
  Future<AppPermissionState> request(AppPermission permission) async {
    _status = nextRequestResult ?? _status;
    return _status;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalled = true;
  }
}
