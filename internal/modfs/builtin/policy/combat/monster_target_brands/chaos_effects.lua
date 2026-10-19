-- Source: attack.cc. Chaos selected as its own brand chooses one
-- eligible monster effect by weight, then applies that effect to the actor.
local component = require("constants.component")
local effect_ids = require("constants.chaos_effects")
local attack_types = require("constants.monster_attack_types")
local flags = require("constants.monster_flags")
local holiness = require("constants.monster_holiness")
local resistances = require("constants.resistance_ids")
local status = require("policy.combat.monster_target_brands.chaos_status")
local slow = require("policy.combat.monster_slow")
local clone_inventory = require("policy.combat.clone_inventory")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local roll = require("policy.combat.roll")

local effects = {}

-- Eligibility is evaluated against the struck monster before weighted
-- selection. Unique, summoned, stationary and resistant targets therefore
-- alter the candidate pool instead of receiving an impossible effect.

-- Read catalog holiness and flags before building the valid chaos effect pool.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Chaos eligibility needs the catalogued level; absent resistance entries mean no protection.
local function resistance(definition, wanted)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == wanted then
            return entry.level
        end
    end

    return 0
end

-- Stationary no-threat monsters lack useful behaviour for a chaos transformation.
local function firewood(hit)
    return has(hit.definition.flags, flags.STATIONARY) and
        has(hit.definition.flags, flags.NO_THREAT)
end

-- Movement effects cannot matter on stationary defenders, so remove them before the weighted draw.
local function slowable(_, hit)
    return not has(hit.definition.flags, flags.STATIONARY)
end

-- Unliving and effectively unhexable targets cannot receive a meaningful polymorph result.
local function polyable(_, hit)
    return not firewood(hit) and
        not has(hit.definition.holiness, holiness.UNDEAD) and
        not has(hit.definition.holiness, holiness.NONLIVING) and
        (hit.definition.willpower or 0) < 5000
end

-- Cloning unique monsters or summon constructs would duplicate special lifecycle state.
local function cloneable(ctx, hit)
    return not has(hit.definition.flags, flags.UNIQUE) and
        not ctx:has(hit.defender, component.SUMMON_CONSTRUCT) and
        not ctx:has(hit.defender, component.SUMMON_SEGMENT) and
        not ctx:has(hit.defender, component.SPECTRAL_WEAPON)
end

-- A chaos shifter needs a natural form and must not already be shifting.
local function shifter(ctx, hit)
    return polyable(ctx, hit) and
        has(hit.definition.holiness, holiness.NATURAL) and
        not status.shifter_active(ctx, hit.defender)
end

-- Rage requires an actual melee attack and excludes states that cannot act or already frenzy.
local function rageable(ctx, hit)
    local attack = hit.definition.attacks and hit.definition.attacks[1]
    local kind = hit.definition.holiness
    local berserkable = has(kind, holiness.NATURAL) or
        has(kind, holiness.DEMONIC) or has(kind, holiness.HOLY)
    local allegiance = ctx:get(hit.defender, component.MONSTER_ALLEGIANCE)
    local stasis = ctx:get(hit.defender, component.MONSTER_STASIS)

    return berserkable and attack and attack.damage > 0 and
        attack.type_id ~= attack_types.NONE and
        not ctx:has(hit.defender, component.PARALYSIS) and
        (not allegiance or allegiance.frenzy_aut == 0 and
            allegiance.fatigue_aut == 0) and
        (not stasis or stasis.petrifying_aut == 0 and
            stasis.petrified_aut == 0)
end

-- Petrification needs a mobile target without innate stone resistance.
local function petrifiable(ctx, hit)
    return slowable(ctx, hit) and
        resistance(hit.definition, resistances.PETRIFY) <= 0
end

-- Reservoir sampling picks each vacant adjacent cell equally without allocating a candidate list.
local function free_cell(ctx, position)
    local seen = 0
    local selected

    for y = position.y - 1, position.y + 1 do
        for x = position.x - 1, position.x + 1 do
            if (x ~= position.x or y ~= position.y) and
                ctx:walkable(position.level_id, x, y) and
                not ctx:actor_at(position.level_id, x, y) then
                seen = seen + 1

                if roll.melee(ctx, seen) == 0 then
                    selected = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    return selected
end

