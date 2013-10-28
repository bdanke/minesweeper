require 'yaml'
require 'colorize'
class Minesweeper
  attr_accessor :board, :hidden_board, :num_mines, :leader_boards, :time, :name
  ADJACENTS = [[1, 0], [1, 1], [0, 1], [-1, 1], [1, -1],
  [-1, 0], [-1, -1], [0, -1]]

  FLAG = "\u2691"
  MINE = "\u2718"
  BLACK_SQUARE = "\u25A3"
  WHITE_SQUARE = "\u25A2"

  def initialize(size, num_mines)
    @time = nil
    @name = nil
    @num_mines = num_mines
    @board = Array.new(size) { Array.new(size, BLACK_SQUARE) }
    @hidden_board = @board.map { |el| el.is_a?(Array) ? el.dup : el}
    self.load_leader_boards
    @leader_boards[size].display
    place_random_mines(num_mines)
    place_numbers
    play
  end

  def place_random_mines(num_mines)
    mines = 0
    until mines == num_mines
      x = rand(board.size)
      y = rand(board.size)
      if hidden_board[x][y] != MINE
        hidden_board[x][y] = MINE
        mines += 1
      end
    end
  end

  def play
    if name.nil?
      puts "What is your name?"
      self.name = gets.chomp
    end
    start_time = Time.now || time
    until game_over?
      render_board
      puts "What coordinate do you want to reveal (r) or flag (f)? (Example: r 1 3)"

      input = gets.chomp.split
      if input[0] == 'save'
        self.time = Time.now - start_time
        save(input[1])
        return
      end
      handle_command(input)
    end
    end_time = Time.now
    render_board
    puts "You #{lose? ? "lose" : "win"}!"
    if win?
      self.time = end_time - start_time
      leader_boards[board.size].check_and_add(time, name)
    end
  end

  def handle_command(commands)
    cmd, x, y = commands
    if (cmd == 'f')
      flag_location(x.to_i, y.to_i)
    elsif (board[x.to_i][y.to_i] == FLAG)
      puts 'That location is flagged, reflag it to reveal.'
    elsif (cmd == 'r')
      reveal_location(x.to_i, y.to_i)
    end
  end

  def flag_location(row, col)
    return unless board[row][col] == BLACK_SQUARE || board[row][col] == FLAG
    board[row][col] = board[row][col] == FLAG ? BLACK_SQUARE : FLAG
  end

  def place_numbers
    hidden_board.each_with_index do |row, x|
      row.each_with_index do |col, y|
        if (hidden_board[x][y] == MINE)
          next
        end
        count = 0
        ADJACENTS.each do |adj|
          adj_x = x + adj[0]
          adj_y = y + adj[1]
          if (adj_x < 0 || adj_y < 0 || adj_x >= board.size || adj_y >= @board.size)
            next
          else
            if hidden_board[adj_x][adj_y] == MINE
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
    if (space == MINE)
      self.board[row][col] = MINE
    elsif (space.is_a?(Fixnum))
      self.board[row][col] = space
    else
      self.board[row][col] = WHITE_SQUARE
      reveal_adjacents(row, col)
    end
  end

  def reveal_adjacents(row, col)
    ADJACENTS.each do |adj|
      adj_x = row + adj[0]
      adj_y = col + adj[1]
      next if (adj_x < 0 || adj_y < 0 || adj_x >= board.size || adj_y >= board.size)
      has_mine = hidden_board[adj_x][adj_y] == MINE
      checked = board[adj_x][adj_y] != BLACK_SQUARE
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
      row_mapped = row.map do |el|
        char = el.to_s.encode('utf-8')
        char.colorize(color_character(char))
       end
      puts row_mapped.join(" ")
    end
  end

  def lose?
    board.flatten.include? MINE
  end

  def win?
    flat = board.flatten
    count = flat.count(FLAG) + flat.count(BLACK_SQUARE)
    return true if count == num_mines
    return false if flat.include? BLACK_SQUARE
  end

  def game_over?
    win? || lose?
  end

  def save(fname="save.game")
    fname ||= "save.game"
    File.open(fname, 'w') do |f|
      f.puts self.to_yaml
    end
  end

  def color_character(char)
    case char
    when '1'
      :cyan
    when '2'
      :blue
    when '3'
      :magenta
    when '4'
      :light_red
    when '5'
    when '6'
    when FLAG
      :red
    when MINE
      :black
    else
      :default
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

  def load_leader_boards
    @leader_boards = {
      9 => LeaderBoard.load(9),
      16 => LeaderBoard.load(16)
    }
  end
end

class LeaderBoard
  attr_accessor :leaders, :size

  def initialize(size)
    @size = size
    @leaders = []
  end

  def add_leader(time, name)
    leaders << [time, name]
    leaders.sort_by! do |leader1, leader2|
      leader1 <=> leader2
    end
    save
  end

  def check_and_add(time, name)
    to_add = false
    if leaders.count < 10
      to_add = true
    elsif leaders.any? { |leader| leader[0] > time }
      to_add = true
    end
    if to_add
      if leaders.count >= 10
        leaders = leaders.take(10)
      end
      add_leader(time, name)
      self.display
    end
  end

  def save(suffix="leader.board")
    fname = "#{size}_#{suffix}"
    File.open(fname, 'w') do |f|
      f.puts self.to_yaml
    end
  end

  def self.load(size, suffix="leader.board")
    fname = "#{size}_#{suffix}"
    return LeaderBoard.new(size) unless File.exists?(fname)
    yaml = File.read(fname)
    YAML::load(yaml)
  end

  def display
    puts
    puts "Name\t\tTime"
    leaders.each do |leader|
      puts "#{leader[1]}\t\t#{leader[0]}"
    end
    puts "==END OF LEADERBOARD=="
    puts
  end
end