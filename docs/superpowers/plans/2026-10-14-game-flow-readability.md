# Game Flow Readability Pass

## Goal

Make run creation and player-command flow easier to read without changing
gameplay, RNG draws, ECS system order, messages, or saved state.

## Work

1. Split `newScenario` into input validation, game construction, player
   creation, character state, population, starting floor items, and final
   activation. Keep the existing order of every state change and draw.
2. Split `Game.Step` into command preparation and turn execution. Put
   movement, stairs, pickup, and quaff checks in named methods so the
   command dispatcher is short. Preserve no-time returns and attack-delay
   draws exactly.
3. Keep helpers at the owner that has the data they need. Avoid generic
   wrappers and temporary compatibility layers.
4. Run focused existing scenario and step tests, then full Go tests, vet,
   build, style check, and diff check at the category boundary. Review the
   diff before one readability commit.
