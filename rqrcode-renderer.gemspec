# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rqrcode/renderer/version', __FILE__)

Gem::Specification.new do |gem|
  gem.author = "Samuel Cochran"
  gem.email = "sj26@sj26.com"
  gem.description = gem.summary
  gem.summary = %q{Render QR codes from Rails as images or SVG.}
  gem.homepage = "https://github.com/sj26/rqrcode-renderer"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.name          = "rqrcode-renderer"
  gem.require_paths = ["lib"]
  gem.version       = RQRCode::Renderer::VERSION

  gem.add_dependency 'activesupport'
  gem.add_dependency 'actionpack'
  gem.add_dependency 'rqrcode'
  gem.add_dependency 'rmagick'
  gem.add_dependency 'mime-types'
end
