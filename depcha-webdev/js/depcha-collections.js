const cards = document.getElementsByClassName('collectionCard');;

// get min and max covered dates for slider
let mins =[], maxs =[];
for (let count = 0; count < cards.length; count++) {
    let card = cards[count];
    let min = parseInt(card.getAttribute('data-from'));
    let max = parseInt(card.getAttribute('data-to'));
    min && mins.push(min);
    max && maxs.push(max);
};
const minDate = Math.min(...mins), maxDate = Math.max(...maxs);
//console.log('Collections: ' + minDate + ' - ' + maxDate);

// initialize Time Slider
let timeSlider = document.getElementById('timeSlider');
noUiSlider.create(timeSlider, {
    // Start values
    start:[minDate, maxDate],
    connect: true,
    step: 1,
    format: wNumb({
        decimals: 0
    }),
    tooltips: true,
    // Min/Max values
    range: {
        'min': minDate,
        'max': maxDate
    }
});

// filters cards (div.collectionCard) in context:depcha -> Collections via fulltext inside the card, subject (@data-subject) and timespan (@data-from/@data-to)
function searchCollection() {
    //text
    let input = document.getElementById('collections-filter').value.toUpperCase();
    //slider
    let sliderMin = parseInt(timeSlider.noUiSlider. get ()[0]);
    let sliderMax = parseInt(timeSlider.noUiSlider. get ()[1]);
    //checkboxes
    let subjects = [""];
    let checkedBoxes = document.querySelectorAll('.subjectCheckbox:checked');
    for (let count = 0; count < checkedBoxes.length; count++) {
        subjects.push(checkedBoxes[count].value);
    }
    //CONDITIONS
    for (let count = 0; count < cards.length; count++) {
        let card = cards[count];
        let collectionFrom = parseInt(card.getAttribute('data-from'));
        let collectionTo = parseInt(card.getAttribute('data-to'));
        let collectionSubject = card.getAttribute('data-subject').split(', ');
        card.innerText.toUpperCase().indexOf(input) < 0 || sliderMin > collectionTo || sliderMax < collectionFrom || collectionSubject.every(s => subjects.indexOf(s) < 0) ? card.style.display = "none" : card.style.display = "";
    }
    //console.log('Text: ' + input);
    //console.log('Subjects: ' + subjects);
    //console.log('Timespan: ' + sliderMin + ' - ' + sliderMax);
}

// call searchCollection() when adjusting slider
timeSlider.noUiSlider.on('slide', searchCollection);

//resetting all filters, showing all cards/collections
function resetFilters(){
    //click all boxes
    let boxes = document.querySelectorAll('.subjectCheckbox');
    for (let count = 0; count < boxes.length; count++) {
        let box = boxes[count];
        box.checked = true;
    };
    //reset slider
    timeSlider.noUiSlider. set ([minDate, maxDate]);
    //clear text filter
    document.getElementById('collections-filter').value = '';
    //show all cards
    for (let count = 0; count < cards.length; count++) {
        let card = cards[count];
        card.style.display = "";
    }
};


// get aggregated number of transactions, economic agents, economic goods and accounts from the collections 
// and insert into collections cards in collections view
totals_query_url = "/archive/objects/query:depcha.totals.context/methods/sdef:Query/getJSON";

//get data from query in JSON format
fetch(totals_query_url, {method: 'get'})
    .then(function(response) 
    { data = (response.json())	
    .then(function(data)
    {
        //console.log(data)

        for (let d in data) {
            dataset = data[d]
            // TODO: remove this part after gwfp RDF is fixed !
           if (String(dataset.collectionID) == '') {
                dataset.collectionID = "context:depcha.gwfp"
            }

            //console.log(String(dataset.collectionID)) 

            
            //get collection card that corresponds to JSON array for  
            collection_card = document.getElementById(String(dataset.collectionID))
            
            // insert number of transactions, economic agents, economic goods and accounts in corresponding elements
            collection_card.getElementsByClassName("nt")[0].innerHTML = dataset.int_nt
            collection_card.getElementsByClassName("neg")[0].innerHTML = dataset.int_neg
            collection_card.getElementsByClassName("nea")[0].innerHTML = dataset.int_nea
            collection_card.getElementsByClassName("nacc")[0].innerHTML = dataset.int_nacc


            
        }
    });
});


//hide and show the teaser text when toggling full description
function toggle_teaser(teaser) {

       if (teaser.style.display === "block") {
            teaser.style.display = "none";
            
            } else {
            teaser.style.display = "block";
                   
            }  
        
}
