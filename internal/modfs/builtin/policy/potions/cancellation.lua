local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")

local cancellation = {}

-- Source: duration-data.h marks these ported durations D_DISPELLABLE.
-- New status owners add their field here when they implement that flag.
local durations = {
    [component.DURATIONS] = {
        "haste_aut",
        "might_aut",
    },
    [component.PLAYER_STATUS] = {
        "swift_aut",
        "wereblood_aut",
        "silence_aut",
        "ice_armour_aut",
        "confusing_touch_aut",
        "portal_projectile_aut",
        "disjunction_aut",
        "vertigo_aut",
    },
    [component.POTION_BRILLIANCE] = { "remaining_aut" },
    [component.POTION_RESISTANCE] = { "remaining_aut" },
    [component.POTION_AMBROSIA] = { "remaining_aut" },
    [component.POTION_ATTRACTION] = { "remaining_aut" },
    [component.POTION_INVISIBILITY] = { "remaining_aut" },
    [component.AGILITY] = { "remaining_aut" },
    [component.ICY_DEFENSE] = { "remaining_aut" },
    [component.ZAP_FLIGHT] = { "remaining_aut" },
    [component.PLAYER_SLOW] = { "remaining_aut" },
    [zap_ids.component.PLAYER_CONFUSION] = { "remaining_aut" },
    [component.PLAYER_PETRIFICATION] = {
        "petrifying_aut",
        "petrified_aut",
    },
}

-- Detect at least one purgeable timer so a no-effect drink can be rejected.
local function active_fields(ctx, player)
    for id, fields in pairs(durations) do
        local state = ctx:get(player, id)

        if state then
            for _, field in ipairs(fields) do
                if state[field] and state[field] > 0 then
                    return true
                end
            end
        end
    end

    return false
end

-- Cancellation reduces selected timed effects rather than deleting their state outright.
local function shorten(ctx, player)
    local changed = false

    for id, fields in pairs(durations) do
        local state = ctx:get(player, id)

        if state then
            for _, field in ipairs(fields) do
                local minimum = id == component.ZAP_FLIGHT and 11 or
                    id == component.PLAYER_PETRIFICATION and
                    field == "petrifying_aut" and 0 or 1

                if state[field] and state[field] > minimum then
                    state[field] = minimum
                    changed = true
                end
            end

            ctx:set(player, id, state)
        end
    end

    return changed
end

-- Only a form that permits cancellation can be removed by this potion.
local function form_cancellable(ctx, player)
    local state = ctx:get(player, component.PLAYER_FORM)

    return state and state.remaining_aut > 0 and
        not state.uncancellable
end

-- Reject a no-effect drink before potion consumption.
function cancellation.available(ctx, player)
    local contamination = ctx:get(player,
        zap_ids.component.CONTAMINATION)

    return (contamination and contamination.amount > 0) or
        active_fields(ctx, player) or form_cancellable(ctx, player) or
        ctx:has(player, component.TELEPORT) or
        ctx:has(player, component.STICKY_FLAME)
end

-- Source: spl-goditem.cc:debuff_player. Most magical durations fall to
-- one aut; flight retains 11 aut to allow safe landing.
-- Example: Cancellation can shorten active buffs and reduce contamination in one potion action.
function cancellation.purge(ctx, player)
    local changed = shorten(ctx, player)
    local form = ctx:get(player, component.PLAYER_FORM)

    if form_cancellable(ctx, player) and form.remaining_aut > 1 then
        form.remaining_aut = 1
        ctx:set(player, component.PLAYER_FORM, form)
        changed = true
    end

    for _, id in ipairs({ component.TELEPORT,
        component.STICKY_FLAME }) do
        if ctx:has(player, id) then
            ctx:remove(player, id)
            changed = true
        end
    end

    if changed then
        ctx:emit("duration", "Your magical effects are unravelling.")
    end

    local contamination = ctx:get(player,
        zap_ids.component.CONTAMINATION)
    local contamination_loss = 1000 + ctx:random("potion", 4000)

    if contamination then
        contamination.amount = math.max(0,
            contamination.amount - contamination_loss)

        if contamination.amount == 0 then
            ctx:remove(player, zap_ids.component.CONTAMINATION)
        else
            ctx:set(player, zap_ids.component.CONTAMINATION,
                contamination)
        end
    end
end

return cancellation
