import 'game_data.dart';
import 'india_states_data.dart';
import 'india_states_geometry.dart';
import 'journeys_data.dart';

/// State Context System — the single source of truth for "which state's
/// content is live right now".
///
/// When a STATE journey is active, every gameplay feature must draw only from
/// the selected state: quiz questions, passport stamps, state spotlight facts,
/// mini-games, treasure, surprises and rewards. Only the India Challenge (or
/// free map browsing) is allowed to mix content from all 28 states.
///
/// Every gameplay screen reads the current Active State through this manager
/// instead of picking a random state on its own; that way no feature can
/// silently leak another state's content into a single-state run.
abstract final class StateContext {
  /// True while the running journey is a single-state stage (not the India
  /// Challenge and not the map overlay with no active run).
  static bool get isStateRun => isStateJourney(GameData.activeJourney);

  /// Name of the Active State during a state run; `null` on the India
  /// Challenge (the only mode allowed to mix states).
  static String? get activeStateName {
    if (!isStateRun) return null;
    return GameData.journey.name;
  }

  /// Full [IndiaState] record of the Active State, or `null` in challenge
  /// mode where content is intentionally mixed.
  static IndiaState? get activeState {
    final name = activeStateName;
    return name == null ? null : stateByName(name);
  }

  /// The state a board tile "counts as" in the current run: on a STATE run
  /// every tile belongs to the ACTIVE state (so passport stamps, monument and
  /// food discoveries never leave the selected state); only the India
  /// Challenge keeps each tile's own mixed-state label.
  static String? tileState(String? tileState) =>
      activeStateName ?? tileState;

  /// Constrains [states] to the Active State during a state run; the full
  /// mixed list is returned on the India Challenge.
  static List<IndiaState> scopeStates(List<IndiaState> states) {
    final active = activeState;
    return active == null
        ? states
        : states.where((s) => s.name == active.name).toList();
  }

  /// True when [state] matches the Active State, or when no single-state run
  /// is active (challenge / map mode) where any content is allowed.
  static bool matchesActive(String? state) {
    final active = activeStateName;
    return active == null || state == null || active == state;
  }
}