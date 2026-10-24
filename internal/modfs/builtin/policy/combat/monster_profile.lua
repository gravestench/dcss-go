-- Most monsters use immutable catalog definitions. Generated lords, ugly
-- things, constructs, and player illusions overlay saved per-actor traits
-- before combat reads the same effective definition shape.
local component = require("constants.component")
local monster_flags = require("constants.monster_flags")

local constructs = require("constants.monster_construct_components")

local resistance = require("policy.combat.monster_summons.resistance")
local ugly_thing = require("policy.monsters.ugly_thing")
local beast_profile = require("policy.monsters.mutant_beast.profile")

local profile = {}

-- Overlay an ugly actor's mutable source traits without changing the
-- shared catalog row. Elemental damage and terminal display both consume
-- this same projected view.
local function project_ugly(definition, ugly)
    local generated = {}

    for key, value in pairs(definition) do
        generated[key] = value
    end

    generated.name = ugly_thing.name(ugly, definition.name)
    generated.colour_id = ugly.colour_id
    generated.attacks = {
        {
            type_id = ugly.attack_type_id,
            flavour_id = ugly.flavour_id,
            damage = ugly.damage,
        },
    }
    generated.resistances = {}

    for _, entry in ipairs(definition.resistances or {}) do
        generated.resistances[#generated.resistances + 1] = entry
    end

    local ids = {}

    for id in pairs(ugly.resistances) do
        ids[#ids + 1] = id
    end

    table.sort(ids)

    for _, id in ipairs(ids) do
        generated.resistances[#generated.resistances + 1] = {
            id = id,
            level = ugly.resistances[id],
        }
    end

    return generated
end

-- Project saved per-actor values into the same read shape as a catalog
-- monster. Consumers use their ordinary combat rules after this one read.
function profile.definition(ctx, entity, definition)
    local beast = ctx:get(entity, component.MONSTER_MUTANT_BEAST)

    if beast then
        definition = beast_profile.project(definition, beast)
    end

    local ugly = ctx:get(entity, component.UGLY_THING)

    if ugly then
        definition = project_ugly(definition, ugly)
    end

    local lord = ctx:get(entity, component.PANDEMONIUM_LORD)

    if lord then
        local generated = {}

        for key, value in pairs(definition) do
            generated[key] = value
        end

        if lord.name ~= "" then
            generated.name = lord.name
        end

        if lord.colour_id ~= "" then
            generated.colour_id = lord.colour_id
        end

        generated.speed = lord.speed
        generated.ac = lord.ac
        generated.ev = lord.ev
        generated.flags = {}

        for _, flag in ipairs(definition.flags or {}) do
            generated.flags[#generated.flags + 1] = flag
        end

        if lord.flies then
            generated.flags[#generated.flags + 1] = monster_flags.FLIES
        end

        generated.resistances = {}

        for _, resistance in ipairs(definition.resistances or {}) do
            generated.resistances[#generated.resistances + 1] = resistance
        end

        local resistance_ids = {}

        for id in pairs(lord.resistances) do
            resistance_ids[#resistance_ids + 1] = id
        end

        table.sort(resistance_ids)

        for _, id in ipairs(resistance_ids) do
            generated.resistances[#generated.resistances + 1] = {
                id = id,
                level = lord.resistances[id],
            }
        end

        generated.attacks = {
            {
                type_id = lord.attack_type_id,
                flavour_id = lord.flavour_id,
                damage = lord.damage,
            },
        }

        definition = generated
    end

    local ghost = ctx:get(entity, component.PLAYER_ILLUSION)

    local weapon = ctx:get(entity, constructs.DANCING_WEAPON)

    if weapon then
        local result = {}

        for key, value in pairs(definition) do
            result[key] = value
        end

        result.speed = weapon.speed
        result.ac = weapon.ac
        result.ev = weapon.ev
        result.attacks = {
            {
                type_id = "AT_HIT",
                flavour_id = "AF_PLAIN",
                damage = weapon.damage,
            },
        }

        definition = result
    end

    if not ghost then
        return resistance.project(ctx, entity, definition)
    end

    local result = {}

    for key, value in pairs(definition) do
        result[key] = value
    end

    result.name = ghost.name .. "'s illusion"
    result.ac = ghost.ac
    result.ev = ghost.ev
    result.holiness = { ghost.holiness_id }
    result.attacks = {
        {
            type_id = "AT_HIT",
            flavour_id = "AF_PLAIN",
            damage = ghost.damage,
        },
    }

    local ids = {}

    for id in pairs(ghost.resistances) do
        ids[#ids + 1] = id
    end

    table.sort(ids)

    result.resistances = {}

    for _, id in ipairs(ids) do
        result.resistances[#result.resistances + 1] = {
            id = id,
            level = ghost.resistances[id],
        }
    end

    -- Ghost traits replace the catalog profile before timed resistance is
    -- projected, so the shared resistance owner retains the correct base.
    return resistance.project(ctx, entity, result)
end

return profile
