local component = require("constants.component")
local catalog = require("policy.catalog")
local defense = require("policy.combat.monster_defense")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local magic_damage = require("policy.magic.damage")
local monster_poison = require("policy.combat.monster_poison")
local player_health = require("policy.combat.player_health")
local spell_range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local accuracy = require("policy.character.accuracy")
local monster_stats = require("policy.combat.monster_stats")
local player_contact = require("policy.combat.player_contact")
local targets = require("policy.ai.targets")
local beam_damage = require("policy.combat.monster_beams.damage")
local flavours = require("constants.beam_flavours")
local will = require("policy.magic.effects.zaps.will")
local monster_drain = require("policy.combat.monster_drain")

local projectile = { specs = {} }

-- Example: to_hit(ctx, player, spec, 60) applies player zap accuracy to the
-- profile's power-scaled base before contact rolls.
-- Combine the profile’s capped power term with caster accuracy before any contact evasion roll.
function projectile.to_hit(ctx, player, spec, power)
    local base = spec.hit.base +
        math.floor(power * spec.hit.numerator / spec.hit.denominator)

    return accuracy.zap_to_hit(ctx, player, base)
end

-- Bound-one draws are deterministic and do not perturb the spell RNG stream.
local function random(ctx, bound)
    if bound <= 1 then
        return 0
    end

    return ctx:random("spell", bound)
end

-- Roll each source die on the spell stream before armour and resistance adjustments.
local function dice(ctx, count, sides)
    local total = 0

    for _ = 1, count do
        total = total + 1 + random(ctx, sides)
    end

    return total
end

-- Convert calcdice totals to whole dice with one rounding draw before any
-- shield or evasion result can discard the projectile.
local function damage_dice(ctx, spec, power)
    local amount = spec.damage.base +
        math.floor(power * spec.damage.numerator / spec.damage.denominator)

    if spec.damage.kind == "calcdice" then
        if amount <= spec.damage.count then
            return math.max(0, amount), 1
        end

        local count = spec.damage.count
        local sides = math.floor(amount / count)
        local remainder = amount % count

        if remainder > 0 and random(ctx, count) < remainder then
            sides = sides + 1
        end

        return count, sides
    end

    return spec.damage.count, amount
end

-- Pain is a source enchantment: immunity precedes its will save, then
-- damage bypasses EV and AC while negative-energy resistance still applies.
local function enchantment_contact(ctx, player, target,
    definition, spec, power)
    if spec.negative_energy and
        monster_drain.resistance(ctx, target, definition) >= 3 then
        ctx:emit("spell", "The " .. definition.name ..
            " is unaffected.")

        return
    end

    -- Source zap data uses Pain's 7*power/2 hit calculator as enchantment
    -- power. Capping first keeps its will check aligned with its damage.
    local capped = math.min(power, spec.cap)
    local enchant_power = spec.hit.base +
        math.floor(capped * spec.hit.numerator / spec.hit.denominator)

    if will.resists(ctx, definition, enchant_power,
        target, nil, player) then
        ctx:emit("spell", "The " .. definition.name ..
            " resists " .. spec.name .. ".")

        return
    end

    local count, sides = damage_dice(ctx, spec, capped)
    local raw = dice(ctx, count, sides)
    local amount = spec.negative_energy and
        beam_damage.resisted(ctx, target, raw, {
            flavour = flavours.BEAM_NEG,
        }) or raw

    magic_damage.apply(ctx, target, amount, player)
    ctx:emit("spell", "The " .. definition.name ..
        " writhes in agony.")
end

-- Monster body size and effective HD alter the shield's source block score.
local function shield_bonus(ctx, target, shield, definition)
    local size = {
        SIZE_LITTLE = 1,
        SIZE_SMALL = 2,
        SIZE_MEDIUM = 3,
        SIZE_LARGE = 4,
        SIZE_GIANT = 5,
    }
    local value = size[definition.size_id]

    if not value then
        error("unsupported monster shield body size " .. tostring(definition.size_id))
    end

    local base = (shield.definition.armour.ac + shield.item.plus * 2) * 2 +
        (value - size.SIZE_MEDIUM) * (shield.definition.subtype_value - 14)
    local hd = monster_stats.hit_dice(ctx, target, definition)
    local bound = base + math.floor(hd * 4 / 3)

    if bound <= 0 then
        return -100
    end

    return math.floor((random(ctx, bound) + random(ctx, bound + 1)) / 4)
