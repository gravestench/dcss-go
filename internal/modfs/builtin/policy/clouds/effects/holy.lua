-- cloud.cc:CLOUD_HOLY and actor::res_holy_energy.
local categories = require("constants.catalog")
local elemental = require("policy.clouds.effects.elemental")
local component = require("constants.component")
local catalog = require("policy.catalog")
local holiness = require("constants.monster_holiness")
local species_ids = require("ids.species")
local monsters = require("ids.monsters")

local holy = {}

local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function player_vulnerable(ctx, actor)
    local identity = ctx:get(actor, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local form = ctx:get(actor, component.PLAYER_FORM)

    return identity.species_id == species_ids.SP_DEMONSPAWN or
        species.undead_type == "US_UNDEAD" or
        form and form.form_id == "lich"
end

function holy.immune(ctx, actor)
    if actor == ctx:player() then
        return false
    end

    local state = ctx:get(actor, component.ACTOR)

    if not state then
        return true
    end

    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    return state.kind_id == monsters.MONS_PROFANE_SERVITOR or
        has(definition.holiness, holiness.HOLY)
end

function holy.adjust(ctx, actor, amount)
    if actor == ctx:player() then
        if player_vulnerable(ctx, actor) then
            return math.floor(amount * 3 / 2)
        end

        return amount
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    if has(definition.holiness, holiness.UNDEAD) or
        has(definition.holiness, holiness.DEMONIC) then
        return math.floor(amount * 3 / 2)
    end

    return amount
end

holy.risk_adjust = holy.adjust

function holy.apply(ctx, actor, state, elapsed_aut, _, definition)
    return elemental.apply(ctx, actor, state, elapsed_aut,
        definition, nil, {
            immune = holy.immune,
            adjust = holy.adjust,
        })
end

return holy
