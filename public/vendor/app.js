$(document).ready(function() {
	$("form#hit input[value=Hit]").on("click", function() {
		$.ajax({
			url: "/game/player/hit",
			type: 'POST'
		}).done(function(msg){
			alert(msg);
		});
	});
});