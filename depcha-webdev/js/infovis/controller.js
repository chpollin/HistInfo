/*    
 * author: Christopher Pollin
 * company: ZIM
 * purpose: InfoVis Controller for DEPCHA Dashboard View 
 * last update: 03/2023
*/

const dashboar_loading_spinner = document.getElementById("dashboar_loading_spinner");

// load the first infovis onload
//# eg query: 'query:depcha.infovis.aggregation.year'
//# eg context: 'context:depcha.gwfp'
function treeMapOnLoad(query, context) {
    //console.log('treemap at start')
    fetch('/archive/objects/' + query + '/methods/sdef:Query/getJSON?params=$1%7C%3Chttps://gams.uni-graz.at/' + context + '%3E')
        .then(result => result.json())
        .then(resultJSON => resultJSON[0] ? createTreeMap(resultJSON, '#depcha_treemap') : console.log('No Data!')
    );
    dashboar_loading_spinner.className = "d-none";
};

// this function calls function that creates the infovis and keeps all already existing infovis hidden and controls the correct hiding!
function switch_infovis_view(infoVis_id, query_url, infovis_type){

    const dashboard = document.querySelector("#infovis_dashboard");
    const container = document.querySelector(infoVis_id);
    // hide infovis created onload
    document.querySelector('#depcha_treemap').classList.add("d-none")
    dashboar_loading_spinner.classList.remove("d-none");
    for (let div of dashboard.children) div.classList.add("d-none");
    if(!container.getElementsByTagName('svg').length)
    {
        //console.log("Query URL InfoVis: " + query_url)
        fetch(query_url).then(
            result => result.json()).then(
            resultJSON => {
                switch (infovis_type) {
                    case 'treemap':
                        //console.log('treemap');
                        resultJSON[0] ? createTreeMap(resultJSON, infoVis_id) : console.log('No Data!'); 
                        dashboar_loading_spinner.className = "d-none";
                        break;
                    case 'barchart': 
                        //console.log('barchart');
                        resultJSON[0] ? createBarChart(resultJSON, infoVis_id) : console.log('No Data!');
                        dashboar_loading_spinner.className = "d-none";
                        for (let div of dashboard.children) div.classList.add("d-none")
                        container.classList.remove("d-none");
                        break;
                    case 'circlepacking': 
                        //console.log('circlepacking');
                        resultJSON[0] ? createCirclePacking(resultJSON, infoVis_id) : console.log('No Data!');
                        dashboar_loading_spinner.className = "d-none";
                        container.classList.remove("d-none");
                        break;
                    case 'linechart': 
                        //console.log('linechart');
                        resultJSON[0] ? createLineChart(resultJSON, infoVis_id) : console.log('No Data!');
                        dashboar_loading_spinner.className = "d-none";
                        container.classList.remove("d-none");
                        break;
                    default:
                        console.log('no vis');
                        break;
                }
            });
    }
    // otherwise hide all other?
    else
    {  
        // hide all existing info vis
        for (let div of dashboard.children) div.classList.add("d-none");
        container.classList.remove("d-none");
    }

}

// resize infovis, transactions table
let fullscreenTrans = false;
let fullscreenVis = false;
let dbHead = document.querySelector('#dashboardHead');
let dbNav = document.querySelector('#dashboardNav');
let transCol = document.querySelector('#transactionsCol');
let visCol = document.querySelector('#visualizationsCol');
let transSwitch = document.querySelector('#transactionsSwitch');
let visSwitch = document.querySelector('#visualizationsSwitch');

// # resize infovis
function resize_vis(){
    if(fullscreenVis){
        transCol.className = "col-md-7";
        visCol.className = "col-md-5";
        dbHead.classList.remove("d-none");
        dbNav.classList.remove("d-none");
        visSwitch.className = "bi bi-arrows-fullscreen";
        fullscreenVis = false;
    }
    else{
        transCol.className = "d-none";
        visCol.className = "col-md-12";
        fullscreenVis = true;
        visSwitch.className = "bi bi-arrows-angle-contract";
        dbHead.classList.add("d-none");
        dbNav.classList.add("d-none");
    }
}

// # resize transactions table
function resize_trans(){
    if(fullscreenTrans){
        transCol.className = "col-md-7";
        visCol.className = "col-md-5";
        dbHead.classList.remove("d-none");
        dbNav.classList.remove("d-none");
        transSwitch.className = "bi bi-arrows-fullscreen";
        fullscreenTrans = false;
    }
    else{
        transCol.className = "col-md-12";
        visCol.className = "d-none";
        fullscreenTrans = true;
        transSwitch.className = "bi bi-arrows-angle-contract";
        dbHead.classList.add("d-none");
        dbNav.classList.add("d-none");
    }
}

//round to max 2 digits
function rnd2(x){
    return Math.round(x * 100) / 100;
}

//custom format for currencies
function myCurrencyFormat(myValue, myCurrency) {
    //if 'dollar' => '$', 'pound' => '£', 'livre' => '₤' ... otherwise just take the string value + whitespace
    myCurrency = myCurrency == 'dollar' ? '$' : myCurrency == 'pound' ? '£' : myCurrency == 'livre' ? '₤' : myCurrency + ' '; 
    const myLocale = d3.formatLocale({
        thousands: ' ',
        grouping: [3],
        currency: [myCurrency, '']
    }).format('$,.2f');//2 decimals fixed (=rounded(!?))
    return myLocale(myValue);
};

//filter datatable by year
function setDatatableFilter(myYear){
    $('#data_table').DataTable().column(2).search(String(myYear)).draw();
    document.getElementById('removeFilterYear').textContent = myYear;
};