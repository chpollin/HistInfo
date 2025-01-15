/**
 * vis-core.js
 *
 * Description:
 *   The main D3 force layout and adjacency logic. Builds BFS adjacency,
 *   sets up node/link elements, assigns colors by type/gender, handles zoom
 *   and drag, and triggers "tick" updates for node/link positions. Also includes
 *   link labeling for quantities (flow_details), along with a scale for thick edges.
 *
 * Responsibilities:
 *   - Build adjacency sets for BFS expansions (used by filter-handler.js or vis-update.js).
 *   - Define BFS methods (getMultiHopNeighbors, multiSourceBFS).
 *   - Create an SVG <g> structure for nodes, links, and labels (including link labels).
 *   - Configure D3 forces (distance, charge, collision) and alpha.
 *   - Provide optional node/link click handlers for showNodeDetails/showEdgeDetails (called in vis-update.js).
 *   - Hide the loading overlay upon successful initialization.
 *
 * Dependencies:
 *   - Relies on `nodesData` and `linksData` from data.js.
 *   - Must be loaded after data.js (for data) and filter-handler.js (if BFS expansions are triggered there).
 *   - Exports BFS methods and references (vizCore.*) for usage in vis-update.js.
 *
 * Author:
 *   [Your Name / Team]
 * Date:
 *   [Year or version]
 */

console.log("Starting visualization core setup...");

// We'll attach everything to a global object so filter-handler.js or vis-update.js can access it
window.vizCore = {};

// -----------------------------------------------------------------------------
// 1) BFS adjacency map & BFS methods
// -----------------------------------------------------------------------------
vizCore.adjacency = new Map();

/**
 * Build adjacency sets from linksData for BFS expansions.
 */
function buildAdjacency() {
  linksData.forEach(link => {
    // Convert link source/target to strings if they might be objects
    const sId = (typeof link.source === 'object') ? link.source.id : link.source;
    const tId = (typeof link.target === 'object') ? link.target.id : link.target;

    if (!vizCore.adjacency.has(sId)) {
      vizCore.adjacency.set(sId, new Set());
    }
    if (!vizCore.adjacency.has(tId)) {
      vizCore.adjacency.set(tId, new Set());
    }
    vizCore.adjacency.get(sId).add(tId);
    vizCore.adjacency.get(tId).add(sId);
  });
  console.log("Adjacency built for BFS highlighting");
}

/**
 * BFS from a single start node with optional maxHops
 * @param {string} startId - Node ID
 * @param {number} [maxHops=Infinity] - BFS hop limit
 * @returns {Set} visited - all visited node IDs
 */
function getMultiHopNeighbors(startId, maxHops = Infinity) {
  const visited = new Set([startId]);
  const queue = [{ id: startId, depth: 0 }];

  while (queue.length > 0) {
    const { id, depth } = queue.shift();
    if (depth < maxHops) {
      const neighbors = vizCore.adjacency.get(id) || new Set();
      neighbors.forEach(nId => {
        if (!visited.has(nId)) {
          visited.add(nId);
          queue.push({ id: nId, depth: depth + 1 });
        }
      });
    }
  }
  return visited;
}

/**
 * BFS from multiple start nodes
 * @param {Array<string>} startIds - array of node IDs
 * @param {number} [maxHops=Infinity]
 * @returns {Set} visited - union of visited from all starts
 */
function multiSourceBFS(startIds, maxHops = Infinity) {
  const globalVisited = new Set();
  startIds.forEach(sid => {
    const localVisited = getMultiHopNeighbors(sid, maxHops);
    localVisited.forEach(n => globalVisited.add(n));
  });
  return globalVisited;
}

// Expose BFS methods so filter-handler.js or vis-update.js can call them
vizCore.multiSourceBFS = multiSourceBFS;

// -----------------------------------------------------------------------------
// 2) Determine link widths based on flow_details.quantity
// -----------------------------------------------------------------------------
let maxQuantity = 0;
linksData.forEach(link => {
  if (link.flow_details && link.flow_details.quantity) {
    const q = parseFloat(link.flow_details.quantity) || 0;
    if (q > maxQuantity) maxQuantity = q;
  }
});
console.log("Maximum quantity among edges:", maxQuantity);

// If needed, we can also expose the scale for re-use in vis-update
vizCore.quantityScale = d3.scaleLinear()
  .domain([0, maxQuantity])
  .range([1.5, 10]);

// -----------------------------------------------------------------------------
// 3) Define colors for node types, genders, link types
// -----------------------------------------------------------------------------
const genderNodeColors = {
  male: "#FFD700",
  female: "#4682B4"
};

vizCore.nodeColors = {
  location: "#2EA043",
  institution: "#F27F1B",
  commodity: "#8250DF",
  unknown: "#999999"
};

