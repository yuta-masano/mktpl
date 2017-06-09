package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"regexp"
	"text/template"

	"gopkg.in/yaml.v2"
)

const helpText = `mktpl is a tool to render Golang text/template with template and YAML data files.

Usage:
  mktpl flags

Flags:
  -d, --data       path to the YAML data file (*)
  -t, --template   path to the template file (*)

  -h, --help       help for mktpl
  -v, --version    show program's version information and exit
`

const (
	exitCodeOK int = 0

	// Errors start at 11
	exitCodeError = 10 + iota
	exitCodeParseFlagsError
	exitCodeInvalidFlags
	exitCodeInvalidFilePath
	exitCodeParseTemplateError
)

var (
	// Flags
	tplPath     string
	dataPath    string
	showVersion bool

	// These values are embedded when building.
	buildVersion  string
	buildRevision string
	buildWith     string
)

var re = regexp.MustCompile(`{{[-.\s\w]+}}`)

type mktpl struct {
	outStream, errStream io.Writer
}

func (m *mktpl) parseFlags(args []string) error {
	flags := flag.NewFlagSet(args[0], flag.ExitOnError)
	flags.SetOutput(m.errStream)
	flags.Usage = func() {
		fmt.Fprint(m.errStream, helpText)
	}

	flags.StringVar(&dataPath, "d", "", "")
	flags.StringVar(&dataPath, "data", "", "")
	flags.StringVar(&tplPath, "t", "", "")
	flags.StringVar(&tplPath, "template", "", "")
	// help flags are skippable.
	flags.BoolVar(&showVersion, "v", false, "")
	flags.BoolVar(&showVersion, "version", false, "")

	// Parse flag
	if err := flags.Parse(args[1:]); err != nil {
		return fmt.Errorf("%s", err)
	}
	return nil
}

func (m *mktpl) Run(args []string) int {
	if err := m.parseFlags(args); err != nil {
		fmt.Fprintf(m.errStream, "faild in parsing flags: %s\n", err)
		return exitCodeParseFlagsError
	}

	if err := isValidFlags(); err != nil {
		fmt.Fprintf(m.errStream, "invalid flags: %s\n", err)
		return exitCodeInvalidFlags
	}

	if showVersion {
		fmt.Fprintf(m.outStream, "version: %s\nrevision: %s\nwith: %s\n",
			buildVersion, buildRevision, buildWith)
		return exitCodeOK
	}

	data, err := ioutil.ReadFile(dataPath)
	if err != nil {
		fmt.Fprintf(m.errStream, "failed in reading the data file: %s\n", err)
		return exitCodeInvalidFilePath
	}
	tpl, err := template.ParseFiles(tplPath)
	if err != nil {
		fmt.Fprintf(m.errStream, "failed in parsing the template file: %s\n", err)
		return exitCodeParseTemplateError
	}

	var out []byte
	if out, err = render(data, tpl); err != nil {
		fmt.Fprintf(m.errStream, "%s\n", err)
		return exitCodeError
	}
	fmt.Fprintf(m.outStream, "%s", string(out))
	return exitCodeOK
}

func isValidFlags() error {
	if (len(tplPath) == 0 || len(dataPath) == 0) && (showVersion == false) {
		return fmt.Errorf("omitting -d[--data] and -t[--template] flags is not allowed")
	}
	return nil
}

func render(data []byte, tpl *template.Template) ([]byte, error) {
	mappedData := make(map[interface{}]interface{})
	if err := yaml.Unmarshal(data, &mappedData); err != nil {
		return nil, fmt.Errorf("failed in unmarshalling the YAML data: %s", err)
	}

	buf := new(bytes.Buffer)
	if err := tpl.Execute(buf, mappedData); err != nil {
		return nil, fmt.Errorf("failed in rendering: %s", err)
	}

	out, err := ioutil.ReadAll(buf)
	if err != nil {
		return nil, fmt.Errorf("failed in reading the buffered text: %s", err)
	}
	if re.MatchString(string(out)) {
		tpl, err := template.New("").Parse(string(out))
		if err != nil {
			return nil, fmt.Errorf("failed in parsing the buffered template %s", err)
		}
		return render(data, tpl)
	}
	return out, nil
}
