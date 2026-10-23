package game

import (
	"testing"

	"crawl/internal/terrain"
	"crawl/internal/vault"
)

// A local feature name changes the inspection label of matching terrain
// inside its source vault, without renaming an identical feature outside.
func TestVaultFeatureNameViewUsesPlacedBounds(t *testing.T) {
	level := &Level{
		width: 3,
		terrain: [][]terrain.ID{{
			terrain.GraniteStatue,
			terrain.GraniteStatue,
			terrain.GraniteStatue,
		}},
		vaultRecords: []vault.Record{{
			Kind: vault.KindFeatureName,
			Arguments: []vault.Argument{
				{
					Name:   "feature_id",
					Kind:   vault.ValueString,
					String: string(terrain.GraniteStatue),
				},

				{
					Name:   "name",
					Kind:   vault.ValueString,
					String: "ruined idol",
				},

				{
					Name: "bounds_x",
					Kind: vault.ValueInt,
					Int:  1,
				},

				{
					Name: "bounds_y",
					Kind: vault.ValueInt,
					Int:  0,
				},

				{
					Name: "bounds_width",
					Kind: vault.ValueInt,
					Int:  1,
				},

				{
					Name: "bounds_height",
					Kind: vault.ValueInt,
					Int:  1,
				},
			},
		}},
	}

	view := View{
		Cells: []CellView{
			{State: Visible},
			{State: Visible},
			{State: Visible},
		},
	}

	(&Game{}).fillFeatureNameView(&view, level)

	if view.Cells[0].Name != "" ||
		view.Cells[1].Name != "ruined idol" ||
		view.Cells[2].Name != "" {
		t.Fatalf("local feature name escaped its vault: %+v", view.Cells)
	}
}
