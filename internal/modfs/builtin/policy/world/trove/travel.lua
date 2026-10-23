-- Theory of operation: preparing a Trove gate is read-only and returns a
-- confirmation tied to one ECS gate ID. After a source reward floor has been
-- staged, this policy rechecks the gate and price, debits the resource,
-- stores the exact return address, and moves the player in one transaction.
-- Example: a modded Trove room needs only a source exit arch; this policy
-- uses the saved visit rather than a hardcoded Dungeon depth on return.
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local domains = require("constants.portal_domains")
local effects = require("constants.vault_effects")
local levels = require("policy.generation.branch_levels")
local payment = require("policy.world.trove.payment")
local portal = require("policy.world.trove.portal")
local terrain = require("constants.terrain")
local toll = require("policy.world.trove.toll")
local trove = require("constants.trove")

local travel = {}

-- Carry the actual cell in every staged plan so a confirmation cannot be
-- reused after stepping onto a different portal or changing floors.
local function source(position)
    return {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    }
end

-- Compare the source-position marker's price field to its Akara owner.
-- Both are saved; a changed mod or forged record must fail before payment.
local function marker_matches(ctx, gate)
    local found = 0

    for _, record in ipairs(ctx:records_at(gate.level_id,
        gate.x, gate.y)) do
        if record.kind == effects.MARKER and
            record.source_id == gate.vault_id and
            record.identity == trove.MARKER_IDENTITY and
            not record.pending and not record.overridden and
            record.arguments.price == gate.price_witness then
            found = found + 1
        end
    end

    return found == 1
end

-- First key press asks permission without matching or consuming any item.
-- Forced confirmation must name the same gate it originally described.
local function prepare_entry(ctx, position, forced, target_id)
    local player = ctx:player()

    if ctx:get(player, component.PLAYER_TROVE_VISIT) then
        error("Treasure Trove entrance found during an active visit")
    end

    local entity, gate = portal.at(ctx, position.level_id,
        position.x, position.y)

    if not entity or gate.spent or
        not marker_matches(ctx, gate) then
        return { message = "The treasure trove entrance is closed." }
    end

    local offer = payment.offer(ctx, entity, gate)

    if not forced then
        return {
            confirmation = offer.prompt,
            confirmation_id = offer.target,
        }
    end

    if target_id ~= offer.target then
        return { message = "That treasure trove is no longer here." }
    end

    local accepted, reason = payment.match(ctx, player, gate)

    if not accepted then
        return { message = reason }
    end

    local identity = ctx:get(player, component.PLAYER)

    if not identity then
        error("Treasure Trove visitor has no character identity")
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "enter",
            source = source(position),
            generate_policy = "world.generate_trove_level",
            generation_input = {
                species_id = identity.species_id,
                player_name = identity.name,
            },
            commit_policy = "world.trove.commit_travel",
            expected_branch_id = branches.BRANCH_TROVE,
            expected_level_id = levels.id(branches.BRANCH_TROVE, 1),
        },
        cost = 10,
    }
end

-- Return always uses the visit's saved outside site. An actor there is a
-- free refusal; it may move later without invalidating the visit pointer.
local function prepare_exit(ctx, position)
    local visit = ctx:get(ctx:player(), component.PLAYER_TROVE_VISIT)

    if not visit or visit.level_id ~= position.level_id then
        error("Treasure Trove exit has no saved return site")
    end

    if not ctx:walkable(visit.origin_level_id,
        visit.origin_x, visit.origin_y) or
        ctx:actor_at(visit.origin_level_id,
            visit.origin_x, visit.origin_y) then
        return { message = "The way back through the gate is blocked." }
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "return",
            source = source(position),
            commit_policy = "world.trove.commit_travel",
            retire_level_id = position.level_id,
            destination = {
                level_id = visit.origin_level_id,
                x = visit.origin_x,
                y = visit.origin_y,
            },
        },
        cost = 10,
    }
end

