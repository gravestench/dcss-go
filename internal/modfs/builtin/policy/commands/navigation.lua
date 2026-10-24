local navigation = {}
local catalog = require("policy.catalog")
local fighter = require("policy.combat.fighter")
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local confusion = require("policy.magic.player_confusion")
local terrain = require("constants.terrain")
local transporters = require("policy.world.transporters")
local intent_ids = require("constants.intent")
local branches = require("ids.branches")
local runes = require("policy.character.runes")
local endgame = require("policy.character.endgame")
local phases = require("constants.endgame")
local pan_travel = require("policy.world.pan.travel")
local hell_travel = require("policy.world.hell.travel")
local temporary_portals = require("policy.world.portals.catalog")
local xom_stairs = require("policy.religion.xom.stair_repel")
local passage = require("policy.religion.fedhas.pass_through")

-- Rooted movement is rejected before checking the destination cell.
local function rooted(ctx)
    local form = ctx:get(ctx:player(), component.PLAYER_FORM)

    return form and form.form_id == "tree" and
        form.remaining_aut > 0
end

-- Movement rejects rooted or blocked destinations before an action is accepted.
-- Example: navigation.move(ctx, position, 1, 0) rejects impassable eastward terrain.
function navigation.move(ctx, position, dx, dy)
    if dx < -1 or dx > 1 or dy < -1 or dy > 1 or (dx == 0 and dy == 0) then
        return {
            message = "Invalid movement direction.",
        }
    end

    local x = position.x + dx
    local y = position.y + dy
    local cell = ctx:cell(position.level_id, x, y)

    if not cell then
        return {
            message = "You cannot move there.",
        }
    end

    local passable_plant = passage.at(ctx, ctx:player(),
        position.level_id, x, y)

    if rooted(ctx) and
        (passable_plant or not ctx:actor_at(position.level_id, x, y)) then
        return {
            message = "Your roots keep you in place.",
        }
    end

    -- Source Fungus Form fear prevents walking while watched, but a bump
    -- attack on the adjacent watcher still proceeds through melee policy.
    if not confusion.active(ctx, ctx:player()) and
        forms.nervous(ctx, ctx:player()) and
        (passable_plant or not ctx:actor_at(position.level_id, x, y)) then
        return {
            message = "You're too terrified to move while being watched!",
        }
    end

    -- Walking into a closed door becomes an open-door intent, keeping door timing in the action resolver.
    if cell == "DNGN_CLOSED_DOOR" then
        return {
            intent = {
                kind = 8,
                dx = dx,
                dy = dy,
            },
            cost = 10,
        }
    end

    if not ctx:walkable(position.level_id, x, y) then
        return {
            message = "You cannot move there.",
        }
    end

    local target = ctx:actor_at(position.level_id, x, y)

    if passable_plant then
        target = nil
    end

    if target then
        local actor = ctx:get(target, "core.actor")

        if not actor then
            error("player melee target has no actor " .. ctx:id(target))
        end

        local attack = fighter.attack(ctx, catalog.get("monsters", actor.kind_id))

        if attack.weapon_plus < -100 or attack.weapon_plus > 100 then
            error("invalid Fighter attack weapon enchantment")
        end
    end

    return {
        intent = {
            kind = 1,
            dx = dx,
            dy = dy,
        },
        cost = 10,
        attack_target = target,
    }
end

-- Stair travel checks the current cell's feature before switching levels.
function navigation.stairs(ctx, position, downstairs, actor, forced,
    pan_state, pan_current_vault_ids, hell_state, target_id)
    if rooted(ctx) then
        return {
            message = "Your roots keep you in place.",
        }
    end

    local glyph = downstairs and "DNGN_STONE_STAIRS_DOWN_I" or
        "DNGN_STONE_STAIRS_UP_I"
    local missing = downstairs and "There are no stairs down here." or
        "There are no stairs up here."
    local cell = ctx:cell(position.level_id, position.x, position.y)

    local portal = pan_travel.prepare(ctx, position, downstairs,
        pan_state, pan_current_vault_ids)

    if portal then
        return portal
    end

    -- An authored Depths entrance is a live arch, not a linked branch
    -- stair. Its destination is the newly generated moving Abyss window.
    if downstairs and cell == terrain.DNGN_ENTER_ABYSS then
        return {
            intent = {
                kind = intent_ids.DOWNSTAIRS,
            },
            cost = 10,
        }
    end

    -- Abyss exits and depth stairs have no fixed level link. Their Lua
    -- world policy creates or leaves the moving window after this intent
    -- spends time, so the ordinary stair_at check must not reject them.
    if position.level_id == abyss.level_id and
        ((downstairs and cell == terrain.DNGN_ABYSSAL_STAIR) or
            (not downstairs and cell == terrain.DNGN_EXIT_ABYSS)) then
        return {
            intent = {
                kind = downstairs and intent_ids.DOWNSTAIRS or
                    intent_ids.UPSTAIRS,
            },
            cost = 10,
        }
    end

    portal = hell_travel.prepare(ctx, position, downstairs, hell_state)

    if portal then
        return portal
    end

    portal = temporary_portals.dispatch(ctx, {
        position = position,
        downstairs = downstairs,
        forced = forced,
        target_id = target_id,
    })

    if portal then
        return portal
    end

    if cell == terrain.DNGN_TRANSPORTER then
        local destination, refusal = transporters.prepare(ctx, position)

        if not destination then
            return { message = refusal }
        end

        return {
            intent = {
                kind = downstairs and intent_ids.DOWNSTAIRS or
                    intent_ids.UPSTAIRS,
            },
            cost = 10,
        }
    end

    local stair = ctx:stair_at(position.level_id, position.x, position.y)

    if cell ~= glyph or not stair then
        return {
            message = missing,
        }
    end

    -- A wrong-direction command never attempts to climb this feature.
    -- Xom's refusal acts only after the requested stair is established.
    if xom_stairs.attempt_climb(ctx, actor or ctx:player(), position) then
        return {
            intent = {
                kind = intent_ids.WAIT,
            },
            cost = 10,
        }
    end

    local abyss_exit = position.level_id == abyss.level_id and not downstairs and
        ctx:has(ctx:player(), "world.banishment")

    if stair.unavailable ~= "" and not abyss_exit then
        return {
            message = stair.unavailable,
        }
    end

    actor = actor or ctx:player()

    -- Source locks Zot on first entry only. A refusal is a free command and
    -- never asks Go to generate the unopened destination floor.
    if downstairs and stair.target_branch_id == branches.BRANCH_ZOT then
        local width = ctx:level_size(stair.to_level_id)

        if not width and runes.count(ctx, actor) < 3 then
            return {
                message = "You need at least 3 runes to enter this place.",
            }
        end
    end

    if stair.exit then
        if endgame.phase(ctx, actor) == phases.EXPLORING and
            not forced then
            return {
                confirmation = "Are you sure you want to leave the Dungeon? This will make you lose the game!",
            }
        end
    end

    return {
        intent = {
            kind = downstairs and 5 or 4,
        },
        cost = 10,
    }
end

return navigation
