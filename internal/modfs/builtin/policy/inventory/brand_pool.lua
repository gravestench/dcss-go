-- Source: item-use.cc:_rebrand_weapon. These weights belong to a scroll,
-- not to ordinary weapon generation tables.
local brands = require("constants.weapon_brands")
local ammunition = require("ids.ammunition")
local item_ids = require("ids.items")

local pool = {}

local melee = {
    {
        id = brands.FLAMING,
        weight = 2,
    },
    {
        id = brands.FREEZING,
        weight = 2,
    },
    {
        id = brands.VORPAL,
        weight = 2,
    },
    {
        id = brands.VENOM,
        weight = 2,
    },
    {
        id = brands.PROTECTION,
        weight = 2,
    },
    {
        id = brands.DRAINING,
        weight = 1,
    },
    {
        id = brands.ELECTROCUTION,
        weight = 1,
    },
    {
        id = brands.SPECTRAL,
        weight = 1,
    },
    {
        id = brands.VAMPIRISM,
        weight = 1,
    },
    {
        id = brands.CHAOS,
        weight = 1,
    },
}

local ranged = {
    {
        id = brands.FLAMING,
        weight = 3,
    },
    {
        id = brands.FREEZING,
        weight = 3,
    },
    {
        id = brands.VENOM,
        weight = 3,
    },
    {
        id = brands.VORPAL,
        weight = 3,
    },
    {
        id = brands.ELECTROCUTION,
        weight = 1,
    },
    {
        id = brands.CHAOS,
        weight = 1,
    },
}

local blessed = {
    [item_ids.WPN_BLESSED_FALCHION] = true,
    [item_ids.WPN_BLESSED_LONG_SWORD] = true,
    [item_ids.WPN_BLESSED_SCIMITAR] = true,
    [item_ids.WPN_BLESSED_TRIPLE_SWORD] = true,
    [item_ids.WPN_EUDEMON_BLADE] = true,
    [item_ids.WPN_SACRED_SCOURGE] = true,
}

function pool.eligible(kind)
    return kind.weapon ~= nil and not blessed[kind.id]
end

function pool.weights(kind)
    if kind.weapon.ammo_id ~= ammunition.NONE then
        return ranged
    end

    return melee
end

function pool.contains(kind, id)
    if not pool.eligible(kind) then
        return false
    end

    for _, entry in ipairs(pool.weights(kind)) do
        if entry.id == id then
            return true
        end
    end

    return false
end

function pool.roll(ctx, kind, old)
    local options = pool.weights(kind)
    local total = 0

    for _, entry in ipairs(options) do
        if entry.id ~= old then
            total = total + entry.weight
        end
    end

    local draw = ctx:random("item", total)

    for _, entry in ipairs(options) do
        if entry.id ~= old then
            if draw < entry.weight then
                return entry.id
            end

            draw = draw - entry.weight
        end
    end

    error("weapon brand pool failed to select")
end

return pool
