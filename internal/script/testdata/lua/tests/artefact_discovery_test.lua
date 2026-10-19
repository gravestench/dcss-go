local artefact_ids = require("ids.artefacts")
local artefact_kinds = require("constants.artefact_kinds")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local identification = require("policy.items.identification")
local item_ids = require("ids.items")
local names = require("policy.item_generation.artefacts.names")
local shop_identification = require("policy.shops.identification")
local identify_scroll = require("policy.scrolls.effects.identify")

local test = {}

-- Use the real catalog fields and ECS schemas. The item entities differ only
-- in their physical identity, which is what source artefact knowledge tracks.
local function fixed_item(ctx, id, base_id)
    local definition = catalog.get("artefacts", id)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = base_id or definition.kind_id,
        quantity = 1,
        plus = definition.properties.plus or 0,
    })

    ctx:add(entity, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.UNIQUE,
        unique_id = id,
        name = definition.name,
        appearance = definition.appearance ~= "" and
            definition.appearance or definition.name,
        properties = definition.properties,
    })

    return entity
end

-- A random ring deliberately shares a base kind with an ordinary ring so
-- the test can catch a global type-discovery leak into artefact identity.
local function random_ring(ctx)
    local definition = catalog.get("items", item_ids.RING_PROTECTION)
    local name, appearance, seed = names.generate(ctx, definition)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = definition.id,
        quantity = 1,
        plus = 2,
    })

    ctx:add(entity, component.ITEM_ARTEFACT, {
        kind = artefact_kinds.RANDOM,
        name = name,
        appearance = appearance,
        seed = seed,
    })

    return entity, name, appearance
end

-- The source gives each artefact its own type flag; a known base kind must
-- not reveal its true name or the identity of another physical artefact.
function test.run(ctx)
    local player = ctx:create()
    identification.initialize(ctx, player)

    local hidden = fixed_item(ctx, artefact_ids.UNRAND_CEREBOV)

    harness.falsy(identification.known(ctx, player, hidden).type,
        "a named unique begins with its own type unknown")
    harness.equal(identification.name(ctx, player, hidden),
        "great serpentine sword", "unknown unique shows source appearance")

    local singing = fixed_item(ctx, artefact_ids.UNRAND_SINGING_SWORD)
    local singing_state = identification.known(ctx, player, singing)

    harness.truthy(singing_state.type and singing_state.pluses and
        singing_state.properties,
        "same-name fixed artefact starts fully identified")

    local octopus = fixed_item(ctx,
        artefact_ids.UNRAND_OCTOPUS_KING_RING,
        item_ids.RING_PROTECTION)

    harness.falsy(identification.known(ctx, player, octopus).type,
        "unided suppresses automatic identification")

    local first, true_name, appearance = random_ring(ctx)
    local second = random_ring(ctx)
    local ordinary = ctx:create()

    local _, amulet_appearance = names.generate(ctx,
        catalog.get("items", item_ids.AMU_REFLECTION))

    harness.truthy(amulet_appearance:match(" amulet$") ~= nil,
        "weighted source appearance keeps an unknown amulet's shape")

    ctx:add(ordinary, component.ITEM, {
        kind_id = item_ids.RING_PROTECTION,
        quantity = 1,
    })

    identification.reveal_type(ctx, player, ordinary)

    harness.falsy(identification.known(ctx, player, first).type,
        "ordinary ring discovery does not identify a random artefact")
    harness.equal(identification.name(ctx, player, first), appearance,
        "unknown random artefact shows its saved appearance")
    harness.falsy(appearance:find("protection", 1, true),
        "unidentified randart appearance hides its ring subtype")

    identification.reveal_type(ctx, player, first)

    harness.equal(identification.name(ctx, player, first), true_name,
        "type discovery reveals only this artefact's true name")
    harness.falsy(identification.known(ctx, player, second).type,
        "another artefact on the same base stays unknown")

    identify_scroll.apply(ctx, player, {
        target_id = tostring(ctx:id(hidden)),
    })

    local identified = identification.known(ctx, player, hidden)
    local artefact = ctx:get(hidden, component.ITEM_ARTEFACT)

    harness.truthy(identified.type and identified.pluses and
        identified.properties,
        "Identify reveals all inspectable fields on the target")
    harness.equal(identification.name(ctx, player, hidden),
        "+6 sword of Cerebov", "Identify shows the true named weapon")

    for id in pairs(artefact.properties) do
        harness.truthy(artefact.known[id],
            "full Identify marks each saved artefact property known")
    end

    shop_identification.stock(ctx, second,
        catalog.get("items", item_ids.RING_PROTECTION))

    harness.truthy(identification.known(ctx, player, second).type,
        "shop stock shows the artefact's own true name")
    identification.validate(ctx, player)
end

return test
