-- Heal Other targets a cell directly rather than firing a beam. Empty
-- cells still consume a successful invocation, so unseen monsters cannot
-- be located by repeatedly asking for free healing.
local abilities = require("ids.abilities")
local allies = require("policy.character.allies")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local pacification = require("policy.religion.elyvilon.pacification")
local power = require("policy.magic.power")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local attitudes = require("constants.attitude")
local vision = require("policy.character.vision")

local healing = {}

-- No Love forbids even the targeted healing ability in source, because
-- it could create a neutral monster that no longer attacks the player.
function healing.available(ctx, player)
    return costs.available(ctx, player, gods.ELYVILON, 2) and
        not allies.forbidden(ctx, player)
end

-- The targeter accepts visible empty cells and ignores projectile path;
-- self, solid terrain, and out-of-sight cells abort without a turn.
function healing.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 2) then
        return "You do not have enough magic."
    end

    local dx = input.dx or 0
    local dy = input.dy or 0

    if dx == 0 and dy == 0 then
        return "Okay, then."
    end

    local origin = ctx:get(player, component.POSITION)
    local range = vision.radius(ctx, player)
    local x = origin.x + dx
    local y = origin.y + dy

    if math.max(math.abs(dx), math.abs(dy)) > range or
        not ctx:visible(origin.level_id, origin.x, origin.y,
            range, x, y) then
        return "That is beyond your range."
    end

    if ctx:solid(origin.level_id, x, y) then
        return "There is nothing there to heal."
    end
end

-- Source uses current vision for the menu's targeting radius too.
function healing.range(_, ctx, player)
    return vision.radius(ctx, player)
end

-- Greater Healing's source dice divide power into a base, then roll
-- two dice of that size. Draws occur before checking an empty cell.
local function healing_amount(ctx, strength)
    local base = roll.random_divide(ctx, strength,
        3, streams.RELIGION)

    return base + roll.draw(ctx, streams.RELIGION, base) +
        roll.draw(ctx, streams.RELIGION, base)
end

-- Hostile targets receive an eligibility check before the failure roll;
-- their class-HP check and chance roll follow it. An empty target pays the
-- successful cost without revealing occupancy.
function healing.resolve(ctx, player, intent)
    local strength = 30 + power.training(ctx, player,
        skills.SK_INVOCATIONS, 1)
    local amount = healing_amount(ctx, strength)
    local origin = ctx:get(player, component.POSITION)
    local target = ctx:actor_at(origin.level_id,
        origin.x + intent.dx, origin.y + intent.dy)

    if target and targets.real_attitude(ctx, target) ==
        attitudes.HOSTILE then
        local actor = ctx:get(target, component.ACTOR)
        local definition = catalog.get(categories.MONSTERS,
            actor.kind_id)
        local reason = pacification.reason(ctx, target, definition)

        if reason then
            ctx:emit("religion", reason)

            return
        end
    end

    -- Source checks the invocation failure after rejecting an ineligible
    -- body, but before the class-HP comparison and pacification chance.
    if costs.failed(ctx, player, 40, 5, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    if not target then
        ctx:emit("religion", "There is nothing there to heal.")
    elseif targets.real_attitude(ctx, target) ==
        attitudes.HOSTILE then
        local result = pacification.attempt(ctx, player, target,
            amount, strength)

        if result == "abort" then
            return
        end
    elseif not pacification.heal(ctx, target, amount) then
        ctx:emit("religion", "Nothing happens.")
    end

    costs.spend(ctx, player, 2, costs.piety_cost(ctx, 2))
end

registry.add(abilities.ELYVILON_HEAL_OTHER, {
    name = "Heal Other",
    available = healing.available,
    range = healing.range,
    prepare = healing.prepare,
    resolve = healing.resolve,
})

return healing
