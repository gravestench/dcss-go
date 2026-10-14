local catalog = require("policy.catalog")
local items = require("policy.inventory.items")

local jobs = {}

for _, job in ipairs(require("data.starting_gear").jobs) do
    jobs[job.job_id] = job.grants
end

local function add_grant(ctx, player, grant, occupied)
    local kind = catalog.get("items", grant.kind_id)
    local item = {
        kind_id = kind.id,
        quantity = grant.quantity,
        plus = grant.plus or 0,
        charges = grant.charges or 0,
        ego = grant.ego or "",
    }

    items.validate(item, kind)

    local entity = ctx:create()
    ctx:add(entity, "core.item", item)
    ctx:add(entity, "core.carried_by", { holder = player })

    if kind.slot and kind.slot ~= "" and not occupied[kind.slot] then
        ctx:add(entity, "core.equipped", { slot = kind.slot })
        occupied[kind.slot] = true
    end
end

register.policy({
    id = "character.starting_gear",
    run = function(ctx, input)
        local grants = jobs[input.job_id]

        if not grants then
            error("unknown starting gear job " .. tostring(input.job_id))
        end

        local player = ctx:player()
        local occupied = {}

        -- The chosen weapon precedes the job's source-ordered grants.
        if input.weapon_id ~= "WPN_UNARMED" then
            add_grant(ctx, player, {
                kind_id = input.weapon_id,
                quantity = 1,
            }, occupied)
        end

        for _, grant in ipairs(grants) do
            add_grant(ctx, player, grant, occupied)
        end

        if not occupied.body or not occupied.shield or
            (input.weapon_id ~= "WPN_UNARMED" and not occupied.weapon) then
            error("starting equipment lacks required Fighter slots")
        end

        return {}
    end,
})
