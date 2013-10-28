require 'yaml'
class Minesweeper
  attr_accessor :board, :hidden_board, :num_mines
  ADJACENTS = [[1, 0], [1, 1], [0, 1], [-1, 1], [1, -1],
  [-1, 0], [-1, -1], [0, -1]]

  def initialize(size, num_mines)
    @num_mines = num_mines
    @board = Array.new(size) { Array.new(size, "*") }
    @hidden_board = @board.map { |el| el.is_a?(Array) ? el.dup : el}
    place_random_mines(num_mines)
    place_numbers
    play
  end

  def place_random_mines(num_mines)
    mines = 0
    until mines == num_mines
      x = rand(board.size)
      y = rand(board.size)
      if hidden_board[x][y] != "O"
        hidden_board[x][y] = "O"
        mines += 1
      end
    end
  end

  def play
    until game_over?
      render_board
      puts "What coordinate do you want to reveal (r) or flag (f)? (Example: r 1 3)"

      input = gets.chomp.split
      if input[0] == 'save'
        save(input[1])
        return
      end
      handle_command(input)
    end
    puts "You #{lose? ? "lose" : "win"}!"
  end

  def handle_command(commands)
    cmd, x, y = commands
    if (cmd == 'f')
      flag_location(x.to_i, y.to_i)
    elsif (board[x.to_i][y.to_i] == 'F')
      puts 'That location is flagged, reflag it to reveal.'
    elsif (cmd == 'r')
      reveal_location(x.to_i, y.to_i)
    end
  end

  def flag_location(row, col)
    return unless board[row][col] == '*' || board[row][col] == 'F'
    board[row][col] = board[row][col] == 'F' ? '*' : 'F'
  end

  def place_numbers
    hidden_board.each_with_index do |row, x|
      row.each_with_index do |col, y|
        if (hidden_board[x][y] == 'O')
          next
        end
        count = 0
        ADJACENTS.each do |adj|
          adj_x = x + adj[0]
          adj_y = y + adj[1]
          if (adj_x < 0 || adj_y < 0 || adj_x >= board.size || adj_y >= @board.size)
            next
          else
            if hidden_board[adj_x][adj_y] == 'O'
              count += 1
            end
          end
        end
        if (count > 0)
          hidden_board[x][y] = count
        end
      end
    end
  end

  def reveal_location(row, col)
    space = hidden_board[row][col]
    if (space == 'O')
      self.board[row][col] = 'O'
    elsif (space.is_a?(Fixnum))
      self.board[row][col] = space
    else
      self.board[row][col] = "_"
      reveal_adjacents(row, col)
    end
  end

  def reveal_adjacents(row, col)
    ADJACENTS.each do |adj|
      adj_x = row + adj[0]
      adj_y = col + adj[1]
      next if (adj_x < 0 || adj_y < 0 || adj_x >= board.size || adj_y >= board.size)
      has_mine = hidden_board[adj_x][adj_y] == 'O'
      checked = board[adj_x][adj_y] != '*'
      unless (has_mine || checked)
        reveal_location(adj_x, adj_y)
      end
    end
  end

  def render_board
    print "    "
    puts (0...board.size).to_a.join(" ")
    puts "--" * (board.size + 2)
    board.each_with_index do |row, idx|
      print "#{idx} | "
      puts row.join(" ")
    end
  end

  def lose?
    board.flatten.include? 'O'
  end

  def win?
    flat = board.flatten
    return true if flat.count("F") == num_mines
    return true if flat.count("*") == num_mines
    return false if flat.include? '*'
  end

  def game_over?
    win? || lose?
  end

  def save(fname="save.game")
    File.open(fname, 'w') do |f|
      f.puts self.to_yaml
    end
  end

  def self.create_or_load
    puts "Do you want to load a saved game?"
    input = gets.chomp
    if (input == 'y' || input == 'yes')
      puts "What's the save file?"
      save_file = gets.chomp
      Minesweeper.load(save_file)
    else
      puts "What size board? 9 or 16"
      size = gets.chomp.to_i
      Minesweeper.new(size, size == 9 ? 10 : 40)
    end
  end

  def self.load(fname="save.game")
    yaml = File.read(fname)
    YAML::load(yaml).play
  end
end