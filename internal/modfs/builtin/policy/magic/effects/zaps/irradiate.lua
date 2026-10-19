local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local monsters = require("ids.monsters")
local damage = require("policy.magic.damage")
local defense = require("policy.combat.monster_defense")
local registry = require("policy.magic.effects.registry")
local roll = require("policy.combat.roll")

local irradiate = {}

-- Missing holiness and flag lists grant no Irradiate immunity.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Undead, nonliving, and already mutable aberrations cannot gain Wretched.
local function can_wretch(definition)
    return not has(definition.holiness, "MH_UNDEAD") and
        not has(definition.holiness, "MH_NONLIVING") and
        definition.id ~= monsters.MONS_CHAOS_SPAWN and
        definition.id ~= monsters.MONS_ABOMINATION_SMALL and
        definition.id ~= monsters.MONS_ABOMINATION_LARGE and
        definition.id ~= monsters.MONS_UGLY_THING and
        definition.id ~= monsters.MONS_VERY_UGLY_THING
end

-- Scale three spell draws by monster speed so Wretched lasts comparable actions.
local function wretched_duration(ctx, target)
    local actor = ctx:get(target, component.ACTOR)
    local speed = math.max(1, actor.speed)
    local base = 20

    for _ = 1, 3 do
        base = base + 1 + ctx:random("spell", 10)
    end

    local centiturns = math.max(2,
        math.floor(base * 10 / math.max(1,
            math.floor(10 * 10 / speed))))
    local raw = centiturns * roll.random_divide(ctx, 100, speed)
    local low = math.floor(raw * 60 / 100)
    local high = math.floor(raw * 40 / 100)
    local fuzz = roll.average_two(ctx, "spell", low + high + 1)

    return math.max(15, raw + fuzz - low)
end

-- Remainder rolls preserve fractional cast-power damage on the spell stream.
local function random_round(ctx, numerator, denominator)
    local value = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        value = value + 1
    end

    return value
end

-- Conjured monsters ignore Irradiate; others roll chunked damage before Wretched.
local function hurt(ctx, target, power)
    local definition, health = damage.monster(ctx, target)

    if not definition or health.current <= 0 or
        has(definition.flags, "M_CONJURED") then
        return
    end

    local max_damage = 35 + random_round(ctx, power, 2)
    local sides = random_round(ctx, max_damage, 3)
    local raw = 3

    for _ = 1, 3 do
        raw = raw + ctx:random("spell", sides)
    end

    local ac = defense.armour(ctx, target, definition)
    local amount = math.max(0, raw - ctx:random("spell", ac + 1))

    damage.apply(ctx, target, amount)
    ctx:emit("spell", "The " .. definition.name ..
        " is blasted with magical radiation.")

    health = ctx:get(target, component.HEALTH)

    if health.current <= 0 or not can_wretch(definition) then
        return
    end

    irradiate.wretch(ctx, target, definition)
end

-- Repeat exposure extends the saved Wretched timer instead of replacing it.
function irradiate.wretch(ctx, target, definition)
    if not can_wretch(definition) then
        return false
    end

    local added = wretched_duration(ctx, target)
    local state = ctx:get(target, zap_ids.component.WRETCHED)

    if state then
        state.remaining_aut = state.remaining_aut + added
        ctx:set(target, zap_ids.component.WRETCHED, state)
    else
        ctx:add(target, zap_ids.component.WRETCHED, {
            remaining_aut = added,
        })
    end

    ctx:emit("spell", "The " .. definition.name ..
        " twists and deforms.")

    return true
end

-- Affect each neighbouring cell and accumulate player contamination from the cast.
function irradiate.resolve(ctx, player, _, _, power)
    local origin = ctx:get(player, component.POSITION)

    ctx:emit("spell", "You erupt in a fountain of uncontrolled magic!")

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = origin.x + dx
                local y = origin.y + dy

                if ctx:walkable(origin.level_id, x, y) then
                    local target = ctx:actor_at(origin.level_id, x, y)

                    if target and target ~= player then
                        hurt(ctx, target, power)
                    end
                end
            end
        end
    end

    -- Every cast adds contamination after the area hit; store the capped
    -- amount for later timed dissipation.
    local state = ctx:get(player, zap_ids.component.CONTAMINATION)
    local amount = math.min(250000,
        (state and state.amount or 0) + 1250 + ctx:random("spell", 750))

    if state then
        state.amount = amount
        ctx:set(player, zap_ids.component.CONTAMINATION, state)
    else
        ctx:add(player, zap_ids.component.CONTAMINATION, { amount = amount })
    end
end

-- Example: A Wretched monster loses its saved duration before choosing another action.
-- Expire the monster's Wretched duration before its next decision.
function irradiate.tick_wretched(ctx, entity)
    -- Wretched duration lives on the monster component so later turns can
    -- expire the effect after save and restore.
    local state = ctx:get(entity, zap_ids.component.WRETCHED)

    if not state then
        return
    end

    state.remaining_aut = state.remaining_aut - 10

    if state.remaining_aut <= 0 then
        ctx:remove(entity, zap_ids.component.WRETCHED)
    else
        ctx:set(entity, zap_ids.component.WRETCHED, state)
    end
end

-- Dissipate the saved player contamination by elapsed action time.
function irradiate.tick_contamination(ctx, entity, aut)
    if entity ~= ctx:player() then
        return
    end

    local state = ctx:get(entity, zap_ids.component.CONTAMINATION)

    if not state then
        return
    end

    -- timed-effects.cc:_apply_contam_over_time dissipates 75 per 10 aut.
    local scaled = 75 * aut
    local decrease = math.floor(scaled / 10)

    if ctx:random("spell", 10) < scaled % 10 then
        decrease = decrease + 1
    end

    state.amount = math.max(0, state.amount - decrease)

    if state.amount == 0 then
        ctx:remove(entity, zap_ids.component.CONTAMINATION)
    else
        ctx:set(entity, zap_ids.component.CONTAMINATION, state)
    end
end

registry.add(spells.SPELL_IRRADIATE, {
    resolve = irradiate.resolve,
})

-- Theory of operation: Wretched monster timers expire before their decisions, so restored state has the same duration.
register.system({
    id = "zap.wretched.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = irradiate.tick_wretched,
})

-- Theory of operation: Player contamination dissipates after spell attacks and before movement using elapsed aut.
register.system({
    id = "zap.contamination.tick",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = irradiate.tick_contamination,
})

return irradiate
