local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local damage = require("policy.magic.damage")
local explosion = require("policy.combat.explosion")
local player_health = require("policy.combat.player_health")
local monster_health = require("policy.combat.monster_health")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local player_contact = require("policy.combat.player_contact")
local streams = require("constants.rng_streams")

local explosive = { specs = {} }

-- Use the explosion spec dice, including fixed damage, before applying target defenses.
local function roll_damage(ctx, spec, power, stream)
    if spec.damage.kind == "fixed" then
        local amount = 0

        for _ = 1, spec.damage.count do
            amount = amount + 1 + ctx:random(stream, spec.damage.sides)
        end

        return amount
    end

    local maximum = spec.damage.base + math.floor(
        math.min(power, spec.cap) * spec.damage.numerator /
            spec.damage.denominator)
    local sides = math.floor(maximum / spec.damage.count)
    local remainder = maximum % spec.damage.count

    if remainder > 0 and ctx:random(stream, spec.damage.count) < remainder then
        sides = sides + 1
    end

    local amount = 0

    for _ = 1, spec.damage.count do
        amount = amount + 1 + ctx:random(stream, sides)
    end

    return amount
end

-- Find the requested elemental resistance level from a monster profile.
local function resistance(definition, wanted)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == wanted then
            return entry.level
        end
    end

    return 0
end

-- Only the resistible fraction of an explosion passes through elemental
-- resistance; the rest of the raw damage is unchanged.
local function resist_monster(ctx, target, raw, definition, spec)
    if not spec.element then
        return raw
    end

    if spec.element == "MR_RES_DAMNATION" then
        return resistance(definition, spec.element) > 0 and 0 or raw
    end

    local fraction = spec.resistible_fraction or 100
    local resistible = math.floor(raw * fraction / 100)

    return raw - resistible +
        damage.monster_elemental(ctx, target, resistible, spec.element)
end

-- Apply the player-specific resistance path only for elemental explosions.
local function resist_player(ctx, player, raw, spec)
    if not spec.element then
        return raw
    end

    if spec.element == "MR_RES_DAMNATION" then
        -- player.h:res_damnation is always false at the pinned revision.
        return raw
    end

    local fraction = spec.resistible_fraction or 100
    local resistible = math.floor(raw * fraction / 100)

    return raw - resistible +
        damage.player_elemental(ctx, player, resistible, spec.element)
end

-- Branch player and monster damage through their own armour and resistance rules.
local function hurt(ctx, player, target, spec, power, stream)
    stream = stream or streams.SPELL

    local raw = roll_damage(ctx, spec, power, stream)

    if target == player then
        local after_ac = damage.player_armour(ctx, player, raw,
            spec.ac_rule, stream)
        local amount = resist_player(ctx, player, after_ac, spec)

        player_health.damage(ctx, player, amount)
        return
    end

    local definition, health = damage.monster(ctx, target)

    if not definition or health.current <= 0 then
        return
    end

    -- A divine or environmental blast has no player attacker. It must
    -- neither record player conduct nor award a player kill on death.
    if not spec.uncredited then
        player_contact.report(ctx, target, definition)
    end

    local after_ac = raw

    if spec.ac_rule ~= "none" then
        local ac = defense.armour(ctx, target, definition)
        after_ac = math.max(0, raw - ctx:random(stream, ac + 1))
    end

    local amount = resist_monster(ctx, target,
        after_ac, definition, spec)

    if spec.uncredited then
        monster_health.damage(ctx, target, amount, nil)
    else
        damage.apply(ctx, target, amount)
    end
    ctx:emit("spell", "The " .. spec.name .. " hits the " .. definition.name .. ".")
end

explosive.hurt = hurt

-- Xom and ordinary spells share blast propagation and resistances. The
-- caller supplies a fixed or power-shaped spec and its own RNG stream;
-- the blast returns the number of live actors it actually contacted.
function explosive.blast(ctx, player, level_id, x, y, radius,
    spec, power, stream, skip_center)
    local contacted = 0

    for _, cell in ipairs(explosion.cells(ctx, level_id,
        x, y, radius)) do
        local target = ctx:actor_at(level_id, cell.x, cell.y)

        if target and not (skip_center and
            cell.x == x and cell.y == y) then
            hurt(ctx, player, target, spec, power, stream)
            contacted = contacted + 1
        end
    end

    return contacted
end

-- Choose an impact cell before expanding the spec radius to nearby actors.
local function resolve(ctx, player, intent, spell, power, spec)
    local source = ctx:get(player, component.POSITION)
    local ray = trajectory.to_target(ctx, source.level_id,
        source.x, source.y,
        source.x + intent.dx, source.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local impact = ray.contacts[1]
    local center_x = impact and impact.x or ray.x
    local center_y = impact and impact.y or ray.y

    ctx:emit("spell", "The " .. spec.name .. " explodes!")

    explosive.blast(ctx, player, source.level_id,
        center_x, center_y, 1, spec, power, streams.SPELL)
end

-- Fail on an unknown explosion spec rather than silently dropping a registered spell.
function explosive.resolve(ctx, player, intent, spell, power)
    local spec = explosive.specs[spell.id]

    if not spec then
        error("missing explosion specification for " .. spell.id)
    end

    return resolve(ctx, player, intent, spell, power, spec)
end

-- Example: A registered explosion spec supplies its radius and damage dice at impact.
-- Pair each spell ID with its blast profile and the shared resolver when the zap module loads.
function explosive.register(id, spec)
    -- Registration pairs spell-specific blast dice with the shared resolver
    -- called by magic.invoke.
    explosive.specs[id] = spec
    registry.add(id, explosive)
end

return explosive
