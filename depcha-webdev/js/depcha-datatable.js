// name: depcha-datatable.js
// author: Christopher Pollin, Jakob Sonnberger
// last update: 2023

/* variables comming from query:depcha.transactions: */
// ?c  ... measurable_class (bk:classified of ?m)
// ?cl ... measurable_class_label (e.g.: 'work')
// ?e  ... bk:entry
// ?f  ... bk:from
// ?fn ... from_label
// ?m  ... measurable 
// ?mt ... measurable_type (bk:Commodity|bk:Money|bk:Service)
// ?q  ... bk:quantity
// ?t  ... bk:Transaction
// ?tn ... to_label
// ?to ... bk:to
// ?tr ... bk:Transfer
// ?u  ... bk:unit
// ?ul ... unit_label
// ?w  ... bk:when


////////////////////////////////////////////////
// @param: context:depcha.wheaton
// builds query url with cid, fetches JSON result, fills datatable
// param: query = query:depcha.transactions

async function get_datatable(query, pid, context = pid){
  let pid_param = `<https://gams.uni-graz.at/${pid}>`;
  const query_url = gamsJs.query.build(`${BASE_URL}/archive/objects/${query}/methods/sdef:Query/getJSON`, {"$1":pid_param});
  //console.log('query_url: ' + query_url);
  const spinner = document.getElementById("loading_spinner");

  //fetch JSON-SPARQL-Result
  await fetch(query_url, {method: 'get'})
      .then(response => response.json())
      .then(function(data)
      {
        //console.log(data);
        $('#data_table').DataTable({
          'columns': [
            {title: '', data: function(data){
              const myID = data.tr.substring(data.tr.lastIndexOf('/o:depcha.') + 10);
              return `<input type='checkbox' title='Add transaction to the databasket' onclick='add_DB(this)' data-id='${myID}'/>`;
            }}, 
            {title: 'Transaction', data: function(data){
              const myURI = data.t.substring(data.t.lastIndexOf('/'));
              const myText = data.t.substring(data.t.lastIndexOf('/o:depcha.') + 10);
                return buildLink(myText, myURI);
            }}, 
            {title: 'Date', data: data => data.w ?? ''}, 
            {title: 'Entry', data: 'e'}, 
            {title: 'From', data: function(data){
              if (data.f){
              const myURI = `/archive/objects/query:depcha.search.economicagents/methods/sdef:Query/get?params=%241%7C%3C${encodeURIComponent(data.f)}%3E`;
              const myText = data.fn ?? data.f.substring(data.f.lastIndexOf('#'));
                return buildLink(myText, myURI);
            }
            else{return ''}
            }}, 
            {title: 'To', data: function(data){
              if (data.to){
              const myURI = `/archive/objects/query:depcha.search.economicagents/methods/sdef:Query/get?params=%241%7C%3C${encodeURIComponent(data.to)}%3E`;
              const myText = data.tn ?? data.to.substring(data.to.lastIndexOf('#'));
                return buildLink(myText, myURI);
              }
              else{return ''}
            }}, 
            {title: 'Measure', data: 'measure'}, 
            {title: 'Good', data: function(data){
              if(data.c){
                const myURI = `/archive/objects/query:depcha.search.economicgoods/methods/sdef:Query/get?params=%241%7C%3C${encodeURIComponent(data.c)}%3E`;
                const myText = data.cl ?? data.c.substring(data.c.lastIndexOf('#'));
                  return buildLink(myText, myURI);
              }
              else{
                return `[${data.ml}]`;
              }
            }}], 
          'data': data,
          retrieve: true,
          'language': {
            'info': '', 
            'infoFiltered': `<span class='badge bg-dark'><span id='removeFilterYear'></span></span><button class='btn btn-close btn-sm' onclick='removeFilter()'/>`
          }, 
          'aaSorting': [1, 'asc'],
          columnDefs: [
            {'orderable': false, targets: 0},
            {type: 'natural-nohtml', targets: 1}],
          dom: 'Biftp',
          buttons: [{
            extend: 'csv', 
            text: 'CSV Export',
            filename: `${context.replace(/[.:]/g, '_')}_transactions`,
            exportOptions: {columns: [ 1,2,3,4,5,6,7 ]}
          }]
        });
      })
    .catch(function(error) {
      console.log('Request failed', error);
    }).then(()=> {
        spinner.className = "d-none";
        check_Boxes();
    });
};

//loading all transactions in scope (for contexts)
async function load_all_transactions(query, pids, context){
  await get_datatable(query, pids[0], context);
  const spinner = document.getElementById("loading_spinner");
  const n = pids.length;
  console.log(`(1/${n}) loaded`);
  if (pids[1]){
    let otherpids = pids.splice(1, pids.length);
    for ([i, pid] of otherpids.entries()){
      spinner.className = 'd-flex align-items-center';
      let pid_param = `<https://gams.uni-graz.at/${pid}>`;
      let query_url = gamsJs.query.build(`${BASE_URL}/archive/objects/${query}/methods/sdef:Query/getJSON`, {"$1":pid_param});
      await fetch(query_url)
        .then(response => response.json()).catch(error => console.log(`fetching ${i+2}/${n} failed: ${error}`))
        .then(data => {$('#data_table').DataTable().rows.add(data)}).catch(error => console.log(`adding ${i+2}/${n} failed: ${error}`))
        .then(() => {console.log(`(${i+2}/${n}) loaded`)})
    }
    check_Boxes();
    spinner.className = 'd-none';
  }
}

//checks if an entry is already in the databasket and checks box
function check_Boxes(){
	if(localStorage.depcha){
		let databasket = JSON.parse(localStorage.getItem('depcha'));
    for (entry in databasket){
      let candidate = document.querySelector(`#data_table input[data-id='${databasket[entry].datasetID}']`);
      if (candidate) candidate.checked = true;
    }
	}
}

//returns a simple HTML link from text and uri
function buildLink(text, uri){
  return `<a target='blank' href='${uri}'>${text}</a>`
}

//remove datatable filter
function removeFilter(){
  //console.log('filter removed')
  $('#data_table').DataTable().column(2).search('').draw();
};