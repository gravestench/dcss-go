local classes = require("constants.mutation_classes")
local choices = require("constants.mutation_choices")
local transition = require("policy.mutations.transition")

local malmutate = {}

-- Source: player.cc:player::malmutate and mutation.cc:mutate. Quality is
-- selected before protection; heavy mutation can cause a removal instead.
function malmutate.apply(ctx, owner, reason)
    local choice = ctx:random("mutation", 5) == 0 and
        choices.ANY or choices.BAD

    return transition.grant_random(ctx, owner, choice,
        classes.ACQUIRED, false)
end

return malmutate
