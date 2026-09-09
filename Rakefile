# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

desc "Lint the .ai/ control plane and gate every change record"
task :ci do
  sh "ruby -Ilib exe/soft-foundry ci"
end

task default: %i[test ci]
