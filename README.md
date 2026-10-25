# Redmine shadcn theme

A theme for Redmine 6 and 7 inspired by [shadcn/ui](https://ui.shadcn.com/). (Unofficial — not affiliated with shadcn/ui.)

- Applies the shadcn/ui design tokens (neutral) across Redmine
- Light and dark mode — follows your OS setting, with a toggle in the top menu
- Icons replaced with [Lucide](https://lucide.dev/)
- Covers issues, Gantt chart, calendar, time tracking, roadmap, admin pages and more
- Tested with Redmine 6.1.5 and 7.0.2

![Issues list](.github/screenshots/issues-light.png#gh-light-mode-only)
![Issues list](.github/screenshots/issues-dark.png#gh-dark-mode-only)

## Screenshots

| | Light | Dark |
|---|---|---|
| Issue | ![](.github/screenshots/issue-light.png) | ![](.github/screenshots/issue-dark.png) |
| Gantt chart | ![](.github/screenshots/gantt-light.png) | ![](.github/screenshots/gantt-dark.png) |
| Calendar | ![](.github/screenshots/calendar-light.png) | ![](.github/screenshots/calendar-dark.png) |

## Installation

Download `redmine-shadcn-theme-v*.zip` from [Releases](https://github.com/techolve/redmine-shadcn-theme/releases) and unzip it into Redmine's `themes/` directory. This creates `themes/shadcn/`.

```sh
cd /path/to/redmine/themes
unzip redmine-shadcn-theme-v0.2.2.zip
```

Or clone the repository:

```sh
cd /path/to/redmine/themes
git clone https://github.com/techolve/redmine-shadcn-theme.git shadcn
```

Restart Redmine, then select **Shadcn** in *Administration → Settings → Display → Theme*.

## Development

```sh
npm install
docker compose up -d                       # Redmine 6 at http://localhost:3000
docker compose --profile redmine7 up -d    # also Redmine 7 at http://localhost:3001

# Load sample data (log in as admin / admin1234)
docker compose exec -T redmine bundle exec rails runner - < src/tools/seed.rb
docker compose exec -T redmine7 bundle exec rails runner - < src/tools/seed.rb

npm run reload                             # build icons and CSS, then restart Redmine
npm run package                            # build the release zip into .dist/
```

Redmine 6 and 7 process assets at startup, so you need to restart Redmine after changing the CSS (`npm run reload`).

> Redmine serves every directory in the theme as assets, except `src/` and directories starting with a dot. Keep build-only files under `src/`.

### Project layout

```
src/                  Source files (not served by Redmine)
  tokens.css          shadcn/ui design tokens — edit this to change colors
  base.css            Text, links, headings
  icons.css           SVG icon color and stroke width
  layout.css          Header, menus, sidebar, footer
  forms.css           Inputs, buttons, login page
  components.css      Tables, tabs, alerts, pagination, wiki
  issues.css          Issue details and history
  views.css           Time tracking, admin pages, editor, jQuery UI and more
  gantt.css           Gantt chart (design inspired by ReUI's Gantt)
  calendar.css        Calendar (design inspired by ReUI's Event Calendar)
  redmine7.css        Components changed in Redmine 7 (top menu, account menu, etc.)
  dark.css            Dark mode tweaks, syntax highlighting, mode toggle
  tools/build-icons.mjs  Maps Redmine icon names to Lucide icons and generates images/icons.svg
  tools/seed.rb       Sample data for local testing
  tools/package.sh    Builds the release zip
stylesheets/          Build output loaded by Redmine (committed)
images/icons.svg      Build output: Lucide icon sprite (committed)
javascripts/theme.js  Dark mode toggle, Gantt chart row height and width adjustments
```

### Changing icons

Edit the mapping in [src/tools/build-icons.mjs](src/tools/build-icons.mjs) and run `npm run build`. Redmine icons that are not in the mapping keep Redmine's default icon.

### Stylesheet load order

`jstoolbar.css` and `context_menu.css` (and, in Redmine 7, `dropdown.css` and `gantt.css`) are loaded after the theme. To override them, the theme raises specificity with selectors such as `div#context-menu` or a `#content` prefix.

### Running Redmine 6 and 7 side by side

Browser cookies don't distinguish ports, so logging in to both `localhost:3000` and `localhost:3001` makes the sessions collide. Open one of them under a different host name, such as `127.0.0.1:3001`.

## Credits

- Design tokens: [shadcn/ui](https://ui.shadcn.com/) (MIT License)
- Icons: [Lucide](https://lucide.dev/) (ISC License)
- The Gantt chart and calendar designs are inspired by [ReUI](https://reui.io/)'s [Gantt](https://reui.io/components/gantt) and [Event Calendar](https://reui.io/components/event-calendar)

## License

[MIT License](LICENSE)
