import '../models/permission.dart';
import '../models/user.dart';

/// Centralized, single source of truth for "can the current user do X?".
///
/// Every screen, widget, and route guard asks THIS service, never a raw
/// `user.role == UserRole.blind` check. This is what makes the RBAC system
/// maintainable: adding/removing a feature from a role means changing the
/// backend's permission grant (and, for the default/optimistic map, one line
/// in role_permission_map.dart) — not hunting through every screen.
///
/// This class is intentionally "dumb": it trusts the permission set it is
/// given. That set must always originate from the backend's authenticated
/// response. Client-side checks like this are a UX convenience (hide a
/// button) — the backend re-checks every request independently (see
/// backend/src/middleware/authorize.js), because frontend hiding is never a
/// substitute for server-side authorization.
class PermissionService {
  final AppUser? _user;

  const PermissionService(this._user);

  bool has(Permission permission) =>
      _user != null && _user.permissions.contains(permission);

  bool hasAny(Iterable<Permission> permissions) =>
      permissions.any((p) => has(p));

  bool hasAll(Iterable<Permission> permissions) =>
      permissions.every((p) => has(p));

  Set<Permission> get all => _user?.permissions ?? const {};
}
