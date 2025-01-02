// filter-handler.js
// A "female BFS" approach that merges with date range, node type, edge type, etc.

const filterState = {
  activeNodeTypes: new Set(),   // location, institution, commodity
  activeEdgeFilters: new Set(), // marriage, residence, education, commodity, service
  activeGenders: new Set(),     // "male", "female"
  showAll: true,
  fromDate: null,
  toDate: null
};

const MIN_YEAR=1828, MAX_YEAR=1859;

function initializeFilters() {
  // show stats
  updateTotalCounts();

  // node type filters
  document.querySelectorAll('.legend-item[data-type]').forEach(item => {
    item.addEventListener('click', () => {
      const nodeType = item.dataset.type;
      toggleNodeTypeFilter(nodeType);
    });
  });

  // edge type filters
  document.querySelectorAll('.legend-item-filter[data-filter]').forEach(item => {
    item.addEventListener('click', () => {
      const filterType = item.dataset.filter;
      toggleEdgeFilter(filterType);
    });
  });

  // gender filters
  document.querySelectorAll('.legend-item-gender[data-gender]').forEach(item => {
    item.addEventListener('click', () => {
      const g = item.dataset.gender;
      toggleGenderFilter(g);
    });
  });

  // "Show All"
  const showAllBtn = document.querySelector('[data-filter="showAll"]');
  if (showAllBtn) {
    showAllBtn.addEventListener('click', () => {
      filterState.showAll=true;
      filterState.activeNodeTypes.clear();
      filterState.activeEdgeFilters.clear();
      filterState.activeGenders.clear();
      filterState.fromDate=null;
      filterState.toDate=null;
      if(window.dateSlider) {
        window.dateSlider.set([MIN_YEAR,MAX_YEAR]);
      }
      updateVisualization();
    });
  }

  // setup date slider
  setupDateSlider();
  updateFilterCounts();
}

function updateTotalCounts() {
  const tn=document.getElementById("totalNodes");
  const te=document.getElementById("totalEdges");
  if(tn) tn.textContent=nodesData.length;
  if(te) te.textContent=linksData.length;
}

function toggleNodeTypeFilter(nt) {
  if(filterState.activeNodeTypes.has(nt)){
    filterState.activeNodeTypes.delete(nt);
  } else {
    filterState.activeNodeTypes.add(nt);
  }
  checkShowAllState();
  updateVisualization();
}
function toggleEdgeFilter(ft){
  if(filterState.activeEdgeFilters.has(ft)){
    filterState.activeEdgeFilters.delete(ft);
  } else {
    filterState.activeEdgeFilters.add(ft);
  }
  checkShowAllState();
  updateVisualization();
}
function toggleGenderFilter(g){
  if(filterState.activeGenders.has(g)){
    filterState.activeGenders.delete(g);
  } else {
    filterState.activeGenders.add(g);
  }
  checkShowAllState();
  updateVisualization();
}

function checkShowAllState(){
  filterState.showAll=(
    filterState.activeNodeTypes.size===0 &&
    filterState.activeEdgeFilters.size===0 &&
    filterState.activeGenders.size===0 &&
    !filterState.fromDate &&
    !filterState.toDate
  );
}

function setupDateSlider(){
  const slider=document.getElementById("dateRangeSlider");
  if(!slider)return;
  window.dateSlider=noUiSlider.create(slider,{
    start:[MIN_YEAR,MAX_YEAR],
    connect:true,
    range:{min:MIN_YEAR,max:MAX_YEAR},
    step:1,
    tooltips:[true,true],
    format:{to:v=>Math.round(v),from:v=>+v}
  });
  window.dateSlider.on('update', vals=>{
    const fv=parseInt(vals[0],10), tv=parseInt(vals[1],10);
    filterState.fromDate=`${fv}-01-01`;
    filterState.toDate=`${tv}-12-31`;
    filterState.showAll=false;
    updateVisualization();
  });
}

function passesDateFilter(edgeDateStr){
  if(!edgeDateStr)return true;
  if(filterState.fromDate && edgeDateStr<filterState.fromDate)return false;
  if(filterState.toDate && edgeDateStr>filterState.toDate)return false;
  return true;
}

