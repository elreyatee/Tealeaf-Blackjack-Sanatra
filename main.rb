require 'rubygems'
require 'sinatra'

set :sessions, true

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
      sum -= 10 if sum > 21
    end
    sum
  end

  def card_image(card) 
    suit = card[0]
    rank = card[1]

    "<img src='/images/cards/#{suit}_#{rank}.svg' class='card'/>"
  end
end

before do
  @show_buttons = true
  @show_flop = false
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
  if player_total == 21
    @success = "Congrats #{session[:username]}! You hit Blackjack!"
    @show_buttons = false
  elsif player_total > 21
    @error = "Sorry, you busted!"
    @show_buttons = false
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

  if dealer_total == 21
    @error = "Sorry, dealer hit blackjack."
  elsif dealer_total > 21
    @success = "Congrats, dealer busted. You win!"
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
  @show_buttons = false
  @show_flop = true

  player_total = check_value(session[:player_cards])
  dealer_total = check_value(session[:dealer_cards])

  if player_total < dealer_total
    @error = "Sorry, you lost."
  elsif player_total > dealer_total
    @success = "Congrats, you won!"
  else
    @success = "It's a tie!"
  end

  erb :game
end



