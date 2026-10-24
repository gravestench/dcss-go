-- Theory of operation: Beogh's two-star Smiting invokes the already
-- registered direct-target spell. This ability owns its piety/MP gate,
-- failure roll, and source power; the spell owner keeps one damage rule.
local abilities = require("ids.abilities")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local costs = require("policy.abilities.god_costs")
local effects = require("policy.magic.effects.registry")
local magic_power = require("policy.magic.power")
local registry = require("policy.abilities.registry")
local skills = require("ids.skills")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local component = require("constants.component")
local gods = require("constants.gods")

local smiting = {}
local range = 7

-- The menu and the resolution gate both read live worship. A stale menu
-- entry cannot smite after conversion or Beogh penance begins.
function smiting.available(ctx, player)
    return costs.available(ctx, player, gods.BEOGH, 2)
end

-- Direction selection precedes the source failure roll. An empty visible
-- cell is a valid aim and consumes the action when invoked.
function smiting.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 3) then
        return "You do not have enough magic."
    end

    local dx = input.dx or 0
    local dy = input.dy or 0

    if dx == 0 and dy == 0 then
        return "Okay, then."
    end

    local position = ctx:get(player, component.POSITION)

    if math.max(math.abs(dx), math.abs(dy)) > range or
        not ctx:visible(position.level_id, position.x, position.y,
            range, position.x + dx, position.y + dy) then
        return "That is beyond your range."
    end

    return nil
end

-- Source skill_bump doubles the first three scaled skill points before
-- applying the same Smiting spell effect used by other player invocations.
function smiting.power(ctx, player)
    local trained = magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, 6)

    return 12 + trained + math.min(trained, 18)
end

-- A failed invocation spends its turn but no MP or piety. Successful
-- damage resolves before the source's three-or-four piety cost is drawn.
function smiting.resolve(ctx, player, intent)
    if costs.failed(ctx, player, 40, 5, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    local spell = catalog.get(categories.SPELLS,
        spells.SPELL_SMITING)
    local effect = effects.get(spell.id)

    effect.resolve(ctx, player, intent, spell,
        smiting.power(ctx, player))

    local piety_points = 3 + ctx:random(streams.RELIGION, 2)

    costs.spend(ctx, player, 3, piety_points)
end

-- Both the ability screen and the targeting preflight show source LOS.
local function visible_range()
    return range
end

registry.add(abilities.BEOGH_SMITING, {
    name = "Smiting",
    available = smiting.available,
    range = visible_range,
    prepare = smiting.prepare,
    resolve = smiting.resolve,
})

return smiting
