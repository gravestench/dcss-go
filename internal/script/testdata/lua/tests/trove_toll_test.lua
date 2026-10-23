-- Exercise the production Trove price owner with deterministic saved-stream
-- draws. These tests import real IDs rather than restating item definitions.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local species = require("ids.species")
local items = require("ids.items")
local sets = require("constants.item_sets")
local shops = require("ids.shops")
local streams = require("constants.rng_streams")
local toll = require("policy.world.trove.toll")
local trove = require("constants.trove")
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local portal = require("policy.world.trove.portal")
local terrain = require("constants.terrain")

local test = {}

-- A tiny context records each draw and exposes the same player components
-- that a real population pass reads. Other RNG streams fail immediately.
local function context(species_id, god_id, draws)
    local used = 0
    local player = 1
    local ctx = {}

    -- One fixture player supplies the real content-policy lookup path.
    function ctx:player()
        return player
    end

    -- Only production player fields needed by toll rolling are projected.
    function ctx:get(_, id)
        if id == component.PLAYER then
            return { species_id = species_id }
        end

        if id == component.RELIGION_WORSHIP then
            return { god_id = god_id }
        end

        if id == component.PLAYER_ITEM_SETS then
            return {
                choices = {
                    [sets.CONCEALMENT_SCROLLS] = items.SCR_FOG,
                },
            }
        end

        if id == component.ITEM_KNOWLEDGE then
            return {
                known_types = {},
                seen_types = {},
            }
        end

        error("unexpected component " .. id)
    end

    -- Scripted draws make source chance and fallback order observable.
    function ctx:random(stream, bound)
        if stream ~= streams.TROVE_TOLL then
            return 0
        end
        used = used + 1
        local value = draws[used] or 0

        harness.truthy(value >= 0 and value < bound,
            "scripted draw fits source bound")

        return value
    end

    -- Callers can prove an early piety choice skipped the fallback dice.
    function ctx:draws_used()
        return used
    end

    return ctx, player
end

-- Source's first one-in-twenty choice allows a nonexcluded character to
-- pay with piety, while Ashenzari and Demigod always fall back to an item.
local function check_piety_exclusions()
    local ordinary, player = context(species.SP_HUMAN, gods.NO_GOD, {0})
    local price = toll.roll(ordinary, player)

    harness.equal(price.kind, "no_piety", "source piety price")
    harness.equal(ordinary:draws_used(), 1,
        "no item pool rolled after piety choice")

    local ash, ash_player = context(species.SP_HUMAN,
        gods.ASHENZARI, {0})
    harness.equal(toll.roll(ash, ash_player).kind, "item",
        "Ashenzari cannot roll no-piety toll")

    local demigod, demi_player = context(species.SP_DEMIGOD,
        gods.NO_GOD, {0})
    harness.equal(toll.roll(demigod, demi_player).kind, "item",
        "Demigod cannot roll no-piety toll")
end

-- A canonical encoded witness is stable, validates field shape, and
-- retains exact rune identity for proof without consuming the rune.
local function check_price_witness()
    local price = {
        kind = "rune",
        item_id = items.RUNE_ABYSSAL,
        quantity = 1,
        minimum_plus = 0,
        source_rune_index = trove.RUNE_ABYSSAL_SOURCE_INDEX,
    }

    harness.equal(toll.encode(price), toll.encode(price),
        "same price has the same source witness")
    harness.truthy(toll.valid(price), "named rune is valid")
    harness.falsy(toll.valid({ kind = "item", quantity = -1 }),
        "malformed mod price is rejected")
end

-- The source's one-in-three shop path may copy identified, nonstackable
-- weapon stock priced at least 1,000 gold. It keeps kind and plus.
local function check_shop_candidate()
    local ctx, player = context(species.SP_HUMAN,
        gods.NO_GOD, {1, 0, 0})
    local previous_get = ctx.get

    -- Only the actual shop and item component shapes are supplied here;
    -- production quote and identification policies make the decision.
    -- One item in a live shop is enough to drive the source shop branch.
    function ctx:query()
        return {2}
    end

    -- The test uses numeric IDs directly as its minimal entity handles.
    function ctx:entity(id)
        return id
    end

    -- A shop contributes stock only after its entrance is in player memory.
    function ctx:remembered()
        return terrain.DNGN_ENTER_SHOP
    end

    -- Project a real stock, item, and shop while preserving player reads.
    function ctx:get(entity, id)
        if entity == 2 then
            if id == component.SHOP_STOCK then
                return { shop_id = 3, order = 1 }
            end

            if id == component.ITEM then
                return {
                    kind_id = items.WPN_RAPIER,
                    quantity = 1,
                    plus = 25,
                    ego = "",
                }
            end

            if id == component.ITEM_IDENTIFICATION then
                return {
                    known_type = true,
                    known_pluses = true,
                    known_properties = true,
                }
            end

            return nil
        end

        if entity == 3 then
            if id == component.SHOP then
                return {
                    kind_id = shops.SHOP_WEAPON,
                    open = true,
                    greed = 10,
                    level_id = 1,
                    x = 3,
                    y = 3,
                }
            end

            return nil
        end

        return previous_get(self, entity, id)
    end

    local price = toll.roll(ctx, player)

    harness.equal(price.item_id, items.WPN_RAPIER,
        "shop path copies identified source item")
    harness.equal(price.minimum_plus, 25,
        "shop path preserves enchantment")
    harness.equal(ctx:draws_used(), 3,
        "shop offer avoids fallback item dice")
