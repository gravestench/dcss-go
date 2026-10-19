-- Source: traps.cc:roll_trap_effects and do_trap_effects. Newly seen cells
-- roll against the level's explorable density; at most one effect fires.
local component = require("constants.component")
local ids = require("ids.traps")
local mark = require("policy.traps.mark")
local noise = require("policy.world.noise")
local teleport = require("policy.magic.player_teleport")
local translocation = require("policy.scrolls.translocation")
local streams = require("constants.rng_streams")
local vision = require("policy.character.vision")

local malevolence = {}
local density_cache = {}

-- Offer shafts only when placement allows them and alarms only below the shallowest depths.
-- Example: malevolence.options(2, false) leaves shaft creation out of the weighted punishments.
function malevolence.options(depth, can_shaft)
    local available = { ids.TRAP_TELEPORT }

    if can_shaft then
        available[#available + 1] = ids.TRAP_SHAFT
    end

    if depth > 3 then
        available[#available + 1] = ids.TRAP_ALARM
    end

    return available
end

-- Level density scales the chance of a surprise trap during exploration.
local function density(ctx, level_id)
    if density_cache[level_id] then
        return density_cache[level_id]
    end

    local width, height = ctx:level_size(level_id)
    local open = 0

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local adjacent = false

            for dy = -1, 1 do
                for dx = -1, 1 do
                    if (dx ~= 0 or dy ~= 0) and
                        ctx:walkable(level_id, x + dx, y + dy) then
                        adjacent = true
                        break
                    end
                end

                if adjacent then
                    break
                end
            end

            if adjacent then
                open = open + 1
            end
        end
    end

    -- Source explorable density is a level-generation statistic. Cache it
    -- for this game VM; door and terrain effects do not reroll the statistic.
    density_cache[level_id] = math.max(1, open)

    return density_cache[level_id]
end

-- Count newly seen cells before deciding whether a surprise hazard can fire.
local function new_cells(ctx, player, position)
    local radius = vision.radius(ctx, player)
    local added = 0

    for _, cell in ipairs(ctx:visible_cells(position.level_id,
        position.x, position.y, radius)) do
        if ctx:map_cell(position.level_id, cell.x, cell.y) then
            added = added + 1
        end
    end

    return added
end

-- Surprise shafts have eligibility separate from known shaft entities.
local function shaft(ctx, player, position)
    local level_id = position.level_id + 1
    local width, height = ctx:level_size(level_id)

    if not width then
        return false
    end

    for _ = 1, 1000 do
        local x = ctx:random(streams.TRAPS, width)
        local y = ctx:random(streams.TRAPS, height)

        if translocation.can_land(ctx, player, level_id, x, y) then
            ctx:emit("trap", "A sourceless malevolence fills the Dungeon...")
            ctx:move_actor(player, level_id, x, y)

            return true
        end
    end

    return false
end

-- Choose one weighted malevolence outcome after the hazard gate passes.
local function trigger(ctx, player, position)
    local can_shaft = ctx:level_size(position.level_id + 1) ~= nil
    local available = malevolence.options(position.level_id, can_shaft)
    local kind_id = available[ctx:random(streams.TRAPS, #available) + 1]

    if kind_id == ids.TRAP_SHAFT then
        shaft(ctx, player, position)
    elseif kind_id == ids.TRAP_ALARM then
        ctx:emit("trap", "A sourceless malevolence fills the Dungeon...")
        ctx:emit("trap", "With a horrendous wail, an alarm goes off!")
        noise.emit(ctx, position, 40, player)
        mark.apply(ctx, player)
    else
        ctx:emit("trap", "A teleportation trap spontaneously manifests!")
        teleport.now(ctx, player)
    end
end

-- Draw only on eligible exploration progress to preserve trap RNG order.
function malevolence.roll(ctx, player)
    local position = ctx:get(player, component.POSITION)
    local count = new_cells(ctx, player, position)

    if count == 0 then
        return
    end

    local denominator = 9 * density(ctx, position.level_id)
    local rate = math.min(9, 1 + math.floor(position.level_id / 10))

    for _ = 1, count do
        if ctx:random(streams.TRAPS, denominator) < rate then
            trigger(ctx, player, position)

            return
        end
    end
end

return malevolence
