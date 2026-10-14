package game

// registerSystems installs Lua systems in their declared order.
func registerSystems(g *Game) error {
	base := make([]systemSpec, 0, len(g.scripts.Systems()))

	for _, system := range g.scripts.Systems() {
		base = append(base, systemSpec{
			name:   system.Name,
			system: system,
			after:  system.After,
			before: system.Before,
		})
	}

	ordered, err := orderSystems(base)

	if err != nil {
		return err
	}

	for _, entry := range ordered {
		if _, err := g.world.AddSystem(entry.system); err != nil {
			return err
		}
	}

	return nil
}
