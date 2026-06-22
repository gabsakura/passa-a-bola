import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/championship_model.dart';

class DemoDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Adicionar campeonatos reais do Passa a Bola
  static Future<void> addRealChampionships() async {
    try {
      // Verificar se já existem campeonatos do Passa a Bola
      final existingChampionships = await _firestore
          .collection('championships')
          .where('organizerId', isEqualTo: 'passabola_admin')
          .get();

      if (existingChampionships.docs.isNotEmpty) {
        print(
          'Campeonatos reais já existem (${existingChampionships.docs.length} encontrados). Pulando adição.',
        );
        return;
      }

      final championships = [
        {
          'title': 'Copa Passa a Bola Feminina 2024',
          'description':
              'Campeonato oficial de futebol feminino do Passa a Bola. Inscrições abertas para times de todas as categorias.',
          'location': 'Centro Esportivo Vila Olímpia',
          'locationData': {
            'latitude': -23.5585,
            'longitude': -46.6253,
            'address': 'Rua das Flores, 123 - Vila Olímpia, São Paulo',
            'city': 'São Paulo',
            'state': 'SP',
            'country': 'Brasil',
            'postalCode': '04551-000',
          },
          'status': ChampionshipStatus.registrationOpen.name,
          'type': 'knockout',
          'registrationType': 'teamOnly',
          'maxTeams': 16,
          'minPlayersPerTeam': 7,
          'maxPlayersPerTeam': 11,
          'rules': [
            'Jogos de 40 minutos (2 tempos de 20min)',
            'Mínimo 7 jogadoras por time',
            'Cartão amarelo = 2 min fora',
            'Cartão vermelho = expulsão do jogo',
          ],
          'prizes': [
            {
              'position': '1º',
              'description': 'R\$ 2.000 + trofeu',
              'monetaryValue': 2000.0,
            },
            {
              'position': '2º',
              'description': 'R\$ 1.000 + medalha',
              'monetaryValue': 1000.0,
            },
            {
              'position': '3º',
              'description': 'R\$ 500 + medalha',
              'monetaryValue': 500.0,
            },
          ],
          'organizerId': 'passabola_admin',
          'organizerName': 'Passa a Bola',
          'registrationFee': 150.0,
          'startDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 30)),
          ),
          'endDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 60)),
          ),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'title': 'Liga Passa a Bola Feminina - Categoria Sub-18',
          'description':
              'Liga oficial para jogadoras até 18 anos. Desenvolvimento e competição saudável.',
          'location': 'Complexo Esportivo Ibirapuera',
          'locationData': {
            'latitude': -23.5555,
            'longitude': -46.6153,
            'address': 'Parque do Ibirapuera - Quadras 1-4, São Paulo',
            'city': 'São Paulo',
            'state': 'SP',
            'country': 'Brasil',
            'postalCode': '04038-000',
          },
          'status': ChampionshipStatus.registrationOpen.name,
          'type': 'league',
          'registrationType': 'teamOnly',
          'maxTeams': 12,
          'minPlayersPerTeam': 8,
          'maxPlayersPerTeam': 15,
          'rules': [
            'Jogos de 35 minutos (2 tempos de 17min)',
            'Mínimo 8 jogadoras por time',
            'Idade máxima: 18 anos',
            'Cartão amarelo = 1 min fora',
          ],
          'prizes': [
            {
              'position': '1º',
              'description': 'R\$ 1.500 + trofeu',
              'monetaryValue': 1500.0,
            },
            {
              'position': '2º',
              'description': 'R\$ 800 + medalha',
              'monetaryValue': 800.0,
            },
            {
              'position': '3º',
              'description': 'R\$ 400 + medalha',
              'monetaryValue': 400.0,
            },
          ],
          'organizerId': 'passabola_admin',
          'organizerName': 'Passa a Bola',
          'registrationFee': 100.0,
          'startDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 45)),
          ),
          'endDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 90)),
          ),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'title': 'Copa Passa a Bola Feminina - Categoria Master',
          'description':
              'Campeonato para jogadoras acima de 30 anos. Foco na diversão e integração.',
          'location': 'Centro Esportivo Morumbi',
          'locationData': {
            'latitude': -23.5455,
            'longitude': -46.6353,
            'address': 'Rua do Morumbi, 456 - Morumbi, São Paulo',
            'city': 'São Paulo',
            'state': 'SP',
            'country': 'Brasil',
            'postalCode': '05615-000',
          },
          'status': ChampionshipStatus.registrationClosed.name,
          'type': 'groups',
          'registrationType': 'teamOnly',
          'maxTeams': 8,
          'minPlayersPerTeam': 6,
          'maxPlayersPerTeam': 12,
          'rules': [
            'Jogos de 30 minutos (2 tempos de 15min)',
            'Mínimo 6 jogadoras por time',
            'Idade mínima: 30 anos',
            'Substituições ilimitadas',
          ],
          'prizes': [
            {
              'position': '1º',
              'description': 'R\$ 1.000 + trofeu',
              'monetaryValue': 1000.0,
            },
            {
              'position': '2º',
              'description': 'R\$ 500 + medalha',
              'monetaryValue': 500.0,
            },
            {
              'position': '3º',
              'description': 'R\$ 250 + medalha',
              'monetaryValue': 250.0,
            },
          ],
          'organizerId': 'passabola_admin',
          'organizerName': 'Passa a Bola',
          'registrationFee': 80.0,
          'startDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 15)),
          ),
          'endDate': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 45)),
          ),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      // Adicionar cada campeonato
      for (final championshipData in championships) {
        await _firestore.collection('championships').add(championshipData);
      }

      print('Campeonatos reais adicionados com sucesso!');
    } catch (e) {
      print('Erro ao adicionar campeonatos reais: $e');
    }
  }

  // Adicionar campeonato individual
  static Future<void> addChampionship(
    Map<String, dynamic> championshipData,
  ) async {
    try {
      await _firestore.collection('championships').add(championshipData);
      print('Campeonato adicionado com sucesso!');
    } catch (e) {
      print('Erro ao adicionar campeonato: $e');
      rethrow;
    }
  }

  // Limpar dados de demonstração
  static Future<void> clearDemoData() async {
    try {
      // Deletar marcadores de demonstração
      final markersQuery = await _firestore
          .collection('scout_markers')
          .where('scoutId', isGreaterThanOrEqualTo: 'demo_')
          .get();

      for (final doc in markersQuery.docs) {
        await doc.reference.delete();
      }

      // Deletar usuário de demonstração
      await _firestore.collection('users').doc('demo_user_123').delete();

      print('Dados de demonstração removidos com sucesso!');
    } catch (e) {
      print('Erro ao remover dados de demonstração: $e');
    }
  }

  // Limpar todos os dados de teste (incluindo campeonatos fictícios)
  static Future<void> clearAllTestData() async {
    try {
      // Deletar marcadores de demonstração
      await clearDemoData();

      // Deletar campeonatos fictícios (que não são do Passa a Bola)
      final fakeChampionshipsQuery = await _firestore
          .collection('championships')
          .where('organizerId', isNotEqualTo: 'passabola_admin')
          .get();

      for (final doc in fakeChampionshipsQuery.docs) {
        await doc.reference.delete();
      }

      print('Todos os dados de teste removidos com sucesso!');
    } catch (e) {
      print('Erro ao remover dados de teste: $e');
    }
  }

  // Corrigir estrutura de dados dos campeonatos existentes
  static Future<void> fixChampionshipDataStructure() async {
    try {
      print('DEBUG: Corrigindo estrutura de dados dos campeonatos...');

      // Buscar todos os campeonatos do Passa a Bola
      final championshipsQuery = await _firestore
          .collection('championships')
          .where('organizerId', isEqualTo: 'passabola_admin')
          .get();

      for (final doc in championshipsQuery.docs) {
        try {
          final data = doc.data();

          // Verificar se os prêmios estão no formato incorreto (strings)
          if (data['prizes'] != null && data['prizes'] is List) {
            final prizes = data['prizes'] as List;
            if (prizes.isNotEmpty && prizes.first is String) {
              print('DEBUG: Corrigindo prêmios do campeonato ${doc.id}');

              // Converter strings para objetos ChampionshipPrize
              final correctedPrizes = prizes.map((prize) {
                if (prize is String) {
                  // Extrair posição e descrição da string
                  final parts = prize.split(': ');
                  if (parts.length == 2) {
                    final position = parts[0].trim();
                    final description = parts[1].trim();

                    // Extrair valor monetário se houver
                    double? monetaryValue;
                    final moneyMatch = RegExp(
                      r'R\$ ([\d.,]+)',
                    ).firstMatch(description);
                    if (moneyMatch != null) {
                      final valueStr = moneyMatch
                          .group(1)!
                          .replaceAll(',', '.');
                      monetaryValue = double.tryParse(valueStr);
                    }

                    return {
                      'position': position,
                      'description': description,
                      'monetaryValue': monetaryValue,
                    };
                  }
                }
                return prize; // Manter como está se já for um objeto
              }).toList();

              // Atualizar o documento
              await doc.reference.update({
                'prizes': correctedPrizes,
                'updatedAt': Timestamp.now(),
              });

              print('DEBUG: Prêmios corrigidos para ${doc.id}');
            }
          }
        } catch (e) {
          print('DEBUG: Erro ao corrigir campeonato ${doc.id}: $e');
        }
      }

      print('DEBUG: Estrutura de dados dos campeonatos corrigida!');
    } catch (e) {
      print('DEBUG: Erro ao corrigir estrutura de dados: $e');
    }
  }
}
