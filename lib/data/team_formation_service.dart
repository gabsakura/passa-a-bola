import 'package:cloud_firestore/cloud_firestore.dart';
import 'team_formation_models.dart';
import 'dart:math';

class TeamFormationService {
  static const String _formedTeamsCollection = 'formed_teams';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Formar times automaticamente a partir de participantes individuais
  static Future<List<FormedTeam>> formTeamsFromIndividuals(
    String championshipId,
    List<IndividualPlayer> individualPlayers, {
    TeamFormationConfig? config,
  }) async {
    final formationConfig = config ?? const TeamFormationConfig();
    final formedTeams = <FormedTeam>[];

    print(
      'DEBUG: Iniciando formação de times com ${individualPlayers.length} jogadores',
    );

    // Filtrar jogadores por posição
    final goalkeepers = individualPlayers
        .where((p) => p.position == PlayerPosition.goalkeeper)
        .toList();
    final defenders = individualPlayers
        .where((p) => p.position == PlayerPosition.defender)
        .toList();
    final midfielders = individualPlayers
        .where((p) => p.position == PlayerPosition.midfielder)
        .toList();
    final forwards = individualPlayers
        .where((p) => p.position == PlayerPosition.forward)
        .toList();

    print('DEBUG: Distribuição por posição:');
    print('  Goleiras: ${goalkeepers.length}');
    print('  Defesas: ${defenders.length}');
    print('  Meio-campo: ${midfielders.length}');
    print('  Atacantes: ${forwards.length}');

    // Verificar se há jogadores suficientes
    if (goalkeepers.length < formationConfig.minGoalkeepers) {
      throw Exception('Não há goleiras suficientes para formar times');
    }

    // Calcular número máximo de times possíveis
    final maxTeamsFromGoalkeepers =
        goalkeepers.length ~/ formationConfig.minGoalkeepers;
    final maxTeamsFromDefenders =
        defenders.length ~/ formationConfig.minDefenders;
    final maxTeamsFromMidfielders =
        midfielders.length ~/ formationConfig.minMidfielders;
    final maxTeamsFromForwards = forwards.length ~/ formationConfig.minForwards;

    final maxPossibleTeams = [
      maxTeamsFromGoalkeepers,
      maxTeamsFromDefenders,
      maxTeamsFromMidfielders,
      maxTeamsFromForwards,
    ].reduce(min);

    print('DEBUG: Máximo de times possíveis: $maxPossibleTeams');

    if (maxPossibleTeams == 0) {
      throw Exception(
        'Não há jogadores suficientes para formar pelo menos um time',
      );
    }

    // Formar times
    for (int teamIndex = 0; teamIndex < maxPossibleTeams; teamIndex++) {
      try {
        final team = await _formSingleTeam(
          championshipId,
          teamIndex + 1,
          goalkeepers,
          defenders,
          midfielders,
          forwards,
          formationConfig,
        );

        if (team != null) {
          formedTeams.add(team);
          print('DEBUG: Time ${teamIndex + 1} formado: ${team.name}');
        }
      } catch (e) {
        print('DEBUG: Erro ao formar time ${teamIndex + 1}: $e');
      }
    }

    print('DEBUG: Total de times formados: ${formedTeams.length}');
    return formedTeams;
  }

  /// Formar um único time
  static Future<FormedTeam?> _formSingleTeam(
    String championshipId,
    int teamNumber,
    List<IndividualPlayer> goalkeepers,
    List<IndividualPlayer> defenders,
    List<IndividualPlayer> midfielders,
    List<IndividualPlayer> forwards,
    TeamFormationConfig config,
  ) async {
    final teamPlayers = <IndividualPlayer>[];
    final usedPlayerIds = <String>{};

    // Selecionar goleira
    if (goalkeepers.isNotEmpty) {
      final goalkeeper = _selectBestPlayer(goalkeepers, usedPlayerIds);
      if (goalkeeper != null) {
        teamPlayers.add(goalkeeper);
        usedPlayerIds.add(goalkeeper.id);
      }
    }

    // Selecionar defesas
    final defendersNeeded = _calculatePlayersNeeded(
      defenders.length,
      config.minDefenders,
      config.maxDefenders,
      teamPlayers.length,
      config.maxPlayersPerTeam,
    );

    for (int i = 0; i < defendersNeeded; i++) {
      final defender = _selectBestPlayer(defenders, usedPlayerIds);
      if (defender != null) {
        teamPlayers.add(defender);
        usedPlayerIds.add(defender.id);
      }
    }

    // Selecionar meio-campistas
    final midfieldersNeeded = _calculatePlayersNeeded(
      midfielders.length,
      config.minMidfielders,
      config.maxMidfielders,
      teamPlayers.length,
      config.maxPlayersPerTeam,
    );

    for (int i = 0; i < midfieldersNeeded; i++) {
      final midfielder = _selectBestPlayer(midfielders, usedPlayerIds);
      if (midfielder != null) {
        teamPlayers.add(midfielder);
        usedPlayerIds.add(midfielder.id);
      }
    }

    // Selecionar atacantes
    final forwardsNeeded = _calculatePlayersNeeded(
      forwards.length,
      config.minForwards,
      config.maxForwards,
      teamPlayers.length,
      config.maxPlayersPerTeam,
    );

    for (int i = 0; i < forwardsNeeded; i++) {
      final forward = _selectBestPlayer(forwards, usedPlayerIds);
      if (forward != null) {
        teamPlayers.add(forward);
        usedPlayerIds.add(forward.id);
      }
    }

    // Verificar se o time tem o mínimo de jogadores
    if (teamPlayers.length < config.minPlayersPerTeam) {
      return null;
    }

    // Selecionar capitão (jogador com maior nível de habilidade)
    final captain = teamPlayers.reduce(
      (a, b) => a.skillLevel.value > b.skillLevel.value ? a : b,
    );

    // Calcular estatísticas do time
    final averageSkill =
        teamPlayers.map((p) => p.skillLevel.value).reduce((a, b) => a + b) /
        teamPlayers.length;

    final positionCount = <PlayerPosition, int>{};
    for (final position in PlayerPosition.values) {
      positionCount[position] = teamPlayers
          .where((p) => p.position == position)
          .length;
    }

    final isBalanced = _isTeamBalanced(positionCount, config);

    // Criar time
    final team = FormedTeam(
      id: '${championshipId}_team_$teamNumber',
      name: 'Time $teamNumber',
      players: teamPlayers,
      captain: captain,
      averageSkill: averageSkill,
      isBalanced: isBalanced,
      positionCount: positionCount,
      createdAt: DateTime.now(),
    );

    return team;
  }

