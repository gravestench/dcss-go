# DCrawl Go development

Keep the port faithful to the pinned DCSS source and make its behavior easy
for a human reader to follow.

## Code readability

- Keep handwritten Go source lines at or below 120 characters. Prefer 80
  characters when the expression stays clear.
- Give distinct steps breathing room. Separate validation, calculation,
  state changes, and event emission with blank lines instead of packing them
  into dense expressions or one-line blocks. Expand nonempty inline callbacks.
- Break long runs of assignments into groups that match the game concepts
  being set up. Group test setup and assertions by behavior rather than by a
  fixed line count. Use a named reset or helper when one operation clears
  many fields.
- Separate top-level declarations, including related constants and types, with
  a blank line so each name is easy to find.
- Leave a blank line before and after a control-flow block when it has a
  neighboring statement in the same block. Separate the final return from
  preceding calculations or mutations.
- Put crowded boolean expressions on separate lines so each check can be
  scanned, including expressions in returns and assignments. Keep lines with
  `&&` or `||` at or below 80 characters where they contain a boolean check.
- When a condition checks an error and another result, give each clause its
  own line. Keep the error check first when short-circuiting protects the
  result check.
- Put entries of keyed literals and named composite literals on separate lines
  whenever they contain more than one entry. A one-entry literal may stay
  inline. Expand slices and lists with three or more values instead of placing
  the whole declaration on one line. Compact fixed arrays of three scalar
  values may stay inline.
- In long struct literals, leave blank lines between groups of related fields.
  Keep the existing field order when grouping saved or imported data.
- Separate consecutive multiline entries in a table, map, or test fixture with
  blank lines so each entry can be scanned on its own.
- Leave a blank line after a multiline literal before the next statement.
- Give multiline raw source fixtures the same breathing room before the next
  statement.
- Declare each struct field on its own line, including fields in test case
  tables. In large state and catalog structs, separate fields into conceptually
  related groups with blank lines. Keep serialized field order stable.
- Assign mutable fields one per line. Keep tuple assignment for values returned
  together by a function, such as a result and its error.
- Give each `var` local state variable its own declaration. Related values
  initialized together with `:=`, such as coordinates and bounds, and
  function result tuples may remain together.
- Use names that expose the game concept. Extract a helper when it removes
  repeated reasoning, not merely to shorten a function.
- Review functions over roughly 100 lines for mixed responsibilities. Split
  projections, validation, decisions, and mutations into named steps when
  those steps can be understood on their own. Do not add wrappers that only
  hide one expression.
- Comment source-specific rules, invariants, ownership, and surprising
  choices. Do not narrate obvious statements. Cite the pinned C++ source
  when a numeric rule or unusual order comes from it.
- Run `gofmt` on changed Go files. Keep each commit to one contiguous problem
  category, then run the relevant tests and broader verification at that
  category boundary.
- Run `sh scripts/check-go-style.sh` at each category boundary to catch line
  length and formatting regressions across handwritten Go code.

## State ownership

Use Akara components for mutable state of dynamic entities and ordered
systems for their turn behavior. Keep dense terrain and exploration grids,
immutable content, RNG streams, save codecs, and terminal rendering with
their focused owners outside ECS. See `docs/ecs-architecture-roadmap.md`.

## Lua-first game rules

The default DCSS rules and mod extension API belong in embedded Lua. Go owns
only reusable kernel services: Akara storage and scheduling, virtual files,
RNG, grids, saves, and terminal primitives. Register component schemas,
systems, content, generation, and policy in Lua. Do not add a Go switch over
content IDs or a second Go behavior path while migrating a domain. See
`docs/superpowers/specs/2026-10-14-lua-first-mod-runtime-design.md`.

Keep handwritten Lua readable: prefer lines near 80 characters, never exceed
120, put fields of multi-field tables on separate lines, and leave space
between validation, calculation, mutation, and event emission. Explain
source-specific roll order and ownership in comments. A Lua module should
have one clear domain responsibility and a stable registration name. Mutable
state that must survive save/restore belongs in Akara components or explicit
session/level stores, not an untracked module global.

Keep all Lua source in `.lua` files under the embedded mod tree or a test mod
directory. Do not put Lua source in Go strings, including Go test fixtures.
