package main

import "testing"

func TestIsValidFlags(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		d       string
		t       string
		v       bool
		isError bool
	}{
		{
			d:       "",
			t:       "",
			v:       false,
			isError: true,
		},
		{
			d:       "",
			t:       "foo",
			v:       false,
			isError: true,
		},
		{
			d:       "bar",
			t:       "foo",
			v:       false,
			isError: false,
		},
		{
			d:       "",
			t:       "",
			v:       true,
			isError: false,
		},
		{
			d:       "",
			t:       "foo",
			v:       true,
			isError: false,
		},
		{
			d:       "bar",
			t:       "foo",
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
		inTpl  string
		expect string
	}{
		{
			inData: `TEST: aaa . * ? %`,
			inTpl:  `test01 is {{ .TEST }}`,
			expect: `test01 is aaa . * ? %`,
		},
		{
			inData: `TEST: 'aaa . * ? %'
TEST_NEST: '{{ .TEST }} nest'`,
			inTpl:  `test02 is {{ .TEST_NEST }}`,
			expect: `test02 is aaa . * ? % nest`,
		},
		{
			inData: `TEST_NEST: '{{ .TEST}} nest'
TEST: aaa`,
			inTpl:  `test03 is {{ .TEST_NEST }}`,
			expect: `test03 is aaa nest`,
		},
		{
			inData: `TEST: [foo, bar, baz]`,
			inTpl:  `test04 is {{ join .TEST "," }}`,
			expect: `test04 is foo,bar,baz`,
		},
		{
			// 0... は 8 進数として解釈される。
			inData: `TEST: [foo, bar, baz, 1, '%.wer', 'hoge', '0123', 017]
TEST_NEST: '{{ join {{ .TEST }} "," }}'`,
			inTpl:  `test05 is {{ join .TEST "," }}`,
			expect: `test05 is foo,bar,baz,1,%.wer,hoge,0123,15`,
		},
	}

	for i, c := range testCases {
		tpl, err := parseTemplate(c.inTpl)
		if err != nil {
			t.Fatal(err)
		}
		out, err := render([]byte(c.inData), tpl)
		if err != nil {
			t.Fatal(err)
		}
		if string(out) != c.expect {
			t.Fatalf("[%d] failed in templateing: expected=%s, but got=%s",
				i+1, c.expect, string(out))
		}
	}
}
