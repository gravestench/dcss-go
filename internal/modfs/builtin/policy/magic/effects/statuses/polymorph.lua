-- Source: monster.cc:can_polymorph and mon-poly.cc:init_poly_set,
-- monster_polymorph and change_monster_type.
local monsters = require("ids.monsters")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local catalog = require("policy.catalog")
local hit_points = require("policy.population.hit_points")
local range = require("policy.magic.range")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")
local monster_stats = require("policy.combat.monster_stats")
local streams = require("constants.rng_streams")
local power_modes = require("constants.polymorph_power")
local selection = require("policy.monsters.polymorph_selection")
local draconian_base = require("policy.monsters.draconian_base")

local polymorph = {}

-- Absent holiness and flag lists cannot grant a catalog trait.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Chaos Spawn is a special exception; abominations and unliving forms resist changing.
local function can_polymorph(definition)
    if definition.id == monsters.MONS_CHAOS_SPAWN then
        return true
    end

    if definition.id == monsters.MONS_ABOMINATION_SMALL or
        definition.id == monsters.MONS_ABOMINATION_LARGE then
        return false
    end

    return not has(definition.holiness, "MH_UNDEAD") and
        not has(definition.holiness, "MH_NONLIVING") and
        not has(definition.flags, "M_NO_POLY_TO")
end

-- Example: An entity without an ACTOR component fails the Polymorph eligibility check.
-- Resolve the live actor's catalog form before checking exclusions; callers may pass non-actors.
function polymorph.can_actor(ctx, target)
    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    return can_polymorph(catalog.get(categories.MONSTERS, actor.kind_id))
end

-- RANDOM_MONSTER checks its current cell rather than the persistent set's
-- old habitat. The optional actor lets standalone catalog tests ask the
-- question without manufacturing a permanent shifter component.
function polymorph.shifter_eligible(ctx, source, definition, position,
    monster, stream)
    return selection.eligible(ctx, monster, source, definition, position,
        stream)
end

-- Expose the production cell pool to source-style RNG fixtures.
function polymorph.shifter_pool(ctx, position)
    return selection.pool(ctx, position)
end

-- Polymorph drops carried gear because the new body cannot retain old equipment slots.
local function drop_inventory(ctx, monster, position)
    for _, item in ipairs(ctx:query({ component.ITEM, component.CARRIED_BY })) do
        local carrier = ctx:get(item, component.CARRIED_BY)

        if carrier.holder == monster then
            if ctx:has(item, component.EQUIPPED) then
                ctx:remove(item, component.EQUIPPED)
            end

            ctx:remove(item, component.CARRIED_BY)
            ctx:add(item, component.POSITION, {
                level_id = position.level_id,
                x = position.x,
                y = position.y,
            })
        end
    end
end

-- Preserve proportional HP with source randomisation, reset energy, and remember original kind.
local function transform(ctx, target, source, definition, stream)
    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)
    local position = ctx:get(target, component.POSITION)
    local marker = ctx:get(target, component.MONSTER_POLYMORPH)
    local original = marker and marker.original_kind_id or source.id
    local old_base = ctx:get(target, component.MONSTER_DRACONIAN_BASE)
    local corpse_kind = old_base and old_base.base_id or source.id
    local maximum = hit_points.roll(ctx, definition.average_hp_10x)
    local current = math.floor(maximum * health.current / health.max) +
        ctx:random(stream or streams.SPELL, maximum)

    actor.kind_id = definition.id
    actor.speed = definition.speed
    health.max = maximum
    health.current = math.max(1, math.min(maximum, current))
    ctx:set(target, component.ACTOR, actor)
    ctx:set(target, component.HEALTH, health)

    -- A new body gets its own fixed color; an ordinary borrowed form must
    -- not keep the previous draconian job's living base component.
    local new_base = draconian_base.for_job(definition.id)

    if old_base then
        ctx:remove(target, component.MONSTER_DRACONIAN_BASE)
    end

    if new_base then
        ctx:add(target, component.MONSTER_DRACONIAN_BASE, {
            base_id = new_base,
        })
    end

    -- Polymorph rolls a new body and maximum HP. Any meal or split history
    -- belonged to the old body; a new slime begins its own history when it
    -- next eats. Keeping the old marker would misvalidate the saved roll.
    if ctx:has(target, component.JIYVA_GROWTH) then
        ctx:remove(target, component.JIYVA_GROWTH)
    end

    -- A transformed body starts as one creature of its new species. Keep a
    -- split-birth marker for roster accounting, but discard the old blob
    -- multiplier before save and combat inspect the new form.
    if ctx:has(target, component.SLIME_BLOB) then
        ctx:remove(target, component.SLIME_BLOB)
    end

    -- An ugly thing's ghost profile is individual actor state. A new body
    -- rolls it once; a departed body cannot keep stale colour or attacks.
    local ugly_thing = require("policy.monsters.ugly_thing")
    local old_ugly = ctx:get(target, component.UGLY_THING)

    if ugly_thing.kind(definition.id) then
        local generated = ugly_thing.roll(ctx, definition, nil, nil,
            stream or streams.SPELL)

        if old_ugly then
            ctx:set(target, component.UGLY_THING, generated)
        else
            ctx:add(target, component.UGLY_THING, generated)
        end
    elseif old_ugly then
        ctx:remove(target, component.UGLY_THING)
    end

    local energy = ctx:get(target, component.MONSTER_ENERGY)

    if energy then
        energy.points = 67 + ctx:random("speed", 6)
        ctx:set(target, component.MONSTER_ENERGY, energy)
    end

    drop_inventory(ctx, target, position)

    if not marker then
        ctx:add(target, component.MONSTER_POLYMORPH, {
            original_kind_id = original,
            corpse_kind_id = corpse_kind,
        })
    end

    selection.replace(ctx, target, definition)

    ctx:emit(channels.SPELL, "The " .. source.name ..
        " evaporates and reforms as a " .. definition.name .. "!")
