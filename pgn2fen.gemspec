# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'pgn2fen'
  s.version = '0.9.0'
  s.summary = %q{Converts a single game chess PGN to an array of FEN strings}
  s.description = <<-EOS
Converts a single game chess PGN to an array of FEN strings. 
The FEN follows the specification as listed on [Forsyth–Edwards Notation](http://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation).
  EOS
  s.authors = ["Vinay Doma"]
  s.email = %q{vinay.doma@gmail.com}
  s.license = "Ruby"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md",
    "TODO",
    "VERSION"
  ]
  s.files = Dir["**/*"] - Dir["*.gem"] - ["Gemfile.lock"]
  s.homepage = %q{http://github.com/nivyatech/pgn2fen}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
end
