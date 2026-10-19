-- Warden seals visible doors and stairs with temporary terrain. Open door
-- panels are closed as one connected group before receiving the seal.
-- Source: mon-cast.cc:_seal_doors_and_stairs.
local component = require("constants.component")
local attitudes = require("constants.attitude")
local doors = require("policy.inventory.doors")
local items = require("policy.inventory.items")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")
local tension = require("policy.combat.monster_seal_tension")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")
local temporary = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")

local effect = {}
local RADIUS = 7

local function pushable(ctx, actor)
    return actor == ctx:player() or
        targets.real_attitude(ctx, actor) ~= attitudes.HOSTILE
end

local function seal_feature(feature)
    if feature == terrain.DNGN_CLOSED_DOOR then
        return terrain.DNGN_SEALED_DOOR
    end

    if feature == terrain.DNGN_CLOSED_CLEAR_DOOR then
        return terrain.DNGN_SEALED_CLEAR_DOOR
    end

    if feature == terrain.DNGN_STONE_STAIRS_UP_I then
        return terrain.DNGN_SEALED_STAIRS_UP
    end

    if feature == terrain.DNGN_STONE_STAIRS_DOWN_I then
        return terrain.DNGN_SEALED_STAIRS_DOWN
    end

    return nil
end

local function in_sight(ctx, caster, player)
    local source = ctx:get(caster, component.POSITION)
    local destination = ctx:get(player, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id or
        not ctx:visible(source.level_id, source.x, source.y,
            RADIUS, destination.x, destination.y) then
        return nil
    end

    return destination
end

-- The source requires the hostile caster's actual foe to be the player.
-- A closed door or travelable stair is sufficient; open doors must have
-- room to displace any body standing in their connected doorway.
function effect.plan(ctx, caster, foe)
    local player = ctx:player()

    if foe ~= player or targets.real_allied(ctx, caster) then
        return nil
    end

    -- The source check_only call still constructs a random seal duration.
    -- The later actual cast draws again instead of reusing this value.
    roll.spell(ctx, 80)

    local origin = in_sight(ctx, caster, player)

    if not origin then
        return nil
    end

    for _, cell in ipairs(ctx:visible_cells(origin.level_id,
        origin.x, origin.y, RADIUS)) do
        local feature = ctx:cell(origin.level_id, cell.x, cell.y)

        if seal_feature(feature) then
            return self_target.plan(caster)
        end

        if feature == terrain.DNGN_OPEN_DOOR or
            feature == terrain.DNGN_OPEN_CLEAR_DOOR then
            local group = doors.group(ctx, origin.level_id,
                cell.x, cell.y, feature)
            local excluded = doors.excluded(group)
            local possible = true

            for _, panel in ipairs(group) do
                local occupant = ctx:actor_at(origin.level_id,
                    panel.x, panel.y)

                if occupant and (not pushable(ctx, occupant) or
                    #doors.push_targets(ctx, origin.level_id,
                        panel, excluded) == 0) then
                    possible = false
                    break
                end
            end

            if possible and tension.allows_close(ctx, player, group) then
                return self_target.plan(caster)
            end
        end
    end

    return nil
end

local function close_group(ctx, level_id, group, closed_feature)
    local excluded = doors.excluded(group)
    local destinations = {}
    local moves = {}

    for _, panel in ipairs(group) do
        local occupant = ctx:actor_at(level_id, panel.x, panel.y)
        local ground = items.at(ctx, {
            level_id = level_id,
            x = panel.x,
            y = panel.y,
        })

        if occupant and not pushable(ctx, occupant) then
            return false
        end

        if occupant or #ground > 0 then
            local candidates = doors.push_targets(ctx, level_id,
                panel, excluded)
            local target

            if occupant then
                local blocked = {}

                for key in pairs(excluded) do
                    blocked[key] = true
                end

                for key in pairs(destinations) do
                    blocked[key] = true
                end

                target = tension.best_push(ctx, occupant,
                    group, panel, blocked)
            else
                for _, candidate in ipairs(candidates) do
                    local key = candidate.x .. ":" .. candidate.y

                    if not destinations[key] and
                        not ctx:actor_at(level_id, candidate.x, candidate.y) then
                        target = candidate
                        break
                    end
                end
            end

            if not target then
                return false
            end

            destinations[target.x .. ":" .. target.y] = true

            moves[#moves + 1] = {
                actor = occupant,
                items = ground,
                target = target,
            }
        end
    end

    -- Preflight every panel before moving anyone; failure leaves the entire
    -- connected doorway unchanged, as _can_force_door_shut does in source.
    for _, move in ipairs(moves) do
        if move.actor then
            ctx:move_actor(move.actor, level_id,
                move.target.x, move.target.y)
        end

        for _, item in ipairs(move.items) do
            local position = ctx:get(item, component.POSITION)

            position.x = move.target.x
            position.y = move.target.y
            ctx:set(item, component.POSITION, position)
        end
    end

    for _, panel in ipairs(group) do
        ctx:set_cell(level_id, panel.x, panel.y,
            closed_feature)
    end

    return true
end

function effect.resolve(ctx, caster, foe, _, plan)
    self_target.require_caster(plan, caster)

    local origin = foe == ctx:player() and in_sight(ctx, caster, foe)

    if not origin then
        return
    end

    local duration = 80 + roll.spell(ctx, 80)
    local changed = 0
    local seen = {}

    for _, cell in ipairs(ctx:visible_cells(origin.level_id,
        origin.x, origin.y, RADIUS)) do
        local distance = math.max(math.abs(cell.x - origin.x),
            math.abs(cell.y - origin.y))
        local key = cell.x .. ":" .. cell.y

        if distance <= RADIUS and not seen[key] then
            local feature = ctx:cell(origin.level_id, cell.x, cell.y)

            if feature == terrain.DNGN_OPEN_DOOR or
                feature == terrain.DNGN_OPEN_CLEAR_DOOR then
                local group = doors.group(ctx, origin.level_id,
                    cell.x, cell.y, feature)
                local closed = feature == terrain.DNGN_OPEN_CLEAR_DOOR and
                    terrain.DNGN_CLOSED_CLEAR_DOOR or
                    terrain.DNGN_CLOSED_DOOR
                local sealed = seal_feature(closed)

                for _, panel in ipairs(group) do
                    seen[panel.x .. ":" .. panel.y] = true
                end

                if tension.allows_close(ctx, foe, group) and
                    close_group(ctx, origin.level_id, group, closed) then
                    for _, panel in ipairs(group) do
                        if temporary.place(ctx, caster,
                            spells.SPELL_SEAL_DOORS,
                            origin.level_id, panel.x, panel.y,
                            sealed, duration) then
                            changed = changed + 1
                        end
                    end
                end
            else
                local sealed = seal_feature(feature)

                if sealed and temporary.place(ctx, caster,
                    spells.SPELL_SEAL_DOORS,
                    origin.level_id, cell.x, cell.y,
                    sealed, duration) then
                    changed = changed + 1
                end
            end
        end
    end

    if changed > 0 then
        ctx:emit("monster_spell", "A sealing rune closes the way!")
    end
end

return effect
