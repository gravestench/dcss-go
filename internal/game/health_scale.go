package game

import "dcrawl-go/internal/ecs"

// DCSS calc_hp keeps current HP and fractional regeneration proportional
// when Fighting or experience level changes the maximum.
func rescaleHealth(
	health *ecs.Health,
	regeneration *ecs.Regeneration,
	nextMax int,
) {
	hundredths := (health.Current*100 + regeneration.HPProgress) *
		nextMax / health.Max
	hundredths = max(100, hundredths)

	health.Max = nextMax
	health.Current = min(nextMax, hundredths/100)
	regeneration.HPProgress = hundredths % 100
}
