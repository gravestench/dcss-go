-- Tremorstones choose a range-three impact from nearby monsters' center
-- of mass, then scatter each radius-two explosion around that cell. The
-- player aims only by deciding when to release the tin.
local component = require("constants.component")
local effects = require("policy.inventory.evokers.effects")
local explosive = require("policy.magic.effects.zaps.explosive")
local items = require("ids.items")
local power = require("policy.magic.power")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local targets = require("policy.inventory.evokers.targets")

local tin = {}
local RANGE = 3
local spec = {
    name = "burst of rock shards",
    damage = {
        kind = "fixed",
        count = 6,
        sides = 6,
    },
}

-- No visible monster prompts before spending time; accepting still allows
-- a blind blast, as source Crawl does.
function tin.prepare(ctx, player, _, _, forced)
    local _, visible = targets.nearby(ctx, player)

    return targets.warn_if_unseen(visible, forced,
        "You can't see anything, release a tremorstone anyway?")
end

-- Evaluate each reachable cell exactly three steps away. A reservoir
-- draw breaks equal-distance ties without depending on grid iteration.
local function choose_center(ctx, origin, enemies)
    local sum_x, sum_y = 0, 0

    for _, enemy in ipairs(enemies) do
        sum_x = sum_x + enemy.position.x
        sum_y = sum_y + enemy.position.y
    end

    local chosen = nil
    local best = nil
    local ties = 0

    for dy = -RANGE, RANGE do
        for dx = -RANGE, RANGE do
            if math.max(math.abs(dx), math.abs(dy)) == RANGE then
                local x, y = origin.x + dx, origin.y + dy

                if ctx:walkable(origin.level_id, x, y) and
                    ctx:visible_no_trans(origin.level_id,
                        origin.x, origin.y,
                        7, x, y) then
                    local distance = math.max(
                        math.abs(sum_x - x * #enemies),
                        math.abs(sum_y - y * #enemies))

                    if #enemies == 0 or not best or distance <= best then
                        if not best or distance < best then
                            best = distance
                            ties = 0
                        end

                        ties = ties + 1

                        if ctx:random(streams.EVOKER, ties) == 0 then
                            chosen = {
                                x = x,
                                y = y,
                            }
                        end
                    end
                end
            end
        end
    end

    return chosen
end

-- Scatter a center across itself and eight adjacent open cells. This
-- makes successive explosions related without stacking every blast.
local function scatter(ctx, level_id, center)
    local chosen = center
    local seen = 1

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x, y = center.x + dx, center.y + dy

                if ctx:walkable(level_id, x, y) then
                    seen = seen + 1

                    if ctx:random(streams.EVOKER, seen) == 0 then
                        chosen = {
                            x = x,
                            y = y,
                        }
                    end
                end
            end
        end
    end

    return chosen
end

-- The source stepdown is 2*log2(1+value/2), rounded to nearest. At zero
-- Evocations this gives one explosion; trained users can reach six.
function tin.explosion_count(skill)
    local value = math.floor(skill / 3)
    local stepped = 2 * math.log(1 + value / 2) / math.log(2)

    return 1 + math.floor(stepped + 0.5)
end

-- One committed release spends one XP charge even if the randomized
-- fragments find no monster. Geometry is recomputed from live actors.
function tin.resolve(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local enemies = targets.nearby(ctx, player)
    local center = choose_center(ctx, origin, enemies)

    if not center then
        ctx:emit("evoke", "Nothing happens.")

        return {
            charge = true,
            practice = 1,
        }
    end

    local skill = power.training(ctx, player,
        skills.SK_EVOCATIONS, 1)

    ctx:emit("evoke", "The tremorstone explodes into fragments!")

    for _ = 1, tin.explosion_count(skill) do
        local impact = scatter(ctx, origin.level_id, center)

        explosive.blast(ctx, player, origin.level_id,
            impact.x, impact.y, 2, spec, 0, streams.EVOKER)
    end

    return {
        charge = true,
        practice = 1,
    }
end

effects.add(items.MISC_TIN_OF_TREMORSTONES, tin)

return tin