function updateVisualization() {
  if(filterState.showAll){
    d3.selectAll('.node').style("display",null);
    d3.selectAll('.node-label').style("display",null);
    d3.selectAll('.link').style("display",null);
  } else {
    // 1) Hide edges that fail edge type or date range
    d3.selectAll('.link').style("display", link=>{
      if(filterState.activeEdgeFilters.has(link.type))return "none";
      if(filterState.fromDate||filterState.toDate){
        const ds=link.date||link.dateStr;
        if(ds && !passesDateFilter(ds))return "none";
      }
      return null;
    });

    // 2) gather visible edges
    const visibleLinks=[];
    d3.selectAll('.link')
      .filter(function(){return d3.select(this).style("display")!=="none";})
      .each(function(d){visibleLinks.push(d);});

    // 3) from these edges, gather node IDs
    const baseNodeIds=new Set();
    visibleLinks.forEach(l=>{
      const sId=typeof l.source==='object'?l.source.id:l.source;
      const tId=typeof l.target==='object'?l.target.id:l.target;
      baseNodeIds.add(sId); baseNodeIds.add(tId);
    });

    // 4) from that base set, remove node types we want hidden
    //    e.g. location, institution, commodity
    const filteredNodeIds=new Set();
    baseNodeIds.forEach(id=>{
      const node=nodesData.find(n=>n.id===id);
      if(!node) return;
      if(filterState.activeNodeTypes.has(node.type)) {
        // e.g. if we hide "commodity", skip
        return;
      }
      // keep it
      filteredNodeIds.add(id);
    });

    // 5) If the user toggles male or female => BFS logic
    //    If NO gender toggled, we keep all. If "female" toggled => BFS from all female in filteredNodeIds
    //    If "male" toggled => BFS from all male in filteredNodeIds. 
    //    If both toggled => BFS from union. 
    if(filterState.activeGenders.size>0){
      // gather BFS starts
      let starts=[];
      for(const id of filteredNodeIds) {
        const node=nodesData.find(n=>n.id===id);
        if(!node)continue;
        // if node.gender in filterState.activeGenders => it's hidden, right?
        // Actually if a user only toggles "female", do we hide "male"? 
        // We want a BFS *from* female to keep bridging nodes. 
        // So let's do the BFS from female nodes if "female" is toggled, from male if "male" toggled, or from both if both toggled
      }
      // Actually, the user said: "If I click female only, I want subgraph from female BFS." 
      // => We'll do BFS from female nodes *in the filtered set*, then keep bridging nodes

      // BFS from all nodes that pass the "kept" set and have gender in filterState.activeGenders? 
      // Actually we want subgraph "connected" to that gender set. 
      // So let's find BFS starts = "all nodes whose gender is in the *selected* set"
      const BFSstarts = [];
      for(const id of filteredNodeIds){
        const node=nodesData.find(n=>n.id===id);
        if(!node) continue;
        // if user toggled 'female', and node.gender==='female', that node is BFS start
        if(node.gender && filterState.activeGenders.has(node.gender)) {
          BFSstarts.push(id);
        }
      }
      // if BFSstarts is empty => we keep no nodes
      if(BFSstarts.length>0){
        // run BFS
        const visited = vizCore.multiSourceBFS(BFSstarts, Infinity);
        // intersect visited with filteredNodeIds => final
        const finalIds = new Set([...visited].filter(x=>filteredNodeIds.has(x)));
        // that's our final node set
        filteredNodeIds.clear();
        finalIds.forEach(x=>filteredNodeIds.add(x));
      } else {
        // user toggled e.g. "female" but no female node is left after dateRange etc => empty subgraph
        filteredNodeIds.clear();
      }
    }

    // 6) Now we have final set of node IDs
    //    Hide nodes & labels not in final set
    d3.selectAll('.node').style("display", node=>{
      return filteredNodeIds.has(node.id)? null : "none";
    });
    d3.selectAll('.node-label').style("display", node=>{
      return filteredNodeIds.has(node.id)? null : "none";
    });

    // 7) Hide edges that connect to invisible nodes
    d3.selectAll('.link').style("display", link=>{
      const sId=typeof link.source==='object'?link.source.id:link.source;
      const tId=typeof link.target==='object'?link.target.id:link.target;
      if(!filteredNodeIds.has(sId)||!filteredNodeIds.has(tId)){
        return "none";
      }
      return null;
    });
  }

  // Collect final sets for the simulation
  const finalVisibleNodeIds=new Set();
  d3.selectAll('.node')
    .filter(function(){return d3.select(this).style("display")!=="none";})
    .each(function(d){finalVisibleNodeIds.add(d.id);});

  const finalVisibleLinks=[];
  d3.selectAll('.link')
    .filter(function(){return d3.select(this).style("display")!=="none";})
    .each(function(d){finalVisibleLinks.push(d);});

  // update stats
  document.getElementById('visibleNodes').textContent=finalVisibleNodeIds.size;
  document.getElementById('visibleEdges').textContent=finalVisibleLinks.length;

  // re-run
  const filteredNodes=nodesData.filter(n=>finalVisibleNodeIds.has(n.id));
  const filteredLinks=linksData.filter(l=>{
    const sId=typeof l.source==='object'?l.source.id:l.source;
    const tId=typeof l.target==='object'?l.target.id:l.target;
    return finalVisibleNodeIds.has(sId)&&finalVisibleNodeIds.has(tId);
  });

  vizCore.simulation.nodes(filteredNodes);
  vizCore.simulation.force("link").links(filteredLinks);
  vizCore.simulation.alpha(0.3).restart();

  updateFilterButtonStates();
}

function updateFilterCounts(){
  const counts=linksData.reduce((acc,l)=>{
    acc[l.type]=(acc[l.type]||0)+1;
    return acc;
  },{});
  document.querySelectorAll('.legend-item-filter[data-filter]').forEach(item=>{
    const ft=item.dataset.filter;
    const badge=item.querySelector('.badge');
    if(badge) badge.textContent=counts[ft]||0;
  });
}
function updateFilterButtonStates(){
  document.querySelectorAll('.legend-item[data-type]').forEach(item=>{
    const nt=item.dataset.type;
    item.classList.toggle('inactive',filterState.activeNodeTypes.has(nt));
  });
  document.querySelectorAll('.legend-item-filter[data-filter]').forEach(item=>{
    const ft=item.dataset.filter;
    item.classList.toggle('inactive',filterState.activeEdgeFilters.has(ft));
  });
  document.querySelectorAll('.legend-item-gender[data-gender]').forEach(item=>{
    const g=item.dataset.gender;
    item.classList.toggle('inactive',filterState.activeGenders.has(g));
  });
  const showAllBtn=document.querySelector('[data-filter="showAll"]');
  if(showAllBtn){
    showAllBtn.classList.toggle('active',filterState.showAll);
  }
}

document.addEventListener('DOMContentLoaded',initializeFilters);
