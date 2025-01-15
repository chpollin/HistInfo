/**
 * filter-handler.js
 *
 * Description:
 *   Manages all user filter interactions for the Wheaton Network Visualization:
 *   - Node type filters (location, institution, commodity)
 *   - Edge type filters (marriage, residence, education, commodity, service)
 *   - Gender toggles (male, female), optionally with BFS expansions
 *   - Date range slider (noUiSlider) to filter by year
 *   - Roles & categories (e.g., "commodity_provider", "economic" vs. "social")
 *   - A "Show All" button to reset everything
 *   - Merges these conditions in updateVisualization() to hide/show nodes & links,
 *     re-running the D3 force simulation on the resulting subgraph.
 *
 * Responsibilities:
 *   - Maintains a global filterState object tracking each filter's active state.
 *   - Provides BFS-based expansions if certain toggles (like gender) are set.
 *   - Ties each UI element (legend items, date slider) to logic that calls updateVisualization().
 *   - Re-renders the subgraph, updating node/edge display, counting visible nodes/edges,
 *     and re-running the force simulation with the final set.
 *
 * Dependencies:
 *   - Must load after data.js (defines nodesData & linksData).
 *   - Usually loaded before vis-core.js if BFS expansions are triggered here,
 *     but after it if you rely on `vizCore.multiSourceBFS`. Ensure both are present.
 *
 * Author:
 *   [Your Name / Team]
 * Date:
 *   [Year or version]
 */

console.log("Initializing filter-handler...");

// The central filter state
const filterState = {
  activeNodeTypes: new Set(),   // location, institution, commodity
  activeEdgeFilters: new Set(), // marriage, residence, education, commodity, service
  activeGenders: new Set(),     // "male", "female"
  activeRoles: new Set(),       // "commodity_provider", "commodity_recipient", etc.
  activeCategories: new Set(),  // "economic", "social"
  showAll: true,
  fromDate: null,
  toDate: null
};

// Typical date range in the Day Book
const MIN_YEAR = 1828;
const MAX_YEAR = 1859;

/**
 * Initializes all filter UI elements and sets up event listeners.
 */
function initializeFilters() {
  // Show total nodes/edges from data.js
  updateTotalCounts();

  // 1) Node type filters
  document.querySelectorAll('.legend-item[data-type]').forEach(item => {
    item.addEventListener('click', () => {
      const nodeType = item.dataset.type;
      toggleNodeTypeFilter(nodeType);
    });
  });

  // 2) Edge type filters
  document.querySelectorAll('.legend-item-filter[data-filter]').forEach(item => {
    item.addEventListener('click', () => {
      const filterType = item.dataset.filter;
      toggleEdgeFilter(filterType);
    });
  });

  // 3) Gender filters
  document.querySelectorAll('.legend-item-gender[data-gender]').forEach(item => {
    item.addEventListener('click', () => {
      const g = item.dataset.gender;
      toggleGenderFilter(g);
    });
  });

  // 4) Role filters
  document.querySelectorAll('.legend-item-role[data-role]').forEach(item => {
    item.addEventListener('click', () => {
      const r = item.dataset.role;
      toggleRoleFilter(r);
    });
  });

  // 5) Category filters
  document.querySelectorAll('.legend-item-category[data-cat]').forEach(item => {
    item.addEventListener('click', () => {
      const c = item.dataset.cat;
      toggleCategoryFilter(c);
    });
  });

  // 6) "Show All" button
  const showAllBtn = document.querySelector('[data-filter="showAll"]');
  if (showAllBtn) {
    showAllBtn.addEventListener('click', () => {
      filterState.showAll = true;
      filterState.activeNodeTypes.clear();
      filterState.activeEdgeFilters.clear();
      filterState.activeGenders.clear();
      filterState.activeRoles.clear();
      filterState.activeCategories.clear();
      filterState.fromDate = null;
      filterState.toDate = null;
      if (window.dateSlider) {
        window.dateSlider.set([MIN_YEAR, MAX_YEAR]);
      }
      updateVisualization();
    });
  }

  // 7) Setup date slider
  setupDateSlider();

  // 8) Show how many links of each type exist
  updateFilterCounts();

  // 9) Initial draw
  updateVisualization();
}

/**
 * Sets the total node/edge counts from data.js (nodesData, linksData).
 */
function updateTotalCounts() {
  const tn = document.getElementById("totalNodes");
  const te = document.getElementById("totalEdges");
  if (tn) tn.textContent = nodesData.length;
  if (te) te.textContent = linksData.length;
}

/**
 * Toggles a node type (location, institution, commodity). Then re-renders.
 */
function toggleNodeTypeFilter(nt) {
  if (filterState.activeNodeTypes.has(nt)) {
    filterState.activeNodeTypes.delete(nt);
  } else {
    filterState.activeNodeTypes.add(nt);
  }
  checkShowAllState();
  updateVisualization();
}

/**
 * Toggles an edge filter (e.g. "marriage", "commodity", etc.). Then re-renders.
 */
