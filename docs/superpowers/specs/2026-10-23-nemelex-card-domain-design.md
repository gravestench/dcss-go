# Nemelex cards

## Intent

Make Nemelex's deck gifts and every currently active card playable through
the same Lua rule, ECS state, command, and save paths as the rest of Crawl.
Modders add cards and deck weights as individual Lua files. Go remains a
generic runtime and terminal bridge; card behavior lives in Lua.

## Approaches

An item-backed deck model would reuse inventory, but the pinned DCSS source
keeps modern Nemelex decks in player properties, not carried items. A single
Lua switch over card IDs would centralize the domain but make additions
and review difficult. Use one saved `religion.nemelex_decks` component on
the player, individual card definitions and effect modules, and a small
deck operation owner. This matches current source ownership and the port's
file-per-content mod model.

## State and content

The versioned `religion.nemelex_decks` component owns player deck counts,
an ordered stack, and a pending operation. Pending state stores the phase,
deck, sampled card IDs, target count, and ordering selection for Triple
Draw or Stack Five. Counts and pending operations survive save and restore.
Renouncing Nemelex clears all three counts, the stack, and pending state.
Card IDs and deck IDs live in shared `ids` modules; no rule repeats literal
IDs. Stable IDs are distinct from display names such as `CARD_SUMMON_BEE`
and “the Swarm”. Each active source card has one content file with display
name, deck membership and weight, and effect module. Catalog validation
checks weights and memberships. A save containing an unknown card ID fails
with that ID named, rather than losing a card silently. The
punishment pool is separate and cannot be drawn voluntarily. Deck maxima
are 13 escape, 26 destruction, and 13 summoning. Effective mod catalogs
are sorted by stable IDs before weighted draws so file order cannot
change a seed.

## Gifts and play

The source first-gift chance, later chance, per-gift 4–13 count, deck
weights 3:1:1, capacity checks, 5 plus random2avg(9, 2) timeout, and
gift counters are Lua rules. `content/gods/nemelex_xobeh.lua` names a gift
module, whose `check` uses `policy.religion.gifts.record` even when all
decks are full; `leave` clears the deck component. Draw consumes one card;
Triple Draw samples up to three and lets the player choose one; Deal Four
consumes up to four; Stack Five draws up to five into an ordered stack that
the player may reorder before use. The stack procedure first completes
replacement and short-stack prompts, checks failure, clears the old stack,
then draws and orders cards. Triple Draw consumes its sampled cards before
the choice prompt. The Lua action owner saves every postcommit phase and
blocks unrelated commands until the pending operation completes, including
after restore. The terminal forwards prompt decisions to that owner and
does not keep authoritative pending cards in Go model fields. A precommit
cancel spends no cards or turn; a postcommit target abort may waste the
drawn Vitriol, Pain, or Orb card after source confirmation. Menus show the
three deck counts and real card names.

Nemelex draw abilities appear while worshipping, with Triple Draw, Deal
Four, and Stack Five unlocking at three, four, and five stars. The existing
Lua ability owner handles availability, MP costs (0 for Draw, 2/8/5 for
Triple/Deal/Stack), piety costs (0 for Draw, 6/4/10 for Triple/Deal/Stack),
Invocations failure, and one normal-turn action. Deal Four uses its source
special failure formula. The generic Go command and terminal bridge carry
deck, card choice, and target decisions without owning the game rule.

## Card effects

Port every active card in the pinned source: Velocity, Tomb, Exile,
Vitriol, Cloud, Storm, Pain, Torment, Orb, Elixir, Pentagram, Dance,
Swarm, Wild Magic, Wrath, Wraith, Swine, Illusion, Degeneration,
Elements, and Rangers. Each effect gets a named Lua module and reuses
existing world, combat, magic, summon, mutation, and religion owners
where possible. Missing generic mechanics are implemented as reusable
Lua policy or ECS components, with the card module selecting their source
parameters. Card power uses Nemelex piety and Invocations; punishment
uses experience level. Target prompts, abort behavior, and deck-use
messages follow the source gameplay flow.

## Verification

Production-schema `_test.lua` scenarios cover gift gates and caps,
deterministic weighted selection, save and restore of counts and pending
choices, renunciation, all four deck actions, and each card effect's
observable outcome. Add game-level input and save tests for the complete
action path. Run the focused Lua and game tests, Go build, changed-file
style checks, and inspect terminal menus. Commit coherent completed
categories to `main` and push after verification.
