import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { admin, usuario, olheiro }

enum TeamPermission {
  // Permissões de visualização
  viewTeams,
  viewTeamDetails,
  viewTeamMembers,

  // Permissões de criação
  createTeam,
  createTeamRequest,

  // Permissões de edição
  editOwnTeam,
  editTeamDetails,
  inviteMembers,
  removeMembers,
  transferCaptaincy,

  // Permissões de administração
  approveTeams,
  rejectTeams,
  deleteTeams,
  manageAllTeams,

  // Permissões de membro
  joinTeam,
  leaveTeam,
  acceptInvites,
  rejectInvites,
}

class RoleService {
  static final RoleService _instance = RoleService._internal();
  factory RoleService() => _instance;
  RoleService._internal();

  UserRole? _cachedRole;

  Future<UserRole> getCurrentUserRole() async {
    if (_cachedRole != null) return _cachedRole!;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _cachedRole = UserRole.usuario;
      return _cachedRole!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};
      final String roleStr =
          (data['role'] as String?)?.toLowerCase() ?? 'usuario';
      _cachedRole = _fromString(roleStr);
      return _cachedRole!;
    } catch (_) {
      _cachedRole = UserRole.usuario;
      return _cachedRole!;
    }
  }

  void clearCache() {
    _cachedRole = null;
  }

  // Método estático para limpar cache globalmente
  static void clearAllCaches() {
    _instance.clearCache();
  }

  UserRole _fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'olheiro':
        return UserRole.olheiro;
      case 'usuario':
      default:
        return UserRole.usuario;
    }
  }

  /// Verifica se o usuário atual tem uma permissão específica
  Future<bool> hasPermission(TeamPermission permission) async {
    final role = await getCurrentUserRole();
    return _hasPermissionForRole(role, permission);
  }

  /// Verifica se um role específico tem uma permissão
  bool _hasPermissionForRole(UserRole role, TeamPermission permission) {
    switch (role) {
      case UserRole.admin:
        return _getAdminPermissions().contains(permission);
      case UserRole.olheiro:
        return _getOlheiroPermissions().contains(permission);
      case UserRole.usuario:
        return _getUsuarioPermissions().contains(permission);
    }
  }

  /// Permissões para administradores
  List<TeamPermission> _getAdminPermissions() {
    return [
      // Visualização
      TeamPermission.viewTeams,
      TeamPermission.viewTeamDetails,
      TeamPermission.viewTeamMembers,

      // Criação
      TeamPermission.createTeam,
      TeamPermission.createTeamRequest,

      // Edição
      TeamPermission.editOwnTeam,
      TeamPermission.editTeamDetails,
      TeamPermission.inviteMembers,
      TeamPermission.removeMembers,
      TeamPermission.transferCaptaincy,

      // Administração
      TeamPermission.approveTeams,
      TeamPermission.rejectTeams,
      TeamPermission.deleteTeams,
      TeamPermission.manageAllTeams,

      // Membros
      TeamPermission.joinTeam,
      TeamPermission.leaveTeam,
      TeamPermission.acceptInvites,
      TeamPermission.rejectInvites,
    ];
  }

  /// Permissões para olheiros
  List<TeamPermission> _getOlheiroPermissions() {
    return [
      // Visualização
      TeamPermission.viewTeams,
      TeamPermission.viewTeamDetails,
      TeamPermission.viewTeamMembers,

      // Criação
      TeamPermission.createTeamRequest,

      // Edição (apenas do próprio time)
      TeamPermission.editOwnTeam,
      TeamPermission.inviteMembers,
      TeamPermission.removeMembers,
      TeamPermission.transferCaptaincy,

      // Membros
      TeamPermission.joinTeam,
      TeamPermission.leaveTeam,
      TeamPermission.acceptInvites,
      TeamPermission.rejectInvites,
    ];
  }

  /// Permissões para usuários comuns
  List<TeamPermission> _getUsuarioPermissions() {
    return [
      // Visualização
      TeamPermission.viewTeams,
      TeamPermission.viewTeamDetails,
      TeamPermission.viewTeamMembers,

      // Criação
      TeamPermission.createTeamRequest,

      // Edição (apenas do próprio time)
      TeamPermission.editOwnTeam,
      TeamPermission.inviteMembers,
      TeamPermission.removeMembers,
      TeamPermission.transferCaptaincy,

      // Membros
      TeamPermission.joinTeam,
      TeamPermission.leaveTeam,
      TeamPermission.acceptInvites,
      TeamPermission.rejectInvites,
    ];
  }

  /// Verifica se o usuário pode gerenciar um time específico
  Future<bool> canManageTeam(String teamId) async {
    final role = await getCurrentUserRole();

    // Admins podem gerenciar qualquer time
    if (role == UserRole.admin) return true;

    // Outros usuários só podem gerenciar times dos quais são capitão
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();

      if (!teamDoc.exists) return false;

      final teamData = teamDoc.data()!;
      return teamData['captainId'] == user.uid;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o usuário é capitão de um time
  Future<bool> isTeamCaptain(String teamId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();

      if (!teamDoc.exists) return false;

      final teamData = teamDoc.data()!;
      return teamData['captainId'] == user.uid;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o usuário é membro de um time
  Future<bool> isTeamMember(String teamId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();

      if (!teamDoc.exists) return false;

      final teamData = teamDoc.data()!;
      final members = teamData['members'] as List<dynamic>? ?? [];

      return members.any(
        (member) =>
            member['userId'] == user.uid && (member['isActive'] ?? true),
      );
    } catch (e) {
      return false;
    }
  }
}
