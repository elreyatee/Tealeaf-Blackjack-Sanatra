require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK = 21

helpers do
  def check_value(cards)
    sum = 0
    cards.each do |card|
      if card[1] == 'ace'
        sum += 11
      elsif card[1].to_i == 0
        sum += 10
      else
        sum += card[1].to_i
      end
    end

    # correct for Aces
    cards.select {|card| card[1] == 'ace'}.count.times do
      sum -= 10 if sum > BLACKJACK
    end
    sum
  end

  def card_image(card) 
    suit = card[0]
    rank = card[1]

    "<img src='/images/cards/#{suit}_#{rank}.svg' class='card'/>"
  end

  def blackjack_pays(bet)
    (bet * 3) / 2
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
  erb :bet
end

post '/submit_bet' do
  case 
  when params[:bet].empty?
    @error = 'Invalid response, please place a bet'
    halt erb(:bet)
  when params[:chip_request].empty?
    @error = 'Invalid response, please request chip amount'
    halt erb(:bet)
  when params[:chip_request].to_i % 5 != 0
    @error = 'Please request chip amount in multiples of 5'
    halt erb(:bet)
  when params[:bet].to_i % 5 != 0 
    @error = 'Please bet amount in multiples of 5'
    halt erb(:bet)
  end

  session[:bet] = params[:bet].to_i
  session[:chips] = params[:chip_request].to_i
  redirect '/game'
end

get '/game' do

  suits = %w{spades clubs hearts diamonds}
  ranks = %w{ace 2 3 4 5 6 7 8 9 10 jack queen king}
  session[:deck] = suits.product(ranks).shuffle!
  
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

  case 
  when player_total == BLACKJACK
    winnings = blackjack_pays(session[:bet])
    @success = "Congrats, you hit Blackjack #{session[:username]}! You won $#{winnings}"
    session[:chips] += winnings
    @round_over = true
    @show_buttons = false
  when player_total > BLACKJACK
    @error = "Sorry, you busted! You lost $#{session[:bet]}"
    @show_buttons = false
    session[:chips] -= session[:bet]
    @round_over = true
  end

  erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to stay."
  @show_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_buttons = false
  @show_flop = true

  dealer_total = check_value(session[:dealer_cards])

  case 
  when dealer_total == BLACKJACK
    @error = "Sorry, dealer hit blackjack. You lost $#{session[:bet]}"
    session[:chips] -= session[:bet]
    @round_over = true
  when dealer_total > BLACKJACK
    @success = "Congrats, dealer busted. You won $#{session[:bet]}!"
    session[:chips] += session[:bet]
    @round_over = true
  when dealer_total >= 17
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
  @show_buttons = false
  @show_flop = true

  player_total = check_value(session[:player_cards])
  dealer_total = check_value(session[:dealer_cards])

  case 
  when player_total < dealer_total
    @error = "Sorry, you lost $#{session[:bet]}."
    session[:chips] -= session[:bet]
  when player_total > dealer_total
    @success = "Congrats, you won $#{session[:bet]}!"
    session[:chips] += session[:bet]
  else
    @success = "It's a tie!"
  end

  @round_over = true

  erb :game
end

get '/game/new_bet' do
  erb :new_bet
end

post '/submit_new_bet' do
  case 
  when params[:bet].empty?
    @error = 'Invalid response, please place a bet'
    halt erb(:new_bet)
  when params[:bet].to_i % 5 != 0 
    @error = 'Please bet amount in multiples of 5'
    halt erb(:new_bet)
  end

  session[:bet] = params[:bet].to_i
  redirect '/game'
end

get '/game/thanks' do
  erb :thanks
end