end

-- PPT_SAME favors similar hit dice, widening asymmetrically after misses.
local function shifter_power_fits(source_hd, target_hd, relax)
    return target_hd >= source_hd - relax and
        target_hd <= source_hd + math.floor(relax * 3 / 2)
end

-- Keep the actor transition shared with Polymorph, but draw source-style
-- shifter forms without the spell's three-form weighted shortlist.
function polymorph.random_shifter(ctx, target, source, stream)
    local position = ctx:get(target, component.POSITION)

    if not position then
        return false
    end

    local pool = selection.pool(ctx, position)

    if #pool == 0 then
        return false
    end

    local source_stream = stream or streams.MONSTER_SPELL
    local source_hd = monster_stats.hit_dice(ctx, target, source)
    local source_tier = selection.demon_tier(source)

    if source_tier == -1 then
        return false
    end

    local relax = 1

    for _ = 1, 1000 do
        local chosen = pool[ctx:random(source_stream, #pool) + 1]

        if ctx:random(source_stream, 200) == 0 then
            relax = relax + 1

            if relax > 50 then
                return false
            end
        end

        local target_tier = selection.demon_tier(chosen)

        if selection.eligible(ctx, target, source, chosen, position,
            source_stream) and
            (source_tier == target_tier or
                ctx:random(source_stream, 200) < relax) and
            shifter_power_fits(source_hd, chosen.hd, relax) then
            transform(ctx, target, source, chosen, source_stream)

            return true
        end
    end

    return false
end

-- PPT_LESS and PPT_MORE use different source power windows around the
-- current monster. Both relax after unsuccessful samples, while species
-- and habitat eligibility remain common to the body transition.
local function relative_power_fits(source_hd, target_hd, relax, stronger)
    if stronger then
        return target_hd >= source_hd + 2 - relax and
            target_hd <= source_hd + relax
    end

    return target_hd >= source_hd - math.floor(relax / 2) and
        target_hd <= source_hd - 3 +
            math.floor(relax * 3 / 2)
end

-- Sample the habitat-safe source species pool. A demon tier mismatch
-- remains rare until relaxation broadens, as in monster_polymorph.
local function relative(ctx, target, source, stream, stronger)
    if not can_polymorph(source) then
        return false
    end

    local position = ctx:get(target, component.POSITION)

    if not position then
        return false
    end

    local pool = selection.pool(ctx, position)

    if #pool == 0 then
        return false
    end

    local source_stream = stream or streams.SPELL
    local source_hd = monster_stats.hit_dice(ctx, target, source)
    local source_tier = selection.demon_tier(source)

    if source_tier == -1 then
        return false
    end

    local relax = 1

    for _ = 1, 1000 do
        local chosen = pool[ctx:random(source_stream, #pool) + 1]

        if ctx:random(source_stream, 200) == 0 then
            relax = relax + 1

            if relax > 50 then
                return false
            end
        end

        local target_tier = selection.demon_tier(chosen)

        if selection.eligible(ctx, target, source, chosen, position,
            source_stream) and
            (source_tier == target_tier or
                ctx:random(source_stream, 200) < relax) and
            relative_power_fits(source_hd, chosen.hd, relax,
                stronger) then
            transform(ctx, target, source, chosen, source_stream)

            return true
        end
    end

    return false
end

-- The source has a separate target picker for relative-power requests but
-- every accepted pick still changes the body through the common transition.
local function ordinary(ctx, target, source, stream, mode)
    if mode == power_modes.LESS then
        return relative(ctx, target, source, stream, false)
    end

    if mode == power_modes.MORE then
        return relative(ctx, target, source, stream, true)
    end

    local position = ctx:get(target, component.POSITION)

    if not position then
        return false
    end

    local definition = selection.pick(ctx, target, stream)

    if not definition or not selection.eligible(ctx, target, source,
        definition, position, stream) then
        return false
    end

    transform(ctx, target, source, definition, stream)

    return true
end

-- Source monster::polymorph handles special bodies before asking a power
-- picker for another species. Recursive slime calls act on the new ECS child
-- separately; each child retains its own rolled form and saved birth origin.
function polymorph.monster(ctx, target, source, stream, mode)
    local source_stream = stream or streams.SPELL
    local source_mode = mode or power_modes.SAME
    local ugly_thing = require("policy.monsters.ugly_thing")

    if ugly_thing.kind(source.id) then
        ugly_thing.force_mutate(ctx, target, source, source_stream)

        return true
    end

    local shifter = ctx:get(target, component.MONSTER_SHAPESHIFTER)

    if shifter then
        local variant = catalog.get(categories.MONSTERS,
            shifter.variant_id)
        local position = ctx:get(target, component.POSITION)

        -- Fixed reversion still runs source _valid_morph. A base-form
        -- shifter or a borrowed flyer above unsafe water cannot revert.
        if not position or not selection.eligible(ctx, target, source,
            variant, position, source_stream) then
            return false
        end

        transform(ctx, target, source, variant, source_stream)

        return true
    end

    if source.id == monsters.MONS_SLIME_CREATURE then
        -- The source always chooses slime destinations from its same-power
        -- polymorph set, even when the caller requested LESS or MORE.
        source_mode = power_modes.SAME
        local blob = ctx:get(target, component.SLIME_BLOB)

        if blob and blob.size > 1 and
            ctx:random(source_stream, 5) < 4 then
            local slime = require("policy.monsters.slime_lifecycle")

            for _ = 1, 11 do
                local child = slime.force_split(ctx, target)

                if not child then
                    break
                end

                polymorph.monster(ctx, child, source, source_stream,
                    source_mode)
            end
        end
    end

    return ordinary(ctx, target, source, source_stream, source_mode)
end

-- Degen and Xom's helpful transformation ask for a weaker body.
function polymorph.less(ctx, target, source, stream)
    return polymorph.monster(ctx, target, source, stream,
        power_modes.LESS)
end

-- Xom's harmful transformation asks for a stronger body; special species
-- routing still applies before the relative-power picker runs.
function polymorph.more(ctx, target, source, stream)
    return polymorph.monster(ctx, target, source, stream,
        power_modes.MORE)
end

-- Only visible living actors along clear in-range rays make the spell usable.
local function can_target(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and position.level_id == origin.level_id and
                distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    position.x, position.y) then
                return true
            end
        end
    end

    return false
end

-- Expose the shared target search to the cast registry before MP is spent.
function polymorph.can_target(ctx, player, spell)
    return can_target(ctx, player, spell)
end

-- The first ray contact rolls will and then chooses among habitat-safe forms.
function polymorph.cast(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit(channels.SPELL, "The mutagenic magic dissipates.")
        return
    end

    local target = contact.actor
    local actor = ctx:get(target, component.ACTOR)
    local source = catalog.get(categories.MONSTERS, actor.kind_id)

    if not can_polymorph(source) then
        ctx:emit(channels.SPELL, "The " .. source.name ..
            " is unaffected.")
        return
    end

    if will.resists(ctx, source, power,
        target, nil, player) then
        ctx:emit(channels.SPELL, "The " .. source.name ..
            " resists polymorph.")
        return
    end

    if not polymorph.monster(ctx, target, source, streams.SPELL,
        power_modes.SAME) then
        ctx:emit(channels.SPELL, "The " .. source.name .. " shudders.")
    end
end

-- Chaos melee uses the same legal forms and saved transformation as the
-- spell, but spends its own combat RNG stream.
function polymorph.chaos(ctx, target, source, power, attacker)
    if not can_polymorph(source) or
        will.resists(ctx, source, math.max(1, power),
            target, nil, attacker) then
        return false
    end

    return polymorph.monster(ctx, target, source, streams.MELEE,
        power_modes.SAME)
end

-- The shifter chaos effect transforms immediately without an enchantment
-- resistance check; later shape changes use this same actor transition.
function polymorph.shapeshift(ctx, target, source, stream)
    return polymorph.monster(ctx, target, source,
        stream or streams.MELEE, power_modes.SAME)
end

-- Porkalator selects its fixed holiness-matched hog rather than a weighted
-- polymorph candidate; keep the same HP, inventory, and original-kind transition.
function polymorph.fixed(ctx, target, definition, stream)
    local actor = ctx:get(target, component.ACTOR)
    local source = catalog.get(categories.MONSTERS, actor.kind_id)

    transform(ctx, target, source, definition,
        stream or streams.MONSTER_SPELL)
end

return polymorph
