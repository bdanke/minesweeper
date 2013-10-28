class Minesweeper

  ADJACENTS = [[1, 0], [1, 1], [0, 1], [-1, 1], [1, -1],
  [-1, 0], [-1, -1], [0, -1]]

  def initialize(size, num_mines)
    @board = Array.new(size) { Array.new(size, "*") }
    @hidden_board = @board.map { |el| el.is_a?(Array) ? el.dup : el}
    place_random_mines(num_mines)
    place_numbers
    play
  end

  def place_random_mines(num_mines)
    mines = 0
    until mines == num_mines
      x = rand(@board.size)
      y = rand(@board.size)
      if @hidden_board[x][y] != "O"
        @hidden_board[x][y] = "O"
        mines += 1
      end
    end
  end

  def play
    until game_over?
      render_board
      puts "What coordinate do you want to reveal or flag?"
      command = gets.chomp.split
      if (command[0] == 'r')
        reveal_location(command[1].to_i, command[2].to_i)
      else
      end
    end
  end

  def place_numbers
    @hidden_board.each_with_index do |row, x|
      row.each_with_index do |col, y|
        if (@hidden_board[x][y] == 'O')
          next
        end
        count = 0
        ADJACENTS.each do |adj|
          adj_x = x + adj[0]
          adj_y = y + adj[1]
          if (adj_x < 0 || adj_y < 0 || adj_x >= @board.size || adj_y >= @board.size)
            next
          else
            puts "ROW: #{x}, COL: #{y}, ADJX: #{adj_x}, ADJY: #{adj_y}"
            if @hidden_board[adj_x][adj_y] == 'O'
              puts @hidden_board[adj_x][adj_y]
              count += 1
            end
            puts count
          end
        end
        if (count > 0)
          @hidden_board[x][y] = count
        end
      end
    end
  end

  def reveal_location(row, col)
    space = @hidden_board[row][col]
    if (space == 'O')
      @board[row][col] = 'O'
    elsif (space.is_a?(Fixnum))
      @board[row][col] = space
    else
      @board[row][col] = "_"
      reveal_adjacents(row, col)
    end
  end

  def reveal_adjacents(row, col)
    ADJACENTS.each do |adj|
      adj_x = row + adj[0]
      adj_y = col + adj[1]
      next if (adj_x < 0 || adj_y < 0 || adj_x >= @board.size || adj_y >= @board.size)
      has_mine = @hidden_board[adj_x][adj_y] == 'O'
      checked = @board[adj_x][adj_y] != '*'
      unless (has_mine || checked)
        reveal_location(adj_x, adj_y)
      end
    end
  end

  def render_board(board=@board)
    board.each do |row|
      puts row.join(" ")
    end
  end

  def lose?
    @board.flatten.include? 'O'
  end

  def win?

  end

  def game_over?
    win? || lose?
  end
end