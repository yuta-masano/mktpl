package main

import "os"

func main() {
	mktpl := &mktpl{
		outStream: os.Stdout,
		errStream: os.Stderr,
	}
	os.Exit(mktpl.Run(os.Args))
}
