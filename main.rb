require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

BLACKJACK = 21
DEFAULT_POT = 500

helpers do
  def check_value(cards) #[['clubs', 'ace'], ['hearts', '5']]

    ranks = cards.collect {|card| card[1]}

    sum = 0
    ranks.each do |rank|
      if rank == 'ace'
        sum += 11
      elsif rank.to_i == 0
        sum += 10
      else
        sum += rank.to_i
      end
    end

    ranks.select {|rank| rank == 'ace'}.count.times do
      sum -= 10 if sum > BLACKJACK
    end
    sum
  end

  def card_image(card) #['clubs', 'ace']
    suit = card[0]
    rank = card[1]

    "<img src='/images/cards/#{suit}_#{rank}.svg' class='card'/>"
  end

  def blackjack_pays(bet)
    (bet * 3) / 2
  end

  def winner!(msg)
    @round_over = true
    @show_buttons = false
    
    if check_value(session[:player_cards]) == BLACKJACK
      session[:chips] += blackjack_pays(session[:bet])
    else
      session[:chips] += session[:bet]
    end
    @success = "<strong>#{session[:username]}</strong> wins! #{msg}"
  end

  def loser!(msg)
    @round_over = true
    @show_buttons = false
    session[:chips] -= session[:bet]
    @error = "<strong>#{session[:username]}</strong> loses! #{msg}"
  end

  def tie!(msg)
    @round_over = true
    @show_buttons = false
    @success = "Push! <strong>#{msg}</strong>"
  end
end

before do
  @show_buttons = true
  @show_flop = false
  @round_over = false
end

get '/' do
  redirect '/welcome'
end

get '/welcome' do
  session[:chips] = DEFAULT_POT
  erb :welcome
end

post '/submit_name' do
  if params[:username].empty?
    @error = "Name is required."
    halt erb(:welcome)
  end

  session[:username] = params[:username] # capture username in cookie
  redirect '/bet'
end

get '/bet' do
  session[:bet] = nil
  erb :bet
end

post '/bet' do

  if params[:bet].nil? || params[:bet].to_i == 0
    @error = "Invalid response, please try again."
    halt erb(:bet)
  elsif params[:bet].to_i > session[:chips].to_i
    @error = "You cannot bet more than $#{session[:chips]}.00, please try again."
    halt erb(:bet)
  else 
    session[:bet] = params[:bet].to_i
    redirect '/game'
  end
end

get '/game' do
  suits = %w{spades clubs hearts diamonds}
  ranks = %w{ace 2 3 4 5 6 7 8 9 10 jack queen king}
  session[:deck] = suits.product(ranks).shuffle!
  session[:deck] *= 3
  
  session[:player_cards] = []
  session[:dealer_cards] = []

  # deal cards in an alternate manner
  2.times do 
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = check_value(session[:player_cards])

  if player_total == BLACKJACK
    winner!("You hit Blackjack #{session[:username]}! You won $#{blackjack_pays(session[:bet])}")
  elsif player_total > BLACKJACK
    loser!("Sorry, you busted! You lost $#{session[:bet]}")
    redirect '/game_over' if session[:chips] == 0
  end

  erb :game, :layout false
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_flop = true
  @show_buttons = false

  dealer_total = check_value(session[:dealer_cards])

  if dealer_total == BLACKJACK
    loser!("Dealer hit blackjack. You lost $#{session[:bet]}.")
    redirect '/game_over' if session[:chips] == 0
  elsif dealer_total > BLACKJACK
    winner!("Dealer busted. You won $#{session[:bet]}!")
  elsif dealer_total >= 17
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_flop = true

  player_total = check_value(session[:player_cards])
  dealer_total = check_value(session[:dealer_cards])
  
  if player_total < dealer_total
    loser!("You lost $#{session[:bet]}.")
    redirect '/game_over' if session[:chips] == 0
  elsif player_total > dealer_total
    winner!("You won $#{session[:bet]}!")
  else
    tie!("It's a tie!")
  end

  erb :game
end

get '/game/thanks' do
  erb :thanks
end

get '/game_over' do
  erb :game_over
end