vizCore.linkColors = {
  marriage: "#FF3366",
  residence: "#9C3EBA",
  education: "#00BCD4",
  commodity: "#FF8C00",
  service: "#5D4037",
  credit: "#42A5F5",
  occupation: "#4CAF50",
  order: "#607D8B",
  cash: "#FFD700",
  other: "#9e9e9e"
};

// -----------------------------------------------------------------------------
// 4) Setup container, SVG, and base sizing
// -----------------------------------------------------------------------------
vizCore.container = document.querySelector('.network-container');
vizCore.svg = d3.select("#networkViz");

/**
 * Compute container dimensions for dynamic resizing
 */
vizCore.getContainerDimensions = function() {
  const bbox = vizCore.container.getBoundingClientRect();
  return { width: bbox.width, height: bbox.height };
};

const { width, height } = vizCore.getContainerDimensions();
vizCore.width = width;
vizCore.height = height;

vizCore.svg
  .attr("width", width)
  .attr("height", height)
  .attr("viewBox", `0 0 ${width} ${height}`);

// -----------------------------------------------------------------------------
// 5) Arrow markers for directed edges
// -----------------------------------------------------------------------------
const defs = vizCore.svg.append("defs");
Object.entries(vizCore.linkColors).forEach(([type, color]) => {
  defs.append("marker")
    .attr("id", `arrow-${type}`)
    .attr("viewBox", "0 -5 10 10")
    .attr("refX", 22)
    .attr("refY", 0)
    .attr("markerWidth", 8)
    .attr("markerHeight", 8)
    .attr("orient", "auto")
    .append("path")
    .attr("fill", color)
    .attr("d", "M0,-5L10,0L0,5L2,0Z");
});

// -----------------------------------------------------------------------------
// 6) Main group for zoom/pan
// -----------------------------------------------------------------------------
vizCore.g = vizCore.svg.append("g")
  .attr("class", "zoom-layer");

// -----------------------------------------------------------------------------
// 7) Build link selection
// -----------------------------------------------------------------------------
vizCore.link = vizCore.g.append("g")
  .attr("class", "links")
  .selectAll("line")
  .data(linksData)
  .join("line")
  .attr("class", d => `link link-${d.type}`)
  .attr("stroke", d => vizCore.linkColors[d.type] || "#999")
  .attr("stroke-width", d => {
    if (d.flow_details && d.flow_details.quantity) {
      const q = parseFloat(d.flow_details.quantity) || 0;
      return vizCore.quantityScale(q);
    }
    return 1.5;
  })
  .attr("stroke-opacity", 0.6)
  .attr("marker-end", d => `url(#arrow-${d.type})`);

// 7.1) Build link label selection (for quantity or commodity info)
vizCore.linkLabel = vizCore.g.append("g")
  .attr("class", "link-labels")
  .selectAll(".link-label")
  .data(linksData)
  .join("text")
  .attr("class", "link-label")
  .text(d => {
    if (d.flow_details && d.flow_details.quantity && d.flow_details.unit) {
      return `${d.flow_details.quantity} ${d.flow_details.unit}`;
    }
    if (d.flow_details && d.flow_details.commodity_id) {
      return d.flow_details.commodity_id.replace(/^c_/, '');
    }
    return "";
  })
  .attr("fill", "green")
  .attr("font-size", "10px")
  .attr("text-anchor", "middle")
  .style("pointer-events", "none");

// -----------------------------------------------------------------------------
// 8) Build node selection
// -----------------------------------------------------------------------------
vizCore.node = vizCore.g.append("g")
  .attr("class", "nodes")
  .selectAll("circle")
  .data(nodesData)
  .join("circle")
  .attr("class", d => {
    // e.g. node node-commodity plus any role-based classes
    const base = [`node`, `node-${d.type || 'unknown'}`];
    if (d.roles && d.roles.length > 0) {
      d.roles.forEach(r => base.push(`role-${r}`));
    }
    return base.join(' ');
  })
  .attr("r", d => {
    // Node radius based on connection count
    const c = d.connections || 0;
    return 6 + Math.sqrt(c) * 2;
  })
  .attr("fill", d => {
    if (d.gender === "male") return genderNodeColors.male;
    if (d.gender === "female") return genderNodeColors.female;
    return vizCore.nodeColors[d.type] || "#999";
  })
  .attr("stroke", "#fff")
  .attr("stroke-width", 1.5);

// -----------------------------------------------------------------------------
// 9) Node labels
// -----------------------------------------------------------------------------
vizCore.label = vizCore.g.append("g")
  .attr("class", "labels")
  .selectAll("text")
  .data(nodesData)
  .join("text")
  .attr("class", "node-label")
  .attr("text-anchor", "start")
  .attr("dx", 10)
  .attr("dy", "0.35em")
  .attr("font-size", "8px")
  .text(d => d.name || d.id)
  .style("pointer-events", "none")
  .style("user-select", "none")
  .style("text-shadow", "1px 1px 2px white, -1px -1px 2px white");

