$: << File.join( File.dirname( __FILE__ ), '../lib/')
require 'pgn2fen'
require 'test/unit'

class Pgn2FenTest < Test::Unit::TestCase

  def test_simple
    pgn = %{
[Event "Rapperswil, Switzerland"]
[Site "Rapperswil, Switzerland"]
[Date "1955.??.??"]
[EventDate "?"]
[Round "?"]
[Result "1-0"]
[White "Martin"]
[Black "Pompei"]
[ECO "C45"]
[WhiteElo "?"]
[BlackElo "?"]
[PlyCount "41"]

1. e4 e5 2. Nf3 Nc6 3. d4 exd4 4. Bc4 Bc5 5. O-O d6 6. c3 dxc3
7. Nxc3 Be6 8. Nd5 Qd7 9. a3 Ne5 10. Nxe5 dxe5 11. Qb3 c6
12. Rd1 Bd4 13. Be3 O-O-O 14. Rac1 Kb8 15. Rxd4 exd4 16. Bf4+
Kc8 17. Qa4 Bxd5 18. exd5 Qg4 19. g3 Ne7 20. dxc6 Nxc6 21. Ba6
1-0
}
    validate_fen_array(Pgn2Fen::Game.new(pgn).parse_pgn().fen_array)
  end

  def test_pawn_capture_two_ways
    pgn = %{
[Event "Enpassent Test"]
[Site ""]
[Date ""]
[Round ""]
[White ""]
[Black ""]
[Result "0-1"]
[WhiteElo ""]
[BlackElo ""]

1.e4 c5 2.Nf3 Nc6 3.Bb5 e6 4.Bxc6 bxc6 5.b3 Ne7 6.Bb2 Ng6 7.h4 h5 8.e5 Be7
9.Nc3 d5 0-1
}
    validate_fen_array(Pgn2Fen::Game.new(pgn).parse_pgn().fen_array)
  end

  def test_promotion_via_capture
    pgn = %{
[Event "Enpassent Test"]
[Site ""]
[Date ""]
[Round ""]
[White ""]
[Black ""]
[Result "0-1"]
[WhiteElo ""]
[BlackElo ""]

1.e4 f5 2.exf5 e6 3.fxe6 Ke7 4.exd7 Qe8 5.dxc8=Q 0-1
}
    validate_fen_array(Pgn2Fen::Game.new(pgn).parse_pgn().fen_array)
  end

  def test_promotion
    pgn = %{
[Event "Enpassent Test"]
[Site ""]
[Date ""]
[Round ""]
[White ""]
[Black ""]
[Result "0-1"]
[WhiteElo ""]
[BlackElo ""]

1.e4 f5 2.exf5 g6 3.fxg6 Nf6 4.g7 h6 5.g8=Q 0-1
}
    validate_fen_array(Pgn2Fen::Game.new(pgn).parse_pgn().fen_array)
  end

  def validate_fen_array(fen_array)
    fen_array.each {|fen|
      assert_equal true, validate_fen(fen) 
    }
  end

  # borrowed some ideas/code from the excellent https://github.com/jhlywa/chess.js 
  def validate_fen fen
    tokens = fen.split
    # check has required fields
    unless tokens.length == 6
      raise 'FEN string must contain six space-delimited fields.'
    end
    # check board layout
    board_rows = tokens[0].split('/')
    unless board_rows.length == 8
      raise 'numbers of rows in piece placement field must be 8.'
    end
    board_rows.each {|row|
      sum = 0
      atoms = row.split("");
      atoms.each {|atom|
        if atom =~ /\b[0-8]\b/
          sum += atom.to_i 
        elsif atom =~ /\b[a-z]|[A-Z]\b/
          sum += 1
        else
          raise "invalid character #{atom} in piece placement row."
        end
      }
      unless sum == 8
        raise "row #{row} too large in piece placement field."
      end
    }
    # check active color field is "w" or "b"
    unless tokens[1] =~ /^(w|b)$/
      raise "active color field needs to be w or b."
    end
    # check castling availability field
    unless tokens[2] =~ /^(KQ?k?q?|Qk?q?|kq?|q|-)$/
      raise "castling availability field is incorrect."
    end
    # check enpassent field
    unless tokens[3] =~ /^(-|[abcdefgh][36])$/
      raise "enpassent field is incorrect."
    end
    # check halfmove clock field is  >= 0
    unless tokens[4] =~ /\b[0-9]+\b/
      raise "halfmove clock field is incorrect."
    end
    # check fullmove number field is > 0
    unless tokens[5] =~ /\b[0-9]+\b/
      raise "fullmove number field is incorrect."
    end
    if tokens[5].to_i == 0
      raise "fullmove number field cannot be zero."
    end
    true
  end

end
