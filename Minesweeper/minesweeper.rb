require 'yaml'
require 'colorize'
require 'debugger'

FLAG = "\u2691"
MINE = "\u2718"
BLACK_SQUARE = "\u25A3"
WHITE_SQUARE = "\u25A2"
ADJACENTS = [[1, 0], [1, 1], [0, 1], [-1, 1], [1, -1],
[-1, 0], [-1, -1], [0, -1]]

class Tile
  attr_accessor :mark, :revealed, :row, :col, :flagged, :board

  def initialize(board, row, col, mark)
    @board = board
    @row = row
    @col = col
    @mark = mark
    @revealed = false
    @flagged = false
  end

  def show
    #mark.colorize(color_character)
    revealed ? mark.colorize(color_character) : (flagged ? FLAG : BLACK_SQUARE)
  end

  def reveal_adjacents
    ADJACENTS.each do |adj|
      adj_x = row + adj[0]
      adj_y = col + adj[1]
      pos = [adj_x, adj_y]
      next if (adj_x < 0 || adj_y < 0 || adj_x >= board.size || adj_y >= board.size)
      has_mine = board[pos].mark == MINE
      checked = board[pos].revealed
      unless (has_mine || checked)
        board[pos].reveal_location
      end
    end
  end

  def reveal_location
    if (mark == MINE || ('0'..'8').to_a.include?(mark))
      self.revealed = true
    else
      self.revealed = true
      reveal_adjacents
    end
  end

  def color_character
    case mark
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
end

class Board
  attr_accessor :grid

  def initialize(size, num_mines)
    @grid = Array.new(size) { Array.new(size) }
    setup_tiles
    place_random_mines(num_mines)
    place_numbers
  end

  def setup_tiles
    grid.each_with_index do |row, x|
      row.each_with_index do |col, y|
        grid[x][y] = Tile.new(self, x, y, WHITE_SQUARE)
      end
    end
  end

  def size
    grid.size
  end

  def place_numbers
    grid.each_with_index do |row, x|
      grid.each_with_index do |col, y|
        if (grid[x][y].mark == MINE)
          next
        end
        count = 0
        ADJACENTS.each do |adj|
          adj_x = x + adj[0]
          adj_y = y + adj[1]
          if (adj_x < 0 || adj_y < 0 || adj_x >= grid.size || adj_y >= grid.size)
            next
          else
            if grid[adj_x][adj_y].mark == MINE
              count += 1
            end
          end
        end
        if (count > 0)
          self.grid[x][y].mark = count.to_s
        end
      end
    end
  end

  def place_random_mines(num_mines)
    mines = 0
    until mines == num_mines
      x = rand(grid.size)
      y = rand(grid.size)
      if grid[x][y].mark != MINE
        grid[x][y].mark = MINE
        mines += 1
      end
    end
  end

  def render
    print "    "
    puts (0...grid.size).to_a.join(" ")
    puts "--" * (grid.size + 2)
    grid.each_with_index do |row, idx|
      print "#{idx} | "
      row_mapped = row.map(&:show)
      puts row_mapped.join(" ")
    end
  end

  def [](pos)
    grid[pos[0]][pos[1]]
  end

  def []=(pos, value)
    grid[pos[0]][pos[1]] = value
  end
end

class Minesweeper
  attr_accessor :board, :num_mines, :leader_boards, :time, :name

  def initialize(size, num_mines)
    @time = nil
    @name = nil
    @num_mines = num_mines
    @board = Board.new(size, num_mines)
    self.load_leader_boards
    @leader_boards[size].display
    play
  end

  def play
    if name.nil?
      puts "What is your name?"
      self.name = gets.chomp
    end
    start_time = Time.now || time
    until game_over?
      board.render
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
    board.render
    puts "You #{lose? ? "lose" : "win"}!"
    if win?
      self.time = end_time - start_time
      leader_boards[board.size].check_and_add(time, name)
    end
  end

  def handle_command(commands)
    cmd, x, y = commands
    pos = [x, y].map(&:to_i)
    if (cmd == 'f')
      board[pos].flagged = !board[pos].flagged
    elsif (board[pos].flagged)
      puts 'That location is flagged, reflag it to reveal.'
    elsif (cmd == 'r')
      board[pos].reveal_location
    end
  end

  def lose?
    board.grid.flatten.any? { |el| el.mark == MINE && el.revealed }
  end

  def win?
    flat = board.grid.flatten
    count = flat.select { |el| el.mark == FLAG || el.mark == BLACK_SQUARE }.count
    count == num_mines
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

if __FILE__ == $PROGRAM_NAME
  Minesweeper.create_or_load
end