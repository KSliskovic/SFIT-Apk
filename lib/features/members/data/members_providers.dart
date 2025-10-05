import 'package:flutter_riverpod/flutter_riverpod.dart';

// Uvozimo PROVIDER i MODELE iz results feature-a
import '../../results/data/results_providers.dart';
import '../../results/domain/models.dart';

// VAŽNO: uvezi i sam repository da bi tip ResultsRepository bio vidljiv
import '../../results/data/results_repository.dart';

/// Stream svih timova iz results repozitorija
final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final repo = ref.read(resultsRepositoryProvider);
  return repo.watchTeams();
});

/// Stream svih igrača iz results repozitorija
final playersStreamProvider = StreamProvider<List<Player>>((ref) {
  final repo = ref.read(resultsRepositoryProvider);
  return repo.watchPlayers();
});

/// Akcije nad članovima/timovima (uredi/obriši)
final membersActionsProvider = Provider<MembersActions>((ref) {
  final repo = ref.read(resultsRepositoryProvider);
  return MembersActions(repo);
});

class MembersActions {
  final ResultsRepository repo;
  MembersActions(this.repo);

  Future<void> renameTeam(String teamId, String newName) async {
    await repo.updateTeamName(teamId, newName);
  }

  Future<void> deleteTeam(String teamId) async {
    await repo.deleteTeam(teamId);
  }

  Future<void> renamePlayer(String playerId, String newName) async {
    await repo.updatePlayerName(playerId, newName);
  }

  Future<void> deletePlayer(String playerId) async {
    await repo.deletePlayer(playerId);
  }
}
