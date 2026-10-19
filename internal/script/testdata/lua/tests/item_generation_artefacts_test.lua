-- Unknown source artefact field rejected.

local streams = require("constants.rng_streams")
local artefacts = require("policy.item_generation.artefacts.unique")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local ids = require("ids.artefacts")
local items = require("ids.items")
local status = require("constants.unique_item_status")
local generation = require("policy.item_generation")
local quality = require("constants.vault_item_quality")
local purpose = require("constants.item_generation_purpose")
local validation = require("policy.item_generation.validate")
local properties = require("policy.item_generation.artefacts.properties")
local property_ids = require("ids.artefact_properties")
local save_artefacts = require("policy.save.artefacts")

local test = {}

-- Hold unique history in a tiny context and choose a boundary RNG slot, so
-- candidate selection can be separated from committing a unique item.
local function context(last)
    local ctx = {
        state = {
            status = {},
        },
    }

    -- Give artefact generation one stable player identity for history reads.
    function ctx:player()
        return 1
    end

    -- Restrict fixture reads to unique history, catching an unexpected
    -- dependency on other player components in this selection path.
    function ctx:get(_, name)
        harness.equal(name, component.PLAYER_UNIQUE_HISTORY,
            "history component")

        return self.state
    end

    -- Persist the committed unique status so the test can distinguish
    -- inspecting a candidate from actually placing it.
    function ctx:set(_, name, value)
        harness.equal(name, component.PLAYER_UNIQUE_HISTORY,
            "persist history")
        self.state = value
    end

    -- Return the first or last legal item-generation slot while asserting
    -- unique choice stays on the item RNG stream.
    function ctx:random(stream, bound)
        harness.equal(stream, streams.ITEM_GENERATION, "unique stream")

        return last and bound - 1 or 0
    end

    return ctx
end

-- Choose a matching source unique, then apply it; history should change only
-- at application while its authored enchantment becomes item state.
local function source_candidate_and_history()
    local ctx = context(true)
    local base = catalog.get("items", items.WPN_DOUBLE_SWORD)
    local chosen = artefacts.choose(ctx, base, {
        depth = 1,
        purpose = purpose.VAULT,
    })

    harness.truthy(chosen, "matching source unique")
    harness.equal(chosen.id, ids.UNRAND_SINGING_SWORD,
        "first matching source unique with last-bound draws")
    harness.equal(ctx.state.status[chosen.id], nil,
        "choosing does not consume unique")

    local result = {
        kind_id = base.id,
        plus = 0,
        ego = "",
        components = {},
    }

    artefacts.apply(ctx, chosen, {
        purpose = purpose.VAULT,
    }, result)

    harness.equal(ctx.state.status[chosen.id], status.ORDINARY,
        "placed unique recorded")
    harness.equal(result.components[component.ITEM_ARTEFACT].unique_id,
        chosen.id, "identity stored on item")
    harness.equal(result.plus, chosen.properties.plus,
        "source enchantment retained")
end

-- A candidate may be inspected without consuming the unique; only the
-- committed item roll records it in history.
local function item_roll_uses_unique_history()
    local ctx = context(false)
    local rolled = generation.roll(ctx, {
        kind_id = items.WPN_DOUBLE_SWORD,
        depth = 1,
        quality = quality.ORDINARY,
        allow_uniques = true,
        purpose = purpose.VAULT,
        site = "unique roll test",
    })
    local artefact = rolled.components[component.ITEM_ARTEFACT]

    harness.truthy(artefact, "source unique roll creates artefact")
    harness.equal(artefact.kind, "unique", "source unique selected")
    harness.equal(ctx.state.status[artefact.unique_id], status.ORDINARY,
        "source unique roll marks history")
end

-- A unique already acquired outside the level cannot spawn again; its source
-- fallback replaces the rolled base while keeping historical uniqueness.
local function nonlevel_unique_uses_source_fallback()
    local ctx = context(false)
    local chosen = catalog.get("artefacts", ids.UNRAND_GUARD)
    local result = {
        kind_id = items.WPN_GLAIVE,
        components = {},
    }

    ctx.state.status[chosen.id] = status.NONLEVEL

    local applied = artefacts.apply(ctx, chosen, {
        purpose = purpose.VAULT,
    }, result)

    harness.falsy(applied, "acquired unique cannot be placed twice")

    local fallback, brand = artefacts.fallback(ctx, chosen, {
        depth = 4,
        site = "unique fallback test",
    }, result)

    harness.equal(fallback.id, items.WPN_BARDICHE,
        "source fallback subtype used")
    harness.equal(result.kind_id, fallback.id,
        "fallback updates the rolled kind")
    harness.equal(brand, chosen.brand,
        "fallback inherits a compatible source brand")
    harness.equal(ctx.state.status[chosen.id], status.NONLEVEL,
        "fallback keeps unique history")
