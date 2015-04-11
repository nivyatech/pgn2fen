# pgn2fen

Converts a single game chess PGN to an array of FEN strings. 
The FEN follows the specification as listed on [Forsyth–Edwards Notation](http://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation).

## Usage

```ruby
require 'pgn2fen'
fen_array = Pgn2Fen::Game.new(pgn_string).parse_pgn().fen_array
```

PGN header information is available in the Game object.

```ruby
require 'pgn2fen'
game = Pgn2Fen::Game.new(pgn_string)
game.parse_pgn()
#FEN Array
puts game.fen_array

#PGN Header
puts game.event
puts game.site
puts game.date
puts game.eventdate
puts game.round
puts game.white
puts game.black
puts game.whiteelo
puts game.blackelo
puts game.result
puts game.eco
puts game.plycount
puts game.fen
```

## Notes

All side lines are ignored - only main game is converted.
Only a single game PGN is supported right now. 