-- The grid feature chooses this domain. Other stairs remain with their
-- ordinary branch owners after nil is returned.
function travel.prepare(ctx, position, downstairs, forced, target_id)
    local feature = ctx:cell(position.level_id, position.x, position.y)

    if feature == terrain.DNGN_ENTER_TROVE then
        if not downstairs then
            return { message = "There are no stairs up here." }
        end

        return prepare_entry(ctx, position, forced, target_id)
    end

    if feature == terrain.DNGN_EXIT_TROVE then
        if downstairs then
            return { message = "There are no stairs down here." }
        end

        return prepare_exit(ctx, position)
    end

    return nil
end

-- Rebuild the price shape from the saved gate and recheck the source
-- witness after staging but before changing the inventory or worship.
local function validate_gate(ctx, site, entity, gate)
    if not entity or gate.spent or
        gate.level_id ~= site.level_id or
        gate.x ~= site.x or gate.y ~= site.y or
        ctx:cell(site.level_id, site.x, site.y) ~=
            terrain.DNGN_ENTER_TROVE then
        error("Treasure Trove entrance changed during travel")
    end

    local price = {
        kind = gate.price_kind,
        item_id = gate.item_id,
        quantity = gate.quantity,
        minimum_plus = gate.minimum_plus,
        ego_id = gate.ego_id,
        artefact_name = gate.artefact_name,
        source_rune_index = gate.source_rune_index,
    }

    if toll.encode(price) ~= gate.price_witness or
        not marker_matches(ctx, gate) then
        error("Treasure Trove price witness changed during travel")
    end
end

-- A successful staging pass makes payment, closure, visit, and movement
-- one reversible command. The item match is made again after staging.
local function commit_entry(ctx, input)
    local site = input.source
    local destination = input.destination
    local entity, gate = portal.at(ctx, site.level_id, site.x, site.y)

    validate_gate(ctx, site, entity, gate)

    local player = ctx:player()
    local accepted, reason = payment.match(ctx, player, gate)

    if not accepted then
        error(reason or "Treasure Trove payment changed during staging")
    end

    local receipt = payment.commit(ctx, player, gate, accepted)

    ctx:add(player, component.PLAYER_TROVE_VISIT, {
        origin_level_id = site.level_id,
        origin_x = site.x,
        origin_y = site.y,
        level_id = destination.level_id,
        vault_id = input.vault_id,
    })

    gate.spent = true
    gate.closure_reason = trove.CLOSURE_PAID
    gate.receipt_kind = receipt.kind
    gate.receipt_item_id = receipt.item_id
    gate.receipt_quantity = receipt.quantity
    gate.destination_id = input.vault_id
    ctx:set(entity, component.WORLD_TROVE_PORTAL, gate)
    ctx:set_cell(site.level_id, site.x, site.y,
        terrain.DNGN_EXPIRED_PORTAL)
    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)

    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_TROVE)

    return { message = branch.entry_message }
end

-- Retire the temporary floor after moving back to the saved outside cell.
-- The outside gate remains spent and cannot create a second room.
local function commit_exit(ctx, input)
    local destination = input.destination
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_TROVE_VISIT)

    if not visit or visit.level_id ~= input.source.level_id or
        visit.origin_level_id ~= destination.level_id or
        visit.origin_x ~= destination.x or
        visit.origin_y ~= destination.y then
        error("Treasure Trove return site changed during travel")
    end

    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)
    ctx:remove(player, component.PLAYER_TROVE_VISIT)

    return { message = "You return from the treasure trove." }
end

-- The kernel has already checked the staged landing, and this callback
-- repeats the check before its first ECS write for changed destinations.
function travel.commit(ctx, input)
    local destination = input.destination

    if not destination or
        not ctx:walkable(destination.level_id,
            destination.x, destination.y) or
        ctx:actor_at(destination.level_id,
            destination.x, destination.y) then
        error("Treasure Trove destination is unavailable")
    end

    if input.operation == "enter" then
        return commit_entry(ctx, input)
    end

    if input.operation == "return" then
        return commit_exit(ctx, input)
    end

    error("unknown Treasure Trove travel operation")
end

register.policy({
    id = "world.trove.commit_travel",
    run = travel.commit,
})

return travel
