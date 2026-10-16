package main

import (
	"flag"
	"fmt"
	"os"

	"dcrawl-go/internal/vaultimport"
)

func main() {
	source := flag.String("source", "", "pinned DCSS arrival directory")
	ports := flag.String("ports", "internal/vaultimport/ports", "script port recipe directory")
	out := flag.String("out", "internal/modfs/builtin", "committed mod root")
	check := flag.Bool("check", false, "verify committed bytes without writing")
	flag.Parse()

	if err := vaultimport.Write(*source, *ports, *out, *check); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
