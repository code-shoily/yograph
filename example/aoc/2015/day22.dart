import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
Hit Points: 13
Damage: 8
''';

class CombatState {
  final int hp;
  final int mana;
  final int bossHp;
  final int bossDmg;
  final int spent;
  final int shield;
  final int poison;
  final int recharge;
  final String mode;

  CombatState({
    required this.hp,
    required this.mana,
    required this.bossHp,
    required this.bossDmg,
    required this.spent,
    required this.shield,
    required this.poison,
    required this.recharge,
    required this.mode,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CombatState &&
        other.hp == hp &&
        other.mana == mana &&
        other.bossHp == bossHp &&
        other.shield == shield &&
        other.poison == poison &&
        other.recharge == recharge &&
        other.mode == mode;
  }

  @override
  int get hashCode =>
      Object.hash(hp, mana, bossHp, shield, poison, recharge, mode);
}

class Spell {
  final String name;
  final int cost;
  final int dmg;
  final int heal;
  final String? effect;
  final int duration;

  const Spell(
    this.name,
    this.cost,
    this.dmg,
    this.heal,
    this.effect,
    this.duration,
  );
}

const spells = [
  Spell('missile', 53, 4, 0, null, 0),
  Spell('drain', 73, 2, 2, null, 0),
  Spell('shield', 113, 0, 0, 'shield', 6),
  Spell('poison', 173, 0, 0, 'poison', 6),
  Spell('recharge', 229, 0, 0, 'recharge', 5),
];

class EffectResult {
  final CombatState state;
  final int armor;
  EffectResult(this.state, this.armor);
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2015,
    day: 22,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, int) solve(String rawInput, bool isSample) {
  final p1 = solvePart1(rawInput);
  final p2 = solvePart2(rawInput);
  return (p1, p2);
}

int solvePart1(String rawInput) {
  final initial = parse(rawInput, 'normal');
  return _solveMode(initial);
}

int solvePart2(String rawInput) {
  final initial = parse(rawInput, 'hard');
  return _solveMode(initial);
}

CombatState parse(String input, String mode) {
  final lines = getLines(input);
  final hp = int.parse(lines[0].split(': ').last);
  final dmg = int.parse(lines[1].split(': ').last);
  return CombatState(
    hp: 50,
    mana: 500,
    bossHp: hp,
    bossDmg: dmg,
    spent: 0,
    shield: 0,
    poison: 0,
    recharge: 0,
    mode: mode,
  );
}

int _solveMode(CombatState initial) {
  final result = AStar.implicitAStar<CombatState>(
    from: initial,
    successors: _getSuccessors,
    isGoal: (state) => state.bossHp <= 0,
    heuristic: (_) => 0.0,
  );
  if (result == null) return -1;
  return result.$2.toInt();
}

EffectResult _applyEffects(CombatState state) {
  var bossHp = state.bossHp;
  var mana = state.mana;
  var armor = 0;

  if (state.poison > 0) {
    bossHp -= 3;
  }
  if (state.recharge > 0) {
    mana += 101;
  }
  if (state.shield > 0) {
    armor = 7;
  }

  final nextState = CombatState(
    hp: state.hp,
    mana: mana,
    bossHp: bossHp,
    bossDmg: state.bossDmg,
    spent: state.spent,
    shield: state.shield > 0 ? state.shield - 1 : 0,
    poison: state.poison > 0 ? state.poison - 1 : 0,
    recharge: state.recharge > 0 ? state.recharge - 1 : 0,
    mode: state.mode,
  );

  return EffectResult(nextState, armor);
}

Iterable<(CombatState, double)> _getSuccessors(CombatState startState) {
  var state = startState;
  if (state.mode == 'hard') {
    state = CombatState(
      hp: state.hp - 1,
      mana: state.mana,
      bossHp: state.bossHp,
      bossDmg: state.bossDmg,
      spent: state.spent,
      shield: state.shield,
      poison: state.poison,
      recharge: state.recharge,
      mode: state.mode,
    );
  }

  if (state.hp <= 0) return const [];

  final effPlayer = _applyEffects(state);
  var activeState = effPlayer.state;

  if (activeState.bossHp <= 0) {
    final winState = CombatState(
      hp: activeState.hp,
      mana: activeState.mana,
      bossHp: 0,
      bossDmg: activeState.bossDmg,
      spent: activeState.spent,
      shield: activeState.shield,
      poison: activeState.poison,
      recharge: activeState.recharge,
      mode: activeState.mode,
    );
    return [(winState, 0.0)];
  }

  final nextStates = <(CombatState, double)>[];
  for (final spell in spells) {
    if (activeState.mana < spell.cost) continue;
    if (spell.effect == 'shield' && activeState.shield > 0) continue;
    if (spell.effect == 'poison' && activeState.poison > 0) continue;
    if (spell.effect == 'recharge' && activeState.recharge > 0) continue;

    var hpAfterCast = activeState.hp;
    var manaAfterCast = activeState.mana - spell.cost;
    var spentAfterCast = activeState.spent + spell.cost;
    var bossHpAfterCast = activeState.bossHp;
    var shieldAfterCast = activeState.shield;
    var poisonAfterCast = activeState.poison;
    var rechargeAfterCast = activeState.recharge;

    if (spell.effect == null) {
      bossHpAfterCast -= spell.dmg;
      hpAfterCast += spell.heal;
    } else {
      if (spell.effect == 'shield') shieldAfterCast = spell.duration;
      if (spell.effect == 'poison') poisonAfterCast = spell.duration;
      if (spell.effect == 'recharge') rechargeAfterCast = spell.duration;
    }

    final playerTurnEndState = CombatState(
      hp: hpAfterCast,
      mana: manaAfterCast,
      bossHp: bossHpAfterCast,
      bossDmg: activeState.bossDmg,
      spent: spentAfterCast,
      shield: shieldAfterCast,
      poison: poisonAfterCast,
      recharge: rechargeAfterCast,
      mode: activeState.mode,
    );

    if (playerTurnEndState.bossHp <= 0) {
      final winState = CombatState(
        hp: playerTurnEndState.hp,
        mana: playerTurnEndState.mana,
        bossHp: 0,
        bossDmg: playerTurnEndState.bossDmg,
        spent: playerTurnEndState.spent,
        shield: playerTurnEndState.shield,
        poison: playerTurnEndState.poison,
        recharge: playerTurnEndState.recharge,
        mode: playerTurnEndState.mode,
      );
      nextStates.add((winState, spell.cost.toDouble()));
    } else {
      final effBoss = _applyEffects(playerTurnEndState);
      var bossTurnState = effBoss.state;
      var armor = effBoss.armor;

      if (bossTurnState.bossHp <= 0) {
        final winState = CombatState(
          hp: bossTurnState.hp,
          mana: bossTurnState.mana,
          bossHp: 0,
          bossDmg: bossTurnState.bossDmg,
          spent: bossTurnState.spent,
          shield: bossTurnState.shield,
          poison: bossTurnState.poison,
          recharge: bossTurnState.recharge,
          mode: bossTurnState.mode,
        );
        nextStates.add((winState, spell.cost.toDouble()));
      } else {
        final dmg = (bossTurnState.bossDmg - armor).clamp(1, 999);
        final finalState = CombatState(
          hp: bossTurnState.hp - dmg,
          mana: bossTurnState.mana,
          bossHp: bossTurnState.bossHp,
          bossDmg: bossTurnState.bossDmg,
          spent: bossTurnState.spent,
          shield: bossTurnState.shield,
          poison: bossTurnState.poison,
          recharge: bossTurnState.recharge,
          mode: bossTurnState.mode,
        );
        if (finalState.hp > 0) {
          nextStates.add((finalState, spell.cost.toDouble()));
        }
      }
    }
  }

  return nextStates;
}
