-- The condenser chooses one cloud species for the entire evocation, then
-- tries to place that cloud around every threatening nearby monster. It
-- uses ordinary saved cloud entities, so movement and damage need no
-- evoker-specific follow-up system.
local clouds = require("ids.clouds")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local effects = require("policy.inventory.evokers.effects")
local items = require("ids.items")
local placement = require("policy.clouds.placement")
local power = require("policy.magic.power")
local roll = require("policy.combat.roll")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local targets = require("policy.inventory.evokers.targets")
local wind = require("policy.combat.monster_support.still_winds")
local allegiance = require("policy.ai.targets")

local vane = {}

-- These source random-pick ranges and rarity curves express why mephitic
-- clouds dominate untrained use while dangerous clouds grow with skill.
local choices = {
    {
        kind = clouds.CLOUD_MEPHITIC,
        last = 50,
        rarity = 200,
        curve = "fall",
    },
    {
        kind = clouds.CLOUD_FIRE,
        last = 100,
        rarity = 125,
        curve = "peak",
    },
    {
        kind = clouds.CLOUD_COLD,
        last = 100,
        rarity = 125,
        curve = "peak",
    },
    {
        kind = clouds.CLOUD_POISON,
        last = 100,
        rarity = 125,
        curve = "peak",
    },
    {
        kind = clouds.CLOUD_NEGATIVE_ENERGY,
        last = 110,
        rarity = 50,
        curve = "rise",
    },
    {
        kind = clouds.CLOUD_STORM,
        last = 110,
        rarity = 50,
        curve = "rise",
    },
    {
        kind = clouds.CLOUD_ACID,
        last = 110,
        rarity = 50,
        curve = "rise",
    },
}

-- random-pick.h scales by 2520 before integer division. Preserve that
-- integer arithmetic so boundary powers draw from the source weights.
local function weight(choice, skill)
    if skill > choice.last then
        return 0
    end

    local rarity = choice.rarity * 2520

    if choice.curve == "fall" then
        return math.floor(rarity * (choice.last - skill + 1) /
            (choice.last + 1))
    elseif choice.curve == "rise" then
        return math.floor(rarity * (skill + 1) /
            (choice.last + 1))
    end

    local length = choice.last + 2

    return math.floor(rarity *
        (length - math.abs(choice.last - 2 * skill)) / length)
end

-- A single weighted roll selects the species shared by all candidate
-- cells. Empty eligible space still consumes this roll in source Crawl.
function vane.choose_cloud(ctx, skill)
    local total = 0

    for _, choice in ipairs(choices) do
        total = total + weight(choice, skill)
    end

    local pick = ctx:random(streams.EVOKER, total)

    for _, choice in ipairs(choices) do
        pick = pick - weight(choice, skill)

        if pick < 0 then
            return choice.kind
        end
    end

    error("condenser cloud picker exhausted")
end

-- Still Winds blocks formation before the player spends time or charge.
-- With no visible foe, the player may confirm a blind evocation.
function vane.prepare(ctx, player, _, _, forced)
    local origin = ctx:get(player, component.POSITION)

    if wind.active_level(ctx, origin.level_id) then
        return "The air is too still to form clouds."
    end

    local _, visible = targets.nearby(ctx, player)

    return targets.warn_if_unseen(visible, forced,
        "You can't see anything. Try to condense clouds anyway?")
end

-- Check each neighbor against floor, visibility, existing clouds, and
-- allies. Clustered foes may nominate one cell twice; placement handles
-- that conflict at resolution time.
local function add_neighbors(ctx, origin, enemy, result)
    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = enemy.position.x + dx
                local y = enemy.position.y + dy
                local occupant = ctx:actor_at(origin.level_id, x, y)

                if ctx:walkable(origin.level_id, x, y) and
                    ctx:visible(origin.level_id, origin.x, origin.y,
                        7, x, y) and
                    not placement.at(ctx, origin.level_id, x, y) and
                    not (occupant and
                        allegiance.allied(ctx, occupant)) then
                    result[#result + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end
end

-- A harmless monster contributes no cells, matching the source's
-- threatening-body check before its adjacent-cell traversal.
local function cells(ctx, player, enemies)
    local origin = ctx:get(player, component.POSITION)
    local result = {}

    for _, enemy in ipairs(enemies) do
        if targets.threatening(ctx, enemy.actor) then
            add_neighbors(ctx, origin, enemy, result)
        end
    end

    return result
end

-- The source cloud power is an averaged three-roll duration in turns.
-- The cloud owner stores AUT, so convert exactly once at placement.
function vane.resolve(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local skill = power.training(ctx, player,
        skills.SK_EVOCATIONS, 7)
    local strength = 15 + math.floor(skill / 2)
    local cloud_kind = vane.choose_cloud(ctx, strength)
    local enemies = targets.nearby(ctx, player)
    local candidates = cells(ctx, player, enemies)

    if #candidates == 0 then
        ctx:emit("evoke", "Nothing happens.")

        return {
            charge = false,
            practice = 1,
        }
    end

    local spread = 12 + roll.random_divide(ctx,
        strength * 3, 4, streams.EVOKER)

    for _, cell in ipairs(candidates) do
        local lifetime = 5 + roll.average_three(ctx,
            streams.EVOKER, spread)

        placement.place(ctx, cloud_kind, player, origin.level_id,
            cell.x, cell.y, lifetime * 10)
    end

    local name = catalog.get(categories.CLOUDS, cloud_kind).name

    ctx:emit("evoke", "Clouds of " .. name ..
        " condense around you!")

    return {
        charge = true,
        practice = 1,
    }
end

effects.add(items.MISC_CONDENSER_VANE, vane)

return vane
