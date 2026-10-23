-- Exercise direct gift placement inside a real Game. The gameplay gate is
-- tested in Lua; this policy checks generic ECS save and restore of the
-- generated item and its god provenance.
local classes = require("ids.object_classes")
local gods = require("constants.gods")
local items = require("policy.religion.gifts.items")

local probe = {}

-- A newly generated Okawaru stack is placed at the actual player position.
function probe.run(ctx)
    local entity = items.grant(ctx, ctx:player(), classes.OBJ_MISSILES,
        gods.OKAWARU)

    if not entity then
        error("test floor rejected a direct god gift")
    end

    return {
        item_id = ctx:id(entity),
    }
end

register.policy({
    id = "test.religion_item_gift",
    run = probe.run,
})

return probe
