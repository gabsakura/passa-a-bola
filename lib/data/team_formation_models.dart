enum PlayerPosition {
  goalkeeper('Goleira', 'GK'),
  defender('Defesa', 'DEF'),
  midfielder('Meio-Campo', 'MC'),
  forward('Atacante', 'ATA');

  const PlayerPosition(this.displayName, this.shortName);
  final String displayName;
  final String shortName;
}

enum SkillLevel {
  beginner('Iniciante', 1),
  intermediate('Intermediário', 2),
  advanced('Avançado', 3);

  const SkillLevel(this.displayName, this.value);
  final String displayName;
  final int value;
}

class IndividualPlayer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final PlayerPosition position;
  final SkillLevel skillLevel;
  final DateTime registeredAt;
  final Map<String, dynamic> additionalInfo;

  IndividualPlayer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.skillLevel,
    required this.registeredAt,
    this.additionalInfo = const {},
  });

  factory IndividualPlayer.fromMap(Map<String, dynamic> data) {
    return IndividualPlayer(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Nome não informado',
      email: data['email'] ?? 'Email não informado',
      phone: data['phone'] ?? 'Telefone não informado',
      position: _parsePosition(data['position']),
      skillLevel: _parseSkillLevel(data['skillLevel']),
      registeredAt: data['registeredAt'] is DateTime
          ? data['registeredAt']
          : DateTime.now(),
      additionalInfo: data['additionalInfo'] ?? {},
    );
  }

  static PlayerPosition _parsePosition(String? position) {
    if (position == null) return PlayerPosition.midfielder;

    final pos = position.toLowerCase();
    if (pos.contains('goleir') || pos.contains('gk')) {
      return PlayerPosition.goalkeeper;
    }
    if (pos.contains('defes') ||
        pos.contains('zagueir') ||
        pos.contains('lateral')) {
      return PlayerPosition.defender;
    }
    if (pos.contains('atacant') ||
        pos.contains('pont') ||
        pos.contains('centroav')) {
      return PlayerPosition.forward;
    }
    return PlayerPosition.midfielder;
  }

  static SkillLevel _parseSkillLevel(String? skillLevel) {
    if (skillLevel == null) return SkillLevel.beginner;

    final skill = skillLevel.toLowerCase();
    if (skill.contains('avançad') || skill.contains('advanced')) {
      return SkillLevel.advanced;
    }
    if (skill.contains('intermedi') || skill.contains('intermediate')) {
      return SkillLevel.intermediate;
    }
    return SkillLevel.beginner;
  }
}

class FormedTeam {
  final String id;
  final String name;
  final List<IndividualPlayer> players;
  final IndividualPlayer captain;
  final double averageSkill;
  final bool isBalanced;
  final Map<PlayerPosition, int> positionCount;
  final DateTime createdAt;
  final TeamFormationStatus status;

  FormedTeam({
    required this.id,
    required this.name,
    required this.players,
    required this.captain,
    required this.averageSkill,
    required this.isBalanced,
    required this.positionCount,
    required this.createdAt,
    this.status = TeamFormationStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'players': players
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'email': p.email,
              'phone': p.phone,
              'position': p.position.name,
              'skillLevel': p.skillLevel.name,
              'registeredAt': p.registeredAt,
              'additionalInfo': p.additionalInfo,
            },
          )
          .toList(),
      'captainId': captain.id,
      'averageSkill': averageSkill,
      'isBalanced': isBalanced,
      'positionCount': positionCount.map((k, v) => MapEntry(k.name, v)),
      'createdAt': createdAt,
      'status': status.name,
    };
  }

  factory FormedTeam.fromMap(Map<String, dynamic> data) {
    final players = (data['players'] as List<dynamic>)
        .map((p) => IndividualPlayer.fromMap(p as Map<String, dynamic>))
        .toList();

    final captainId = data['captainId'] as String;
    final captain = players.firstWhere((p) => p.id == captainId);

    return FormedTeam(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Time Formado',
      players: players,
      captain: captain,
      averageSkill: (data['averageSkill'] ?? 0.0).toDouble(),
      isBalanced: data['isBalanced'] ?? false,
      positionCount: (data['positionCount'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          PlayerPosition.values.firstWhere((p) => p.name == k),
          v as int,
        ),
      ),
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.now(),
      status: TeamFormationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TeamFormationStatus.pending,
      ),
    );
  }
}

enum TeamFormationStatus {
  pending('Pendente'),
  approved('Aprovado'),
  rejected('Rejeitado'),
  active('Ativo');

  const TeamFormationStatus(this.displayName);
  final String displayName;
}

class TeamFormationConfig {
  final int minPlayersPerTeam;
  final int maxPlayersPerTeam;
  final int minGoalkeepers;
  final int maxGoalkeepers;
  final int minDefenders;
  final int maxDefenders;
  final int minMidfielders;
  final int maxMidfielders;
  final int minForwards;
  final int maxForwards;
  final bool requireBalancedSkill;
  final double maxSkillVariance;

  const TeamFormationConfig({
    this.minPlayersPerTeam = 7,
    this.maxPlayersPerTeam = 11,
    this.minGoalkeepers = 1,
    this.maxGoalkeepers = 1,
    this.minDefenders = 2,
    this.maxDefenders = 4,
    this.minMidfielders = 2,
    this.maxMidfielders = 4,
    this.minForwards = 1,
    this.maxForwards = 3,
    this.requireBalancedSkill = true,
    this.maxSkillVariance = 1.0,
  });
}
