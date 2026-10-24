-- Xom's own action can be lethal even when he did not mean to kill a
-- worshipper. Source ouch.cc defers that death for an interested Xom;
-- xom.cc then restores the victim after the action has finished.
local channels = require("constants.message_channels")
local component = require("constants.component")
local gods = require("constants.gods")
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_records = require("policy.mutations.records")

local accidental_death = {}

-- Keep only the state Xom's source recovery can reverse. Copy records
-- because an effect may mutate the tables returned by the ECS context.
function accidental_death.capture(ctx, player, worship)
    local health = ctx:get(player, component.HEALTH)
    local form = ctx:get(player, component.PLAYER_FORM)
    local mutations = {}

    for _, entry in ipairs(mutation_records.list(ctx, player)) do
        local state = entry.state

        mutations[state.mutation_id] = {
            entity = entry.entity,
            state = {
                owner = player,
                mutation_id = state.mutation_id,
                innate = state.innate,
                acquired = state.acquired,
                temporary = state.temporary,
            },
        }
    end

    return {
        health = health and {
            current = health.current,
            max = health.max,
        },
        form = form and {
            form_id = form.form_id,
            remaining_aut = form.remaining_aut,
            power = form.power,
            appendage_mask = form.appendage_mask,
            uncancellable = form.uncancellable,
        },
        mutations = mutations,
        protected = worship.god_id == gods.XOM and
            ((worship.penance or {})[gods.XOM] or 0) == 0 and
            worship.gift_timeout > 0,
    }
end

-- Restore changed mutation ranks after a protected death. Keeping the
-- original entity IDs avoids breaking any saved owner references. The
-- mutation effect owner refreshes derived state after each rank change.
local function restore_mutations(ctx, player, before)
    local changed = {}

    for _, entry in ipairs(mutation_records.list(ctx, player)) do
        local id = entry.state.mutation_id
        local original = before[id]

        if not original then
            ctx:remove(entry.entity, component.MUTATION)
            changed[id] = true
        elseif entry.state.acquired ~= original.state.acquired or
            entry.state.temporary ~= original.state.temporary or
            entry.state.innate ~= original.state.innate then
            ctx:set(entry.entity, component.MUTATION, original.state)
            changed[id] = true
        end
    end

    for id, original in pairs(before) do
        if not mutation_records.find(ctx, player, id) then
            ctx:add(original.entity, component.MUTATION, original.state)
            changed[id] = true
        end
    end

    local ids = {}

    for id in pairs(changed) do
        ids[#ids + 1] = id
    end

    table.sort(ids)

    for _, id in ipairs(ids) do
        mutation_effects.changed(ctx, player, id)
    end
end

-- Interested Xom saves only his current worshippers. A bored or penitent
-- action remains lethal, and Felid's already scheduled revival takes
-- precedence over Xom claiming credit for the same death.
-- Example: after a bad spell drops HP to zero, Xom restores the HP and
-- form captured before the event when he was interested and unpenitent.
function accidental_death.resolve(ctx, player, before)
    if not before.protected or not before.health or
        before.health.current <= 0 then
        return false
    end

    local health = ctx:get(player, component.HEALTH)
    local lives = ctx:get(player, component.EXTRA_LIVES)

    if not health or health.current > 0 or
        (lives and lives.pending_revival) then
        return false
    end

    ctx:emit(channels.RELIGION, "You die...")
    ctx:emit(channels.RELIGION, "Xom revives you!")

    restore_mutations(ctx, player, before.mutations)

    local form = ctx:get(player, component.PLAYER_FORM)

    if before.form and form then
        ctx:set(player, component.PLAYER_FORM, before.form)
    elseif before.form then
        ctx:add(player, component.PLAYER_FORM, before.form)
    elseif form then
        ctx:remove(player, component.PLAYER_FORM)
    end

    health = ctx:get(player, component.HEALTH)
    health.max = before.health.max
    health.current = math.min(before.health.current, health.max)
    ctx:set(player, component.HEALTH, health)

    return true
end

return accidental_death
