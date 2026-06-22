import 'package:flutter/material.dart';
import '../data/constants.dart';
import '../data/championship_model.dart';
import '../data/team_formation_models.dart';
import '../data/team_formation_service.dart';
import '../data/championship_service.dart';

class TeamFormationPage extends StatefulWidget {
  final Championship championship;

  const TeamFormationPage({super.key, required this.championship});

  @override
  State<TeamFormationPage> createState() => _TeamFormationPageState();
}

class _TeamFormationPageState extends State<TeamFormationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<IndividualPlayer> _individualPlayers = [];
  List<FormedTeam> _formedTeams = [];
  bool _isLoading = true;
  bool _isFormingTeams = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Carregar participantes individuais
      final participantsData =
          await ChampionshipService.getChampionshipParticipants(
            widget.championship.id,
          );

      final individualParticipants =
          participantsData['individualParticipants'] as List<dynamic>;
      _individualPlayers = individualParticipants
          .map((p) => IndividualPlayer.fromMap(p as Map<String, dynamic>))
          .toList();

      // Carregar times já formados
      _formedTeams = await TeamFormationService.getFormedTeams(
        widget.championship.id,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _formTeams() async {
    try {
      setState(() {
        _isFormingTeams = true;
      });

      final teams = await TeamFormationService.formTeamsFromIndividuals(
        widget.championship.id,
        _individualPlayers,
      );

      await TeamFormationService.saveFormedTeams(widget.championship.id, teams);

      setState(() {
        _formedTeams = teams;
        _isFormingTeams = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${teams.length} times formados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isFormingTeams = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao formar times: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Formação de Times - ${widget.championship.title}'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KConstants.textLightColor,
          labelColor: KConstants.textLightColor,
          unselectedLabelColor: KConstants.textLightColor.withValues(
            alpha: 0.7,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Jogadores'),
            Tab(icon: Icon(Icons.group), text: 'Times Formados'),
            Tab(icon: Icon(Icons.settings), text: 'Configurações'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: KTextStyle.titleText.copyWith(color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: KTextStyle.bodyText.copyWith(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPlayersTab(),
        _buildFormedTeamsTab(),
        _buildSettingsTab(),
      ],
    );
  }

  Widget _buildPlayersTab() {
    if (_individualPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum jogador individual',
              style: KTextStyle.titleText.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Não há jogadores individuais para formar times',
              style: KTextStyle.bodyText.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Estatísticas
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'Estatísticas dos Jogadores',
                style: KTextStyle.titleText.copyWith(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Total',
                    '${_individualPlayers.length}',
                    Icons.people,
                  ),
                  _buildStatCard(
                    'Goleiras',
                    '${_individualPlayers.where((p) => p.position == PlayerPosition.goalkeeper).length}',
                    Icons.sports_soccer,
                  ),
                  _buildStatCard(
                    'Defesas',
                    '${_individualPlayers.where((p) => p.position == PlayerPosition.defender).length}',
                    Icons.shield,
                  ),
                  _buildStatCard(
                    'Meio-Campo',
                    '${_individualPlayers.where((p) => p.position == PlayerPosition.midfielder).length}',
                    Icons.sports,
                  ),
                  _buildStatCard(
                    'Atacantes',
                    '${_individualPlayers.where((p) => p.position == PlayerPosition.forward).length}',
                    Icons.sports_soccer,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista de jogadores
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _individualPlayers.length,
            itemBuilder: (context, index) {
              final player = _individualPlayers[index];
              return _buildPlayerCard(player);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: KTextStyle.titleText.copyWith(
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: KTextStyle.smallText.copyWith(color: Colors.blue[600]),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(IndividualPlayer player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getPositionColor(player.position),
              child: Text(
                player.position.shortName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.name, style: KTextStyle.titleText),
                  Text(
                    player.position.displayName,
                    style: KTextStyle.bodySecondaryText,
                  ),
                  Text(
                    player.skillLevel.displayName,
                    style: KTextStyle.smallText.copyWith(
                      color: _getSkillLevelColor(player.skillLevel),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSkillLevelColor(
                  player.skillLevel,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player.skillLevel.displayName,
                style: TextStyle(
                  color: _getSkillLevelColor(player.skillLevel),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormedTeamsTab() {
    if (_formedTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum time formado',
              style: KTextStyle.titleText.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Use o botão "Formar Times" para criar times automaticamente',
              style: KTextStyle.bodyText.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _individualPlayers.isNotEmpty ? _formTeams : null,
              icon: const Icon(Icons.group_add),
              label: const Text('Formar Times'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KConstants.primaryColor,
                foregroundColor: KConstants.textLightColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Botão de ação
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isFormingTeams ? null : _formTeams,
                  icon: _isFormingTeams
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.group_add),
                  label: Text(
                    _isFormingTeams ? 'Formando...' : 'Formar Novos Times',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KConstants.primaryColor,
                    foregroundColor: KConstants.textLightColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de times
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _formedTeams.length,
            itemBuilder: (context, index) {
              final team = _formedTeams[index];
              return _buildTeamCard(team);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(FormedTeam team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    'T${_formedTeams.indexOf(team) + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name, style: KTextStyle.titleText),
                      Text(
                        'Capitão: ${team.captain.name}',
                        style: KTextStyle.bodySecondaryText,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: team.isBalanced
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    team.isBalanced ? 'Balanceado' : 'Desbalanceado',
                    style: TextStyle(
                      color: team.isBalanced
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Estatísticas do time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamStat('Jogadores', '${team.players.length}'),
                _buildTeamStat(
                  'Habilidade Média',
                  team.averageSkill.toStringAsFixed(1),
                ),
                _buildTeamStat(
                  'Goleiras',
                  '${team.positionCount[PlayerPosition.goalkeeper] ?? 0}',
                ),
                _buildTeamStat(
                  'Defesas',
                  '${team.positionCount[PlayerPosition.defender] ?? 0}',
                ),
                _buildTeamStat(
                  'Meio-Campo',
                  '${team.positionCount[PlayerPosition.midfielder] ?? 0}',
                ),
                _buildTeamStat(
                  'Atacantes',
                  '${team.positionCount[PlayerPosition.forward] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Ações
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTeamDetails(team),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver Detalhes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveTeam(team),
                    icon: const Icon(Icons.check),
                    label: const Text('Aprovar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectTeam(team),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeitar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: KTextStyle.titleText.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: KTextStyle.smallText.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return const Center(child: Text('Configurações em desenvolvimento'));
  }

  Color _getPositionColor(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return Colors.red;
      case PlayerPosition.defender:
        return Colors.blue;
      case PlayerPosition.midfielder:
        return Colors.green;
      case PlayerPosition.forward:
        return Colors.orange;
    }
  }

  Color _getSkillLevelColor(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return Colors.green;
      case SkillLevel.intermediate:
        return Colors.orange;
      case SkillLevel.advanced:
        return Colors.red;
    }
  }

  void _viewTeamDetails(FormedTeam team) {
    // TODO: Implementar visualização detalhada do time
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes - ${team.name}'),
        content: Text('Detalhes do time em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveTeam(FormedTeam team) async {
    try {
      await TeamFormationService.approveTeam(team.id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time ${team.name} aprovado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aprovar time: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectTeam(FormedTeam team) async {
    try {
      await TeamFormationService.rejectTeam(team.id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Time ${team.name} rejeitado!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao rejeitar time: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
