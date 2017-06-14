package main

import "testing"

func TestIsValidFlags(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		t       string
		d       string
		v       bool
		isError bool
	}{
		{
			t:       "",
			d:       "",
			v:       false,
			isError: true,
		},
		{
			t:       "foo",
			d:       "",
			v:       false,
			isError: true,
		},
		{
			t:       "foo",
			d:       "bar",
			v:       false,
			isError: false,
		},
		{
			t:       "",
			d:       "",
			v:       true,
			isError: false,
		},
		{
			t:       "foo",
			d:       "",
			v:       true,
			isError: false,
		},
		{
			t:       "foo",
			d:       "bar",
			v:       true,
			isError: false,
		},
	}

	for i, c := range testCases {
		dataPath, tplPath, showVersion = c.d, c.t, c.v
		if err := isValidFlags(); (err == nil) == c.isError {
			t.Fatalf("[%d] invalid error state: expected=%t, but got=%t",
				i+1, c.isError, (err == nil) == c.isError)
		}
	}
}

func TestRender(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		inData string
		intpl  string
		expect string
	}{
		{
			inData: `TEST: test-01 . * ? %`,
			intpl:  `test = {{ .TEST }}`,
			expect: `test = test-01 . * ? %`,
		},
		{
			inData: `TEST: 'test-02 . * ? %'
TEST_NEST: '{{ .TEST }} nest'`,
			intpl:  `test = {{ .TEST_NEST }}`,
			expect: `test = test-02 . * ? % nest`,
		},
		{
			inData: `TEST_NEST: '{{ .TEST}} nest'
TEST: test-03`,
			intpl:  `test = {{ .TEST_NEST }}`,
			expect: `test = test-03 nest`,
		},
		{
			inData: `TEST: [test04, foo, bar, baz]`,
			intpl:  `test = {{ join .TEST "," }}`,
			expect: `test = test04,foo,bar,baz`,
		},
	}

	for i, c := range testCases {
		tpl, _ := parseTemplate(c.intpl)
		out, err := render([]byte(c.inData), tpl)
		if err != nil {
			t.Fatal(err)
		}
		if string(out) != c.expect {
			t.Fatalf("[%d] failed in templateing: expected=%s, but got=%s", i+1, c.expect, string(out))
		}
	}
}
