import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/championship_service.dart';

class DebugParticipantsTest {
  static Future<void> testGetParticipants() async {
    try {
      print('=== TESTE DE PARTICIPANTES ===');

      // Verificar todas as coleções disponíveis
      print('Verificando coleções disponíveis...');

      // Buscar todos os campeonatos
      final championships = await ChampionshipService.getAllChampionships();
      print('Total de campeonatos encontrados: ${championships.length}');

      if (championships.isEmpty) {
        print('Nenhum campeonato encontrado!');
        return;
      }

      // Testar com o primeiro campeonato
      final championship = championships.first;
      print(
        'Testando com campeonato: ${championship.title} (ID: ${championship.id})',
      );

      // Verificar se há inscrições na coleção championship_registrations
      print('Buscando inscrições na coleção championship_registrations...');
      final registrations = await FirebaseFirestore.instance
          .collection('championship_registrations')
          .where('championshipId', isEqualTo: championship.id)
          .get();

      print('Inscrições encontradas na coleção: ${registrations.docs.length}');

      for (final doc in registrations.docs) {
        print('Inscrição: ${doc.id} - ${doc.data()}');
      }

      // Verificar se há inscrições em outras coleções possíveis
      print('Verificando outras coleções...');

      // Tentar buscar em 'registrations' (sem championship_)
      try {
        final altRegistrations = await FirebaseFirestore.instance
            .collection('registrations')
            .where('championshipId', isEqualTo: championship.id)
            .get();
        print('Inscrições em "registrations": ${altRegistrations.docs.length}');
      } catch (e) {
        print('Erro ao buscar em "registrations": $e');
      }

      // Tentar buscar em 'participants'
      try {
        final participants = await FirebaseFirestore.instance
            .collection('participants')
            .where('championshipId', isEqualTo: championship.id)
            .get();
        print('Participantes em "participants": ${participants.docs.length}');
      } catch (e) {
        print('Erro ao buscar em "participants": $e');
      }

      // Verificar especificamente por inscrições individuais
      print('Buscando inscrições individuais...');
      final individualRegistrations = await FirebaseFirestore.instance
          .collection('championship_registrations')
          .where('championshipId', isEqualTo: championship.id)
          .where('registrationType', isEqualTo: 'individual')
          .get();

      print(
        'Inscrições individuais encontradas: ${individualRegistrations.docs.length}',
      );

      final individualPairingRegistrations = await FirebaseFirestore.instance
          .collection('championship_registrations')
          .where('championshipId', isEqualTo: championship.id)
          .where('registrationType', isEqualTo: 'individualPairing')
          .get();

      print(
        'Inscrições individualPairing encontradas: ${individualPairingRegistrations.docs.length}',
      );

      // Buscar participantes usando o serviço
      print('Testando serviço getChampionshipParticipants...');
      final participants =
          await ChampionshipService.getChampionshipParticipants(
            championship.id,
          );
      print('Dados de participantes: $participants');
    } catch (e) {
      print('Erro no teste: $e');
    }
  }
}
