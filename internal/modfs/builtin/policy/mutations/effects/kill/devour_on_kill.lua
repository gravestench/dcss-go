local component = require("constants.component")
local holiness_ids = require("constants.monster_holiness")
local mutations = require("ids.mutations")
local effects = require("policy.combat.player_kill_effects")
local statuses = require("policy.magic.effects.statuses.player")

local devour = {}

-- Only natural and plant holiness count as food for this legacy kill effect;
-- inspect every holiness tag because monsters can carry more than one.
local function edible(monster)
    for _, holiness in ipairs(monster.holiness or {}) do
        if holiness == holiness_ids.NATURAL or
            holiness == holiness_ids.PLANT then
            return true
        end
    end

    return false
end

-- Source: mon-death.cc grants 1+random2avg(1+XL, 3) HP on half of
-- eligible natural or plant kills, unless Death's Door is active.
-- Example: an edible natural kill has a one-in-two mutation-stream gate before it heals the player.
function devour.on_kill(ctx, player, monster)
    if not edible(monster) or ctx:random("mutation", 2) ~= 0 then
        return
    end

    local progress = ctx:get(player, component.PROGRESSION)
    local health = ctx:get(player, component.HEALTH)

    if not progress or not health then
        error("Devour on Kill requires player vitals and progression")
    end

    local maximum = 1 + progress.level
    local total = ctx:random("mutation", maximum)

    for _ = 1, 2 do
        total = total + ctx:random("mutation", maximum + 1)
    end

    local healing = 1 + math.floor(total / 3)

    if health.current >= health.max or
        statuses.death_door_active(ctx, player) then
        return
    end

    health.current = math.min(health.max, health.current + healing)
    ctx:set(player, component.HEALTH, health)
    ctx:emit("health", "You feel better.")
end

effects.add(mutations.MUT_DEVOUR_ON_KILL, devour.on_kill)

return devour
