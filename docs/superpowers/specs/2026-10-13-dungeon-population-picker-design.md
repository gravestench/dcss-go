# Dungeon population picker

The Go port should use the committed Dungeon population to make the same weighted monster choice as the pinned tag-34 `random_picker::pick` (`crawl-ref/source/random-pick.h:47-82`). This category prepares monster selection for level generation without changing the fixed two-floor scenario.

For a requested depth, the catalog builds an immutable pool in source row order. Each in-range row contributes its existing 2520-scale `WeightAtDepth`; duplicate monster IDs remain separate chances. An optional veto excludes a monster before its row contributes, as in the source picker. A caller draws one integer in `[0, TotalWeight)` with its owned RNG stream and supplies it to `Pick`. The pool returns an empty ID if no rows qualify and rejects any out-of-range roll when rows do qualify. Pool construction does not draw random numbers or mutate the catalog.

The pool exposes only its total and `Pick`, so generation can own RNG and eligibility policy. This slice does not filter to the two presently implemented animal behaviors: doing so would distort the Dungeon table. Normal play continues using the fixed rat/quokka scenario until general monster creation and level placement exist.
