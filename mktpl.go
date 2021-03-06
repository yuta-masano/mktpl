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

Flags (* is mandatory):
  -d, --data string       path to the YAML data file (*)
  -t, --template string   path to the template file (*)

  -h, --help              help for mktpl
  -v, --version           show program's version information and exit`

const (
	exitCodeOK int = 0
	// Errors start from 11.
	exitCodeError = 10 + iota
	exitCodeParseFlagsError
	exitCodeInvalidFlags
	exitCodeInvalidFilePath
	exitCodeParseTemplateError
)

// Flags
var (
	tplPath     string
	dataPath    string
	showHelp    bool
	showVersion bool
)

// version information
var (
	// These values are embedded when building.
	buildVersion  string
	buildRevision string
	buildWith     string
)

var re = regexp.MustCompile(`{{\s*-?\s*(\.?\w+\s*)+-?\s*}}`)

type mktpl struct {
	outStream, errStream io.Writer
}

func (m *mktpl) parseFlags(args []string) error {
	flags := flag.NewFlagSet(args[0], flag.ExitOnError)
	flags.SetOutput(m.errStream)
	flags.Usage = func() {
		fmt.Fprintf(m.errStream, "%s\n", helpText)
	}

	flags.StringVar(&dataPath, "d", "", "")
	flags.StringVar(&dataPath, "data", "", "")
	flags.StringVar(&tplPath, "t", "", "")
	flags.StringVar(&tplPath, "template", "", "")
	flags.BoolVar(&showHelp, "h", false, "")
	flags.BoolVar(&showHelp, "help", false, "")
	flags.BoolVar(&showVersion, "v", false, "")
	flags.BoolVar(&showVersion, "version", false, "")

	// Parse flag
	if err := flags.Parse(args[1:]); err != nil {
		return fmt.Errorf("%s", err)
	}
	return nil
}

// Run is the actual main function.
func (m *mktpl) Run(args []string) int {
	if err := m.parseFlags(args); err != nil {
		fmt.Fprintf(m.errStream, "faild in parsing flags: %s\n", err)
		return exitCodeParseFlagsError
	}

	if showHelp {
		fmt.Fprintf(m.outStream, "%s\n", helpText)
		return exitCodeOK
	}

	if showVersion {
		fmt.Fprintf(m.outStream, "version: %s\nrevision: %s\nwith: %s\n",
			buildVersion, buildRevision, buildWith)
		return exitCodeOK
	}

	if err := isValidFlags(); err != nil {
		fmt.Fprintf(m.errStream, "invalid flags: %s\n", err)
		return exitCodeInvalidFlags
	}

	data, err := ioutil.ReadFile(dataPath)
	if err != nil {
		fmt.Fprintf(m.errStream, "failed in reading the data file: %s\n", err)
		return exitCodeInvalidFilePath
	}

	t, err := ioutil.ReadFile(tplPath)
	if err != nil {
		fmt.Fprintf(m.errStream, "failed in reading the template file: %s\n", err)
		return exitCodeInvalidFilePath
	}

	tpl, err := parseTemplate(string(t))
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

func parseTemplate(text string) (*template.Template, error) {
	tpl, err := template.New("").Funcs(tplFuncMap).Parse(text)
	if err != nil {
		return nil, err
	}
	return tpl, nil
}

func isValidFlags() error {
	if len(tplPath) == 0 || len(dataPath) == 0 {
		return fmt.Errorf("omitting -d|--data and -t|--template flags is not allowed")
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
		tpl, err := parseTemplate(string(out))
		if err != nil {
			return nil, fmt.Errorf("failed in parsing the buffered template %s", err)
		}
		return render(data, tpl)
	}
	return out, nil
}