end

-- Place every committed entrance through production placement, then let
-- the real Trove owner create one saved gate from its source-position O.
-- The fixture supplies only generic context operations, not a second toll.
local function check_all_entrances()
    for _, path in ipairs(mod.paths("vaults/trove_entry", ".des")) do
        local source = require("policy.generation.vaults.des")
        local definition = source.parse(path, mod.read(path))
        local ctx, player = context(species.SP_HUMAN,
            gods.NO_GOD, {1})
        local sequence = 0
        local gates = {}
        local replacements = 0

        -- Placement seed handles are deterministic across all 14 entrances.
        function ctx:random_u64()
            sequence = sequence + 1
            return sequence, sequence * 17
        end

        -- Distinct gates reveal accidental duplicate source O records.
        function ctx:create()
            return #gates + 2
        end

        -- Capture the real schema name and saved witness for assertions.
        function ctx:add(_, kind, fields)
            gates[#gates + 1] = {
                kind = kind,
                fields = fields,
            }
        end

        -- Require a compare-and-replace on the authored empty marker price.
        function ctx:replace_record_string(_, _, _, source_id,
            kind, identity, key, expected, replacement)
            harness.equal(source_id, definition.id,
                "marker source identity")
            harness.equal(kind, "marker", "marker effect kind")
            harness.equal(identity, "trove:toll",
                "source gate identity")
            harness.equal(key, "price", "witness key")
            harness.equal(expected, "", "empty source price")
            harness.truthy(replacement ~= "", "filled source price")
            replacements = replacements + 1
        end

        local placed = placement.place(ctx, grid.new(ctx),
            definition, {
                branch_id = branches.BRANCH_DUNGEON,
                depth = 14,
                absolute_depth = 14,
                branch_bottom = 15,
                species_id = species.SP_HUMAN,
                started = true,
            })
        local markers = 0

        for index, record in ipairs(placed.records) do
            record.source_id = record.vault_id
            record.index = index

            if portal.is_marker(record) then
                portal.materialize(ctx, { id = 1 }, record)
                markers = markers + 1
            end
        end

        harness.equal(markers, 1, definition.id .. " source toll")
        harness.equal(#gates, 1, definition.id .. " ECS gate")
        harness.equal(replacements, 1,
            definition.id .. " marker witness update")
        harness.equal(gates[1].kind, component.WORLD_TROVE_PORTAL,
            definition.id .. " gate component")
        harness.truthy(gates[1].fields.price_witness ~= "",
            definition.id .. " saved price")
    end
end

-- A modded entrance with no source-position O, two O markers, or a
-- nonempty price must fail during population, before it can be saved.
local function check_malformed_entrance()
    local ctx = {}

    -- A live arch lets this fixture isolate marker cardinality and price.
    function ctx:cell()
        return terrain.DNGN_ENTER_TROVE
    end

    local level = {
        id = 1,
        vault_ids = { "enter_trove_1" },
        vault_records = {},
    }
    local okay = pcall(portal.validate_level, ctx, level)

    harness.falsy(okay, "missing Trove toll fails at placement")

    local marker = {
        kind = "marker",
        source_id = "enter_trove_1",
        identity = "trove:toll",
        x = 4,
        y = 4,
        arguments = {
            glyph = "O",
            price = "forged",
        },
    }

    level.vault_records = { marker, marker }
    harness.falsy(pcall(portal.validate_level, ctx, level),
        "duplicate Trove toll fails at placement")

    level.vault_records = { marker }
    harness.truthy(pcall(portal.validate_level, ctx, level),
        "one source marker reaches toll validation")
    harness.falsy(pcall(portal.materialize, ctx, level, marker),
        "malformed Trove price fails before rolling")
end

-- Run source-class and witness checks without constructing alternate
-- schemas or a parallel item catalog in the fixture.
function test.run()
    check_piety_exclusions()
    check_price_witness()
    check_shop_candidate()
    check_all_entrances()
    check_malformed_entrance()
end

return test