// -----------------------------------------------------------------------------
// 10) D3 force simulation
// -----------------------------------------------------------------------------
vizCore.simulation = d3.forceSimulation(nodesData)
  .force("link", d3.forceLink(linksData)
    .id(d => d.id)
    .distance(d => {
      // Optionally vary link distance if certain roles or relationships matter
      return 80; // default
    })
  )
  .force("charge", d3.forceManyBody()
    .strength(d => {
      const base = -300;
      // Nodes with roles repel more strongly
      if (d.roles && d.roles.length > 0) {
        return base * 1.2;
      }
      return base;
    })
    .distanceMax(500)
  )
  .force("collide", d3.forceCollide()
    .radius(d => {
      // Expand collision radius for high-connection nodes
      const c = d.connections || 0;
      return 20 + Math.sqrt(c) * 2;
    })
    .strength(0.9)
  )
  .on("tick", () => {
    // Each simulation tick => update positions
    vizCore.link
      .attr("x1", d => d.source.x)
      .attr("y1", d => d.source.y)
      .attr("x2", d => d.target.x)
      .attr("y2", d => d.target.y);

    vizCore.node
      .attr("cx", d => d.x)
      .attr("cy", d => d.y);

    // Position link labels at midpoint of source/target
    vizCore.linkLabel
      .attr("x", d => (d.source.x + d.target.x) / 2)
      .attr("y", d => (d.source.y + d.target.y) / 2);

    vizCore.label
      .attr("x", d => d.x)
      .attr("y", d => d.y);
  });

// -----------------------------------------------------------------------------
// 11) Zoom
// -----------------------------------------------------------------------------
vizCore.zoom = d3.zoom()
  .scaleExtent([0.2, 4])
  .on("zoom", function(event) {
    vizCore.g.attr("transform", event.transform);
    // Hide node labels unless zoomed in beyond a threshold
    vizCore.label.style("display", event.transform.k > 1.2 ? "block" : "none");
  });
vizCore.svg.call(vizCore.zoom);

// -----------------------------------------------------------------------------
// 12) Drag behaviors for nodes
// -----------------------------------------------------------------------------
function dragstarted(event, d) {
  if (!event.active) vizCore.simulation.alphaTarget(0.3).restart();
  d.fx = d.x;
  d.fy = d.y;
  d3.select(this).classed("dragging", true).attr("stroke", "#000");
}
function dragged(event, d) {
  d.fx = event.x;
  d.fy = event.y;
}
function dragended(event, d) {
  if (!event.active) vizCore.simulation.alphaTarget(0);
  d.fx = null;
  d.fy = null;
  d3.select(this).classed("dragging", false).attr("stroke", "#fff");
}
vizCore.node.call(d3.drag()
  .on("start", dragstarted)
  .on("drag", dragged)
  .on("end", dragended)
);

// -----------------------------------------------------------------------------
// 13) Fit-to-container method
// -----------------------------------------------------------------------------
vizCore.fitToContainer = function() {
  const bounds = vizCore.g.node().getBBox();
  if (!bounds.width || !bounds.height) return; // if there's nothing drawn yet

  const fullWidth = bounds.width;
  const fullHeight = bounds.height;
  const scale = 0.95 / Math.max(fullWidth / vizCore.width, fullHeight / vizCore.height);
  const transform = d3.zoomIdentity
    .translate(
      vizCore.width / 2 - (bounds.x + fullWidth / 2) * scale,
      vizCore.height / 2 - (bounds.y + fullHeight / 2) * scale
    )
    .scale(scale);

  vizCore.svg.transition()
    .duration(750)
    .call(vizCore.zoom.transform, transform);
};

// -----------------------------------------------------------------------------
// 14) Handle window resizing
// -----------------------------------------------------------------------------
window.addEventListener('resize', _.debounce(() => {
  const { width: newWidth, height: newHeight } = vizCore.getContainerDimensions();
  vizCore.svg
    .attr("width", newWidth)
    .attr("height", newHeight)
    .attr("viewBox", `0 0 ${newWidth} ${newHeight}`);
  vizCore.width = newWidth;
  vizCore.height = newHeight;
  vizCore.simulation.alpha(0.3).restart();
}, 250));

// -----------------------------------------------------------------------------
// 15) Build adjacency for BFS & hide loading overlay
// -----------------------------------------------------------------------------
buildAdjacency();

console.log("Visualization core setup complete");

// Hide spinner overlay now that the initial setup is done
const overlay = document.getElementById("loadingOverlay");
if (overlay) {
  overlay.style.display = "none";
}
