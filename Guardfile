guard :minitest, autorun: false do
  watch(%r{^spec/(.*)_spec\.rb})

  watch(%r{^lib/(.+)\.rb}) { 'spec' }
  watch(%r{^spec/support/(.+)\.rb}) { 'spec' }
  watch(%r{^spec/spec_helper\.rb}) { 'spec' }
end

guard 'rubocop', run_all: false, cli: ['--auto-correct'] do
  watch(%r{^lib/(.+)\.rb})
  watch(%r{^spec/(.+)\.rb})
end
