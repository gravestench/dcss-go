# Human skill batch allocation design

## Purpose and source

The playable Human/Fighter currently chooses a weighted skill for every
single point of skill XP. DCSS instead divides an XP batch among enabled
skills, trains those allocations in shuffled order, then spends remaining
XP through weighted choices. This slice ports that control flow for the
existing Human/Fighter skills. Pinned source anchors are
`crawl-ref/source/skills.cc:619-656,747-821,880-1053,1260-1337` and
`random.h:229-249` at revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Ownership and boundary

The player keeps authoritative `Skills` and `SkillTraining` Akara
components. The ordered skill system spends from `SkillTraining.AvailableXP`
after combat practice and kill credit, before character advancement. The
immutable Human point and skill-cost tables remain in `character`. The
session's named `skill` RNG stream supplies shuffled order and weighted
remainder choices, and its saved state continues after restore.

This slice does not introduce manuals, skill targets, cross-training,
species aptitudes, magic practice, or other character starts. It replaces
the current per-point spending implementation, rather than adding a second
training path.

## Spending contract

For each cost-level batch, cap the available XP at the next cost-level
boundary plus the current point cost minus one, as `train_skills` does.
Normalize current practice or manual weights to a 100-point training array.
Automatic mode assigns any percentage remainder in ascending remainder
order, as `_scale_array` does; stable Go skill order settles ties. Manual
mode keeps the truncated percentages. The existing source-shaped
focus floor is applied before scaling.

For each enabled skill, calculate its first-phase XP share as
`training_percent * batch_xp / 100`. If any positive share is smaller than
the current point cost, skip this phase for the whole batch. Otherwise,
shuffle the enabled skill order with the saved `skill` stream. Train each
skill from its share in source-sized chunks of at most 2650 XP, stopping at
level 27 or when its share cannot buy another point. A cost-level increase
changes the cost of later chunks.

Use the remaining batch XP for weighted selection. Prefer the unspent
first-phase shares when that phase ran; fall back to the full training
weights when a selected skill is disabled or cannot be trained. Each
selection buys as many points as fit within the current 2650-XP chunk,
the remaining batch, the current point cost, and level 27. Stop when no
enabled skill can spend or the remaining XP is below cost. Repeat with
the next cost-level batch while progress is possible.

The exact C++ RNG sequence is not claimed: the Go port uses named
SplitMix64 streams and stable Go skill order. The distribution phases,
budget arithmetic, cost boundaries, and deterministic save continuation
are the fidelity targets.

## Verification

Pure allocation tests cover scaling, too-small shares, first-phase
distribution, 2650-XP chunks, maxed skills, and cost-level boundaries.
Game tests cover an earned multi-skill XP gain and save/restore with the
same subsequent training results and RNG state. The full Go test suite,
vet, build, style check, diff check, and code review gate the category
commit. Handwritten Go follows `AGENTS.md` readability rules.
