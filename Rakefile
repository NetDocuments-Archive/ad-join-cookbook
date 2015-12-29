require 'foodcritic'

FoodCritic::Rake::LintTask.new(:foodcritic) do |fc|
  # fc.options = {context: true}
  fc.options = { fail_tags: %w(any) }
end

require 'rubocop/rake_task'

desc 'Run RuboCop on the lib directory'
RuboCop::RakeTask.new(:rubocop) do |task|
  # task.patterns = ['lib/**/*.rb']
  # only show the files with failures
  task.formatters = ['html']
  task.options = ['-orubocop.html']
  # don't abort rake on failure
  task.fail_on_error = false
end

task default: [:rubocop, :foodcritic]
