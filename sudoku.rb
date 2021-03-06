require 'sinatra'
require 'sinatra/partial'
require 'rack-flash'
require_relative './lib/sudoku'
require_relative './lib/cell'

set :partial_template_engine, :erb
use Rack::Flash
set :session_secret, 'Secret key here, signing the cookie.'
enable :sessions

get '/' do
  prepare_to_check_solution
  generate_new_puzzle_if_necessary
  @current_solution = session[:current_solution] || session[:puzzle]
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  erb :index
end

get '/restart' do
  session[:current_solution] = nil
  redirect to('/')
end

get '/solution' do
  @current_solution = session[:solution]
  @puzzle = session[:puzzle]
  @solution = session[:solution]
  erb :index
end

post '/' do
  cells = box_order_to_row_order(params['cell'])
  session[:current_solution] = cells.map { |value| value.to_i }.join
  session[:check_solution] = true
  puts params
  redirect to('/')
end

def random_sudoku
  seed = (1..9).to_a.shuffle + Array.new(81 - 9, 0)
  sudoku = Sudoku.new(seed.join)
  sudoku.solve!
  sudoku.to_s.chars
end

def puzzle(sudoku)
  sudoku.map { |i| rand < 0.75 ? 0 : i }
end

def generate_new_puzzle_if_necessary
  return if session[:current_solution]
  sudoku = random_sudoku
  session[:solution] = sudoku
  session[:puzzle] = puzzle(sudoku)
  session[:current_solution] = session[:puzzle]
end

def prepare_to_check_solution
  @check_solution = session[:check_solution]
  puts @check_solution
  if @check_solution
    flash.now[:notice] = 'Incorrect values are highlighted in yellow.'
  end
  session[:check_solution] = nil
end

def box_order_to_row_order(cells)
  boxes = cells.each_slice(9).to_a
  (0..8).to_a.inject([]) do |memo, i|
    first_box_index = i / 3 * 3
    three_boxes = boxes[first_box_index, 3]
    three_rows_of_three = three_boxes.map do |box|
      row_number_in_a_box = i % 3
      first_cell_in_the_row_index = row_number_in_a_box * 3
      box[first_cell_in_the_row_index, 3]
    end
    memo += three_rows_of_three.flatten
  end
end

helpers do

  def cell_value(value)
    value.to_i == 0 ? '' : value
  end

  def colour_class(solution_to_check, puzzle_value, current_solution_value, solution_value)
    must_be_guessed = puzzle_value == 0
    tried_to_guess = current_solution_value.to_i != 0
    guessed_incorrectly = current_solution_value != solution_value

    if solution_to_check && must_be_guessed && tried_to_guess && guessed_incorrectly
      'incorrect'
    elsif !must_be_guessed
      'value-provided'
    end
  end
end
