$(document).ready(function() {
	
	$(document).on('click', 'form#hit input[type=submit', function () {
		$.ajax({
			url: '/game/player/hit',
			type: 'POST'
		}).done(function(msg){
			$("#game").replaceWith(msg);
		});
		return false;
	});
});