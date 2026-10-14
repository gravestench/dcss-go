# Presentation Readability Pass

## Goal

Make the live view and HUD rendering paths easy to scan without changing
their output or game state. This responds to the remaining crowded code in
the Go port and is separate from the jackal gameplay commit.

## Work

1. Split `Game.View` into terrain, player, visible-entity, and inventory
   projections. Each helper reads the existing ECS stores and fills one
   part of the same value snapshot.
2. Split HUD rendering into named vital, defense, attribute, and status
   sections. Keep source pane coordinates and drawing order unchanged.
3. Replace large anonymous inline tables with small named data types where
   the names clarify the purpose. Separate calculations from canvas writes.
4. Run existing view, save, and terminal rendering tests, then the full Go
   suite, vet, build, style check, and diff check once for the category.
   Review the resulting diff before one readability commit.

## Follow-up

Apply the same responsibility-based cleanup to scenario setup, command
handling, and importer parsers in later contiguous style categories. The
current line-length and AST checker cannot establish that a long function
has one clear responsibility.
