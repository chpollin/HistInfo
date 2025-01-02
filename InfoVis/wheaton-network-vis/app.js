////////////////////////////////////////////////////////////////////////////////
// app.js
// - Force-directed layout with collision, stable center
// - Zoom & pan, "fit to screen" on load
// - Multi-filter logic for edges by transactionType
// - Node click => fill #nodeDetails
// - Edge click => fill #edgeDetails
// - Node & Edge get typed classes for CSS coloring
////////////////////////////////////////////////////////////////////////////////

console.log("APP.JS: Checking nodesData and linksData:", nodesData, linksData);

// 1) Basic Setup: select SVG & tooltip
const svg = d3.select("#networkViz");
const tooltip = d3.select("#tooltip");

// We'll create a <g> for zoom/pan transformations
const zoomLayer = svg.append("g").attr("class", "zoomLayer");

// Determine width & height from the style
const width = parseInt(svg.style("width"), 10);
const height = parseInt(svg.style("height"), 10);

// 2) Force Simulation
let simulation = d3.forceSimulation(nodesData)
  .force("link", d3.forceLink().id(d => d.id).distance(120))
  .force("charge", d3.forceManyBody().strength(-300))
  .force("center", d3.forceCenter(width / 2, height / 2))
  .force("collide", d3.forceCollide().radius(20)); // reduce overlapping nodes

// We'll keep references to link/node/label selections
let link = zoomLayer.selectAll(".link");
let node = zoomLayer.selectAll(".node");
let labels = zoomLayer.selectAll(".nodelabel");

// 3) Arrow Marker for Directed Edges
zoomLayer.append("defs").append("marker")
  .attr("id", "arrowhead")
  .attr("viewBox", "0 -5 10 10")
  .attr("refX", 15)
  .attr("refY", 0)
  .attr("markerWidth", 6)
  .attr("markerHeight", 6)
  .attr("orient", "auto")
  .append("path")
  .attr("d", "M0,-5L10,0L0,5")
  .attr("fill", "#999");

// 4) Zoom & Pan
const zoomBehavior = d3.zoom()
  .scaleExtent([0.05, 5])
  .on("zoom", event => {
    zoomLayer.attr("transform", event.transform);
  });

svg.call(zoomBehavior).on("dblclick.zoom", null); // disable dblclick zoom if desired

/**
 * fitToScreen():
 *  After the layout ends, compute bounding box of nodes, scale & translate
 *  so that everything is visible within the SVG.
 */
function fitToScreen() {
  if (!nodesData.length) return;

  let minX = d3.min(nodesData, d => d.x);
  let maxX = d3.max(nodesData, d => d.x);
  let minY = d3.min(nodesData, d => d.y);
  let maxY = d3.max(nodesData, d => d.y);

  let contentWidth = maxX - minX;
  let contentHeight = maxY - minY;
  const padding = 40;

  contentWidth += padding * 2;
  contentHeight += padding * 2;

  const scale = Math.min(width / contentWidth, height / contentHeight);

  const midX = (minX + maxX) / 2;
  const midY = (minY + maxY) / 2;

  const translate = [
    width / 2 - scale * midX,
    height / 2 - scale * midY
  ];

  svg.transition()
    .duration(750)
    .call(
      zoomBehavior.transform,
      d3.zoomIdentity.translate(translate[0], translate[1]).scale(scale)
    );
}

// 5) Filter State
// We allow multiple transaction types at once. If none => showAll = true
let activeTxFilters = new Set();
let showAll = true;

function passFilter(l) {
  if (showAll) return true;
  // Only keep edges whose transactionType is in activeTxFilters
  return activeTxFilters.has(l.transactionType);
}

