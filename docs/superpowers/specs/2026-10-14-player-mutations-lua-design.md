# Player mutations in Lua: design

## Intent

Port the pinned DCSS player mutation domain as a complete Lua-owned ruleset.
Mutation acquisition, loss, conflicts, suppression, consequences, and display
must use the same source-derived state. A modder can add a mutation definition
under `content/mutations/` and, when needed, a focused effect file under
`policy/mutations/effects/`. Neither path requires editing a Go dispatcher or
rebuilding a generated index. This domain also completes Violent Unravelling,
whose blast can malmutate its caster.

The pinned source is `crawl-ref/source` at revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. The source catalog is
`mutation-type.h` and `mutation-data.h`; behavior comes from `mutation.cc`,
`player.cc`, and the relevant combat, item, magic, world, and UI call sites.
The pinned table contains 196 entries, including entries retained only for
old source saves. The importer must distinguish active entries from removed
ones. The Go game never reads the C++ source during builds or play.

## Ownership and state

Each mutation identity has one committed Lua definition in
`content/mutations/`, with source location and revision in comments. Runtime
fields contain game facts only: ID, status, selection weight, maximum level,
use flags, form suppression, descriptions, and any declarative scalar
modifiers. Shared IDs come from `ids.mutations` at each use site. All Lua
files use named functions and return a local module table.

Akara owns one `character.mutation` entity per player and mutation ID that
has a nonzero level. Its Lua schema stores owner, mutation ID, innate levels,
ordinary acquired levels, and temporary levels. A separate player component
stores the one XP countdown shared by all temporary mutations, matching
`ATTR_TEMP_MUT_XP` in the source. Mutation levels are never serialized into an
opaque player string or duplicated in an unrelated Go struct. Species
definitions remain
the source for scheduled innate grants; Lua character creation and level-up
turn those grants into the same ECS records. Species fake mutations that are
rules rather than actual mutation levels stay in focused species policy.

One Lua query API computes base and effective levels from those records,
including form suppression and relevant statuses. Character formulas,
equipment checks, combat, magic, passive systems, and the mutation screen
read this API. A source mutation level can affect play only through this
path. Removing or suppressing a level must update every consumer on the next
query rather than leave a copied modifier behind.

## Selection and transitions

Lua owns the source weighted selection order, acceptance rules, physiology
restrictions, conflict table, mutation resistance, and temporary/permanent
grant and loss paths. Preserve the pinned source's RNG sequence using a saved
named mutation stream. The importer may produce committed Lua tables for
ordered conflicts and other fixed source data, with provenance in comments.
The conflict table remains ordered because forced and ordinary cases can
resolve the same pair differently. Invalid or unimplemented definitions may
not silently enter a random selection pool.

Transition APIs distinguish the source concepts: innate grant, acquired
grant, temporary grant, delete, and malmutate. They return an explicit
result, update ECS state in the current transaction, and emit Lua-owned
messages. Equipment fit, HP/MP changes, stat changes, and death are resolved
in source order after a successful transition. A failed or refused mutation
does not alter state or consume a later random draw.

## Consequences and extension points

Declarative modifiers cover genuinely uniform rules such as a fixed stat,
resistance, or HP/MP multiplier. Behavioral mutations have focused Lua
modules registered by mutation ID or capability; no central hundreds-case
resolver is allowed. Existing generic systems call a capability query at
the point of use. A mod may override a definition or effect by replacing
its relative path, or add both files for a new behavior. A missing required
effect for an active, selectable mutation fails at boot with its ID and
file path. Removed source mutations remain identified for provenance but
are not selected or granted in new games.

This category includes the consequences of every active mutation that can
be selected, granted by a current species, or produced by a ported action.
Where the consequence depends on a not-yet-ported domain, implement that
domain's generic interaction in Lua as part of this category. Source
selection weights remain intact. Do not mark a mutation operational merely
because its ID and text load.

## Violent Unravelling

The existing Lua target and blast code becomes a registered spell effect
after player malmutation is functional. On a valid enchanted or summoned
target, the source dispel or dismissal creates the radius-one mutagenic
blast. Monsters receive their source mutation and damage behavior. If the
caster is in the blast, player mutation selection and acquisition occur
through the same durable Lua mutation API used by other sources. Target
rejection remains a no-time abort. Successful casts, including self-hits,
preserve source MP, failure, damage, and RNG order.

## Save, UI, and verification

Go saves store the Lua ECS records and ruleset manifest; Lua save policy
validates owner, known ID, nonnegative levels, maximum, duplicate records,
and the shared temporary XP countdown. A changed ruleset still requires the
existing
explicit mismatch opt-in. Current incompatible saves fail clearly rather
than interpreting old origin strings as mutation records. The mutation
screen uses the effective records and source descriptions; its layout stays
full-terminal DCSS-shaped.

Verify the imported active/removed catalog against the pinned source,
representative source RNG and conflict vectors, suppression, innate level-up,
HP/MP and equipment effects, passive effects, malformed mod content, save
round trips, and self-hit Unravelling. Coverage must prove that every
selectable mutation has its required behavior path. Run category-focused
tests during the broad sweep, then build, vet, style, importer checks, and
the broad test suite at the category boundary. Commit this domain as one
contiguous category and merge only after the integrated behavior is verified.
