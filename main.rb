require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

BLACKJACK = 21

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
    @success = "#{session[:username]} wins! #{msg}"
  end

  def loser!(msg)
    @round_over = true
    @show_buttons = false
    @error = "#{session[:username]} loses! #{msg}"
  end

  def tie!(msg)
    @round_over = true
    @show_buttons = false
    @success = "Push! #{msg}"
  end

  def valid_bet?(bet)
    if bet == 0 || bet < 0
      @error = 'Invalid submission, please place a valid bet'
      halt erb(:bet)
    elsif bet > session[:chips] 
      @error = 'You cannot bet more than your chip amount'
      halt erb(:bet)
    end
    true
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
  erb :welcome
end

post '/submit_name' do
  if params[:username].empty?
    @error = 'Name is required'
    halt erb(:welcome)
  end

  session[:username] = params[:username] # capture username in cookie
  redirect '/bet'
end

get '/bet' do
  session[:chips] = 500
  erb :bet
end

post '/submit_bet' do

  if valid_bet?(params[:bet].to_i)
    session[:bet] = params[:bet].to_i
  end

  redirect '/game'
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
    session[:chips] += blackjack_pays(session[:bet])
    @round_over = true
    @show_buttons = false
  elsif player_total > BLACKJACK
    loser!("Sorry, you busted! You lost $#{session[:bet]}")
    session[:chips] -= session[:bet]
    @round_over = true
    @show_buttons = false
    redirect '/game_over' if session[:chips] == 0
  end

  erb :game
end

post '/game/player/stay' do
  @show_buttons = false
  @success = "You have chosen to stay."
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_flop = true

  dealer_total = check_value(session[:dealer_cards])

   
  if dealer_total == BLACKJACK
    loser!("Dealer hit blackjack. You lost $#{session[:bet]}")
    session[:chips] -= session[:bet]
    redirect '/game_over' if session[:chips] == 0
  elsif dealer_total > BLACKJACK
    winner!("Dealer busted. You won $#{session[:bet]}!")
    session[:chips] += session[:bet]
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
    session[:chips] -= session[:bet]
    redirect '/game_over' if session[:chips] == 0
  elsif player_total > dealer_total
    winner!("You won $#{session[:bet]}!")
    session[:chips] += session[:bet]
  else
    tie!("It's a tie!")
  end

  erb :game
end

get '/game/new_bet' do
  erb :new_bet
end

post '/submit_new_bet' do

  if valid_bet?(params[:bet].to_i)
    session[:bet] = params[:bet].to_i
  end

  redirect '/game'
end

get '/game/thanks' do
  erb :thanks
end

get '/game_over' do
  erb :game_over
end


