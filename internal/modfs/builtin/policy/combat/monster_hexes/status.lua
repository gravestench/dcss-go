local component = require("constants.component")
local vault_enchantments = require("policy.monsters.vault_enchantments")
local enchantments = require("constants.vault_monster_enchantments")

local status = {}

local fields = {
    "corona_aut",
    "anchor_aut",
    "poison_vuln_aut",
    "sap_aut",
    "no_cast_aut",
}

-- Read one field of the shared hex component without treating an expired
-- sibling status as active.
local function active(ctx, actor, field)
    local state = ctx:get(actor, component.HEX_STATUS)

    return state ~= nil and state[field] > 0
end

-- Hex durations share one component; reapplication adds time up to each effect's cap.
local function extend(ctx, actor, field, added, maximum)
    local state = ctx:get(actor, component.HEX_STATUS)
    local existed = state ~= nil

    state = state or {
        corona_aut = 0,
        anchor_aut = 0,
        poison_vuln_aut = 0,
        sap_aut = 0,
        no_cast_aut = 0,
    }

    state[field] = math.min(maximum, state[field] + added)

    if existed then
        ctx:set(actor, component.HEX_STATUS, state)
    else
        ctx:add(actor, component.HEX_STATUS, state)
    end
end

-- Invisibility checks Corona through this live field, not the mere presence
-- of another hex in the shared component.
function status.backlit(ctx, actor)
    return active(ctx, actor, "corona_aut")
end

-- Translocation forbids movement while the saved Anchor timer is positive.
function status.anchored(ctx, actor)
    return active(ctx, actor, "anchor_aut")
end

-- Poison resistance consumers apply Virulence only during its active timer.
function status.poison_vulnerable(ctx, actor)
    return active(ctx, actor, "poison_vuln_aut")
end

-- Spellcasting consequences consult the Sap Magic timer independently.
function status.sapped(ctx, actor)
    return active(ctx, actor, "sap_aut")
end

-- Hexed actors cannot cast until No Cast expires, even if Corona persists.
function status.cannot_cast(ctx, actor)
    return active(ctx, actor, "no_cast_aut")
end

-- Example: status.corona(ctx, monster, 100) adds backlighting, capped at
-- 2500 AUT so repeated casts cannot grow an unbounded save value.
function status.corona(ctx, actor, duration_aut)
    extend(ctx, actor, "corona_aut", duration_aut, 2500)
end

-- Anchor uses a shorter 500 AUT cap because movement denial has its own rule.
function status.anchor(ctx, actor, duration_aut)
    extend(ctx, actor, "anchor_aut", duration_aut, 500)
end

-- Virulence extends only its field, preserving Corona or Sap Magic timers.
function status.poison_vulnerability(ctx, actor, duration_aut)
    extend(ctx, actor, "poison_vuln_aut", duration_aut, 500)
end

-- Sap Magic reapplication adds time rather than replacing a longer duration.
function status.sap_magic(ctx, actor, duration_aut)
    extend(ctx, actor, "sap_aut", duration_aut, 500)
end

-- No Cast shares the 500 AUT cap but cannot reset other hex fields.
function status.no_cast(ctx, actor, duration_aut)
    extend(ctx, actor, "no_cast_aut", duration_aut, 500)
end

-- Duration fields tick together so expired hex effects cannot survive save/restore.
-- Advance all fields in one write, then remove the component if none remain.
function status.tick(ctx, actor, elapsed)
    local state = ctx:get(actor, component.HEX_STATUS)

    if not state or elapsed <= 0 then
        return
    end

    local remaining = false

    for _, field in ipairs(fields) do
        if field ~= "corona_aut" or not
            vault_enchantments.active(ctx, actor, enchantments.CORONA) then
            state[field] = math.max(0, state[field] - elapsed)
        end
        remaining = remaining or state[field] > 0
    end

    if remaining then
        ctx:set(actor, component.HEX_STATUS, state)
    else
        ctx:remove(actor, component.HEX_STATUS)
    end
end

return status
