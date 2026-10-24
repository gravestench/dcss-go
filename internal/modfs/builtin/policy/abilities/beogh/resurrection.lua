-- Theory of operation: an orc corpse contains the saved identity of its
-- dead actor. Resurrection selects that body, confirms the choice, finds
-- an adjacent habitable cell, creates a follower with its former HP and
-- name, and reclaims gear still lying on the corpse's cell. Only then does
-- it consume the body and pay source piety.
local abilities = require("ids.abilities")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local corpse = require("policy.abilities.beogh.corpse")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local habitat = require("policy.combat.monster_habitat")
local beogh = require("policy.religion.gods.beogh")
local factory = require("policy.population.factory")
local registry = require("policy.abilities.registry")
local selection_kinds = require("constants.selection_kinds")

local resurrection = {}

-- The six-star menu row follows live worship and Beogh penance.
local function available(ctx, player)
    return costs.available(ctx, player, gods.BEOGH, 6)
end

-- Defined before the confirmation handler so its no-room preflight can
-- abort without consuming the player turn, as the source ability does.
local function landing(ctx, player, kind_id)
    local origin = ctx:get(player, component.POSITION)

    for dy = -1, 1 do
        for dx = -1, 1 do
            local x = origin.x + dx
            local y = origin.y + dy

            if (dx ~= 0 or dy ~= 0) and
                not ctx:actor_at(origin.level_id, x, y) and
                habitat.kind_at(ctx, kind_id, origin.level_id,
                    x, y) then
                return origin.level_id, x, y
            end
        end
    end

    return nil
end

-- The source offers only resurrection-marked bodies under the player.
-- These coordinates must be checked again after the confirmation prompt.
function resurrection.reachable(ctx, player, body)
    local player_position = ctx:get(player, component.POSITION)
    local body_position = body and ctx:get(body, component.POSITION)

    return player_position ~= nil and body_position ~= nil and
        body_position.level_id == player_position.level_id and
        body_position.x == player_position.x and
        body_position.y == player_position.y and
        ctx:has(body, component.CORPSE) and
        ctx:has(body, component.BEOGH_CORPSE)
end

-- Stable IDs distinguish two orc bodies on the same tile; the label is
-- human-facing and may repeat without affecting the selected entity.
local function corpses_prompt(ctx, player)
    local options = {}

    for _, body in ipairs(ctx:query({ component.BEOGH_CORPSE })) do
        if resurrection.reachable(ctx, player, body) then
            local saved = ctx:get(body, component.BEOGH_CORPSE)
            local definition = catalog.get(categories.MONSTERS,
                saved.kind_id)
            local label = saved.custom_name ~= "" and
                saved.custom_name or definition.name

            options[#options + 1] = {
                id = tostring(ctx:id(body)),
                label = label,
            }
        end
    end

    if #options == 0 then
        return { message = "There's nobody here you can resurrect." }
    end

    return {
        selection = {
            kind = selection_kinds.ITEM,
            title = "Resurrect which orc?",
            options = options,
        },
    }
end

-- The second free prompt mirrors the source's explicit yes/no question.
local function confirmation(ctx, body)
    local saved = ctx:get(body, component.BEOGH_CORPSE)
    local definition = catalog.get(categories.MONSTERS, saved.kind_id)
    local name = saved.custom_name ~= "" and saved.custom_name or
        definition.name

    return { confirmation = "Resurrect " .. name .. "?" }
end