-- Clone only after a legal destination exists; preserve HP, summon state, and original roster identity.
local function clone(ctx, hit)
    local position = ctx:get(hit.defender, component.POSITION)
    local destination = position and free_cell(ctx, position)

    if not destination then
        return
    end

    local source = ctx:get(hit.defender, component.ACTOR)
    local health = ctx:get(hit.defender, component.HEALTH)
    local twin = ctx:create()

    ctx:add(twin, component.ACTOR, {
        kind_id = source.kind_id,
        speed = source.speed,
    })
    ctx:add(twin, component.MONSTER_ENERGY, { points = 70 })
    ctx:add(twin, component.HEALTH, {
        current = health.current,
        max = health.max,
    })
    ctx:add(twin, component.COMBAT, { shield_blocks = 0 })
    ctx:add(twin, component.AI, { behavior = "wander" })

    local slow_state = ctx:get(hit.defender, component.PROJECTILE_SLOW)

    if slow_state then
        ctx:add(twin, component.PROJECTILE_SLOW, slow_state)
    end

    local summon = ctx:get(hit.defender, component.SUMMON)

    if summon then
        ctx:add(twin, component.SUMMON, summon)

        local summon_stats = ctx:get(hit.defender, component.SUMMON_STATS)

        if summon_stats then
            ctx:add(twin, component.SUMMON_STATS, summon_stats)
        end

        -- A mirrored summon keeps its original kind and recursion guard
        -- when Chaos makes another physical copy of that summon.
        local mirror = ctx:get(hit.defender, component.SUMMON_MIRROR)

        if mirror then
            ctx:add(twin, component.SUMMON_MIRROR, mirror)

            local polymorph = ctx:get(hit.defender,
                component.MONSTER_POLYMORPH)

            if polymorph then
                ctx:add(twin, component.MONSTER_POLYMORPH, polymorph)
            end
        end
    end

    local old_form = ctx:get(hit.defender, component.MONSTER_POLYMORPH)

    ctx:add(twin, component.CHAOS_CLONE, {
        roster_kind_id = old_form and old_form.original_kind_id or
            source.kind_id,
        created_aut = ctx:aut(),
    })
    clone_inventory.copy(ctx, hit.defender, twin)
    ctx:place_actor(twin, position.level_id,
        destination.x, destination.y)
    ctx:emit("combat", "The " .. hit.definition.name .. " splits in two!")
end

-- Damage already dealt is passed to polymorph so its chaos strength follows the triggering hit.
local function transform(ctx, hit)
    polymorph.chaos(ctx, hit.defender, hit.definition,
        hit.damage_done)
end

-- Mark the monster before reshaping it so later turns continue the shifter behaviour.
local function make_shifter(ctx, hit)
    status.make_shifter(ctx, hit.defender)
    polymorph.shapeshift(ctx, hit.defender, hit.definition)
end

-- Extend frenzy to at least 120 aut without shortening a longer existing frenzy.
local function rage(ctx, hit)
    local value = ctx:get(hit.defender, component.MONSTER_ALLEGIANCE) or {
        charm_aut = 0,
        frenzy_aut = 0,
        fatigue_aut = 0,
    }

    value.frenzy_aut = math.max(value.frenzy_aut, 120)

    if ctx:has(hit.defender, component.MONSTER_ALLEGIANCE) then
        ctx:set(hit.defender, component.MONSTER_ALLEGIANCE, value)
    else
        ctx:add(hit.defender, component.MONSTER_ALLEGIANCE, value)
    end

    ctx:emit("combat", "The " .. hit.definition.name ..
        " flies into a frenzy!")
end

-- Chaos Haste uses the shared enchantment duration rather than another speed state.
local function haste(ctx, hit)
    status.apply(ctx, hit.defender, effect_ids.HASTE, 100)
    ctx:emit("combat", "The " .. hit.definition.name .. " speeds up!")
end

-- Shared chaos status storage keeps Might's expiry consistent with other temporary boons.
local function might(ctx, hit)
    status.apply(ctx, hit.defender, effect_ids.MIGHT, 100)
    ctx:emit("combat", "The " .. hit.definition.name .. " grows stronger!")
end

-- Shared chaos status storage keeps Agility's expiry consistent with other temporary boons.
local function agility(ctx, hit)
    status.apply(ctx, hit.defender, effect_ids.AGILITY, 100)
    ctx:emit("combat", "The " .. hit.definition.name .. " becomes agile!")
end

