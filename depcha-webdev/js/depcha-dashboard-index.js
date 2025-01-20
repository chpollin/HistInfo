// name: depcha-dashboard-index.js;
// author: Christopher Pollin
// date: 2021
// dependencies:

/*
 Queries data and represents it as a html list in the depcha dashboard.
 param:
 * CONTEXT --> https://gams.uni-graz.at/context:depcha.schlandersberger
 * ID --> 'assets-index-content', id of the html div, where the reslt is appended
 * QUERY --> 'query:depcha-dashboard-index-assets' --> pid of the sparl query objet
 */
function jsonResult_to_IndexList (CONTEXT, ID, QUERY) {

    const div = document.getElementById(ID);
    // for only creating one list
    if (! div.classList.contains("list-group")) {
        div.classList.add("list-group");
        div.classList.add("list-group-flush");
        const QUERY_URL = gamsJs.query.build(BASE_URL + "/archive/objects/" + QUERY + "/methods/sdef:Query/getJSON", {
            "$1": "<" + CONTEXT + ">"
        });
        //console.log('QUERY-URL: ' + QUERY_URL);
        
        fetch(QUERY_URL, {
            method: 'get'
        }).then(response => response.json()).then(function (data) {
            //console.log('RAW DATA: ');
            //console.log(data);
            // specific data for query:depcha.dashboard.index.economicgoods
            if (QUERY == 'query:depcha.dashboard.index.economicgoods') {
                
                data = gamsJs.utils.groupBy(data, 'topConcept'??'group');
                Object.values(data).forEach(function(n) {
                    n.total = n.count.reduce((partial, x) => partial + parseInt(x), 0)
                });

                for (n in data) {
                    let item = document.createElement("div");
                    item.classList.add("list-data-item");
                    item.classList.add("py-2");
                    div.append(item)
                    
                    let row = document.createElement("div");
                    row.classList.add("row");
                    item.append(row);
                    
                    if (data[n].topConceptName){
                        let h3 = document.createElement("h3");
                        h3.textContent = data[n].topConceptName[0];
                        row.prepend(h3);
                    
                        let topSpan = document.createElement("span");
                        topSpan.classList.add("badge", "rounded-pill", "text-dark", "bg-light", "border", "ms-1");
                        topSpan.textContent = data[n].total;
                        h3.append(topSpan);
                    }
                    
                    for (let m = 0; m < data[n].name.length; m++) {
                        
                        let h5 = document.createElement("h5");
                        h5.classList.add("col-8");
                        h5.classList.add("ps-4");
                        row.append(h5)
                        h5.textContent = data[n].name[m] + " ";
                        
                        let span = document.createElement("span");
                        span.classList.add("badge", "rounded-pill", "bg-dark");
                        span.textContent = data[n].count[m];
                        h5.append(span);
                        
                        let span_col = document.createElement("span");
                        span_col.classList.add("col-4");
                        row.append(span_col);
                        
                        let a = document.createElement("a");
                        let i = document.createElement("i");
                        a.href = gamsJs.query.build(BASE_URL + "/archive/objects/query:depcha.search.economicgoods/methods/sdef:Query/get", {
                            "$1": "<" + data[n].group[m] + ">"
                        });
                        a.setAttribute('target', '_blank')
                        i.textContent = " ";
                        
                        i.classList.add("bi");
                        i.classList.add("bi-search");
                        i.classList.add("link-dark");
                        a.append(i);
                        span_col.append(a);
                    }
                    
                    let hr = document.createElement("hr");
                    row.append(hr);
                }
                // for query:depcha.dashboard.index.economicagents, query:depcha.dashboard.index.accounts, query:depcha.dashboard.index.units & query:depcha.dashboard.index.places
            } else {
                
                data = data.sort((a, b) => b.count - a.count);
                //console.log('DATA: ')
                //console.log(data)
                for (n in data) {
                    let item = document.createElement("div");
                    item.classList.add("list-group-item");
                    item.classList.add("py-2");
                    div.append(item)
                    
                    let row = document.createElement("div");
                    row.classList.add("row");
                    item.append(row);

                    let left_col = document.createElement("col");
                    left_col.classList.add("col-8");
                    row.append(left_col);

                    let right_col = document.createElement("col");
                    right_col.classList.add("col-4");
                    row.append(right_col);
                    
                    let h5 = document.createElement("h5");
                    h5.classList.add("col-4");
                    let uriFragment = data[n].group.substring(data[n].group.indexOf('#'))
                    //console.log(uriFragment);
                    h5.textContent = (data[n].name||uriFragment) + " ";
                    left_col.append(h5)
                    
                    let span = document.createElement("span");
                    span.classList.add("badge", "rounded-pill", "bg-dark");
                    span.textContent = data[n].count;
                    h5.append(span);
                    
                    
                    let a = document.createElement("a");
                    let i = document.createElement("i");
                    
                    // specific data for query:depcha.dashboard.index.economicagents, query:depcha.dashboard.index.accounts
                    if (QUERY == 'query:depcha.dashboard.index.economicagents'||'query:depcha.dashboard.index.accounts') {
                        a.href = gamsJs.query.build(BASE_URL + "/archive/objects/query:depcha.search.economicagents/methods/sdef:Query/get", {
                            "$1": "<" + data[n].group + ">"
                        });
                    }
                    // specific data for query:depcha.dashboard.index.units
                    if (QUERY == 'query:depcha.dashboard.index.units') {
                        a.href = gamsJs.query.build(BASE_URL + "/archive/objects/query:depcha.search.units/methods/sdef:Query/get", {
                            "$1": "<" + data[n].group + ">"
                        });
                    }
                    // specific data for query:depcha.dashboard.index.places
                    if (QUERY == 'query:depcha.dashboard.index.places') {
                        let settlement = data[n].containedInPlace;
                        if (settlement){
                            let span_containedInPlace = document.createElement("p");
                            span_containedInPlace.textContent = "Settlement: " + settlement;
                            left_col.append(span_containedInPlace);
                        }
                        let longitude = data[n].longitude;
                        if (longitude){
                            let span_longitude = document.createElement("p");
                            span_longitude.textContent = "Longitude: " + longitude;
                            left_col.append(span_longitude);
                        }
                        let latitude = data[n].latitude;
                        if (latitude){
                            let span_latitude = document.createElement("p");
                            span_latitude.textContent = "Latitude: " + latitude;
                            left_col.append(span_latitude);
                        }
                        a.href = gamsJs.query.build(BASE_URL + "/archive/objects/query:depcha.search.places/methods/sdef:Query/get", {
                            "$1": "<" + data[n].group + ">"
                        });
                    }
                    
                    a.setAttribute('target', '_blank')
                    i.textContent = " ";
                    
                    i.classList.add("bi");
                    i.classList.add("bi-search");
                    i.classList.add("link-dark");
                    a.append(i);
                    right_col.append(a);
                }
            }
            //console.log('GROUPED DATA: ');
            //console.log(data);
        }). catch (function (error) {
            console.log('Request failed', error);
        });
    }
}