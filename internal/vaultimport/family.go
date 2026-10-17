package vaultimport

// Family identifies one pinned source collection and its committed mod path.
// These values are developer import settings, never runtime game state.
type Family struct {
	name        string
	sourcePath  string
	outputPath  string
	sourceFiles map[string]string
	wantNames   int
}

var ArrivalFamily = Family{
	name:       "arrival",
	sourcePath: "arrival",
	outputPath: "vaults/arrival",
	sourceFiles: map[string]string{
		"large.des":   "5ae5d53469dc5713c70a3c1a35e82d8b0807e038585225f9b5e8d9ecab91880b",
		"simple.des":  "9c1dcfac919d6ac52725692ca1a7f200909ace1f7be2c626db314c03de02d1d5",
		"small.des":   "65a73745881c73d1f861d70efc3aa5f1f9643914c1ceba5f5834e9abb0761847",
		"twisted.des": "4dbe0cf3c64a8d61ea22c8267aa0eeea3671ca75e40a2cd0c58b029a6f9a4e0d",
	},
	wantNames: 339,
}

var ShopFamily = Family{
	name:       "shop",
	sourcePath: "builder",
	outputPath: "vaults/shop",
	sourceFiles: map[string]string{
		"shops.des":      "4c5268cca221223c4c3ce8be64caec3f78cfd29327e5bfc0af544383b172132b",
		"alphashops.des": "235b3fbfa6adf9ac4ec9696894580cfff90afa1a9dd2de5c3680e0f9ddfb9965",
	},
	wantNames: 70,
}