-- Retain any longer invisibility duration and preserve other monster enchantments.
local function invisible(ctx, hit)
    local value = ctx:get(hit.defender, component.MONSTER_ENCHANT) or {
        blind_aut = 0,
        corrosion_aut = 0,
        invisible_aut = 0,
    }

    value.invisible_aut = math.max(value.invisible_aut, 100)

    if ctx:has(hit.defender, component.MONSTER_ENCHANT) then
        ctx:set(hit.defender, component.MONSTER_ENCHANT, value)
    else
        ctx:add(hit.defender, component.MONSTER_ENCHANT, value)
    end

    ctx:emit("combat", "The " .. hit.definition.name ..
        " vanishes from sight!")
end

-- An existing paralysis may be longer; Chaos must not shorten it to 50 aut.
local function paralyze(ctx, hit)
    local value = ctx:get(hit.defender, component.PARALYSIS)

    if value then
        value.remaining_aut = math.max(value.remaining_aut, 50)
        ctx:set(hit.defender, component.PARALYSIS, value)
    else
        ctx:add(hit.defender, component.PARALYSIS, {
            remaining_aut = 50,
        })
    end

    ctx:emit("combat", "The " .. hit.definition.name ..
        " suddenly stops moving!")
end

-- Advance an existing stasis record without losing sleep or petrification progress.
local function petrify(ctx, hit)
    local value = ctx:get(hit.defender, component.MONSTER_STASIS) or {
        hibernating = false,
        sleep_wary_aut = 0,
        petrifying_aut = 0,
        petrified_aut = 0,
    }

    value.petrifying_aut = math.max(value.petrifying_aut, 50)

    if ctx:has(hit.defender, component.MONSTER_STASIS) then
        ctx:set(hit.defender, component.MONSTER_STASIS, value)
    else
        ctx:add(hit.defender, component.MONSTER_STASIS, value)
    end

    ctx:emit("combat", "The " .. hit.definition.name ..
        " begins to turn to stone!")
end

-- Use the monster slow policy so resistance and duration match other slow sources.
local function slow_monster(ctx, hit)
    slow.apply(ctx, hit.defender, hit.definition)
end

local choices = {
    {
        name = effect_ids.CLONE,
        weight = 1,
        valid = cloneable,
        apply = clone,
    },

    {
        name = effect_ids.POLYMORPH,
        weight = 2,
        valid = polyable,
        apply = transform,
    },

    {
        name = effect_ids.SHIFTER,
        weight = 1,
        valid = shifter,
        apply = make_shifter,
    },

    {
        name = effect_ids.RAGE,
        weight = 5,
        valid = rageable,
        apply = rage,
    },

    {
        name = effect_ids.HASTE,
        weight = 10,
        valid = slowable,
        apply = haste,
    },

    {
        name = effect_ids.MIGHT,
        weight = 10,
        apply = might,
    },

    {
        name = effect_ids.AGILITY,
        weight = 10,
        apply = agility,
    },

    {
        name = effect_ids.INVISIBLE,
        weight = 10,
        apply = invisible,
    },

    {
        name = effect_ids.SLOW,
        weight = 10,
        valid = slowable,
        apply = slow_monster,
    },

    {
        name = effect_ids.PARALYSIS,
        weight = 5,
        valid = slowable,
        apply = paralyze,
    },

    {
        name = effect_ids.PETRIFY,
        weight = 5,
        valid = petrifiable,
        apply = petrify,
    },
}

-- Named dispatch reuses the same effect body for deterministic callers and the random table.
function effects.apply_named(ctx, name, hit)
    for _, choice in ipairs(choices) do
        if choice.name == name then
            choice.apply(ctx, hit)
            return
        end
    end

    error("unknown chaos effect " .. tostring(name))
end

-- Example: with stream = 'melee',
-- effects.apply(ctx, hit, stream) -> applies one valid monster effect and returns its name
-- Draw once from the sum of eligible weights, then walk that same filtered
-- list. The caller supplies a saved RNG stream so combat can be replayed.
function effects.apply(ctx, hit, stream)
    local total = 0

    for _, choice in ipairs(choices) do
        if not choice.valid or choice.valid(ctx, hit) then
            total = total + choice.weight
        end
    end

    local draw = ctx:random(stream or "melee", total)

    for _, choice in ipairs(choices) do
        if not choice.valid or choice.valid(ctx, hit) then
            draw = draw - choice.weight

            if draw < 0 then
                choice.apply(ctx, hit)
                return choice.name
            end
        end
    end

    error("chaos has no eligible monster effect")
end

return effects
