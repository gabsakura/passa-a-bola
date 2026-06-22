import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/championship_service.dart';
import 'data/team_service.dart';

/// Script de teste para verificar permissões de inscrição de times
class PermissionsTest {
  static Future<void> testTeamRegistrationPermissions() async {
    print('=== TESTE DE PERMISSÕES DE INSCRIÇÃO DE TIMES ===\n');

    try {
      // Verificar se o usuário está autenticado
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ ERRO: Usuário não autenticado');
        return;
      }

      print('✅ Usuário autenticado: ${user.email} (${user.uid})');

      // Listar times do usuário
      final teamsStream = TeamService.getUserTeams(user.uid);
      final teams = await teamsStream.first;
      print('📋 Times do usuário: ${teams.length}');

      for (final team in teams) {
        print(
          '  - ${team.name} (ID: ${team.id}) - Capitão: ${team.captainId == user.uid ? "✅" : "❌"}',
        );
      }

      if (teams.isEmpty) {
        print('⚠️  Nenhum time encontrado para o usuário');
        return;
      }

      // Listar campeonatos disponíveis
      final championships = await ChampionshipService.getPublicChampionships();
      print('\n🏆 Campeonatos disponíveis: ${championships.length}');

      for (final championship in championships) {
        print('  - ${championship.title}');
        print('    Status: ${championship.statusDisplayName}');
        print(
          '    Tipo de inscrição: ${championship.registrationTypeDisplayName}',
        );
        print(
          '    Permite times: ${championship.canRegisterTeams ? "✅" : "❌"}',
        );
        print(
          '    Inscrições abertas: ${championship.isRegistrationOpen ? "✅" : "❌"}',
        );
        print('');
      }

      // Testar inscrição com o primeiro time e campeonato compatível
      final team = teams.first;
      final championship = championships.firstWhere(
        (c) => c.canRegisterTeams && c.isRegistrationOpen,
        orElse: () => championships.first,
      );

      print('🧪 Testando inscrição:');
      print('  Time: ${team.name}');
      print('  Campeonato: ${championship.title}');
      print('  Permite times: ${championship.canRegisterTeams}');
      print('  Inscrições abertas: ${championship.isRegistrationOpen}');

      if (championship.canRegisterTeams && championship.isRegistrationOpen) {
        try {
          final registrationId = await ChampionshipService.registerTeam(
            championshipId: championship.id,
            teamId: team.id,
          );
          print('✅ Inscrição realizada com sucesso! ID: $registrationId');
        } catch (e) {
          print('❌ Erro na inscrição: $e');
        }
      } else {
        print(
          '⚠️  Campeonato não permite inscrição de times ou inscrições fechadas',
        );
      }
    } catch (e) {
      print('❌ ERRO GERAL: $e');
    }
  }

  static Future<void> testFirestoreRules() async {
    print('\n=== TESTE DAS REGRAS DO FIRESTORE ===\n');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Usuário não autenticado');
        return;
      }

      // Testar leitura de inscrições
      print('📖 Testando leitura de inscrições...');
      final registrations = await FirebaseFirestore.instance
          .collection('championship_registrations')
          .where('userId', isEqualTo: user.uid)
          .get();
      print(
        '✅ Leitura de inscrições: ${registrations.docs.length} inscrições encontradas',
      );

      // Testar leitura de times
      print('📖 Testando leitura de times...');
      final teams = await FirebaseFirestore.instance
          .collection('teams')
          .where('captainId', isEqualTo: user.uid)
          .get();
      print('✅ Leitura de times: ${teams.docs.length} times encontrados');

      // Testar leitura de campeonatos
      print('📖 Testando leitura de campeonatos...');
      final championships = await FirebaseFirestore.instance
          .collection('championships')
          .limit(5)
          .get();
      print(
        '✅ Leitura de campeonatos: ${championships.docs.length} campeonatos encontrados',
      );
    } catch (e) {
      print('❌ Erro no teste das regras: $e');
    }
  }
}
