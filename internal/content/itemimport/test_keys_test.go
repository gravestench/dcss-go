package itemimport

func itemKeyFor(classID, subtypeID string) itemKey {
	return itemKey{
		ClassID:   classID,
		SubtypeID: subtypeID,
	}
}
