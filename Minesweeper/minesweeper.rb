class Minesweeper

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
      input = gets.chomp.split
      cmd, x, y = input
      if (cmd == 'f')
        flag_location(x.to_i, y.to_i)
      elsif (@board[x.to_i][y.to_i] == 'F')
        puts 'That location is flagged, reflag it to reveal.'
      elsif (cmd == 'r')
        reveal_location(x.to_i, y.to_i)
      end
    end
    puts "You #{lose? ? "lose" : "win"}!"
  end

  def flag_location(row, col)
    return unless @board[row][col] == '*' || @board[row][col] == 'F'
    @board[row][col] = @board[row][col] == 'F' ? '*' : 'F'
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
            if @hidden_board[adj_x][adj_y] == 'O'
              count += 1
            end
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
    flat = @board.flatten
    return false if flat.include? '*'
    return true if flat.count("F") == @num_mines
    return true if flat.count("*") == @num_mines
  end

  def game_over?
    win? || lose?
  end
end