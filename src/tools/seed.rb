# Sample data for local testing
#   docker compose exec -T redmine bundle exec rails runner - < src/tools/seed.rb
#   docker compose exec -T redmine7 bundle exec rails runner - < src/tools/seed.rb
#
# Safe to run more than once: each block only runs when its data is missing.

Redmine::DefaultData::Loader.load('en') unless Tracker.exists?

admin = User.find_by_login('admin')
admin.password = admin.password_confirmation = 'admin1234'
admin.must_change_passwd = false
admin.language = 'en'
admin.save!

Setting.ui_theme = 'shadcn'
Setting.default_language = 'en'
Setting.text_formatting = 'common_mark'
Setting.rest_api_enabled = '1'

project = Project.find_by_identifier('demo') || Project.create!(
  name: 'Demo project',
  identifier: 'demo',
  description: "A project for previewing the shadcn theme.\n\n- Issues\n- Wiki\n- Gantt chart",
  is_public: true,
  enabled_module_names: Redmine::AccessControl.available_project_modules.map(&:to_s),
  trackers: Tracker.all
)

if project.issues.empty?
  statuses = IssueStatus.all.to_a
  priorities = IssuePriority.all.to_a
  [
    'Redesign the login page',
    'Issue list filters are not saved',
    'Add pagination to API responses',
    'Tune the dark mode color palette',
    'Wiki markdown preview is broken',
    'Print layout for the Gantt chart',
    'Revise email notification wording',
    'Fix garbled characters in CSV export'
  ].each_with_index do |subject, i|
    Issue.create!(
      project: project,
      tracker: project.trackers[i % project.trackers.size],
      author: admin,
      assigned_to: i.even? ? admin : nil,
      subject: subject,
      description: "## Overview\n\n#{subject}.\n\n```ruby\nputs 'hello'\n```\n\n| Field | Value |\n|---|---|\n| Priority | High |",
      status: statuses[i % statuses.size],
      priority: priorities[i % priorities.size],
      start_date: Date.today - i,
      due_date: Date.today + (i * 3),
      done_ratio: (i * 15) % 100
    )
  end
  issue = project.issues.first
  issue.init_journal(admin, 'This is a sample comment with some `inline code`.')
  issue.save!
end

wiki = project.wiki || Wiki.create!(project: project, start_page: 'Wiki')
unless wiki.find_page('Wiki')
  page = WikiPage.new(wiki: wiki, title: 'Wiki')
  page.content = WikiContent.new(
    page: page, author: admin,
    text: "# Wiki\n\nA sample **wiki** page for the shadcn theme.\n\n> A blockquote\n\n- Item 1\n- Item 2\n\n```js\nconsole.log('hi')\n```"
  )
  page.save!
end

if project.versions.empty?
  v1 = project.versions.create!(name: 'v1.0', effective_date: Date.today + 7, description: 'First release')
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
        comments: "Work on: #{issue.subject}"
      )
    end
  end
end

# Issue relations and a parent issue, to check the Gantt chart
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
    project: project, author: admin, title: 'v1.0 released',
    summary: 'The release with the new shadcn theme',
    description: "## What's new\n\n- New theme\n- Dark mode\n\nSee the wiki for details."
  )
  news.comments.create!(author: admin, content: 'Congratulations!')
  News.create!(project: project, author: admin, title: 'Scheduled maintenance', description: 'The server will be under maintenance next weekend.')
end

if project.boards.empty?
  board = project.boards.create!(name: 'General', description: 'Talk about anything')
  project.boards.create!(name: 'Feature requests', description: 'Ideas for new features')
  topic = board.messages.create!(author: admin, subject: 'Thoughts on the new theme', content: "What do you think of the new theme?\n\n> Quotes work too")
  topic.children.create!(board: board, author: admin, subject: 'RE: Thoughts on the new theme', content: 'Looks great!')
end

# Git repository, to check the diff view
repo_path = '/usr/src/redmine/files/demo-repo'
unless File.directory?(repo_path)
  work = "#{repo_path}-work"
  sh = ->(cmd) { system(cmd, exception: true) }
  sh.("git init -q -b main #{work}")
  git = "git -C #{work} -c user.name='Redmine Admin' -c user.email=admin@example.net"
  File.write("#{work}/README.md", "# Demo\n\nA sample repository\n")
  File.write("#{work}/app.rb", "class App\n  def hello\n    puts 'hello'\n  end\nend\n")
  sh.("#{git} add -A && #{git} commit -q -m 'Initial commit'")
  File.write("#{work}/app.rb", "class App\n  # Say hello\n  def hello(name = 'world')\n    puts \"hello, \#{name}\"\n  end\n\n  def bye\n    puts 'bye'\n  end\nend\n")
  File.write("#{work}/README.md", "# Demo\n\nA sample repository\n\n## Usage\n\n`ruby app.rb`\n")
  sh.("#{git} add -A && #{git} commit -q -m 'Add a name argument to hello refs #1'")
  sh.("git clone -q --bare #{work} #{repo_path}")
end
unless project.repository
  repo = Repository::Git.create!(project: project, url: repo_path, identifier: 'demo', is_default: true)
  repo.fetch_changesets
end

puts 'seeded'