end

-- An enhancer staff can produce a weapon-based source unique, so generation
-- must switch its base kind when that unique wins the roll.
local function enhancer_staff_can_roll_unique()
    local rolled = generation.roll(context(false), {
        kind_id = items.STAFF_FIRE,
        depth = 3,
        quality = quality.ORDINARY,
        allow_uniques = true,
        purpose = purpose.ACQUIREMENT,
        site = "enhancer staff test",
    })
    local artefact = rolled.components[component.ITEM_ARTEFACT]

    harness.truthy(artefact, "enhancer staff rolls source uniques")
    harness.equal(artefact.kind, "unique", "enhancer unique kind")
    harness.equal(rolled.kind_id, items.WPN_STAFF,
        "enhancer unique uses its source weapon base")
end

-- If the staff unique is unavailable, its authored quarterstaff fallback
-- still replaces the rolled kind rather than leaving an enhancer staff.
local function enhancer_fallback_uses_quarterstaff()
    local ctx = context(false)
    local chosen = catalog.get("artefacts", ids.UNRAND_OLGREB)
    local result = {
        kind_id = items.WPN_STAFF,
        components = {},
    }
    local fallback = artefacts.fallback(ctx, chosen, {
        depth = 3,
        site = "enhancer fallback test",
    }, result)

    harness.equal(fallback.id, items.WPN_QUARTERSTAFF,
        "source weapon fallback converts enhancer staff")
    harness.equal(result.kind_id, fallback.id,
        "enhancer fallback updates rolled kind")
end

-- RANDART quality must create persisted property and brand data during the
-- roll, before materialization or save code sees the item.
local function forced_randart_saves_properties()
    local rolled = generation.roll(context(false), {
        kind_id = items.WPN_DAGGER,
        depth = 1,
        quality = quality.RANDART,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "random artefact test",
    })
    local artefact = rolled.components[component.ITEM_ARTEFACT]

    harness.truthy(artefact, "randart quality creates a random artefact")
    harness.equal(artefact.kind, "random", "random artefact kind")
    harness.truthy(next(artefact.properties), "source property rolls retained")
    harness.truthy(artefact.brand ~= "", "weapon artefact has brand")
end

-- Source placeholders must never enter the selectable unique pool even
-- though they remain in the committed artefact catalog.
local function dummy_and_nogen_are_excluded()
    local dummy = catalog.get("artefacts", ids.UNRAND_DUMMY1)

    harness.falsy(artefacts.eligible(dummy), "dummy cannot spawn")
end

-- Mutate a copy of a real source artefact so validation can report both the
-- unknown property and the effective Lua file that supplied it.
local function invalid_source_property_reports_origin()
    local original = catalog.get("artefacts", ids.UNRAND_SINGING_SWORD)
    local changed = {}

    for key, value in pairs(original) do
        changed[key] = value
    end

    changed.properties = {
        impossible_property = 1,
    }

    local okay, failure = pcall(validation.artefact, changed)

    harness.falsy(okay, "unknown source artefact field rejected")
    harness.truthy(failure:find("content/artefacts/unrand_singing_sword.lua", 1, true),
        "validation reports effective artefact file")
    harness.truthy(failure:find("impossible_property", 1, true),
        "validation reports bad property")
end

-- An armour fallback paired with a weapon kind is invalid; include its
-- source path in the error so a mod author can find the bad declaration.
local function invalid_fallback_reports_origin()
    local original = catalog.get("artefacts", ids.UNRAND_GUARD)
    local changed = {}

    for key, value in pairs(original) do
        changed[key] = value
    end

    changed.fallback = {
        class = "OBJ_ARMOUR",
        kind_id = items.WPN_BARDICHE,
    }

    local okay, failure = pcall(validation.artefact, changed)

    harness.falsy(okay, "incompatible source fallback rejected")
    harness.truthy(failure:find("content/artefacts/unrand_guard.lua", 1, true),
        "fallback failure reports effective artefact file")
end

