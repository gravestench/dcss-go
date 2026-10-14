# DCrawl Go development

Keep the port faithful to the pinned DCSS source and make its behavior easy
for a human reader to follow.

## Code readability

- Keep handwritten Go source lines at or below 120 characters. Prefer 80
  characters when the expression stays clear.
- Give distinct steps breathing room. Separate validation, calculation,
  state changes, and event emission with blank lines instead of packing them
  into dense expressions or one-line blocks.
- Put fields of a struct literal on separate lines whenever it populates
  more than one field. A one-field literal may stay inline.
- Use names that expose the game concept. Extract a helper when it removes
  repeated reasoning, not merely to shorten a function.
- Comment source-specific rules, invariants, ownership, and surprising
  choices. Do not narrate obvious statements. Cite the pinned C++ source
  when a numeric rule or unusual order comes from it.
- Run `gofmt` on changed Go files. Keep each commit to one contiguous problem
  category, then run the relevant tests and broader verification at that
  category boundary.

## State ownership

Use Akara components for mutable state of dynamic entities and ordered
systems for their turn behavior. Keep dense terrain and exploration grids,
immutable content, RNG streams, save codecs, and terminal rendering with
their focused owners outside ECS. See `docs/ecs-architecture-roadmap.md`.
