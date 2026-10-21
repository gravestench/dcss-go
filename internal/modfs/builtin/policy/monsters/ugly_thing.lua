-- Theory of operation: an ugly thing is one mutable actor, not six catalog
-- species. Spawn rolls a contact type and colour; the colour determines its
-- attack flavour and intrinsic resistance. A successful mutation replaces
-- that profile while leaving HP and HD untouched. Combat, display,
-- and save validation all read the same component.
-- Source: ghost.cc:ghost_demon::init_ugly_thing and
-- ghost_demon::ugly_thing_to_very_ugly_thing.
local attacks = require("constants.monster_attack_types")
local colours = require("constants.ugly_thing_colours")
local component = require("constants.component")
local behaviors = require("constants.ai_behaviors")
local monsters = require("ids.monsters")
local channels = require("constants.message_channels")
local contamination_ids = require("policy.magic.effects.zaps.ids")
local senses = require("policy.character.senses")
local resistance = require("constants.resistance_ids")
local streams = require("constants.rng_streams")

local ugly = {}

-- Source attack types are deliberately limited to these twelve contacts.
-- A colour chooses the effect separately, so mutation can change both.
local attack_types = {
    attacks.BITE,
    attacks.STING,
    attacks.ENGULF,
    attacks.CLAW,
    attacks.PECK,
    attacks.HEADBUTT,
    attacks.PUNCH,
    attacks.KICK,
    attacks.TENTACLE_SLAP,
    attacks.TAIL_SLAP,
    attacks.GORE,
    attacks.TRUNK_SLAP,
}

-- A modded vault may spell a forced colour as its human adjective or as
-- a terminal colour. Both forms select the same source body archetype.
local function colour_index(forced)
    if not forced or forced == "" or forced == "any" then
        return nil
    end

    local wanted = forced:upper()

    for index, row in ipairs(colours) do
        if row.name == forced:lower() or row.low == wanted or
            row.high == wanted then
            return index
        end
    end

    error("unknown ugly thing colour " .. tostring(forced))
end

