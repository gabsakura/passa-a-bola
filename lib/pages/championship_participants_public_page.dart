import 'package:flutter/material.dart';
import '../data/constants.dart';
import '../data/championship_model.dart';
import '../data/championship_service.dart';

class ChampionshipParticipantsPublicPage extends StatefulWidget {
  final Championship championship;

  const ChampionshipParticipantsPublicPage({
    super.key,
    required this.championship,
  });

  @override
  State<ChampionshipParticipantsPublicPage> createState() =>
      _ChampionshipParticipantsPublicPageState();
}

class _ChampionshipParticipantsPublicPageState
    extends State<ChampionshipParticipantsPublicPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _participantsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadParticipants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    try {
      print(
        'DEBUG: Carregando participantes para campeonato: ${widget.championship.id}',
      );
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await ChampionshipService.getChampionshipParticipants(
        widget.championship.id,
      );

      print('DEBUG: Dados recebidos: $data');

      if (mounted) {
        setState(() {
          _participantsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Erro ao carregar participantes: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participantes - ${widget.championship.title}'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: KConstants.textLightColor,
          labelColor: KConstants.textLightColor,
          unselectedLabelColor: KConstants.textLightColor.withValues(
            alpha: 0.7,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.person),
              text:
                  'Individuais (${_participantsData?['totalIndividual'] ?? 0})',
            ),
            Tab(
              icon: const Icon(Icons.group),
              text: 'Times (${_participantsData?['totalTeams'] ?? 0})',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadParticipants,
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
              'Erro ao carregar participantes',
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
              onPressed: _loadParticipants,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_participantsData == null) {
      return const Center(child: Text('Nenhum dado disponível'));
    }

    return TabBarView(
      controller: _tabController,
      children: [_buildIndividualParticipants(), _buildTeamParticipants()],
    );
  }

  Widget _buildIndividualParticipants() {
    final participants =
        _participantsData!['individualParticipants'] as List<dynamic>;

    if (participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'Nenhum participante individual',
                style: KTextStyle.titleText.copyWith(
                  color: Colors.grey[600],
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ainda não há inscrições individuais para este campeonato',
                style: KTextStyle.bodyText.copyWith(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Estatísticas dos participantes individuais
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Participantes Individuais',
                    style: KTextStyle.titleText.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${participants.length} jogador${participants.length != 1 ? 'es' : ''} inscrito${participants.length != 1 ? 's' : ''}',
                style: KTextStyle.bodyText.copyWith(
                  color: Colors.blue[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Lista de participantes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index] as Map<String, dynamic>;
              return _buildIndividualParticipantCard(participant, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualParticipantCard(
    Map<String, dynamic> participant,
    int number,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do participante
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: KConstants.primaryColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant['name'] ?? 'Nome não informado',
                        style: KTextStyle.titleText.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        participant['email'] ?? 'Email não informado',
                        style: KTextStyle.bodySecondaryText.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de posição
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPositionColor(
                      participant['position'],
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getPositionColor(participant['position']),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getPositionDisplayName(participant['position']),
                    style: TextStyle(
                      color: _getPositionColor(participant['position']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Informações do participante
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.phone,
                  participant['phone'] ?? 'Telefone não informado',
                  Colors.blue,
                ),
                _buildInfoChip(
                  Icons.sports_soccer,
                  participant['position'] ?? 'Posição não informada',
                  Colors.green,
                ),
                _buildInfoChip(
                  Icons.star,
                  _getSkillLevelText(participant['skillLevel']),
                  _getSkillLevelColor(participant['skillLevel']),
                ),
              ],
            ),
            // Data de inscrição
            if (participant['registeredAt'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Inscrito em: ${_formatDate(participant['registeredAt'])}',
                      style: KTextStyle.smallText.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamParticipants() {
    final participants =
        _participantsData!['teamParticipants'] as List<dynamic>;

    if (participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'Nenhum time participando',
                style: KTextStyle.titleText.copyWith(
                  color: Colors.grey[600],
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ainda não há times inscritos para este campeonato',
                style: KTextStyle.bodyText.copyWith(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Estatísticas dos times
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, color: Colors.green[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Times Participantes',
                    style: KTextStyle.titleText.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${participants.length} time${participants.length != 1 ? 's' : ''} inscrito${participants.length != 1 ? 's' : ''}',
                style: KTextStyle.bodyText.copyWith(
                  color: Colors.green[600],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Lista de times
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index] as Map<String, dynamic>;
              return _buildTeamParticipantCard(participant, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamParticipantCard(
    Map<String, dynamic> participant,
    int number,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do time
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Icon(Icons.group, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant['teamName'] ?? 'Nome do time não informado',
                        style: KTextStyle.titleText.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capitão: ${participant['captainName'] ?? 'Nome não informado'}',
                        style: KTextStyle.bodySecondaryText.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de membros
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    '${participant['memberCount'] ?? 0} membros',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Informações do time
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.email,
                  participant['captainEmail'] ?? 'Email não informado',
                  Colors.blue,
                ),
                _buildInfoChip(
                  Icons.people,
                  '${participant['memberCount'] ?? 0} jogadores',
                  Colors.green,
                ),
              ],
            ),
            // Data de inscrição
            if (participant['registeredAt'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Inscrito em: ${_formatDate(participant['registeredAt'])}',
                      style: KTextStyle.smallText.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, [Color? color]) {
    final chipColor = color ?? Colors.grey[600]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String? position) {
    if (position == null) return Colors.grey;

    final pos = position.toLowerCase();
    if (pos.contains('goleir') || pos.contains('gk')) return Colors.red;
    if (pos.contains('defes') ||
        pos.contains('zagueir') ||
        pos.contains('lateral')) {
      return Colors.blue;
    }
    if (pos.contains('atacant') ||
        pos.contains('pont') ||
        pos.contains('centroav')) {
      return Colors.orange;
    }
    return Colors.green; // meio-campo
  }

  String _getPositionDisplayName(String? position) {
    if (position == null) return 'Posição';

    final pos = position.toLowerCase();
    if (pos.contains('goleir') || pos.contains('gk')) return 'Goleira';
    if (pos.contains('defes') ||
        pos.contains('zagueir') ||
        pos.contains('lateral')) {
      return 'Defesa';
    }
    if (pos.contains('atacant') ||
        pos.contains('pont') ||
        pos.contains('centroav')) {
      return 'Atacante';
    }
    return 'Meio-Campo';
  }

  Color _getSkillLevelColor(String? skillLevel) {
    if (skillLevel == null) return Colors.grey;

    final skill = skillLevel.toLowerCase();
    if (skill.contains('avançad') || skill.contains('advanced')) {
      return Colors.red;
    }
    if (skill.contains('intermedi') || skill.contains('intermediate')) {
      return Colors.orange;
    }
    return Colors.green; // iniciante
  }

  String _getSkillLevelText(String skillLevel) {
    switch (skillLevel) {
      case 'beginner':
        return 'Iniciante';
      case 'intermediate':
        return 'Intermediário';
      case 'advanced':
        return 'Avançado';
      default:
        return skillLevel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
