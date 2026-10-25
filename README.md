# Redmine shadcn theme

[shadcn/ui](https://ui.shadcn.com/) のデザインを取り入れた Redmine 6 / 7 用のテーマです。（shadcn/ui 公式のものではありません）

- shadcn/ui のデザイントークン（neutral）を Redmine の画面に適用しています
- ライトモードとダークモードに対応しています（OS の設定に合わせて切り替わり、トップメニューのボタンでも切り替えられます）
- アイコンを [Lucide](https://lucide.dev/) に差し替えています
- チケット、ガントチャート、カレンダー、作業時間、ロードマップ、管理画面などに対応しています
- 動作確認済みのバージョン: Redmine 6.1.5 / 7.0.2

![チケット一覧](.github/screenshots/issues-light.png#gh-light-mode-only)
![チケット一覧](.github/screenshots/issues-dark.png#gh-dark-mode-only)

## スクリーンショット

| | ライト | ダーク |
|---|---|---|
| チケット | ![](.github/screenshots/issue-light.png) | ![](.github/screenshots/issue-dark.png) |
| ガントチャート | ![](.github/screenshots/gantt-light.png) | ![](.github/screenshots/gantt-dark.png) |
| カレンダー | ![](.github/screenshots/calendar-light.png) | ![](.github/screenshots/calendar-dark.png) |

## インストール

[リリース一覧](https://github.com/techolve/redmine-shadcn-theme/releases)から `redmine-shadcn-theme-v*.zip` をダウンロードして、Redmine の `themes/` に展開してください（`themes/shadcn/` ができます）。

```sh
cd /path/to/redmine/themes
unzip redmine-shadcn-theme-v0.2.1.zip
```

git で clone することもできます。

```sh
cd /path/to/redmine/themes
git clone https://github.com/techolve/redmine-shadcn-theme.git shadcn
```

Redmine を再起動してから、`管理` → `設定` → `表示` → `テーマ` で **Shadcn** を選んでください。

## 開発

```sh
npm install
docker compose up -d                       # Redmine 6 を起動（http://localhost:3000）
docker compose --profile redmine7 up -d    # Redmine 7 も起動（http://localhost:3001）

# サンプルデータを入れる（ログインは admin / admin1234）
docker compose exec -T redmine bundle exec rails runner - < src/tools/seed.rb
docker compose exec -T redmine7 bundle exec rails runner - < src/tools/seed.rb

npm run reload                             # アイコンと CSS をビルドして Redmine を再起動
npm run package                            # リリース用の zip を .dist/ に作る
```

Redmine 6 / 7 はアセットを起動時に処理するので、CSS を変更したら再起動が必要です（`npm run reload`）。

> テーマ直下の `src/` と「.」で始まるフォルダ以外は、Redmine がアセットとして配信します。ビルド用のファイルは必ず `src/` に置いてください。

### 構成

```
src/                  ソース一式（Redmine は src/ を配信しません）
  tokens.css          shadcn のデザイントークン（色を変えるならここ）
  base.css            文字・リンク・見出し
  icons.css           SVG アイコンの色・線の太さ
  layout.css          ヘッダー・メニュー・サイドバー・フッター
  forms.css           入力欄・ボタン・ログイン画面
  components.css      テーブル・タブ・メッセージ（Alert）・ページ送り・Wiki
  issues.css          チケット詳細・履歴
  views.css           作業時間・管理画面・エディタ・jQuery UI など
  gantt.css           ガントチャート（ReUI の Gantt を参考にしたデザイン）
  calendar.css        カレンダー（ReUI の Event Calendar を参考にしたデザイン）
  redmine7.css        Redmine 7 で変わった部品（トップメニュー・アカウントメニューなど）
  dark.css            ダークモードの追加調整・シンタックスハイライト・切り替えボタン
  tools/build-icons.mjs  Redmine のアイコン名と Lucide のアイコン名の対応表（images/icons.svg を生成）
  tools/seed.rb       ローカル確認用のサンプルデータ
  tools/package.sh    リリース用の zip を作るスクリプト
stylesheets/          ビルド結果（Redmine が読み込みます。コミットしてください）
images/icons.svg      ビルド結果（Lucide のアイコンスプライト。コミットしてください）
javascripts/theme.js  ダークモードの切り替え、ガントチャートの行の高さと横幅の調整
```

### アイコンを変えたいとき

[src/tools/build-icons.mjs](src/tools/build-icons.mjs) の対応表を編集して、`npm run build` を実行してください。対応表にない Redmine のアイコンは、Redmine 標準のものがそのまま使われます。

### 本体 CSS の読み込み順について

`jstoolbar.css` と `context_menu.css`（Redmine 7 では `dropdown.css` と `gantt.css` も）は、テーマより後に読み込まれます。そのため、これらを上書きするときは `div#context-menu` や `#content` を付けて詳細度を上げています。

### ローカルで 6 と 7 を同時に開くとき

ブラウザの Cookie はポート番号を区別しないので、`localhost:3000` と `localhost:3001` に同時にログインするとセッションがぶつかります。片方は `127.0.0.1:3001` のように、別のホスト名で開いてください。

## クレジット

- デザイントークン: [shadcn/ui](https://ui.shadcn.com/)（MIT License）
- アイコン: [Lucide](https://lucide.dev/)（ISC License）
- ガントチャートとカレンダーのデザインは [ReUI](https://reui.io/) の [Gantt](https://reui.io/components/gantt) と [Event Calendar](https://reui.io/components/event-calendar) を参考にしています

## ライセンス

[MIT License](LICENSE)