  /// Selecionar o melhor jogador disponível
  static IndividualPlayer? _selectBestPlayer(
    List<IndividualPlayer> players,
    Set<String> usedPlayerIds,
  ) {
    final availablePlayers = players
        .where((p) => !usedPlayerIds.contains(p.id))
        .toList();

    if (availablePlayers.isEmpty) return null;

    // Ordenar por nível de habilidade (maior primeiro) e depois por data de inscrição (mais antigo primeiro)
    availablePlayers.sort((a, b) {
      final skillComparison = b.skillLevel.value.compareTo(a.skillLevel.value);
      if (skillComparison != 0) return skillComparison;
      return a.registeredAt.compareTo(b.registeredAt);
    });

    return availablePlayers.first;
  }

  /// Calcular quantos jogadores de uma posição são necessários
  static int _calculatePlayersNeeded(
    int availablePlayers,
    int minNeeded,
    int maxNeeded,
    int currentTeamSize,
    int maxTeamSize,
  ) {
    final remainingSlots = maxTeamSize - currentTeamSize;
    final maxPossible = min(availablePlayers, min(maxNeeded, remainingSlots));
    return max(minNeeded, maxPossible);
  }

  /// Verificar se o time está balanceado
  static bool _isTeamBalanced(
    Map<PlayerPosition, int> positionCount,
    TeamFormationConfig config,
  ) {
    return positionCount[PlayerPosition.goalkeeper]! >= config.minGoalkeepers &&
        positionCount[PlayerPosition.goalkeeper]! <= config.maxGoalkeepers &&
        positionCount[PlayerPosition.defender]! >= config.minDefenders &&
        positionCount[PlayerPosition.defender]! <= config.maxDefenders &&
        positionCount[PlayerPosition.midfielder]! >= config.minMidfielders &&
        positionCount[PlayerPosition.midfielder]! <= config.maxMidfielders &&
        positionCount[PlayerPosition.forward]! >= config.minForwards &&
        positionCount[PlayerPosition.forward]! <= config.maxForwards;
  }

  /// Salvar times formados no Firestore
  static Future<void> saveFormedTeams(
    String championshipId,
    List<FormedTeam> teams,
  ) async {
    final batch = _firestore.batch();

    for (final team in teams) {
      final teamRef = _firestore
          .collection(_formedTeamsCollection)
          .doc(team.id);
      batch.set(teamRef, team.toMap());
    }

    await batch.commit();
    print('DEBUG: ${teams.length} times salvos no Firestore');
  }

  /// Buscar times formados de um campeonato
  static Future<List<FormedTeam>> getFormedTeams(String championshipId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_formedTeamsCollection)
          .where('id', isGreaterThan: '${championshipId}_')
          .where('id', isLessThan: '${championshipId}_z')
          .get();

      return querySnapshot.docs
          .map((doc) => FormedTeam.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('DEBUG: Erro ao buscar times formados: $e');
      return [];
    }
  }

  /// Aprovar time formado
  static Future<void> approveTeam(String teamId) async {
    await _firestore.collection(_formedTeamsCollection).doc(teamId).update({
      'status': TeamFormationStatus.approved.name,
    });
  }

  /// Rejeitar time formado
  static Future<void> rejectTeam(String teamId) async {
    await _firestore.collection(_formedTeamsCollection).doc(teamId).update({
      'status': TeamFormationStatus.rejected.name,
    });
  }

  /// Deletar time formado
  static Future<void> deleteTeam(String teamId) async {
    await _firestore.collection(_formedTeamsCollection).doc(teamId).delete();
  }
}
