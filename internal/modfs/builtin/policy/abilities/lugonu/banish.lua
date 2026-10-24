-- Theory of operation: Lugonu's Banish fires the source single-target
-- enchantment zap from the player. The generic ray finds its first
-- contact, monster willpower answers the enchantment, and the existing
-- Abyss owner relocates a failed defender with its ECS identity intact.
local abilities = require("ids.abilities")
local banishment = require("policy.combat.monster_hexes.banishment")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local magic_power = require("policy.magic.power")
local registry = require("policy.abilities.registry")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local trajectory = require("policy.combat.trajectory")
local vision = require("policy.character.vision")
local will = require("policy.magic.effects.zaps.will")

local banish = {}

-- The third star and absence of penance own the menu row.
function banish.available(ctx, player)
    return costs.available(ctx, player, gods.LUGONU, 3)
end

-- The source uses current sight, including Nightstalker, rather than a
-- permanently fixed seven-cell range. The player cannot aim at themself.
function banish.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 4) then
        return "You do not have enough magic."
    end

    local dx = input.dx or 0
    local dy = input.dy or 0

    if dx == 0 and dy == 0 then
        return "You cannot banish yourself!"
    end

    local origin = ctx:get(player, component.POSITION)
    local reach = vision.radius(ctx, player)

    if math.max(math.abs(dx), math.abs(dy)) > reach or
        not ctx:visible(origin.level_id, origin.x, origin.y,
            reach, origin.x + dx, origin.y + dy) then
        return "That is beyond your range."
    end

    return nil
end

-- In source zap-data, player Banish uses the raw power up to cap 150;
-- the monster version divides power by ENCH_POW_FACTOR instead.
function banish.power(ctx, player)
    local trained = magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, 3)

    return math.min(150, 68 + trained)
end

-- A non-beam enchantment stops at its first actor contact. Resistance
-- spends the invocation but never moves or replaces that actor.
local function contact(ctx, player, intent)
    local origin = ctx:get(player, component.POSITION)
    local reach = vision.radius(ctx, player)
    local ray = trajectory.trace(ctx, origin.level_id,
        origin.x, origin.y, origin.x + intent.dx,
        origin.y + intent.dy, reach)
    local first = ray.contacts[1]

    if not first then
        ctx:emit("spell", "The banishing magic dissipates.")

        return
    end

    local target = first.actor
    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return
    end

    local definition = catalog.get(categories.MONSTERS,
        actor.kind_id)

    if will.resists(ctx, definition,
        banish.power(ctx, player), target) then
        ctx:emit("spell", "The " .. definition.name ..
            " resists banishment.")

        return
    end

    banishment.apply(ctx, player, target)
end

-- A failed invocation costs only the action. The ordinary 3-4 piety
-- cost and four MP are paid after a successful cast, even on a miss.
function banish.resolve(ctx, player, intent)
    if costs.failed(ctx, player, 85, 7, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    contact(ctx, player, intent)
    costs.spend(ctx, player, 4,
        3 + ctx:random(streams.RELIGION, 2))
end

-- Ability menus receive the live sight radius through the registry.
local function current_range(_, ctx, player)
    return vision.radius(ctx, player)
end

registry.add(abilities.LUGONU_BANISH, {
    name = "Banish",
    available = banish.available,
    range = current_range,
    prepare = banish.prepare,
    resolve = banish.resolve,
})

return banish
