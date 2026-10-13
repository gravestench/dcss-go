package game

import (
	"fmt"

	"dcrawl-go/internal/content"
	"dcrawl-go/internal/ecs"
)

func (g *Game) createStartingGear(jobID, weaponID string) error {
	grants, err := g.catalog.StartingGrants(jobID)
	if err != nil {
		return err
	}
	if weaponID != "WPN_UNARMED" {
		grants = append([]content.StartingGrant{{Raw: weaponID, KindID: weaponID, Quantity: 1}}, grants...)
	}
	occupied := map[string]bool{}
	for _, grant := range grants {
		kind, err := g.catalog.Item(grant.KindID)
		if err != nil {
			return err
		}
		entity, err := g.world.CreateEntity()
		if err != nil {
			return err
		}
		if _, err := g.stores.Items.Set(entity, ecs.Item{KindID: kind.ID, Quantity: grant.Quantity, Plus: grant.Plus, Charges: grant.Charges, Ego: grant.Ego}); err != nil {
			return err
		}
		if _, err := g.stores.CarriedBy.Set(entity, ecs.CarriedBy{Holder: g.player}); err != nil {
			return err
		}
		if kind.Slot != "" && !occupied[kind.Slot] {
			if _, err := g.stores.Equipped.Set(entity, ecs.Equipped{Slot: kind.Slot}); err != nil {
				return err
			}
			occupied[kind.Slot] = true
		}
	}
	if !occupied["body"] || !occupied["shield"] || (weaponID != "WPN_UNARMED" && !occupied["weapon"]) {
		return fmt.Errorf("starting equipment lacks required Human/Fighter slots")
	}
	return nil
}
