-- Save and live-link checks read the leader's own band declaration. A
-- follower remains a legal member after its leader's entity is gone.
local members = {}

-- Static bands list their source members in slots. A dynamic member
-- policy can expose `allows` for exact restore checks; older policies
-- without it still retain their declared band origin.
function members.allowed(profile, kind_id)
    if not profile then
        return false
    end

    if profile.member_policy then
        local policy = require(profile.member_policy)

        return not policy.allows or policy.allows(kind_id)
    end

    for _, slot in ipairs(profile.slots or {}) do
        for _, choice in ipairs(slot) do
            local id = type(choice) == "string" and choice or choice.id

            if id == kind_id then
                return true
            end
        end
    end

    return false
end

return members
