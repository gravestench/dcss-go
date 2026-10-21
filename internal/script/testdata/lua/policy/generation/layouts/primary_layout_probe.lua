-- A wrapping layout must receive the exact builder and bounds supplied by
-- the generation owner, so it cannot guess a primary's source dimensions.
local probe = {}

-- A wrapping layout is eligible only when its owner has placed the source
-- primary first. The veto must run before geometry or stairs are mutated.
function probe.reject_without_primary(api)
    return not api.primary_vault
end

-- Assert the generation contract while using the real layout catalog path.
function probe.primary_layout_probe(api)
    if not api.builder or not api.primary_vault then
        error("wrapping layout lacks preplaced primary")
    end

    if api.primary_vault.x1 ~= 25 or api.primary_vault.y1 ~= 22 or
        api.primary_vault.x2 ~= 35 or api.primary_vault.y2 ~= 32 then
        error("wrapping layout received different primary bounds")
    end

    if not api.map_parameters or api.map_parameters[1] ~= "central" then
        error("wrapping layout lacks source central parameter")
    end

    return {
        builder = api.builder,
    }
end

return probe
