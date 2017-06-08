package main

import (
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"text/template"

	"gopkg.in/yaml.v2"
)

const helpText = `mktpl is a tool to render Golang text/template with template and YAML data files.

Usage:
  mktpl flags

Flags:
  -d, --data       path to the data YAML file (*)
  -t, --template   path to the template file (*)

  -h, --help       help for mktpl
  -v, --version    show program's version information and exit
`

var (
	// These values are embedded when building.
	buildVersion  string
	buildRevision string
	buildWith     string
)

type mktpl struct {
	outStream, errStream io.Writer
}

func (m *mktpl) render(dataPath, tplPath string) error {
	data, err := ioutil.ReadFile(dataPath)
	if err != nil {
		return fmt.Errorf("failed in reading the data file: %s", err)
	}

	mappedData := make(map[interface{}]interface{})
	if err = yaml.Unmarshal(data, &mappedData); err != nil {
		return fmt.Errorf("failed in %s", err)
	}

	tpl, err := template.ParseFiles(tplPath)
	if err != nil {
		return fmt.Errorf("failed in reading the template file %s", err)
	}

	if err = tpl.Execute(m.outStream, mappedData); err != nil {
		return fmt.Errorf("failed in rendering: %s", err)
	}
	return nil
}

func (m *mktpl) Run(args []string) int {
	flags := flag.NewFlagSet(args[0], flag.ExitOnError)
	flags.SetOutput(m.errStream)
	flags.Usage = func() {
		fmt.Fprint(m.errStream, helpText)
	}

	var (
		tplPath  string
		dataPath string

		showVersion bool
	)

	flags.StringVar(&dataPath, "d", "", "")
	flags.StringVar(&dataPath, "data", "", "")

	flags.StringVar(&tplPath, "t", "", "")
	flags.StringVar(&tplPath, "template", "", "")

	// help flags are skippable.

	flags.BoolVar(&showVersion, "v", false, "")
	flags.BoolVar(&showVersion, "version", false, "")

	// Parse flag
	if err := flags.Parse(args[1:]); err != nil {
		return 2
	}

	if len(tplPath) == 0 || len(dataPath) == 0 {
		fmt.Fprintf(m.errStream, "omitting -d[--data] and -t[--template] flags is not allowed\n")
		return 2
	}

	if showVersion {
		fmt.Fprintf(m.outStream, "version: %s\nrevision: %s\nwith: %s\n",
			buildVersion, buildRevision, buildWith)
		return 0
	}

	if err := m.render(dataPath, tplPath); err != nil {
		fmt.Fprintf(m.errStream, "%s\n", err)
		return 2
	}

	return 0
}
