$(document).ready(function() {
	
	$(document).on('click', 'form#hit input', function () {
		$.ajax({
			url: '/game/player/hit',
			type: 'POST'
		}).done(function(msg){
			$('#game').replaceWith(msg);
		});
		return false;
	});

	$(document).on('click', 'form#stay input', function() {
		$.ajax({
			url: '/game/player/stay',
			type: 'POST'
		}).done(function(msg){
			$('#game').replaceWith(msg);
		});

		window.location.href = '#dealer-cards';
		return false;
	});

	$(document).on('click', 'form#dealer_hit input', function() {
		$.ajax({
			url: '/game/dealer/hit',
			type: 'POST'
		}).done(function(msg){
			$('#game').replaceWith(msg);
		});
		return false;
	});
});