-- A corpse choice is kept on the player until yes, no, or cancellation.
function resurrection.prepare(ctx, player, input)
    if input.cancelled then
        if ctx:has(player, component.BEOGH_RESURRECTION_CHOICE) then
            ctx:remove(player, component.BEOGH_RESURRECTION_CHOICE)
        end

        return "Okay."
    end

    local pending = ctx:get(player,
        component.BEOGH_RESURRECTION_CHOICE)

    if pending then
        if not resurrection.reachable(ctx, player, pending.corpse) then
            ctx:remove(player, component.BEOGH_RESURRECTION_CHOICE)

            return "That corpse is no longer here."
        end

        if not input.forced then
            return confirmation(ctx, pending.corpse)
        end

        local saved = ctx:get(pending.corpse,
            component.BEOGH_CORPSE)

        if not landing(ctx, player, saved.kind_id) then
            ctx:remove(player,
                component.BEOGH_RESURRECTION_CHOICE)

            return "There's no room!"
        end

        input.item_id = ctx:id(pending.corpse)

        return nil
    end

    local selected_id = tonumber(input.target_id)
    local body = selected_id and ctx:entity(selected_id)

    if not body then
        return corpses_prompt(ctx, player)
    end

    if not resurrection.reachable(ctx, player, body) then
        return "That is not an orc corpse you can resurrect."
    end

    ctx:add(player, component.BEOGH_RESURRECTION_CHOICE, {
        corpse = body,
    })

    return confirmation(ctx, body)
end

-- Gear is reclaimed only while its original item entity still lies on
-- the corpse's tile. The player may have moved it since the orc died.
local function reclaim_gear(ctx, saved, follower, origin)
    for slot, id in pairs(saved.dropped_gear) do
        local item = ctx:entity(id)
        local floor = item and ctx:get(item, component.POSITION)

        if floor and floor.level_id == origin.level_id and
            floor.x == origin.x and floor.y == origin.y and
            ctx:has(item, component.ITEM) and
            not ctx:has(item, component.CARRIED_BY) then
            ctx:remove(item, component.POSITION)
            ctx:add(item, component.CARRIED_BY, {
                holder = follower,
            })
            ctx:add(item, component.EQUIPPED, {
                slot = slot,
            })
        end
    end
end

-- A blocked preflight aborts for free. The saved marker admits a
-- successfully restored actor during later save validation.
function resurrection.resolve(ctx, player, intent)
    local pending = ctx:get(player,
        component.BEOGH_RESURRECTION_CHOICE)
    local body = pending and pending.corpse

    if not body or body ~= intent.item_id or
        not resurrection.reachable(ctx, player, body) then
        error("invalid Beogh resurrection intent")
    end

    local saved = ctx:get(body, component.BEOGH_CORPSE)
    corpse.validate(ctx, body)
    local level_id, x, y = landing(ctx, player, saved.kind_id)

    ctx:remove(player, component.BEOGH_RESURRECTION_CHOICE)

    if not level_id then
        ctx:emit("religion", "There's no room!")

        return
    end

    local origin = ctx:get(body, component.POSITION)
    local follower = factory.spawn(ctx, saved.kind_id,
        level_id, x, y, {
            hp = saved.max_hp,
            hd = saved.hit_dice,
            custom_name = saved.custom_name,
            name_adjective = saved.name_adjective,
            equipment = {},
            restore_identity = true,
        })

    local actor = ctx:get(follower, component.ACTOR)

    actor.speed = saved.speed
    ctx:set(follower, component.ACTOR, actor)

    ctx:add(follower, component.BEOGH_RESURRECTED, {
        created_aut = ctx:aut(),
    })
    beogh.resurrect(ctx, follower, saved.gift_category)
    reclaim_gear(ctx, saved, follower, origin)
    ctx:destroy(body)
    costs.spend(ctx, player, 0, costs.piety_cost(ctx, 28))
    ctx:emit("religion", "Your orcish follower rises again.")
end

-- A saved confirmation must still belong to a living Beogh worshipper
-- and point to a body under that player, never a remote item.
function resurrection.validate(ctx, player)
    local pending = ctx:get(player,
        component.BEOGH_RESURRECTION_CHOICE)

    if pending and (not costs.available(ctx, player, gods.BEOGH, 6) or
        not resurrection.reachable(ctx, player, pending.corpse)) then
        error("invalid saved Beogh resurrection choice")
    end
end

registry.add(abilities.BEOGH_RESURRECTION, {
    name = "Resurrection",
    available = available,
    owns_cancellation = true,
    prepare = resurrection.prepare,
    resolve = resurrection.resolve,
})

return resurrection
