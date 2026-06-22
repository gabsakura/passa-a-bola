import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/constants.dart';
import '../data/team_service.dart';
import '../data/team_model.dart';

class MyTeamsPage extends StatefulWidget {
  const MyTeamsPage({super.key});

  @override
  State<MyTeamsPage> createState() => _MyTeamsPageState();
}

class _MyTeamsPageState extends State<MyTeamsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Times'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
      ),
      body: StreamBuilder<List<Team>>(
        stream: TeamService.getUserTeams(_auth.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: KConstants.errorColor,
                  ),
                  const SizedBox(height: KConstants.spacingMedium),
                  Text(
                    'Erro ao carregar seus times',
                    style: KTextStyle.heading3,
                  ),
                  const SizedBox(height: KConstants.spacingSmall),
                  Text(
                    snapshot.error.toString(),
                    style: KTextStyle.bodyText.copyWith(
                      color: KConstants.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: KConstants.textSecondaryColor,
                  ),
                  const SizedBox(height: KConstants.spacingMedium),
                  Text(
                    'Você não está em nenhum time',
                    style: KTextStyle.heading3,
                  ),
                  const SizedBox(height: KConstants.spacingSmall),
                  Text(
                    'Crie um time ou aceite um convite para começar',
                    style: KTextStyle.bodyText.copyWith(
                      color: KConstants.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KConstants.spacingLarge),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTeamDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Time'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(KConstants.spacingMedium),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return _buildTeamCard(team);
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    final isCaptain = team.isCaptain(_auth.currentUser?.uid ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: KConstants.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(KConstants.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: KConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: team.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            team.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.group,
                                color: KConstants.primaryColor,
                              );
                            },
                          ),
                        )
                      : Icon(Icons.group, color: KConstants.primaryColor),
                ),
                const SizedBox(width: KConstants.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              team.name,
                              style: KTextStyle.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isCaptain)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: KConstants.spacingSmall,
                                vertical: KConstants.spacingXSmall,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Capitão',
                                    style: KTextStyle.smallText.copyWith(
                                      color: Colors.amber[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: KConstants.spacingSmall),
                      Text(
                        'Capitão: ${team.captainName}',
                        style: KTextStyle.bodyText.copyWith(
                          color: KConstants.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: KConstants.spacingMedium),

            // Descrição
            Text(
              team.description,
              style: KTextStyle.bodyText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: KConstants.spacingMedium),

            // Informações do time
            Row(
              children: [
                _buildInfoChip(
                  Icons.people,
                  '${team.currentMembersCount}/${team.maxMembers}',
                ),
                const SizedBox(width: KConstants.spacingSmall),
                _buildInfoChip(Icons.flag, team.levelDisplayName),
                const SizedBox(width: KConstants.spacingSmall),
                _buildInfoChip(
                  Icons.calendar_today,
                  _formatDate(team.createdAt),
                ),
              ],
            ),

            // Estatísticas (se ativo)
            if (team.status == TeamStatus.active) ...[
              const SizedBox(height: KConstants.spacingMedium),
              Row(
                children: [
                  _buildStatChip(
                    Icons.sports_soccer,
                    '${team.gamesPlayed} jogos',
                  ),
                  const SizedBox(width: KConstants.spacingSmall),
                  _buildStatChip(
                    Icons.emoji_events,
                    '${(team.winRate * 100).toStringAsFixed(0)}% vitórias',
                  ),
                ],
              ),
            ],

            const SizedBox(height: KConstants.spacingMedium),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTeamDetails(team),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Detalhes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KConstants.primaryColor,
                      side: BorderSide(color: KConstants.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: KConstants.spacingSmall),
                if (isCaptain) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showManageTeamDialog(team),
                      icon: const Icon(Icons.settings),
                      label: const Text('Gerenciar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: KConstants.spacingSmall),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showLeaveTeamDialog(team),
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Sair'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KConstants.errorColor,
                      side: BorderSide(color: KConstants.errorColor),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KConstants.spacingSmall,
        vertical: KConstants.spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: KConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KConstants.primaryColor),
          const SizedBox(width: KConstants.spacingXSmall),
          Text(
            text,
            style: KTextStyle.smallText.copyWith(
              color: KConstants.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KConstants.spacingSmall,
        vertical: KConstants.spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: KConstants.textSecondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: KConstants.textSecondaryColor),
          const SizedBox(width: KConstants.spacingXSmall),
          Text(
            text,
            style: KTextStyle.smallText.copyWith(
              color: KConstants.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _showTeamDetails(Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes do Time: ${team.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações básicas
              _buildDetailRow('Nome:', team.name),
              _buildDetailRow('Descrição:', team.description),
              _buildDetailRow('Capitão:', team.captainName),
              _buildDetailRow('Nível:', team.levelDisplayName),
              _buildDetailRow(
                'Membros:',
                '${team.currentMembersCount}/${team.maxMembers}',
              ),
              _buildDetailRow('Criado em:', _formatDate(team.createdAt)),

              // Estatísticas (se ativo)
              if (team.status == TeamStatus.active) ...[
                const SizedBox(height: KConstants.spacingMedium),
                const Text(
                  'Estatísticas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: KConstants.spacingSmall),
                _buildDetailRow('Jogos:', '${team.gamesPlayed}'),
                _buildDetailRow('Vitórias:', '${team.gamesWon}'),
                _buildDetailRow('Derrotas:', '${team.gamesLost}'),
                _buildDetailRow('Empates:', '${team.gamesDrawn}'),
                _buildDetailRow(
                  'Taxa de Vitórias:',
                  '${(team.winRate * 100).toStringAsFixed(1)}%',
                ),
                _buildDetailRow('Gols Marcados:', '${team.totalGoals}'),
                _buildDetailRow('Gols Sofridos:', '${team.totalGoalsConceded}'),
              ],

              // Lista de membros
              const SizedBox(height: KConstants.spacingMedium),
              const Text(
                'Membros:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: KConstants.spacingSmall),
              ...team.members
                  .where((member) => member.isActive)
                  .map(
                    (member) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            member.role == 'captain'
                                ? Icons.star
                                : Icons.person,
                            size: 16,
                            color: member.role == 'captain'
                                ? Colors.amber
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${member.userName}${member.role == 'captain' ? ' (Capitão)' : ''}',
                              style: TextStyle(
                                fontWeight: member.role == 'captain'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  ,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCreateTeamDialog() {
    // Implementar criação de time
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Funcionalidade de criação de time será implementada em breve',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showManageTeamDialog(Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gerenciar Time: ${team.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar Time'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditTeamDialog(team);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Gerenciar Membros'),
              onTap: () {
                Navigator.of(context).pop();
                _showManageMembersDialog(team);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Convidar Jogadores'),
              onTap: () {
                Navigator.of(context).pop();
                _showInvitePlayersDialog(team);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Excluir Time'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteTeamDialog(team);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showEditTeamDialog(Team team) {
    // Implementar edição de time
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Funcionalidade de edição de time será implementada em breve',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showManageMembersDialog(Team team) {
    // Implementar gerenciamento de membros
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Funcionalidade de gerenciamento de membros será implementada em breve',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showInvitePlayersDialog(Team team) {
    // Implementar convite de jogadores
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Funcionalidade de convite de jogadores será implementada em breve',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDeleteTeamDialog(Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Time'),
        content: Text(
          'Tem certeza que deseja excluir o time "${team.name}"?\n\n'
          'Esta ação não pode ser desfeita e irá:\n'
          '• Remover o time permanentemente\n'
          '• Excluir todos os convites pendentes\n'
          '• Remover todos os membros do time',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteTeam(team);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTeam(Team team) async {
    try {
      await TeamService.deleteTeam(team.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Time "${team.name}" excluído com sucesso!'),
          backgroundColor: KConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir time: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }

  void _showLeaveTeamDialog(Team team) {
    final isCaptain = team.isCaptain(_auth.currentUser?.uid ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Time'),
        content: Text(
          isCaptain
              ? 'Você é o capitão do time "${team.name}".\n\n'
                    'Para sair do time, você precisa:\n'
                    '• Transferir a capitania para outro membro, ou\n'
                    '• Excluir o time completamente\n\n'
                    'O que você gostaria de fazer?'
              : 'Tem certeza que deseja sair do time "${team.name}"?\n\n'
                    'Você poderá ser convidado novamente pelo capitão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          if (isCaptain) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showTransferCaptaincyDialog(team);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Transferir Capitania'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteTeamDialog(team);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KConstants.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir Time'),
            ),
          ] else
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _leaveTeam(team);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KConstants.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair do Time'),
            ),
        ],
      ),
    );
  }

  void _showTransferCaptaincyDialog(Team team) {
    final members = team.members
        .where(
          (member) =>
              member.isActive &&
              member.role != 'captain' &&
              member.userId != _auth.currentUser?.uid,
        )
        .toList();

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não há outros membros ativos para transferir a capitania',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transferir Capitania'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecione o novo capitão:'),
            const SizedBox(height: KConstants.spacingMedium),
            ...members
                .map(
                  (member) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(member.userName),
                    subtitle: Text(member.userEmail),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _transferCaptaincy(team, member.userId);
                    },
                  ),
                )
                ,
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _transferCaptaincy(Team team, String newCaptainId) async {
    try {
      await TeamService.transferCaptaincy(
        teamId: team.id,
        newCaptainId: newCaptainId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Capitania transferida com sucesso!'),
          backgroundColor: KConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao transferir capitania: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _leaveTeam(Team team) async {
    try {
      await TeamService.leaveTeam(team.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Você saiu do time "${team.name}" com sucesso!'),
          backgroundColor: KConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao sair do time: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }
}
