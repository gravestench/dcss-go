-- Source DES writes a head count in a hydra display name. Parse that
-- source syntax once so catalog validation and placement cannot disagree.
local heads = {}
local word_counts = {
    one = 1,
    two = 2,
    three = 3,
    four = 4,
    five = 5,
    six = 6,
    seven = 7,
    eight = 8,
    nine = 9,
    ten = 10,
    eleven = 11,
    twelve = 12,
    thirteen = 13,
    fourteen = 14,
    fifteen = 15,
    sixteen = 16,
    seventeen = 17,
    eighteen = 18,
    nineteen = 19,
    twenty = 20,
}

-- Return nil for ordinary monsters and the count for a named hydra.
function heads.from_name(name)
    local prefix = name:match("^([%a%d]+)%-headed hydra$")

    if not prefix then
        return nil
    end

    local count = tonumber(prefix) or word_counts[prefix]

    if not count then
        error("unknown source hydra head count " .. prefix)
    end

    if count < 1 then
        error("source hydra head count must be positive")
    end

    -- Legacy get_hydra_spec clamps explicitly written counts above twenty.
    return math.min(20, count)
end

return heads