-- Read legacy property fields through typed IDs, ensuring combat and UI
-- consumers no longer need raw source spellings.
local function source_properties_have_typed_effect_ids()
    local ctx = {}

    -- Return one saved artefact component and reject other component reads,
    -- isolating typed-property lookup from unrelated item state.
    function ctx:get(_, name)
        harness.equal(name, component.ITEM_ARTEFACT,
            "artefact property component")

        return {
            kind = "unique",
            properties = {
                will = 2,
                base_dam = 3,
                base_acc = -1,
                base_delay = 4,
            },
            flags = {
                "poison",
            },
        }
    end

    harness.equal(properties.value(ctx, 1, property_ids.WILLPOWER), 2,
        "source willpower property")
    harness.equal(properties.value(ctx, 1, property_ids.POISON), 1,
        "source poison flag")
    harness.equal(properties.value(ctx, 1, property_ids.BASE_DAMAGE), 3,
        "source base weapon damage")
    harness.equal(properties.value(ctx, 1, property_ids.BASE_ACCURACY), -1,
        "source base weapon accuracy")
    harness.equal(properties.value(ctx, 1, property_ids.BASE_DELAY), 4,
        "source base weapon delay")
end

-- Sum bonuses from an equipped carried artefact using saved ECS links, not
-- the original source definition, which may be overridden by a mod later.
local function worn_properties_use_saved_components()
    local ctx = {}
    local player = 1
    local item = 2
    local parts = {
        [item] = {
            [component.ITEM] = {
                kind_id = items.WPN_DAGGER,
                quantity = 1,
                plus = 0,
                charges = 0,
                ego = "",
            },
            [component.CARRIED_BY] = {
                holder = player,
            },
            [component.EQUIPPED] = {
                slot = "weapon",
            },
            [component.ITEM_ARTEFACT] = {
                kind = "unique",
                properties = {
                    str = 2,
                    ac = 3,
                    slay = 4,
                },
                flags = {},
            },
        },
    }

    -- Identify the owner whose equipped artefact should contribute bonuses.
    function ctx:player()
        return player
    end

    -- Read the fixture's saved item, carrier, equipment, and artefact parts
    -- through the same component lookup used in play.
    function ctx:get(entity, name)
        return parts[entity] and parts[entity][name]
    end

    -- Offer the one fixture item to the worn-property collector so its link
    -- checks determine whether the bonus applies.
    function ctx:query()
        return { item }
    end

    harness.equal(properties.sum_worn(ctx, player,
        property_ids.STRENGTH), 2, "equipped artefact strength")
    harness.equal(properties.sum_worn(ctx, player,
        property_ids.AC), 3, "equipped artefact armour")
    harness.equal(properties.sum_worn(ctx, player,
        property_ids.SLAYING), 4, "equipped artefact slaying")
end

-- Save validation checks typed randart properties again on restore rather
-- than trusting serialized property ids and values.
local function restore_rejects_incompatible_randart_property()
    local ctx = {}
    local item = {
        kind_id = items.WPN_DAGGER,
    }
    local artefact = {
        kind = "random",
        unique_id = "",
        name = "dagger of Bad Data",
        appearance = "dagger",
        brand = "SPWPN_VENOM",
        properties = {
            [property_ids.SLAYING] = 2,
        },
        known = {},
    }

    -- Present the malformed randart as a saved entity for restore validation.
    function ctx:query()
        return { 1 }
    end

    -- Return the paired item and artefact records while omitting everything
    -- else, isolating property compatibility checks during restore.
    function ctx:get(_, name)
        if name == component.ITEM then
            return item
        end

        if name == component.ITEM_ARTEFACT then
            return artefact
        end
    end

    -- Preserve the fixture entity number in diagnostics so a bad save entry
    -- can be identified without a full ECS world.
    function ctx:id(entity)
        return entity
    end

    local okay, failure = pcall(save_artefacts.validate, ctx)

    harness.falsy(okay, "incompatible randart save rejected")
    harness.truthy(failure:find("incompatible random property", 1, true),
        "save failure identifies property compatibility")
end

-- Exercise unique selection, fallback, random properties, and restore
-- validation together because all four share the saved artefact contract.
function test.run()
    source_candidate_and_history()
    item_roll_uses_unique_history()
    nonlevel_unique_uses_source_fallback()
    enhancer_staff_can_roll_unique()
    enhancer_fallback_uses_quarterstaff()
    forced_randart_saves_properties()
    dummy_and_nogen_are_excluded()
    invalid_source_property_reports_origin()
    invalid_fallback_reports_origin()
    source_properties_have_typed_effect_ids()
    worn_properties_use_saved_components()
    restore_rejects_incompatible_randart_property()
end

return test
