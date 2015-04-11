require 'set'
#require 'byebug'

module Pgn2Fen

  class Game
    # constants
    START_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    HEADER_KEY_REGEX = /^\[([A-Z][A-Za-z]*)\s.*\]$/
    HEADER_VALUE_REGEX = /^\[[A-Za-z]+\s"(.*)"\]$/
    OPEN_PAREN = "("
    CLOSE_PAREN = ")"
    OPEN_BRACE = "{"
    CLOSE_BRACE = "}"

    # attr_accessors
#    attr_accessor :event, :site, :date, :eventdate, :round, :white, :black, :whiteelo, :blackelo, :result, :eco, :plycount, :fen
    attr_accessor :pgn, :fen_array
    attr_accessor :can_white_castle_kingside, :can_black_castle_kingside, :can_black_castle_queenside, :potential_enpassent_ply, :halfmove, :fullmove, :promotion, :promotion_piece, :board_color_from_fen

    #  Board Representation
    # (a8, 0)  (b8, 1)  (c8, 2)  (d8, 3)   (e8, 4)   (f8, 5)   (g8, 6)   (h8, 7)
    # (a7, 8)  (b7, 9)  (c7,10)  (d7,11)   (e7,12)   (f7,13)   (g7,14)   (h7,15)
    # (a6,16)  (b6,17)  (c6,18)  (d6,19)   (e6,20)   (f6,21)   (g6,22)   (h6,23)
    # (a5,24)  (b5,25)  (c5,26)  (d5,27)   (e5,28)   (f5,29)   (g5,30)   (h5,31)
    # (a4,32)  (b4,33)  (c4,34)  (d4,35)   (e4,36)   (f4,37)   (g4,38)   (h4,39)
    # (a3,40)  (b3,41)  (c3,42)  (d3,43)   (e3,44)   (f3,45)   (g3,46)   (h3,47)
    # (a2,48)  (b2,49)  (c2,50)  (d2,51)   (e2,52)   (f2,53)   (g2,54)   (h2,55)
    # (a1,56)  (b1,57)  (c1,58)  (d1,59)   (e1,60)   (f1,61)   (g1,62)   (h1,63)

    # static initializers
    @@pgn_squares = ["a8","b8","c8","d8","e8","f8","g8","h8","a7","b7","c7","d7","e7","f7","g7","h7","a6","b6","c6","d6","e6","f6","g6","h6","a5","b5","c5","d5","e5","f5","g5","h5","a4","b4","c4","d4","e4","f4","g4","h4","a3","b3","c3","d3","e3","f3","g3","h3","a2","b2","c2","d2","e2","f2","g2","h2","a1","b1","c1","d1","e1","f1","g1","h1"];

    @@number_squares = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63]

    @@pgn_number_hash = Hash[@@pgn_squares.zip(@@number_squares)]
    @@number_pgn_hash = Hash[@@number_squares.zip(@@pgn_squares)]

    @@aFile = Set.new; @@bFile = Set.new; @@cFile = Set.new; @@dFile = Set.new;
    @@eFile = Set.new; @@fFile = Set.new; @@gFile = Set.new; @@hFile = Set.new;

    (0...8).each {|i|
      @@aFile.add(i * 8 + 0)
      @@bFile.add(i * 8 + 1)
      @@cFile.add(i * 8 + 2)
      @@dFile.add(i * 8 + 3)
      @@eFile.add(i * 8 + 4)
      @@fFile.add(i * 8 + 5)
      @@gFile.add(i * 8 + 6)
      @@hFile.add(i * 8 + 7)
    }

    @@firstRank = Set.new; @@secondRank = Set.new; @@thirdRank = Set.new; @@fourthRank = Set.new;
    @@fifthRank = Set.new; @@sixthRank = Set.new; @@seventhRank = Set.new; @@eighthRank = Set.new;

    (0...8).each {|i|
      @@firstRank.add(8 * 7 + i)
      @@secondRank.add(8 * 6 + i)
      @@thirdRank.add(8 * 5 + i)
      @@fourthRank.add(8 * 4 + i)
      @@fifthRank.add(8 * 3 + i)
      @@sixthRank.add(8 * 2 + i)
      @@seventhRank.add(8 * 1 + i)
      @@eighthRank.add(8 * 0 + i)
    }

    @@light_squares = Set.new
    @@dark_squares = Set.new

    [ 0, 2, 4, 6, 
      9, 11, 13, 15,
      16, 18, 20, 22,
      25, 27, 29, 31,
      32, 34, 36, 38,
      41, 43, 45, 47,
      48, 50, 52, 54,
      57, 59, 61, 63 ].each {|i| 
      @@light_squares.add(i)
    }

    [ 1, 3, 5, 7, 
      8, 10, 12, 14,
      17, 19, 21, 23,
      24, 26, 28, 30,
      33, 35, 37, 39,
      40, 42, 44, 46,
      49, 51, 53, 55,
      56, 58, 60, 62 ].each {|i| 
      @@dark_squares.add(i)
    }

    @@one_thru_eight = Set.new
    @@a_thru_h = Set.new
    
    ('1'..'8').each {|i| @@one_thru_eight.add(i)}
    ('a'..'h').each {|i| @@a_thru_h.add(i)}

    def initialize(pgn_data)
      @pgn_data = pgn_data
      @board = []
      @board_start_fen = START_FEN
      @fen = nil
      @potential_enpassent_ply = nil
      @halfmove = 0
      @fullmove = 1
      @promotion = false
      @promotion_piece = nil
      @board_color_from_fen = nil
    end

    def reset_castle_options(option)
      @can_white_castle_kingside = option
      @can_white_castle_queenside = option
      @can_black_castle_kingside = option
      @can_black_castle_queenside = option
    end


    def parse_headers(headers)
      #puts headers
      headers.each {|header|
        key = HEADER_KEY_REGEX.match(header)[1]
        value = HEADER_VALUE_REGEX.match(header)[1]
        instance_variable_set(:"@#{key.downcase.to_sym}", value)
      }
    end

    def parse_pgn
      unless is_single_game
        raise Pgn2FenError, 'Only a single game PGN is supported right now.'
      end
      headers = []
      @pgn_data.strip!
      pgn_data_array = @pgn_data.split("\n")
      pgn_data_array.each {|line|
        if line.index("[") == 0
          headers << line
        else
          break
        end
      }
      parse_headers(headers)
      pgn_data_array = pgn_data_array[headers.size..-1]
      # get pgn
      @pgn = ""
      pgn_data_array.each {|line|
          @pgn = pgn.concat(line).concat(" ")
      }
      @pgn = clean_pgn(@pgn)

      #if fen does exist, use that as start board
      unless @fen.nil?
        tokens = @fen.split
        unless tokens.size == 6
          raise Pgn2FenError, "Invalid FEN header #{@fen}"
        end
        @board_start_fen = @fen
        @board_color_from_fen = tokens[1]
        @fullmove = tokens[5].to_i
        castle_options = tokens[3]
        update_castle_options_from_fen(castle_options)
      else
        reset_castle_options(true)
      end 

      init_board
      @plies = plies_from_pgn(@pgn)
      @fen_array = fen_array_from_plies(@plies)
      self # allow chaining
    end

    def to_s
      str = ""
      str << "Event: #{@event}\n"
      str << "Site: #{@site}\n"
      str << "Date: #{@date}\n"
      str << "EventDate: #{@eventdate}\n"
      str << "Round: #{@round}\n"
      str << "White: #{@white}\n"
      str << "Black: #{@black}\n"
      str << "WhiteElo: #{@whiteElo}\n"
      str << "BlackElo: #{@blackElo}\n"
      str << "Result: #{@result}\n"
      str << "Eco: #{@eco}\n"
      str << "Plycount: #{@plycount}\n"
      str << "FEN: #{@fen}\n"

      str << "PGN: #{@pgn}\n"
      str << "Plies: #{@plies}\n"
      str << "FEN Array:\n"
      unless @fen_array.nil?
        @fen_array.each {|fen|
          str << fen << "\n"
        }
      end
      str
    end

    def rank_for_hint(hint)
      case hint
      when '1'
        return @@firstRank
      when '2'
        return @@secondRank
      when '3'
        return @@thirdRank
      when '4'
        return @@fourthRank
      when '5'
        return @@fifthRank
      when '6'
        return @@sixthRank
      when '7'
        return @@seventhRank
      when '8'
        return @@eighthRank
      else
        return nil
      end
    end

    def file_for_hint(hint)
      case hint
      when 'a'
        return @@aFile
      when 'b'
        return @@bFile
      when 'c'
        return @@cFile
      when 'd'
        return @@dFile
      when 'e'
        return @@eFile
      when 'f'
        return @@fFile
      when 'g'
        return @@gFile
      when 'h'
        return @@hFile
      else
        return nil
      end
    end

    def light_square_by_pgn square_pgn
      @@light_squares.include?(@@pgn_number_hash[square_pgn])
    end

    def dark_square_by_pgn square_pgn
      @@dark_squares.include?(@@pgn_number_hash[square_pgn])
    end

    def light_square_by_number square_number
      @@light_squares.include?(square_number)
    end

    def dark_square_by_number square_number
      @@dark_squares.include?(square_number)
    end

    def init_board
      @board_start_fen.split(" ").first.each_char {|c|
        case c
        when 'r', 'n', 'b', 'q', 'k', 'p'
          @board << c
        when 'R', 'N', 'B', 'Q', 'K', 'P'
          @board << c
        when '1', '2', '3', '4', '5', '6', '7', '8'
          (0...c.to_i).each {|n| @board << "" }
        else
          # do nothing
        end
      }
    end

    def games_from_pgn(pgn)
      games = []
      pos_array = pgn.enum_for(:scan, /\[Event/).map{Regexp.last_match.begin(0)}
        pos_array.each_with_index {|pos, index|
          if (pos_array.size > index + 1) # all elements but last
            single_game_pgn = pgn[pos..pos_array[index+1]-1]
          else # last element
            single_game_pgn = pgn[pos..-1]
          end
          games << game_from_pgn(single_game_pgn)
        }
        games
    end

    ##
    # check to verify PGN includes only a single game
    def is_single_game
      count = @pgn_data.scan(/\[Event /).count
        #puts "Event count:#{count}"
        if count > 1; return false; end

        # result header also includes result, hence compare with 2
        count = @pgn_data.scan(/1-0/).count
        #puts "1-0 count:#{count}"
        if count > 2; return false; end

        count = @pgn_data.scan(/0-1/).count
        #puts "0-1 count:#{count}"
        if count > 2; return false; end

        count = @pgn_data.scan(/1\/2-1\/2/).count
        #puts "1/2-1/2 count:#{count}"
        if count > 2; return false; end

        true
    end

    ##
    # get plies from pgn
    def plies_from_pgn(pgn)
      moves = pgn.split(/[0-9]+\./)
      moves.shift # remove first ""
      plies = []
      moves.each {|move|
        move.strip!
        move.gsub!(".", "")
        move.split(" ").each {|ply|
          plies << ply
        }
      }
      plies
    end

    ##
    # clean pgn - remove comments and other unrequired text
    def clean_pgn(pgn)
      pgn.strip!
      # clean result
      pgn.sub!("1-0", ""); pgn.sub!("0-1", ""); pgn.sub!("1/2-1/2", "")
      # clean mate and incomplete game marker
      pgn.gsub!("#", ""); pgn.gsub!("*", "")
      #remove all chessbase $ characters
      pgn.gsub!(/\$(\w+)/, "")
      #remove all comments - content within {}
      #pgn.gsub!(/(\{[^}]+\})+?/, "")
      pgn = clean_comments(pgn)
      #remove all subvariations - content within ()
      #pgn.gsub!(/(\([^}]+\))+?/, "")
      pgn = clean_subvariations(pgn)
    end

    def clean_comments(pgn)
      remove_text_between_tokens_inclusive(pgn, OPEN_BRACE, CLOSE_BRACE)
    end

    def clean_subvariations(pgn)
      remove_text_between_tokens_inclusive(pgn, OPEN_PAREN, CLOSE_PAREN)
    end

    def remove_text_between_tokens_inclusive(text, open_token, close_token)
      open_token_count = 0
      new_text = ""
      text.split("").each {|c|
        if c == open_token
          open_token_count += 1
        elsif c == close_token
          open_token_count -= 1
        else
          if open_token_count == 0
            new_text << c
          end
        end
      }
      new_text
    end

    ##
    # get FEN array from plies
    def fen_array_from_plies(plies)
      fen_array = []
      fen_array << @board_start_fen
      ply_number = 1 #ply_number starts at 1 for regular game
      unless @fen.nil?
        if @board_color_from_fen == "w"
          ply_number = (@fullmove.to_i * 2) + 1
        else
          ply_number = (@fullmove.to_i * 2)
        end
      end
      plies.each{|ply|
        #puts "ply=#{ply}, ply_number=#{ply_number}, move_number=#{ply_number/2 + 1}"
        fen_array << fen_for_ply(ply, ply_number)
        ply_number += 1
      }
      fen_array
    end

    ##
    # get FEN from a ply and ply number 
    def fen_for_ply(ply, ply_number)
      #puts ply
      is_white = (ply_number % 2 != 0)
      @halfmove = @halfmove + 1
      long_ply = short_ply_to_long_ply(ply, is_white)

      if long_ply.eql? "O-O"
        if is_white
          make_ply_on_board("e1g1")
          make_ply_on_board("h1f1")
          @can_white_castle_kingside = false
          @can_white_castle_queenside = false
        else
          make_ply_on_board("e8g8")
          make_ply_on_board("h8f8")
          @can_black_castle_kingside = false
          @can_black_castle_queenside = false
        end
      elsif long_ply.eql? "O-O-O"
        if is_white
          make_ply_on_board("e1c1")
          make_ply_on_board("a1d1")
          @can_white_castle_kingside = false
          @can_white_castle_queenside = false
        else
          make_ply_on_board("e8c8")
          make_ply_on_board("a8d8")
          @can_black_castle_kingside = false
          @can_black_castle_queenside = false
        end
      else # rest of moves
        if is_white
          if @can_white_castle_kingside && long_ply[0,2] == "h1"; @can_white_castle_kingside = false; end
          if @can_white_castle_queenside && long_ply[0,2] == "a1"; @can_white_castle_queenside = false; end
        else
          if @can_black_castle_kingside && long_ply[0,2] == "h8"; @can_white_castle_kingside = false; end
          if @can_black_castle_queenside && long_ply[0,2] == "a8"; @can_white_castle_queenside = false; end
        end
        make_ply_on_board(long_ply)
      end

      fen = board_to_fen
      fen.concat(" ").concat(is_white ? "b": "w")
      fen.concat(" ").concat(fen_castle_text)
      #enpassent square
      unless @potential_enpassent_ply.nil?
        fen.concat(" ").concat(@potential_enpassent_ply)
        @potential_enpassent_ply = nil
      else
        fen.concat(" ").concat("-")
      end
      fen.concat(" ").concat(@halfmove.to_s)
      if is_white 
        fen.concat(" ").concat((@fullmove).to_s)
      else
        fen.concat(" ").concat((@fullmove += 1).to_s)
      end
      #pp_board
      fen
    end

    ##
    # get FEN castle text based on castling availability
    def fen_castle_text
      text = ""
      if @can_white_castle_kingside; text.concat("K"); end
      if @can_white_castle_queenside; text.concat("Q"); end
      if @can_black_castle_kingside; text.concat("k"); end
      if @can_black_castle_queenside; text.concat("q"); end
      if text.empty?; text = "-"; end
      text
    end

    ##
    # update castling options from FEN header
    def update_castle_options_from_fen castle_options
      reset_castle_options(false)
      if castle_options == "-"
        return
      end
      tokens = castle_options.split("")
      tokens.each {|token|
        case token
        when "K" 
          @can_white_castle_kingside = true
        when "Q"
          @can_white_castle_queenside = true
        when "k"
          @can_black_castle_kingside = true
        when "q"
          @can_black_castle_queenside = true
        end
      }
    end

    ##
    # make a ply on the board
    def make_ply_on_board(long_ply)
      from_pgn = long_ply[0,2] 
      to_pgn = long_ply[2,2] 
      from_idx = @@pgn_number_hash[from_pgn]
      to_idx = @@pgn_number_hash[to_pgn]
      #puts "from_pgn:#{from_pgn}, to_pgn:#{to_pgn}, from_idx:#{from_idx}, to_idx:#{to_idx}"
      if @promotion
        if "P" == @board[from_idx] #white
          @board[to_idx] = @promotion_piece.upcase
        else #black
          @board[to_idx] = @promotion_piece.downcase
        end
        @promotion = false
        @promotion_piece = nil
      else #general case
        @board[to_idx] = @board[from_idx]
      end
      @board[from_idx] = ""
    end
    
    ##
    # return fen representation from board
    def board_to_fen
      fen = ""
      empty_square_counter = 0;
      @board.each_with_index { |tok, idx|
        if (idx % 8 == 0 && idx > 0)
          if empty_square_counter != 0
            fen.concat(empty_square_counter.to_s)
            empty_square_counter = 0
          end
          fen.concat("/")
        end
        if tok.empty?
          empty_square_counter = empty_square_counter + 1
        else
          if empty_square_counter != 0
            fen.concat(empty_square_counter.to_s)
            empty_square_counter = 0
          end
          fen.concat(tok)
        end
      }
      # last squares could be empty
      if empty_square_counter != 0
        fen.concat(empty_square_counter.to_s)
        empty_square_counter = 0
      end
      fen
    end

    def pp_board
      str = ""
      @board.each_with_index { |sq, idx|
        if sq.empty?; sq = "*"; end
        if (idx % 8 == 0 && idx != 0); str << "\n"; end
        str << sq << " "
      }
      puts "= = = = = = = ="
      puts str
      puts "= = = = = = = =\n\n\n"
    end
    
    ##
    # convert short ply to long ply
    def short_ply_to_long_ply(ply, is_white)
      from_idx = -1
      to_idx = -1
      from_pgn = ""
      to_pgn = ""
      hint = nil

      if ply.eql?("O-O"); return ply; end
      if ply.eql?("O-O-O"); return ply; end
      unless ply.index('+').nil?; ply.sub!("+", ""); end
      unless ply.index('x').nil?; ply.sub!("x", ""); @halfmove = 0; end
      unless ply.index('=').nil?
        @promotion = true
        @promotion_piece = ply[-1]
        ply = ply.chop.chop
      end

      if ply.length == 2 # pawn non-capture
        to_pgn = ply
        to_idx = @@pgn_number_hash[to_pgn]
        if is_white
          if !@board[to_idx+8].empty?
            from_idx = to_idx+8
          else
            from_idx = to_idx+16
#            if @board[to_idx-1].eql?"p" or @board[to_idx+1].eql?"p"
              @potential_enpassent_ply = @@number_pgn_hash[from_idx-8]
#            end
          end
        else  # isBlack
          if !@board[to_idx-8].empty?
            from_idx = to_idx-8
          else
            from_idx = to_idx-16
#            if @board[to_idx-1].eql?"P" or @board[to_idx+1].eql?"P"
              @potential_enpassent_ply = @@number_pgn_hash[from_idx+8]
#            end
          end
        end
        from_pgn = @@number_pgn_hash[from_idx]
        @halfmove = 0
        return from_pgn + to_pgn
      end

      if ('a'..'h').include?(ply[0]) && ply.length == 3 #pawn capture, non-enpassent
        to_pgn = ply[1..-1]
        to_idx = @@pgn_number_hash[to_pgn]
        if is_white
          if @board[to_idx+7].eql?("P") && file_for_hint(ply[0]).include?(to_idx+7)
            from_idx = to_idx+7
          elsif @board[to_idx+9].eql?("P")&& file_for_hint(ply[0]).include?(to_idx+9)
            from_idx = to_idx+9
          end
        else #is_black
          if @board[to_idx-7].eql?("p") && file_for_hint(ply[0]).include?(to_idx-7)
            from_idx = to_idx-7
          elsif @board[to_idx-9].eql?("p") && file_for_hint(ply[0]).include?(to_idx-9)
            from_idx = to_idx-9
          end
        end
        if from_idx == -1; raise Pgn2FenError, "Error parsing pawn capture at ply #{ply}"; end
        from_pgn = @@number_pgn_hash[from_idx]
        @halfmove = 0
        return from_pgn + to_pgn
      end

      if ply.length == 3; to_pgn = ply[1,2]; end
      if ply.length() == 4
        to_pgn = ply[2,2]
        hint = ply[1]
      end
      to_idx = @@pgn_number_hash[to_pgn]

      if ply[0].downcase.eql?('r'); return short_ply_to_long_ply_for_rook(to_idx, to_pgn, hint, is_white); end
      if ply[0].downcase.eql?('n'); return short_ply_to_long_ply_for_knight(to_idx, to_pgn, hint, is_white); end
      if ply[0].downcase.eql?('b'); return short_ply_to_long_ply_for_bishop(to_idx, to_pgn, hint, is_white); end
      if ply[0].downcase.eql?('q'); return short_ply_to_long_ply_for_queen(to_idx, to_pgn, hint, is_white); end
      if ply[0].downcase.eql?('k'); return short_ply_to_long_ply_for_king(to_idx, to_pgn, hint, is_white); end
      return from_pgn + to_pgn
    end

    def short_ply_to_long_ply_for_rook(to_idx, to_pgn, hint, is_white)
      from_idx = -1
      from_pgn = ""
      piece = is_white ? "R" : "r"
      if !hint.nil?
        if @@one_thru_eight.include?(hint)
          from_pgn = to_pgn[0,1] + hint
        end
        if @@a_thru_h.include?(hint)
          from_pgn = hint + to_pgn[1,1]
        end
        return from_pgn + to_pgn
      else # no hint
        # check file
        up = to_idx
        while up > -1 do
          up = up - 8
          if (up < 0)
            break
          end
          if @board[up].eql?(piece)
            from_idx = up
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[up].eql?("")
            next
          else
            break
          end
        end
        down = to_idx
        while down < 64 do
          down = down + 8
          if down > 63
            break
          end
          if @board[down].eql?(piece)
            from_idx = down
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[down].eql?("")
            next
          else
            break
          end
        end

        # check rank
        left = to_idx
        while left > -1 do
          left = left  - 1
          if left % 8 == 7
            break
          end
          if @board[left].eql?(piece)
            from_idx = left
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[left].eql?("")
            next
          else
            break
          end
        end
        right = to_idx
        while right < 64 do
          right = right + 1
          if right % 8 == 0
            break
          end
          if @board[right].eql?(piece)
            from_idx = right
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[right].eql?("")
            next
          else
            break
          end
        end
      end
      from_pgn + to_pgn
    end

    def short_ply_to_long_ply_for_knight(to_idx, to_pgn, hint, is_white)
      from_idx = -1
      from_pgn = ""
      piece = is_white ? "N" : "n"
      if !hint.nil?
        # -17,-15, 10, -6, 6, 10, 15, 17 are possible knight moves
        knight_moves = [17+to_idx, 17+to_idx, -15+to_idx, 15+to_idx, -10+to_idx, 10+to_idx, -6+to_idx, 6+to_idx]
        if @@one_thru_eight.include?(hint) 
          rank = rank_for_hint(hint)
          knight_moves = knight_moves & rank.to_a # intersection
        end
        if @@a_thru_h.include?(hint) 
          file = file_for_hint(hint)
          knight_moves = knight_moves & file.to_a #intersection
        end
        knight_moves.each {|idx|
          if @board[idx].eql?(piece)
            from_idx = idx
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          end
        }
      else
        # -17,-15, 10, -6, 6, 10, 15, 17 are possible knight moves
        knight_moves = [-17, 17, -15, 15, -10, 10, -6, 6]
        knight_moves.each {|i|
          idx = to_idx + i
          if (idx < 0 && idx > 63)
            next
          end
          if @board[idx].eql?(piece)
            from_idx = idx
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          end
        }
      end
      #return from_pgn + to_pgn
      raise Pgn2FenError, "Error parsing knight move to square #{to_pgn}"
    end

    def short_ply_to_long_ply_for_bishop(to_idx, to_pgn, hint, is_white)
      from_idx = -1
      from_pgn = ""
      piece = is_white ? "B" : "b"
      is_light = light_square_by_number(to_idx) ? true : false
      if (!hint.nil?)
        if @@one_thru_eight.include?(hint)
          from_pgn = to_pgn[0,1] + h
        end
        if @@a_thru_h.include?(hint)
          from_pgn = h + to_pgn[1,1]
        end
        return from_pgn + to_pgn
      else
        # check nw direction
        nw = to_idx
        while(nw > -1) do
          nw = nw - 9
          if (nw < 0)
            break
          end
#          puts "nw=#{nw}"
          if light_square_by_number(nw) != is_light # square colors don't match - overflow
            break
          elsif @board[nw].eql?(piece)
            from_idx = nw
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[nw].eql?("")
            next
          else
            break
          end
        end
        # check ne direction
        ne = to_idx
        while(ne > 0) do
          ne = ne - 7
          if (ne < 1)
            break
          end
#          puts "ne=#{ne}"
          if light_square_by_number(ne) != is_light # square colors don't match - overflow
            break
          elsif @board[ne].eql?(piece)
            from_idx = ne
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[ne].eql?("")
            next
          else
            break
          end
        end
        # check sw direction
        sw = to_idx
        while(sw < 63) do
          sw = sw + 7
          if (sw > 62)
            break
          end
#          puts "sw=#{sw}"
          if light_square_by_number(sw) != is_light # square colors don't match - overflow
            break
          elsif @board[sw].eql?(piece)
            from_idx = sw
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[sw].eql?("")
            next
          else
            break
          end
        end
        # check se direction
        se = to_idx
        while(se < 64) do
          se = se + 9
          if (se > 63)
            break
          end
#          puts "se=#{se}"
          if light_square_by_number(se) != is_light # square colors don't match - overflow
            break
          elsif @board[se].eql?(piece)
            from_idx = se
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[se].eql?("")
            next
          else
            break
          end
        end
      end
      return from_pgn + to_pgn
    end

    def short_ply_to_long_ply_for_queen(to_idx, to_pgn, hint, is_white)
      # check bishop type moves
      from_idx = -1
      from_pgn = ""
      piece = is_white ? "Q" : "q"
      is_light = light_square_by_number(to_idx) ? true : false
      if (!hint.nil?)
        if @@one_thru_eight.include?(hint)
          from_pgn = to_pgn[0,1] + hint
        end
        if @@a_thru_h.include?(hint)
          from_pgn = hint + to_pgn[1,1]
        end
        return from_pgn + to_pgn
      else
        # check nw direction
        nw = to_idx
        while(nw > -1) do
          nw = nw - 9
          if (nw < 0)
            break
          end
          if light_square_by_number(nw) != is_light # square colors don't match - overflow
            break
          elsif @board[nw].eql?(piece)
            from_idx = nw
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[nw].eql?("")
            next
          else
            break
          end
        end
        # check ne direction
        ne = to_idx
        while(ne > 0) do
          ne = ne - 7
          if (ne < 1)
            break
          end
          if light_square_by_number(ne) != is_light # square colors don't match - overflow
            break
          elsif @board[ne].eql?(piece)
            from_idx = ne
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[ne].eql?("")
            next
          else
            break
          end
        end
        # check sw direction
        sw = to_idx
        while(sw < 63) do
          sw = sw + 7
          if (sw > 62)
            break
          end
          if light_square_by_number(sw) != is_light # square colors don't match - overflow
            break
          elsif @board[sw].eql?(piece)
            from_idx = sw
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[sw].eql?("")
            next
          else
            break
          end
        end
        # check se direction
        se = to_idx
        while(se < 64) do
          se = se + 9
          if (se > 63)
            break
          end
          if light_square_by_number(se) != is_light # square colors don't match - overflow
            break
          elsif @board[se].eql?(piece)
            from_idx = se
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[se].eql?("")
            next
          else
            break
          end
        end
      end
      if (from_pgn.length == 2)
        return from_pgn + to_pgn
      end
      # check rook type moves
      if !hint.nil?
        if @@one_thru_eight.include?(hint)
          from_pgn = to_pgn[0,1] + hint
        end
        if @@a_thru_h.include?(hint)
          from_pgn = hint + to_pgn[1,1]
        end
        return from_pgn + to_pgn
      else # no hint
        # check file
        up = to_idx
        while up > -1 do
          up = up - 8
          if (up < 0)
            break
          end
          if @board[up].eql?(piece)
            from_idx = up
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[up].eql?("")
            next
          else
            break
          end
        end
        down = to_idx
        while down < 64 do
          down = down + 8
          if down > 63
            break
          end
          if @board[down].eql?(piece)
            from_idx = down
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[down].eql?("")
            next
          else
            break
          end
        end

        # check rank
        left = to_idx
        while left > -1 do
          left = left  - 1
          if left % 8 == 7
            break
          end
          if @board[left].eql?(piece)
            from_idx = left
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[left].eql?("")
            next
          else
            break
          end
        end
        right = to_idx
        while right < 64 do
          right = right + 1
          if right % 8 == 0
            break
          end
          if @board[right].eql?(piece)
            from_idx = right
            from_pgn = @@number_pgn_hash[from_idx]
            return from_pgn + to_pgn
          elsif @board[right].eql?("")
            next
          else 
            break
          end
        end
      end
      from_pgn + to_pgn
    end

    def short_ply_to_long_ply_for_king(to_idx, to_pgn, hint, is_white)
      from_idx = -1
      from_pgn = ""
      if is_white
        @board.reverse.each_with_index {|i,idx| if i.eql?("K"); from_idx = 63 - idx; break; end }
      else
       @board.each_with_index {|i,idx| if i.eql?("k"); from_idx = idx; break; end }
      end
      from_pgn = @@number_pgn_hash[from_idx]
      return from_pgn + to_pgn
    end

  end

  class Pgn2FenError < StandardError; end

end #end module
