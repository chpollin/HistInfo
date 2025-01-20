// project: depcha
// author: Sonnberger Jakob
// last update: 03/2023

//add databasket entry via checkbox in transaction table
function add_DB(checkBox){
    let databasket = JSON.parse(localStorage.getItem('depcha')) || [];
    const dataset = checkBox.closest('tr');
	const datasetID = checkBox.getAttribute('data-id');
	if(checkBox.checked){
		/*
		/ Die Zählung über den Index ist unschön, den tr ein Bezeichnung (class?) mitgeben?
		/ Oder überhaupt die die Einträge nochmal als data-Attribute an die tr hängen (mehr Code)?
		*/
		let dbEntry = {};
		dbEntry.datasetID = datasetID;
		//td[0] is the checkbox itself
		dbEntry.id = dataset.querySelectorAll('td')[1].innerHTML.trim();
		dbEntry.date = dataset.querySelectorAll('td')[2].innerHTML.trim();
		dbEntry.entry = dataset.querySelectorAll('td')[3].innerHTML.trim();
		dbEntry.from = dataset.querySelectorAll('td')[4].innerHTML.trim();
		dbEntry.to = dataset.querySelectorAll('td')[5].innerHTML.trim();
		dbEntry.measure = dataset.querySelectorAll('td')[6].innerHTML.trim();
		dbEntry.good = dataset.querySelectorAll('td')[7].innerHTML.trim();
		databasket.push(dbEntry);
		count_DB(databasket);
		blink_DB();
	}
	else{
		del_DB(datasetID, databasket)
	}
	localStorage.setItem('depcha', JSON.stringify(databasket));
	//console.log('Databasket after addition: ' + databasket);
};

//remove databasket entry via trash icon in databasket section
function kick_DB(icon){
	let kickedRow = icon.closest('tr');
	let kickedID = kickedRow.getAttribute('data-id');
	//console.log('kickedID: ' + kickedID);
	del_DB(kickedID);
	kickedRow.remove();
	location.reload(); // geht das schöner?
}

//delete entry via id from local storage
function del_DB(id, basket = JSON.parse(localStorage['depcha'])){
	let i = basket.indexOf(basket.find(x => x.datasetID == id));
	basket.splice(i,1);
	count_DB(basket);
	localStorage.setItem('depcha', JSON.stringify(basket));
	//console.log('Databasket after deletion: ' + basket)
	blink_DB();
}	

//build databasket table from local storage in databasket section
function show_DB(){	
	if(localStorage.depcha){
		//initalize the localStorage-Array
		const databasket = JSON.parse(localStorage['depcha']);	
		const tbody = document.querySelector("#db_table tbody");
		for (entry in databasket){
			/* Warum gibt entry hier eigentlich nur den Index zurück? */
			let dbEntry = databasket[entry];
			let tr = makeMe('tr', tbody);
			tr.setAttribute('data-id', dbEntry.datasetID);
			/* td[0] */let tdID = makeMe('td', tr, dbEntry.id);
			/* td[1] */let tdDate = makeMe('td', tr, dbEntry.date);
			/* td[2] */let tdEntry = makeMe('td', tr, dbEntry.entry);
			/* td[3] */let tdFrom = makeMe('td', tr, dbEntry.from);
			/* td[4] */let tdTo = makeMe('td', tr, dbEntry.to);
			/* td[5] */let tdMeasure = makeMe('td', tr, dbEntry.measure);
			/* td[6] */let tdGood = makeMe('td', tr, dbEntry.good);
			/* td[7] */let tdDel = makeMe('td', tr);
			let iconDel = makeMe('i', tdDel, null, 'fas fa-trash');
			iconDel.setAttribute("onclick", "kick_DB(this)");
			iconDel.setAttribute("title", "remove entry from databasket")
		}
	}
}

//count DB entries & show in navbar
function count_DB(basket = localStorage.depcha ? JSON.parse(localStorage['depcha']) : []){
	let count = basket.length;
 	//console.log('DB-entries: ' + count);
 	document.getElementById('dbCount').textContent = count;
}

//let number of basket entries in menu blink
function blink_DB(){
	let dbCount = document.getElementById('dbCount');
	dbCount.style.fontWeight = 'bold';
	setTimeout(function() {
		dbCount.style.fontWeight = null;
	}, 100);
}

//clear local storage and databasket table
function clear_DB(){
 localStorage.clear();
 location.reload(); // geht das schöner?
 blink_DB();
}

///AUX FUNCTIONS
// this function creates and appends an html element, 'element_content' and 'element_class' are optional
function makeMe(element, parentElement, element_content, element_class){
    element = document.createElement(element)
    parentElement.appendChild(element);
    if(element_content){element.innerHTML = element_content};
	if(element_class){element.className = element_class}
    return element;   
}