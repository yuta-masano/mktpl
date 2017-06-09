# {{BINARY}}

{{BINARY}} は YAML データを使って text/template の記法に従ったテンプレートを標準出力にレンダリングするコマンドラインツールです。

## Description

* コマンドオプションで YAML 形式のデータファイルと text/template スタイルのテンプレートファイルのパスを指定すると、標準出力にレンダリングされる。
* YAML データファイルではハッシュの値にキーを指定することができる。

## Motivation

* ロジックレスでシンプルなテンプレートエンジンの、[mustache](https://mustache.github.io/) というものがある。
* Bash で実装された CLI もあるが、データの受け渡しがシェル変数または環境変数としてしか渡せず、データが増えてくるとつらい。
* ロジックレスなテンプレートが売りだが、やっぱり多少はロジックを含めたい。

## Installation

[Releases ページ](https://github.com/yuta-masano/{{BINARY}}/releases)からダウンロードしてください。

あるいは、`go get` でも可能かもしれませんが、ライブラリパッケージは glide で vendoring しています。

```
$ go get github.com/yuta-masano/{{BINARY}}
```

## Usage

```
$ {{BINARY}} --help
{{HELP_OUT}}
```

## License

The MIT License (MIT)

{{#THANKS_OUT}}
## Thanks

{{BINARY}} uses the following packages. These packages are licensed under their own license.

{{THANKS_OUT}}

{{/THANKS_OUT}}
## Author

[Yuta MASANO](https://github.com/yuta-masano)

## Development

### セットアップ

```
$ # 1. リポジトリを取得。
$ go get -v -u -d github.com/yuta-masano/{{BINARY}}

$ # 2. リポジトリディレクトリに移動。
$ cd $GOPATH/src/github.com/yuta-masano/{{BINARY}}

$ # 3. 開発ツールと vendor パッケージを取得。
$ make deps-install

$ # 4. その他のターゲットは help をどうぞ。
$ make help
USAGE: make [target]

TARGETS:
help           show help
...
```

### リリースフロー

see: [yuta-masano/dp#リリースフロー](https://github.com/yuta-masano/dp#%E3%83%AA%E3%83%AA%E3%83%BC%E3%82%B9%E3%83%95%E3%83%AD%E3%83%BC)
