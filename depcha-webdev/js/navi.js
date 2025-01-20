(function( $ ) {
	

$(document).ready(function(){
	
	function updateDescElementList(htmlStrg){
		$('#descElementList').html(htmlStrg);
	}
	
	$( "input[name='elementSearch']" ).val('');
	
	
	$('div[id="moduleList"] a[id]').click(function(){
		
		if($(this).attr('id') == 'module_all'){
			//all modules are selected
			
			$('.elementLink').css({'display':'block'});
			$('.elementDesc').css({'display':'block'});
			
			updateDescElementList('Das gesamdte Projekt verwendet fogende Elemente:');
			
		}
		else{
			var value = $(this).attr('data-value');
			$('.elementLink').css({'display':'none'});
			$('.elementDesc').css({'display':'none'});
			
			console.log("display block selected elements");
			$('.'+value).css({'display':'block'});
			
			updateDescElementList('Folgende Elemente aus dem Module <strong>' + value.substring(value.indexOf('_')+1) + '</strong> werden im Projekt verwendet:');

		}
		
		console.log("exit click");
	});
	
	
	
	$( "input[name='elementSearch']" ).keyup(function() {
		
		var value = $(this).val();
		
		$('*[id^="tei_"]').css({'display':'none'});
		$('*[id^="tei_'+value+'"]').css({'display':'block'});
		
		$('.elementLink').css({'display':'none'});

		$('a[href^="#tei_'+ value +'"]').parent().css({'display':'block'});
		
		
		if(value == ''){
			$('*[id^="tei_"]').css({'display':'block'});
			$('.elementLink').css({'display':'block'});
		}
		
		updateDescElementList('Die Suche nach dem Wert "' + value + '" ergab folgende Elemente im Projekt:');
		
	});
	
	
});
}( jQuery ));