// 6) updateVisualization():
// Re-bind data, apply classes for typed nodes & edges, re-run simulation
function updateVisualization() {
  console.log("[updateVisualization] start");

  // A) Filter links
  const filteredLinks = linksData.filter(passFilter);

  // B) Which nodes appear in those edges
  function getID(e) {
    return (typeof e === "object") ? e.id : e;
  }
  const activeNodeIDs = new Set();
  filteredLinks.forEach(l => {
    activeNodeIDs.add(getID(l.source));
    activeNodeIDs.add(getID(l.target));
  });
  const filteredNodes = nodesData.filter(n => activeNodeIDs.has(n.id));

  // C) Re-bind link data
  link = link.data(filteredLinks, d => {
    let sID = getID(d.source);
    let tID = getID(d.target);
    return sID + "-" + tID + "-" + (d.dateStr || "");
  });
  link.exit().remove();

  const linkEnter = link.enter().append("line");
  link = linkEnter.merge(link)
    // 1) Base class
    .attr("class", d => {
      // E.g., "link link-marriage"
      let base = "link";
      if (d.transactionType) base += ` link-${d.transactionType}`;
      return base;
    })
    .attr("stroke-width", 2)
    .attr("marker-end", "url(#arrowhead)");

  // D) Re-bind node data
  node = node.data(filteredNodes, d => d.id);
  node.exit().remove();

  const nodeEnter = node.enter().append("circle");
  node = nodeEnter.merge(node)
    // 1) Base class
    .attr("class", d => {
      // E.g. "node node-person" if d.type == "person"
      let base = "node";
      if (d.type) base += ` node-${d.type}`;
      return base;
    })
    .attr("r", 10);

  // E) Re-bind labels
  labels = labels.data(filteredNodes, d => d.id);
  labels.exit().remove();

  const labelsEnter = labels.enter().append("text")
    .attr("class", "nodelabel")
    .attr("font-size", 12)
    .attr("text-anchor", "middle");

  labels = labelsEnter.merge(labels)
    .text(d => d.name || d.id);

  // F) Node hover + click
  node
    .on("mouseover", (event, d) => {
      tooltip
        .style("visibility", "visible")
        .html(`<strong>${d.name || d.id}</strong>`);
    })
    .on("mousemove", (event) => {
      tooltip
        .style("top", (event.pageY + 10) + "px")
        .style("left", (event.pageX + 10) + "px");
    })
    .on("mouseout", () => {
      tooltip.style("visibility", "hidden");
    })
    .on("click", (event, d) => {
      // Helper function to format property display
      const formatProperty = (label, value) => {
        if (value === undefined || value === null || value === "") return "";
        return `<p><strong>${label}:</strong> ${value}</p>`;
      };

      // Build type-specific details
      let typeSpecificDetails = "";
      switch(d.type) {
        // In the person case of the switch statement:
case "person":
  // Format name components
  const formatNames = (namesArray) => {
    if (!namesArray) return "";
    return namesArray.map(n => `${n.name}${n.type ? ` (${n.type})` : ""}`).join(", ");
  };

  // Format location details
  const formatLocation = (loc) => {
    if (!loc) return "";
    const parts = [];
    if (loc.settlement) parts.push(loc.settlement);
    if (loc.region) parts.push(loc.region);
    if (loc.full) return loc.full;
    return parts.join(", ");
  };

  // Format birth/death details
  const formatEvent = (event) => {
    if (!event || Object.keys(event).length === 0) return "";
    const parts = [];
    if (event.date) parts.push(`Date: ${event.date}`);
    if (event.location) parts.push(`Location: ${formatLocation(event.location)}`);
    return parts.join(", ");
  };

  typeSpecificDetails = `
    ${formatProperty("Full Name", d.full)}
    <div class="mt-3">
      <h6>Names:</h6>
      ${formatProperty("Forenames", formatNames(d.forenames))}
      ${formatProperty("Surnames", formatNames(d.surnames))}
    </div>
    <div class="mt-3">
      <h6>Life Events:</h6>
      ${formatProperty("Birth", formatEvent(d.birth))}
      ${formatProperty("Death", formatEvent(d.death))}
    </div>
    ${formatProperty("Faith", d.faith)}
    ${formatProperty("Education", d.education?.join(", "))}
  `;
  break;
      }

      // Get all non-standard properties
      const standardProps = new Set(['id', 'full', 'forenames', 'surnames', 'faith', 'type', 'x', 'y', 'fx', 'fy', 'index', 'vx', 'vy', 'birth', 'death', 'location']);
      const otherProps = Object.entries(d)
        .filter(([key]) => !standardProps.has(key))
        .map(([key, value]) => formatProperty(key, value))
        .join('');

      // Populate #nodeDetails with comprehensive information
      d3.select("#nodeDetails").html(`
        <h5>Node Details</h5>
        <div class="node-details-content">
          ${formatProperty("ID", d.id)}
          ${formatProperty("Name", d.name)}
          ${formatProperty("Type", d.type || "unknown")}
          ${typeSpecificDetails}
          ${otherProps ? '<h6 class="mt-3">Additional Properties</h6>' + otherProps : ''}
        </div>
      `);
    });

  // G) Link hover + click
  link
    .on("mouseover", (event, d) => {
      tooltip
        .style("visibility", "visible")
        .html(`
          <strong>Type:</strong> ${d.transactionType}<br/>
          <strong>Date:</strong> ${d.dateStr || "N/A"}<br/>
          <small>${d.note || ""}</small>
        `);
    })
    .on("mousemove", (event) => {
      tooltip
        .style("top", (event.pageY + 10) + "px")
        .style("left", (event.pageX + 10) + "px");
    })
    .on("mouseout", () => {
      tooltip.style("visibility", "hidden");
    })
    .on("click", (event, d) => {
      // Populate #edgeDetails
      d3.select("#edgeDetails").html(`
        <h5>Edge Details</h5>
        <p><strong>Transaction Type:</strong> ${d.transactionType}</p>
        <p><strong>Date:</strong> ${d.dateStr || "N/A"}</p>
        <p><strong>Note:</strong> ${d.note || ""}</p>
        <p>(More fields: e.g., commodity details, source->target, etc.)</p>
      `);
    });

  // H) Update simulation
  simulation.nodes(filteredNodes);
  simulation.force("link").links(filteredLinks);
  simulation.alpha(0.8).restart();

  console.log("[updateVisualization] end");
}

