package content

import (
	"encoding/json"
	"testing"
)

func TestDefaultItemManifest(t *testing.T) {
	catalog, err := LoadItemsForImport()
	if err != nil {
		t.Fatal(err)
	}
	if len(catalog.ItemIDs()) != 408 || len(catalog.items) != 368 {
		t.Fatalf("item coverage: identities=%d definitions=%d", len(catalog.ItemIDs()), len(catalog.items))
	}
	ration, err := catalog.Item("FOOD_RATION")
	if err != nil {
		t.Fatal(err)
	}
	if ration.Name != "removed food" || ration.PropertyName != "buggy ration" {
		t.Fatalf("food display/property names were conflated: %+v", ration)
	}
	if _, err := catalog.Item("POT_GAIN_STRENGTH"); err == nil {
		t.Fatal("known undefined legacy item became instantiable")
	}
	if _, err := catalog.ItemIdentity("POT_GAIN_STRENGTH"); err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		name                   string
		itemData, identityData []byte
	}{
		{"bad item bytes", []byte(`{"items":`), defaultItemIdentitiesJSON},
		{"bad identity bytes", defaultItemsJSON, []byte(`{"identities":`)},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if _, _, err := loadItemPair(tc.itemData, tc.identityData); err == nil {
				t.Fatal("bad artifact pair accepted")
			}
		})
	}
	var artifact ItemArtifact
	if err := json.Unmarshal(defaultItemsJSON, &artifact); err != nil {
		t.Fatal(err)
	}
	artifact.Items[0].ID = "ARM_SUBSTITUTED"
	changed, err := json.Marshal(artifact)
	if err != nil {
		t.Fatal(err)
	}
	if _, _, err := loadItemPair(changed, defaultItemIdentitiesJSON); err == nil {
		t.Fatal("substituted item accepted")
	}
}
