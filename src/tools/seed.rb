# ローカル確認用のサンプルデータ
#   docker compose exec -T redmine bundle exec rails runner - < src/tools/seed.rb

Redmine::DefaultData::Loader.load('ja') unless Tracker.exists?

admin = User.find_by_login('admin')
admin.password = admin.password_confirmation = 'admin1234'
admin.must_change_passwd = false
admin.language = 'ja'
admin.save!

Setting.ui_theme = 'shadcn'
Setting.default_language = 'ja'
Setting.text_formatting = 'common_mark'
Setting.rest_api_enabled = '1'

project = Project.find_by_identifier('demo') || Project.create!(
  name: 'デモプロジェクト',
  identifier: 'demo',
  description: "shadcn テーマの見た目確認用プロジェクト。\n\n- チケット一覧\n- Wiki\n- ガントチャート",
  is_public: true,
  enabled_module_names: Redmine::AccessControl.available_project_modules.map(&:to_s),
  trackers: Tracker.all
)

if project.issues.empty?
  statuses = IssueStatus.all.to_a
  priorities = IssuePriority.all.to_a
  [
    'ログイン画面のデザインを刷新する',
    'チケット一覧のフィルタが保存されない',
    'API レスポンスのページネーション対応',
    'ダークモードの配色を調整する',
    'Wiki のマークダウンプレビューが崩れる',
    'ガントチャートの印刷レイアウト',
    'メール通知の文面を見直す',
    'CSV エクスポートの文字化け対応'
  ].each_with_index do |subject, i|
    Issue.create!(
      project: project,
      tracker: project.trackers[i % project.trackers.size],
      author: admin,
      assigned_to: i.even? ? admin : nil,
      subject: subject,
      description: "## 概要\n\n#{subject}。\n\n```ruby\nputs 'hello'\n```\n\n| 項目 | 値 |\n|---|---|\n| 優先度 | 高 |",
      status: statuses[i % statuses.size],
      priority: priorities[i % priorities.size],
      start_date: Date.today - i,
      due_date: Date.today + (i * 3),
      done_ratio: (i * 15) % 100
    )
  end
  issue = project.issues.first
  issue.init_journal(admin, 'コメントのサンプルです。`inline code` もあります。')
  issue.save!
end

wiki = project.wiki || Wiki.create!(project: project, start_page: 'Wiki')
unless wiki.find_page('Wiki')
  page = WikiPage.new(wiki: wiki, title: 'Wiki')
  page.content = WikiContent.new(
    page: page, author: admin,
    text: "# Wiki\n\nshadcn テーマの **Wiki** 表示サンプル。\n\n> 引用ブロック\n\n- リスト1\n- リスト2\n\n```js\nconsole.log('hi')\n```"
  )
  page.save!
end

if project.versions.empty?
  v1 = project.versions.create!(name: 'v1.0', effective_date: Date.today + 7, description: '最初のリリース')
  v2 = project.versions.create!(name: 'v1.1', effective_date: Date.today + 30)
  project.issues.order(:id).each_with_index do |issue, i|
    issue.update!(fixed_version: i < 5 ? v1 : v2)
  end
end

if TimeEntry.where(project: project).empty?
  activities = TimeEntryActivity.all.to_a
  project.issues.order(:id).each_with_index do |issue, i|
    2.times do |n|
      TimeEntry.create!(
        project: project, issue: issue, user: admin, author: admin,
        hours: [0.5, 1, 1.5, 2, 3][(i + n) % 5],
        spent_on: Date.today - (i + n),
        activity: activities[(i + n) % activities.size],
        comments: "#{issue.subject} の作業"
      )
    end
  end
end

# ガントの関連線・親チケットの確認用
issues = project.issues.order(:id).to_a
if IssueRelation.where(issue_from: issues).empty?
  IssueRelation.create!(issue_from: issues[3], issue_to: issues[7], relation_type: 'precedes')
  IssueRelation.create!(issue_from: issues[1], issue_to: issues[2], relation_type: 'blocks')
end
if issues[5].parent.nil?
  issues[5].update!(parent_issue_id: issues[6].id)
end

if project.news.empty?
  news = News.create!(
    project: project, author: admin, title: 'v1.0 をリリースしました',
    summary: 'shadcn テーマ対応版のリリースです',
    description: "## 変更点\n\n- テーマを刷新\n- ダークモード対応\n\n詳しくは Wiki を参照してください。"
  )
  news.comments.create!(author: admin, content: 'おめでとうございます！')
  News.create!(project: project, author: admin, title: 'メンテナンスのお知らせ', description: '来週末にサーバのメンテナンスを行います。')
end

if project.boards.empty?
  board = project.boards.create!(name: '雑談', description: '何でも気軽にどうぞ')
  project.boards.create!(name: '要望', description: '機能の要望はこちら')
  topic = board.messages.create!(author: admin, subject: 'テーマの感想', content: "新しいテーマどうですか？\n\n> 引用もできます")
  topic.children.create!(board: board, author: admin, subject: 'RE: テーマの感想', content: 'いい感じです！')
end

# Git リポジトリ（差分表示の確認用）
repo_path = '/usr/src/redmine/files/demo-repo'
unless File.directory?(repo_path)
  work = "#{repo_path}-work"
  sh = ->(cmd) { system(cmd, exception: true) }
  sh.("git init -q -b main #{work}")
  git = "git -C #{work} -c user.name='Redmine Admin' -c user.email=admin@example.net"
  File.write("#{work}/README.md", "# Demo\n\nサンプルリポジトリ\n")
  File.write("#{work}/app.rb", "class App\n  def hello\n    puts 'hello'\n  end\nend\n")
  sh.("#{git} add -A && #{git} commit -q -m 'Initial commit'")
  File.write("#{work}/app.rb", "class App\n  # 挨拶する\n  def hello(name = 'world')\n    puts \"hello, \#{name}\"\n  end\n\n  def bye\n    puts 'bye'\n  end\nend\n")
  File.write("#{work}/README.md", "# Demo\n\nサンプルリポジトリ\n\n## 使い方\n\n`ruby app.rb`\n")
  sh.("#{git} add -A && #{git} commit -q -m 'hello に引数を追加 refs #1'")
  sh.("git clone -q --bare #{work} #{repo_path}")
end
unless project.repository
  repo = Repository::Git.create!(project: project, url: repo_path, identifier: 'demo', is_default: true)
  repo.fetch_changesets
end

puts 'seeded'
