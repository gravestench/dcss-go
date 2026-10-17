-- cloud.cc:CLOUD_MIASMA and beam.cc:miasma_monster.
local categories = require("constants.catalog")
local component = require("constants.component")
local attribution = require("constants.cloud_attribution")
local poison_sources = require("constants.poison_sources")
local streams = require("constants.rng_streams")
local capabilities = require("constants.mutation_capabilities")
local resistances = require("constants.resistance_ids")
local holiness = require("constants.monster_holiness")
local species_ids = require("ids.species")
local catalog = require("policy.catalog")
local effects = require("policy.mutations.effects.registry")
local player_resistance = require("policy.combat.player_resistance")
local statuses = require("policy.magic.effects.statuses.player")
local brands = require("policy.combat.brands")
local player_slow = require("policy.character.slow")
local monster_poison = require("policy.combat.monster_poison")
local monster_slow = require("policy.combat.monster_slow")

local miasma = {}

local exempt_holiness = {
    [holiness.HOLY] = true,
    [holiness.DEMONIC] = true,
    [holiness.UNDEAD] = true,
    [holiness.NONLIVING] = true,
}

local function player_immune(ctx, actor)
    if effects.sum(ctx, actor,
        capabilities.MIASMA_IMMUNITY) > 0 or
        statuses.death_door_active(ctx, actor) then
        return true
    end

    local identity = ctx:get(actor, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local form = ctx:get(actor, component.PLAYER_FORM)

    return identity.species_id == species_ids.SP_GARGOYLE or
        identity.species_id == species_ids.SP_DJINNI or
        species.undead_type == "US_UNDEAD" or
        form and (form.form_id == "lich" or
            form.form_id == "statue" or form.form_id == "storm")
end

local function monster_immune(definition)
    for _, resistance in ipairs(definition.resistances or {}) do
        if resistance.id == resistances.MIASMA and
            resistance.level > 0 then
            return true
        end
    end

    for _, kind in ipairs(definition.holiness or {}) do
        if exempt_holiness[kind] then
            return true
        end
    end

    return false
end

function miasma.immune(ctx, actor)
    if actor == ctx:player() then
        return player_immune(ctx, actor)
    end

    local state = ctx:get(actor, component.ACTOR)

    return state and
        monster_immune(catalog.get(categories.MONSTERS, state.kind_id)) or false
end

function miasma.afflict(ctx, actor, source, stream, player_credit)
    if miasma.immune(ctx, actor) then
        return 0
    end

    if actor == ctx:player() then
        if player_resistance.poison(ctx, actor) < 3 then
            local amount = 5

            for _ = 1, 3 do
                amount = amount + 1 + ctx:random(stream, 12)
            end

            brands.poison(ctx, amount, poison_sources.MIASMA)
        end

        if ctx:random(stream, 3) == 0 then
            player_slow.apply(ctx, actor,
                10 + ctx:random(stream, 5))
        end

        return 0
    end

    local monster = ctx:get(actor, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, monster.kind_id)

    monster_poison.apply(ctx, actor, definition, 1, source, false,
        player_credit)

    if ctx:random(stream, 3) == 0 then
        monster_slow.apply(ctx, actor, definition)
    end

    return 0
end

function miasma.apply(ctx, actor, state)
    local source

    if state.source_actor_id and state.source_actor_id > 0 then
        source = ctx:entity(state.source_actor_id)
    end

    return miasma.afflict(ctx, actor, source, streams.CLOUDS,
        state.kill_category == attribution.PLAYER)
end

function miasma.avoid()
    return true
end

return miasma