end

-- Each prior shield block raises the bypass bound quadratically; persist the
-- new block count before the next projectile contact.
local function blocked(ctx, target, definition, to_hit)
    local shield = equipment.monster_shield(ctx, target)

    if not shield then
        return false
    end

    local bonus = shield_bonus(ctx, target, shield, definition)

    if bonus <= 0 then
        return false
    end

    local combat = ctx:get(target, component.COMBAT)
    local bound = math.floor(to_hit * 130 / 100) +
        4 * combat.shield_blocks * combat.shield_blocks

    if random(ctx, bound) >= bonus then
        return false
    end

    combat.shield_blocks = combat.shield_blocks + 1
    ctx:set(target, component.COMBAT, combat)

    return true
end

-- Automatic hits bypass the evasion draw; ordinary zaps use two-stage evasion
-- randomization on the spell stream.
local function hit(ctx, spec, to_hit, evasion)
    if spec.auto_hit then
        return true
    end

    local random_ev = random(ctx, evasion)
    local attack = random(ctx, to_hit)
    local defense = math.floor((random(ctx, random_ev) +
        random(ctx, random_ev + 1)) / 2)

    return attack >= defense
end

-- Profile AC rules select none, half, normal, or triple armour rolls.
local function armour(ctx, spec, target, definition)
    local ac = defense.armour(ctx, target, definition)

    if spec.ac_rule == "none" then
        return 0
    end

    if spec.ac_rule == "triple" then
        return random(ctx, ac + 1) + random(ctx, ac + 1) +
            random(ctx, ac + 1)
    end

    if spec.ac_rule == "half" then
        return math.floor(random(ctx, ac + 1) / 2)
    end

    return random(ctx, ac + 1)
end

-- Keep thirty percent of Poison Arrow damage outside poison resistance.
local function poison_arrow_damage(ctx, target, raw, definition)
    -- fight.cc:resist_adjust_damage: 70% of a poison arrow is resistible.
    -- Poison is a boolean resistance, so monster rPois uses 2 + r*r.
    local resistance = monster_poison.effective_resistance(ctx,
        target, definition)
    local resistible = math.floor(raw * 70 / 100)
    local solid = raw - resistible

    if resistance >= 3 then
        resistible = 0
    elseif resistance > 0 then
        resistible = math.floor(resistible /
            (2 + resistance * resistance))
    elseif resistance < 0 then
        resistible = math.floor(resistible * 3 / 2)
    end

    return solid + resistible, resistance
end

-- A visible living actor behind a clear projectile path is enough to offer
-- a zap; the later intent still chooses its exact ray.
local function can_target(ctx, player, spell)
    local source = ctx:get(player, component.POSITION)
    local range = spell_range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local location = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(math.abs(location.x - source.x),
                math.abs(location.y - source.y))

            if health.current > 0 and
                location.level_id == source.level_id and
                distance <= range and
                ctx:visible(source.level_id, source.x, source.y, range,
                    location.x, location.y) and
                ctx:projectile_clear(location.level_id, source.x, source.y,
                    location.x, location.y) then
                return true
            end
        end
    end

    return false
end

