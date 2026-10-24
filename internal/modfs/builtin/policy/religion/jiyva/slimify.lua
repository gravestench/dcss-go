-- Theory of operation: the charged player intercepts one successful
-- primary melee hit before damage, brands, or auxiliary attacks. The
-- target keeps its ECS identity while the shared polymorph owner gives it
-- a slime body; a saved Jiyva allegiance then changes its real side.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local habitats = require("constants.monster_habitats")
local holiness = require("constants.monster_holiness")
local identity = require("policy.religion.jiyva.identity")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local powers = require("policy.religion.jiyva.powers")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local slimify = {}

-- Tentacle segments are independent ECS actors but the source treats
-- them as limbs of a larger creature, never valid conversion victims.
local tentacles = {
    [monsters.MONS_KRAKEN_TENTACLE] = true,
    [monsters.MONS_KRAKEN_TENTACLE_SEGMENT] = true,
    [monsters.MONS_ELDRITCH_TENTACLE] = true,
    [monsters.MONS_ELDRITCH_TENTACLE_SEGMENT] = true,
    [monsters.MONS_STARSPAWN_TENTACLE] = true,
    [monsters.MONS_STARSPAWN_TENTACLE_SEGMENT] = true,
    [monsters.MONS_MNOLEG_TENTACLE] = true,
    [monsters.MONS_MNOLEG_TENTACLE_SEGMENT] = true,
}

-- Catalog lists carry the source holiness and substance flags. Only a
-- natural or undead, substantial non-slime body can be slimified.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- A hit against an ineligible monster leaves the charge in place.
function slimify.eligible(ctx, target)
    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS,
        actor.kind_id)

    return not tentacles[definition.id] and
        not has(definition.flags, flags.INSUBSTANTIAL) and
        not identity.slime(definition) and
        (has(definition.holiness, holiness.NATURAL) or
            has(definition.holiness, holiness.UNDEAD))
end

-- Source HD plus a signed zero-to-four variation chooses the slime body.
-- Water restricts the form to the amphibious jelly and slime creature.
local function form(ctx, target, source)
    local hd = monster_stats.hit_dice(ctx, target, source)
    local sign = ctx:random(streams.RELIGION, 2) == 0 and 1 or -1
    local score = hd + sign * ctx:random(streams.RELIGION, 5)
    local position = ctx:get(target, component.POSITION)
    local feature = ctx:cell(position.level_id,
        position.x, position.y)
    local water = feature == terrain.DNGN_SHALLOW_WATER or
        feature == terrain.DNGN_DEEP_WATER or
        feature == terrain.DNGN_OPEN_SEA
    local kind

    if water then
        kind = score < 7 and monsters.MONS_JELLY or
            monsters.MONS_SLIME_CREATURE
    elseif score < 3 then
        kind = monsters.MONS_ENDOPLASM
    elseif score < 5 then
        kind = monsters.MONS_JELLY
    elseif score <= 11 then
        kind = monsters.MONS_SLIME_CREATURE
    elseif ctx:random(streams.RELIGION, 2) == 0 then
        kind = monsters.MONS_ACID_BLOB
    else
        kind = monsters.MONS_AZURE_JELLY
    end

    return catalog.get(categories.MONSTERS, kind), feature
end

-- The source consumes the charge even when a slime cannot live on the
-- victim's current terrain. This aborts the normal damage path as well.
function slimify.contact(ctx, target, cleave_secondary)
    local player = ctx:player()

    if cleave_secondary or not powers.slimify_active(ctx, player) or
        not slimify.eligible(ctx, target) then
        return false
    end

    local actor = ctx:get(target, component.ACTOR)
    local source = catalog.get(categories.MONSTERS, actor.kind_id)
    local chosen, feature = form(ctx, target, source)

    powers.consume_slimify(ctx, player)

    if feature == terrain.DNGN_LAVA or
        feature == terrain.DNGN_DEEP_WATER and
            chosen.habitat_id ~= habitats.AMPHIBIOUS and
            chosen.habitat_id ~= habitats.WATER then
        ctx:emit(channels.MONSTER,
            "The " .. source.name .. " quivers momentarily.")

        return true
    end

    polymorph.fixed(ctx, target, chosen, streams.RELIGION)
    local allegiance = {
        attitude = attitudes.GOOD_NEUTRAL,
        attempted = true,
    }

    if ctx:has(target, component.JIYVA_SLIME) then
        ctx:set(target, component.JIYVA_SLIME, allegiance)
    else
        ctx:add(target, component.JIYVA_SLIME, allegiance)
    end

    return true
end

return slimify
