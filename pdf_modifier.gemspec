# frozen_string_literal: true

require_relative "lib/pdf_modifier/version"

Gem::Specification.new do |spec|
  spec.name = "pdf_modifier"
  spec.version = PdfModifier::VERSION
  spec.authors = ["Divyarajsinh solanki"]
  spec.email = ["divyaraj@atharvasystem.com"]

  spec.summary = "Write a short summary, because RubyGems requires one."
  spec.description = "Write a longer description or delete this line."
  spec.homepage = "https://github.com/Divyarajsinhsolanki/pdf_modifier"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 2.4.0"
  spec.add_dependency "prawn", "~> 2.4"
  spec.add_dependency "combine_pdf", "~> 1.0"
  spec.add_dependency "pdf-reader", "~> 2.9"
  spec.add_dependency "hexapdf", "~> 0.30"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://example.com"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile]) ||
        f.end_with?(".gem")
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