-- Trace once, then process contacts in path order; a bolt continues after a
-- hit, while a non-beam projectile stops on block or hit.
local function resolve(ctx, player, intent, spell, spec, power,
    range_override)
    local source = ctx:get(player, component.POSITION)
    local range = range_override or spec.range or
        spell_range.for_spell(ctx, player, spell)
    local ray

    if spec.bounce then
        ray = trajectory.bouncing(ctx, source.level_id,
            source.x, source.y,
            source.x + intent.dx, source.y + intent.dy,
            range, spec.bounce)
    else
        ray = trajectory.trace(ctx, source.level_id,
            source.x, source.y,
            source.x + intent.dx, source.y + intent.dy, range)
    end

    for _, contact in ipairs(ray.contacts) do
        local target = contact.actor

        if target == player then
            local zap_power = math.min(power, spec.cap)
            -- A reflected shot rolls damage before the player evasion check,
            -- keeping the seeded spell-stream sequence stable on a miss.
            local count, sides = damage_dice(ctx, spec, zap_power)
            local raw = dice(ctx, count, sides)

            if hit(ctx, spec, zap_power, fighter.defense(ctx).ev) then
                local after_ac = magic_damage.player_armour(ctx,
                    player, raw, spec.ac_rule)
                local amount = after_ac

                if spec.element_fraction then
                    local flavoured = math.floor(after_ac *
                        spec.element_fraction / 100)

                    amount = after_ac - flavoured +
                        magic_damage.player_elemental(ctx, player,
                            flavoured, spec.element)
                elseif spec.element then
                    amount = magic_damage.player_elemental(ctx,
                        player, after_ac, spec.element)
                end

                player_health.damage(ctx, player, amount)
                ctx:emit("spell", "The " .. spec.name .. " hits you.")
            else
                ctx:emit("spell", "The " .. spec.name .. " misses you.")
            end

        else
            local actor = ctx:get(target, component.ACTOR)
            local health = ctx:get(target, component.HEALTH)

            if not actor or not health then
                error(spec.name .. " struck an actor without health")
            end

            local definition = catalog.get("monsters", actor.kind_id)
            player_contact.report(ctx, target, definition)

            if spec.enchantment then
                enchantment_contact(ctx, player, target,
                    definition, spec, power)

                return
            end

            local zap_power = math.min(power, spec.cap)
            local count, sides = damage_dice(ctx, spec, zap_power)
            local raw = dice(ctx, count, sides)
            local amount = math.max(0, raw - armour(ctx, spec, target, definition))

            local poison_resistance

            if spec.poison_arrow then
                amount, poison_resistance = poison_arrow_damage(ctx,
                    target, amount, definition)
            elseif spec.negative_energy then
                amount = beam_damage.resisted(ctx, target, amount, {
                    flavour = flavours.BEAM_NEG,
                })
            elseif spec.element_fraction then
                local flavoured = math.floor(amount *
                    spec.element_fraction / 100)

                amount = amount - flavoured +
                    magic_damage.monster_elemental(ctx, target,
                        flavoured, spec.element)
            elseif spec.element then
                amount = magic_damage.monster_elemental(ctx, target,
                    amount, spec.element)
            end
            local to_hit = projectile.to_hit(ctx, player, spec, zap_power)

            if not spec.beam and blocked(ctx, target, definition, to_hit) then
                ctx:emit("spell", "The " .. definition.name .. " blocks the " .. spec.name .. ".")
                return
            elseif not hit(ctx, spec, to_hit,
                defense.evasion(ctx, target, definition)) then
                ctx:emit("spell", "The " .. spec.name .. " misses the " .. definition.name .. ".")
            else
                if spec.poison_arrow then
                    local stacks = 1

                    if poison_resistance > 0 then
                        stacks = random(ctx, 2)
                    end

                    monster_poison.apply(ctx, target, definition, stacks,
                        player, true)
                end

                local remaining = magic_damage.apply(ctx, target, amount)

                if remaining > 0 and spec.after_hit then
                    spec.after_hit(ctx, player, target, definition, amount)
                end

                ctx:emit("spell", "The " .. spec.name .. " hits the " .. definition.name .. ".")

                if not spec.beam then
                    return
                end
            end

        end
    end

    if #ray.contacts == 0 then
        ctx:emit("spell", "The " .. spec.name .. " dissipates.")
    end
end

-- Expose the shared projectile resolver to spell-specific callers without changing its spec.
function projectile.fire(ctx, player, intent, spell, spec, power,
    range_override)
    return resolve(ctx, player, intent, spell, spec, power,
        range_override)
end

-- Divine random beams trace their maximum straight path before choosing a
-- zap. Refuse friendly contacts without spending a turn or consuming costs.
function projectile.safe_aim(ctx, player, intent, reach)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id,
        origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy, reach)

    for _, contact in ipairs(ray.contacts) do
        if contact.actor ~= player and
            not targets.enemy(ctx, player, contact.actor) then
            return false
        end
    end

    return true
end

-- Use the same range and target predicate for casting preflight as resolution.
function projectile.can_target(ctx, player, spell)
    return can_target(ctx, player, spell)
end

-- Reject a missing spell spec before dispatching a projectile cast.
function projectile.resolve(ctx, player, intent, spell, power)
    local spec = projectile.specs[spell.id]

    if not spec then
        error("missing projectile specification for " .. spell.id)
    end

    return resolve(ctx, player, intent, spell, spec, power)
end

-- Register a concrete zap profile (for example Magic Dart) under its spell
-- ID so the generic resolver can use the same beam path for modded effects.
function projectile.register(id, spec)
    projectile.specs[id] = spec
    registry.add(id, projectile)
end

return projectile
