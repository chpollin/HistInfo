// name: depcha-collection.js; 
// author: Jakob Sonnberger
// date: 2022
// dependencies: 
// # JSZip (lib\jszip\jszip.min.js), 
// # FileSaver (lib\filesaver\FileSaver.min.js)

let myContext;
let myRDFs = [];
let myTEIs = [];
const RDFzip = new JSZip();
const TEIzip = new JSZip();
const zipFilename = "gamsExport.zip";

$(document).ready(function () {
  //console.log('myRDFs (' + myRDFs.length + '): '+ myRDFs)
  //console.log('myTEIs (' + myTEIs.length + '): ' + myTEIs)
  myRDFs.length > 0 && myRDFs.forEach(function (object) {
    fetch('/' + object, {
        method: 'get',
        mode: 'cors'
      }, )
      .then(data => data.text())
      .then(function (textFile) {
        let fileName = object.substr(0, object.indexOf('/')).replace(':', '_') + '.xml';
        RDFzip.file(fileName, textFile, {
          binary: false
        });
      })
  });
  myTEIs.length > 0 && myTEIs.forEach(function (object) {
    fetch('/' + object, {
        method: 'get',
        mode: 'cors'
      }, )
      .then(data => data.text())
      .then(function (textFile) {
        let fileName = object.replace(/[/:]/g, '_') + '.xml';
        TEIzip.file(fileName, textFile, {
          binary: false
        });
      })
  })

  // loading transaction count from query
  const myContextURI = 'https://gams.uni-graz.at/' + myContext;
  const totals_query = gamsJs.query.build(BASE_URL + "/archive/objects/query:depcha.totals.collection/methods/sdef:Query/getJSON", {"$1": '<' + myContextURI + '>'});
  /*  
  ?o 			... all objects of a collection
  ?nt     ... depcha:numberOfTransactions
  ?nea  	... depcha:numberOfEconomicAgents 
  ?neg  	... depcha:numberOfEconomicGoods
  ?nacc 	... depcha:numberOfAccounts
  */
  fetch(totals_query)
    .then(result => result.json())
    .then(function(myTotals){
      myTotals.forEach(function(total){
        let myPID = total.o.substring(total.o.lastIndexOf('/') + 1)
        let mySpan = document.querySelector('span[data-pid="' + myPID + '"]')
        mySpan.textContent = total.nt;
      });
    });
});

function RDFzipAndDownload(event) {
  event.preventDefault();
  RDFzip.generateAsync({
    type: 'blob'
  }).then(function (content) {
    saveAs(content, myContext.replace(':', '_') + '_RDF.zip');
  })
}

function TEIzipAndDownload(event) {
  event.preventDefault();
  TEIzip.generateAsync({
    type: 'blob'
  }).then(function (content) {
    saveAs(content, myContext.replace(':', '_') + '_TEI.zip');
  })
}