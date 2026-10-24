-- Theory of operation: Kiku's first active power pays a source divine cost
-- and calls the wretch owner. The latter creates real corpse-bearing monsters
-- whose short lifecycle can feed later Necromancy effects.
local abilities = require("ids.abilities")
local channels = require("constants.message_channels")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local kiku = require("constants.kikubaaqudgha")
local registry = require("policy.abilities.registry")
local wretches = require("policy.religion.kikubaaqudgha.wretches")

local unearth = {}

-- One piety star grants this power only while Kiku currently accepts the
-- worshipper. The registry rechecks it when the queued action resolves.
function unearth.available(ctx, player)
    return costs.available(ctx, player, gods.KIKUBAAQUDGHA,
        kiku.WRETCH_RANK)
end

-- Reject an empty MP pool before taking any player time.
function unearth.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, kiku.WRETCH_MP) then
        return "You do not have enough magic."
    end

    return nil
end

-- Successful invocation pays even when nearby terrain offers no room;
-- the source explicitly reports that outcome rather than refunding it.
function unearth.resolve(ctx, player)
    if costs.failed(ctx, player, kiku.WRETCH_FAIL_BASE,
        kiku.WRETCH_FAIL_SCALE, kiku.WRETCH_FAIL_PIETY) then
        ctx:emit(channels.RELIGION, "You fail to use your ability.")

        return
    end

    local created = wretches.invoke(ctx, player)

    if created == 0 then
        ctx:emit(channels.RELIGION,
            "Kikubaaqudgha has no space to call forth the wretched!")
    else
        ctx:emit(channels.RELIGION,
            "Kikubaaqudgha calls piteous wretches from the earth!")
    end

    costs.spend(ctx, player, kiku.WRETCH_MP,
        costs.piety_cost(ctx, kiku.WRETCH_PIETY))
end

-- The menu shows the same radius-two footprint used by the placement owner.
function unearth.range()
    return kiku.WRETCH_RADIUS
end

registry.add(abilities.KIKU_UNEARTH_WRETCHES, {
    name = "Unearth Wretches",
    available = unearth.available,
    prepare = unearth.prepare,
    resolve = unearth.resolve,
    range = unearth.range,
})

return unearth
