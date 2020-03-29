lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vagrant/devenv/version"

Gem::Specification.new do |spec|
    spec.name = "vagrant-devenv"
    spec.version = Vagrant::Devenv::VERSION
    spec.authors = ["Ben Fiola"]
    spec.summary = %q{Vagrant plugin that will bootstrap development environment VMs.}
    spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
        `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
    spec.require_paths = ["lib"]
    spec.add_dependency "thor", "~> 1.0", ">= 1.0.1"
    spec.add_development_dependency "bundler", "~> 1.17"
    spec.add_development_dependency "rake", "~> 10.0"
    spec.add_development_dependency "rspec", "~> 3.0"

    if spec.respond_to?(:metadata)
        spec.metadata["allowed_push_host"] = ""
    else
        raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
    end
end
