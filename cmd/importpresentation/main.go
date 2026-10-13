package main

import (
	"flag"
	"fmt"
	"os"

	"dcrawl-go/internal/content/presentationimport"
)

func main() {
	source := flag.String("source", "", "pinned crawl-ref/source directory")
	out := flag.String("out", "", "committed presentation artifact path")
	check := flag.Bool("check", false, "verify output without writing")
	flag.Parse()
	if err := presentationimport.Write(*source, *out, *check); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