function toggleEdgeFilter(ft) {
  if (filterState.activeEdgeFilters.has(ft)) {
    filterState.activeEdgeFilters.delete(ft);
  } else {
    filterState.activeEdgeFilters.add(ft);
  }
  checkShowAllState();
  updateVisualization();
}

/**
 * Toggles a gender filter (male/female). BFS expansions might apply if coded so.
 */
function toggleGenderFilter(g) {
  if (filterState.activeGenders.has(g)) {
    filterState.activeGenders.delete(g);
  } else {
    filterState.activeGenders.add(g);
  }
  checkShowAllState();
  updateVisualization();
}

/**
 * Toggles a role filter (e.g. "commodity_provider").
 */
function toggleRoleFilter(r) {
  if (filterState.activeRoles.has(r)) {
    filterState.activeRoles.delete(r);
  } else {
    filterState.activeRoles.add(r);
  }
  checkShowAllState();
  updateVisualization();
}

/**
 * Toggles a category (e.g. "economic", "social").
 */
function toggleCategoryFilter(c) {
  if (filterState.activeCategories.has(c)) {
    filterState.activeCategories.delete(c);
  } else {
    filterState.activeCategories.add(c);
  }
  checkShowAllState();
  updateVisualization();
}

/**
 * If all sets are empty and date range is default, we set showAll = true.
 */
function checkShowAllState() {
  filterState.showAll =
    (filterState.activeNodeTypes.size === 0 &&
     filterState.activeEdgeFilters.size === 0 &&
     filterState.activeGenders.size === 0 &&
     filterState.activeRoles.size === 0 &&
     filterState.activeCategories.size === 0 &&
     !filterState.fromDate &&
     !filterState.toDate);
}

/**
 * Setup noUiSlider for the date range (MIN_YEAR–MAX_YEAR).
 */
function setupDateSlider() {
  const slider = document.getElementById("dateRangeSlider");
  if (!slider) return;
  window.dateSlider = noUiSlider.create(slider, {
    start: [MIN_YEAR, MAX_YEAR],
    connect: true,
    range: { min: MIN_YEAR, max: MAX_YEAR },
    step: 1,
    tooltips: [true, true],
    format: { to: v => Math.round(v), from: v => +v }
  });
  window.dateSlider.on('update', vals => {
    const fv = parseInt(vals[0], 10);
    const tv = parseInt(vals[1], 10);
    filterState.fromDate = `${fv}-01-01`;
    filterState.toDate = `${tv}-12-31`;
    filterState.showAll = false;
    updateVisualization();
  });
}

/**
 * Checks whether an edge's date is within the active date range.
 */
function passesDateFilter(edgeDateStr) {
  if (!edgeDateStr) return true;
  if (filterState.fromDate && edgeDateStr < filterState.fromDate) return false;
  if (filterState.toDate && edgeDateStr > filterState.toDate) return false;
  return true;
}

/**
 * The main function that merges filter conditions and toggles node/edge visibility.
 */
