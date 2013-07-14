# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "hiera-crypt"
  spec.version       = "0.1"
  spec.authors       = ["Carl Jackson"]
  spec.email         = ["carl@avtok.com"]
  spec.description   = "Encrypted file backend for Hiera"
  spec.summary       = "A data backend for Hiera that returns the decrypted " +
                       "contents of files. Useful for secrets."
  spec.homepage      = "https://github.com/zenazn/hiera-crypt"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "hiera", ">= 1.2.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
