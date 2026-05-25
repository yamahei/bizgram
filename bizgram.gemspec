require_relative "lib/bizgram/version"

Gem::Specification.new do |spec|
  spec.name          = "bizgram"
  spec.version       = Bizgram::VERSION
  spec.authors       = ["yamahei"]
  spec.email         = ["yamaorii@gmail.com"]

  spec.summary       = "A DSL for generating business model diagrams as SVG."
  spec.description   = "Bizgram provides an intuitive Ruby DSL to generate beautiful business model diagrams in SVG format."
  spec.homepage      = "https://github.com/yamahei/bizgram"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Add runtime dependencies here
  spec.add_dependency "rexml", "~> 3.2"

  # Add development dependencies here
  spec.add_development_dependency "rspec", "~> 3.0"
end
