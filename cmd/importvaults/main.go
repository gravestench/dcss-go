package main

import (
	"flag"
	"fmt"
	"os"

	"dcrawl-go/internal/vaultimport"
)

func main() {
	familyName := flag.String("family", "arrival", "vault family: arrival or shop")
	source := flag.String("source", "", "pinned DCSS vault family directory")
	ports := flag.String("ports", "", "script port recipe directory")
	out := flag.String("out", "internal/modfs/builtin", "committed mod root")
	check := flag.Bool("check", false, "verify committed bytes without writing")
	flag.Parse()

	family := vaultimport.ArrivalFamily

	switch *familyName {
	case "arrival":
		if *ports == "" {
			*ports = "internal/vaultimport/ports"
		}

	case "shop":
		family = vaultimport.ShopFamily

		if *ports == "" {
			*ports = "internal/vaultimport/shop_ports"
		}

	default:
		fmt.Fprintln(os.Stderr, "unknown vault family", *familyName)
		os.Exit(2)
	}

	if err := vaultimport.WriteFamily(family, *source, *ports, *out, *check); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