// 7) Force simulation "tick" => position
simulation.on("tick", () => {
  link
    .attr("x1", d => d.source.x)
    .attr("y1", d => d.source.y)
    .attr("x2", d => d.target.x)
    .attr("y2", d => d.target.y);

  node
    .attr("cx", d => d.x)
    .attr("cy", d => d.y);

  labels
    .attr("x", d => d.x)
    .attr("y", d => d.y - 15);
});

// 8) On simulation end => fit the entire graph to the screen
simulation.on("end", () => {
  console.log("Simulation ended => fitToScreen...");
  fitToScreen();
});

// 9) Drag Handlers
function dragStarted(event, d) {
  if (!event.active) simulation.alphaTarget(0.3).restart();
  d.fx = d.x;
  d.fy = d.y;
}
function dragged(event, d) {
  d.fx = event.x;
  d.fy = event.y;
}
function dragEnded(event, d) {
  if (!event.active) simulation.alphaTarget(0);
  d.fx = null;
  d.fy = null;
}

// 10) Transaction Type Filter Buttons
const filterButtons = document.querySelectorAll("[data-filter]");
filterButtons.forEach(btn => {
  btn.addEventListener("click", () => {
    const val = btn.getAttribute("data-filter");
    if (val === "all") {
      showAll = true;
      activeTxFilters.clear();
    } else {
      // Toggle approach for multi-filter
      if (activeTxFilters.has(val)) {
        activeTxFilters.delete(val);
      } else {
        activeTxFilters.add(val);
      }
      showAll = (activeTxFilters.size === 0);
    }
    updateVisualization();
  });
});

// 11) Initial render
updateVisualization();
console.log("APP.JS: Visualization initialized.");