function updateVisualization() {
  if (filterState.showAll) {
    // Show everything
    d3.selectAll('.node').style("display", null);
    d3.selectAll('.node-label').style("display", null);
    d3.selectAll('.link').style("display", null);
    d3.selectAll('.link-label').style("display", null);
  } else {
    // Step 1: Hide edges that fail edge-type, category, or date range
    d3.selectAll('.link')
      .style("display", link => {
        if (filterState.activeEdgeFilters.has(link.type)) return "none";
        if (filterState.activeCategories.has(link.category)) return "none";
        if ((filterState.fromDate || filterState.toDate) &&
            !passesDateFilter(link.date)) {
          return "none";
        }
        return null; // keep visible
      });

    // Step 2: gather visible edges
    const visibleLinks = [];
    d3.selectAll('.link')
      .filter(function() {
        return d3.select(this).style("display") !== "none";
      })
      .each(function(d) {
        visibleLinks.push(d);
      });

    // Step 3: from these edges, gather node IDs
    const baseNodeIds = new Set();
    visibleLinks.forEach(l => {
      const sId = typeof l.source === 'object' ? l.source.id : l.source;
      const tId = typeof l.target === 'object' ? l.target.id : l.target;
      baseNodeIds.add(sId);
      baseNodeIds.add(tId);
    });

    // Step 4: Filter out node types or roles we want hidden
    const filteredNodeIds = new Set();
    baseNodeIds.forEach(id => {
      const node = nodesData.find(n => n.id === id);
      if (!node) return;

      // If the node's type is toggled => hide it
      if (filterState.activeNodeTypes.has(node.type)) return;

      // If roles are toggled => keep only nodes that match at least one toggled role
      if (filterState.activeRoles.size > 0) {
        const hasRole = node.roles.some(r => filterState.activeRoles.has(r));
        if (!hasRole) return;
      }

      filteredNodeIds.add(id);
    });

    // Step 5: BFS expansions for gender toggles
    if (filterState.activeGenders.size > 0) {
      // gather BFS starts from all nodes whose gender is toggled
      const BFSstarts = [];
      for (const id of filteredNodeIds) {
        const node = nodesData.find(n => n.id === id);
        if (node && node.gender && filterState.activeGenders.has(node.gender)) {
          BFSstarts.push(id);
        }
      }
      // If BFSstarts is non-empty => run BFS. Otherwise => no nodes remain
      if (BFSstarts.length > 0) {
        const visited = vizCore.multiSourceBFS(BFSstarts, Infinity);
        const finalIds = new Set([...visited].filter(x => filteredNodeIds.has(x)));
        filteredNodeIds.clear();
        finalIds.forEach(x => filteredNodeIds.add(x));
      } else {
        filteredNodeIds.clear();
      }
    }

    // Step 6: Hide nodes/labels not in final set
    d3.selectAll('.node').style("display", node =>
      filteredNodeIds.has(node.id) ? null : "none"
    );
    d3.selectAll('.node-label').style("display", node =>
      filteredNodeIds.has(node.id) ? null : "none"
    );

    // Step 7: Hide edges whose endpoints aren’t both in final set
    d3.selectAll('.link').style("display", function(link) {
      const sId = typeof link.source === 'object' ? link.source.id : link.source;
      const tId = typeof link.target === 'object' ? link.target.id : link.target;
      if (!filteredNodeIds.has(sId) || !filteredNodeIds.has(tId)) {
        return "none";
      }
      return d3.select(this).style("display"); // keep previous setting
    });

    // Also hide link labels for hidden edges
    d3.selectAll('.link-label').style("display", link => {
      const sId = typeof link.source === 'object' ? link.source.id : link.source;
      const tId = typeof link.target === 'object' ? link.target.id : link.target;
      return (!filteredNodeIds.has(sId) || !filteredNodeIds.has(tId)) ? "none" : null;
    });
  }

  // Collect final sets for the D3 simulation
  const finalVisibleNodeIds = new Set();
  d3.selectAll('.node')
    .filter(function() {
      return d3.select(this).style("display") !== "none";
    })
    .each(function(d) {
      finalVisibleNodeIds.add(d.id);
    });

  const finalVisibleLinks = [];
  d3.selectAll('.link')
    .filter(function() {
      return d3.select(this).style("display") !== "none";
    })
    .each(function(d) {
      finalVisibleLinks.push(d);
    });

  // 8) Update stats
  document.getElementById('visibleNodes').textContent = finalVisibleNodeIds.size;
  document.getElementById('visibleEdges').textContent = finalVisibleLinks.length;

  // 9) Re-run the force simulation with the final sets
  const filteredNodes = nodesData.filter(n => finalVisibleNodeIds.has(n.id));
  const filteredLinks = linksData.filter(l => {
    const sId = typeof l.source === 'object' ? l.source.id : l.source;
    const tId = typeof l.target === 'object' ? l.target.id : l.target;
    return finalVisibleNodeIds.has(sId) && finalVisibleNodeIds.has(tId);
  });

  // Re-assign nodes & links to the force simulation
  vizCore.simulation.nodes(filteredNodes);
  vizCore.simulation.force("link").links(filteredLinks);
  vizCore.simulation.alpha(0.3).restart();

  updateFilterButtonStates();
}

/**
 * Show how many edges of each type exist, updating the badges in the UI.
 */
function updateFilterCounts() {
  const counts = linksData.reduce((acc, l) => {
    acc[l.type] = (acc[l.type] || 0) + 1;
    return acc;
  }, {});
  document.querySelectorAll('.legend-item-filter[data-filter]').forEach(item => {
    const ft = item.dataset.filter;
    const badge = item.querySelector('.badge');
    if (badge) badge.textContent = counts[ft] || 0;
  });
}

/**
 * Reflect active/inactive states in the UI legend items (dim if active).
 */
function updateFilterButtonStates() {
  // Node types
  document.querySelectorAll('.legend-item[data-type]').forEach(item => {
    const nt = item.dataset.type;
    item.classList.toggle('inactive', filterState.activeNodeTypes.has(nt));
  });
  // Edge types
  document.querySelectorAll('.legend-item-filter[data-filter]').forEach(item => {
    const ft = item.dataset.filter;
    item.classList.toggle('inactive', filterState.activeEdgeFilters.has(ft));
  });
  // Gender
  document.querySelectorAll('.legend-item-gender[data-gender]').forEach(item => {
    const g = item.dataset.gender;
    item.classList.toggle('inactive', filterState.activeGenders.has(g));
  });
  // Roles
  document.querySelectorAll('.legend-item-role[data-role]').forEach(item => {
    const r = item.dataset.role;
    item.classList.toggle('inactive', filterState.activeRoles.has(r));
  });
  // Categories
  document.querySelectorAll('.legend-item-category[data-cat]').forEach(item => {
    const c = item.dataset.cat;
    item.classList.toggle('inactive', filterState.activeCategories.has(c));
  });

  // "Show All" button
  const showAllBtn = document.querySelector('[data-filter="showAll"]');
  if (showAllBtn) {
    showAllBtn.classList.toggle('active', filterState.showAll);
  }
}

document.addEventListener('DOMContentLoaded', initializeFilters);
