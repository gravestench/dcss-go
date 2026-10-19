local gold_dust = {}

-- Gold dust's cloud record is the effect; exposure does not mutate an actor.
-- Example: gold dust remains a cloud entity but does not write a status to the standing actor.
function gold_dust.apply()
end

return gold_dust