-- The source retries its six-colour draw until it differs from the old
-- colour. Drawing once from the other five has the same distribution and
-- also terminates for a deterministic mod RNG that always returns zero.
local function choose_colour(ctx, stream, forced, previous)
    local wanted = colour_index(forced)

    if wanted then
        return wanted
    end

    if not previous then
        return 1 + ctx:random(stream, #colours)
    end

    local old = colour_index(previous)
    local chosen = 1 + ctx:random(stream, #colours - 1)

    if chosen >= old then
        chosen = chosen + 1
    end

    return chosen
end

-- A bright very ugly thing keeps its ordinary colour's attack family.
-- Fire and poison upgrade to sticky flame and strong poison respectively;
-- acid stays at one resistance level, unlike the other four elements.
local function profile(definition, attack_type, row, very)
    local resistances = {}

    if row.resistance then
        local level = very and row.resistance ~= resistance.ACID and
            2 or 1
        resistances[row.resistance] = level
    end

    if row.sticky_immune then
        resistances[resistance.STICKY_FLAME] = 1
    end

    local damage = definition.attacks[1].damage

    if row.magenta_damage then
        damage = math.floor(damage * 4 / 3)
    end

    return {
        colour_id = very and row.high or row.low,
        adjective = row.name,
        attack_type_id = attack_type,
        flavour_id = very and row.very_flavour or row.flavour,
        damage = damage,
        resistances = resistances,
    }
end

-- Roll once at spawn or once per mutation. The caller chooses the stream;
-- the saved component, rather than a later redraw, owns the result.
function ugly.roll(ctx, definition, forced, previous, stream)
    if not ugly.kind(definition.id) then
        error("cannot roll ugly traits for " .. definition.id)
    end

    stream = stream or streams.MONSTER_TRAITS

    local attack_type = attack_types[1 + ctx:random(stream,
        #attack_types)]
    local index = choose_colour(ctx, stream, forced, previous)
    local very = definition.id == monsters.MONS_VERY_UGLY_THING

    return profile(definition, attack_type, colours[index], very)
end

-- Only the two source species own this component. Genus checks alone
-- would accidentally attach it to a polymorphed or derived monster.
function ugly.kind(kind_id)
    return kind_id == monsters.MONS_UGLY_THING or
        kind_id == monsters.MONS_VERY_UGLY_THING
end

-- Replace only the mutable profile once a source effect has passed its
-- chance and adjacency checks. HP and HD belong to other actor owners.
function ugly.mutate(ctx, entity, definition, forced, stream)
    local current = ctx:get(entity, component.UGLY_THING)

    if not current or not ugly.kind(definition.id) then
        return false
    end

    local next = ugly.roll(ctx, definition, forced,
        current.adjective, stream)

    ctx:set(entity, component.UGLY_THING, next)

    return true
end

-- Search only neighboring occupied cells. A different-coloured kin forces
-- its colour; same-coloured kin or a contaminated player allows a fresh
-- draw. The caller makes the source one-in-nine chance before this scan.
local function nearby_source(ctx, position, state)
    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local neighbor = ctx:actor_at(position.level_id,
                    position.x + dx, position.y + dy)

                if neighbor then
                    local kin = ctx:get(neighbor, component.UGLY_THING)

                    if kin then
                        if kin.adjective ~= state.adjective then
                            return kin.adjective,
                                "the mutagenic energy from its kin"
                        end

                        return nil, "the mutagenic energy from its kin"
                    end

                    if neighbor == ctx:player() then
                        local glow = ctx:get(neighbor,
                            contamination_ids.component.CONTAMINATION)

                        if glow and glow.amount > 0 then
                            return nil, "your mutagenic energy"
                        end
                    end
                end
            end
        end
    end
end

-- Legacy Malmutate and Polymorph both call this same gated routine and
-- report success even if it finds no source. Natural ability use also calls
-- it, after the active-turn eligibility check below.
function ugly.try_mutate(ctx, entity, definition, stream)
    stream = stream or streams.MONSTER_TRAITS

    if ctx:random(stream, 9) ~= 0 then
        return false
    end

    local state = ctx:get(entity, component.UGLY_THING)
    local position = ctx:get(entity, component.POSITION)

    if not state or not position then
        return false
    end

    local forced, cause = nearby_source(ctx, position, state)

    if not cause then
        return false
    end

    ugly.mutate(ctx, entity, definition, forced, stream)

    if senses.player_sees_actor(ctx, entity) then
        ctx:emit(channels.MONSTER, "The " ..
            ugly.name(state, definition.name) ..
            " basks in " .. cause .. " and changes!")
    end

    return true
end

-- Source mon-abil.cc offers the gated mutation as an awake monster ability
-- only while an enemy is near. Malmutate calls try_mutate without these
-- turn-specific restrictions.
function ugly.tick(ctx, entity)
    local state = ctx:get(entity, component.UGLY_THING)
    local actor = ctx:get(entity, component.ACTOR)
    local position = ctx:get(entity, component.POSITION)
    local health = ctx:get(entity, component.HEALTH)
    local ai = ctx:get(entity, component.AI)
    local stasis = ctx:get(entity, component.MONSTER_STASIS)

    if not state or not actor or not position or not health or
        health.current <= 0 or not ai or
        ai.behavior == behaviors.SLEEP or
        ctx:has(entity, component.PARALYSIS) or
        stasis and (stasis.hibernating or stasis.petrifying_aut > 0 or
            stasis.petrified_aut > 0) then
        return false
    end

    -- Target policy imports combat presentation, which also uses this
    -- profile's name. Resolve it only when a live actor takes a turn.
    local targets = require("policy.ai.targets")

    if not targets.nearest(ctx, entity, position, 7) then
        return false
    end

    local definition = require("policy.catalog").get("monsters",
        actor.kind_id)

    return ugly.try_mutate(ctx, entity, definition,
        streams.MONSTER_TRAITS)
end

-- The actor's source colour adjective is part of its visible species name.
function ugly.name(state, ordinary_name)
    return state.adjective .. " " .. ordinary_name
end

-- Save restore rejects a component detached from its species or a forged
-- combination such as a cold red body with a poison resistance.
function ugly.validate(ctx, entity, definition)
    local state = ctx:get(entity, component.UGLY_THING)

    if not state then
        if ugly.kind(definition.id) then
            error("ugly thing " .. ctx:id(entity) .. " has no saved traits")
        end

        return
    end

    if not ugly.kind(definition.id) then
        error("non-ugly monster " .. ctx:id(entity) ..
            " has ugly thing traits")
    end

    local row
    local very = definition.id == monsters.MONS_VERY_UGLY_THING

    for _, candidate in ipairs(colours) do
        if state.colour_id == (very and candidate.high or
            candidate.low) then
            row = candidate
            break
        end
    end

    local legal_attack = false

    for _, attack_type in ipairs(attack_types) do
        if state.attack_type_id == attack_type then
            legal_attack = true
            break
        end
    end

    if not row or not legal_attack then
        error("ugly thing " .. ctx:id(entity) ..
            " has invalid colour or attack")
    end

    local expected = profile(definition, state.attack_type_id, row,
        very)

    if state.adjective ~= expected.adjective or
        state.flavour_id ~= expected.flavour_id or
        state.damage ~= expected.damage then
        error("ugly thing " .. ctx:id(entity) ..
            " has mismatched attack traits")
    end

    for id, level in pairs(expected.resistances) do
        if state.resistances[id] ~= level then
            error("ugly thing " .. ctx:id(entity) ..
                " has mismatched resistance")
        end
    end

    for id in pairs(state.resistances) do
        if expected.resistances[id] == nil then
            error("ugly thing " .. ctx:id(entity) ..
                " has extra resistance")
        end
    end
end

return ugly
