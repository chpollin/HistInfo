////////////////////////////////////////////////////////////////////////////////
// vis-core.js
// BFS adjacency, role-based clustering, edge weighting
// Person => use gender color if available
////////////////////////////////////////////////////////////////////////////////

console.log("Starting visualization core setup...");

window.vizCore = {};

// BFS adjacency
vizCore.adjacency = new Map();

function buildAdjacency() {
  linksData.forEach(link => {
    const sId = (typeof link.source === 'object') ? link.source.id : link.source;
    const tId = (typeof link.target === 'object') ? link.target.id : link.target;
    if (!vizCore.adjacency.has(sId)) vizCore.adjacency.set(sId, new Set());
    if (!vizCore.adjacency.has(tId)) vizCore.adjacency.set(tId, new Set());
    vizCore.adjacency.get(sId).add(tId);
    vizCore.adjacency.get(tId).add(sId);
  });
  console.log("Adjacency built for BFS highlighting");
}

function getMultiHopNeighbors(startIds, maxHops = Infinity) {
  // startIds is an array of node IDs, e.g. all female IDs
  const visited = new Set(startIds);
  const queue = startIds.map(id => ({ id, depth: 0 }));

  while (queue.length) {
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
vizCore.getMultiHopNeighbors = getMultiHopNeighbors;

// Edge weighting
let maxQuantity = 0;
linksData.forEach(link => {
  if (link.flow_details && link.flow_details.quantity) {
    const q = parseFloat(link.flow_details.quantity) || 0;
    if (q > maxQuantity) {
      maxQuantity = q;
    }
  }
});
console.log("Maximum quantity among edges:", maxQuantity);

const quantityScale = d3.scaleLinear()
  .domain([0, maxQuantity])
  .range([1.5, 10]);

// Gender colors
const genderNodeColors = {
  male: "#3C7FFF",
  female: "#FF5AC4"
};

// Fallback node colors
vizCore.nodeColors = {
  location: "#2EA043",
  institution: "#F27F1B",
  commodity: "#8250DF",
  unknown: "#999999"
};

// Link colors
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

vizCore.container = document.querySelector('.network-container');
vizCore.svg = d3.select("#networkViz");

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
  .attr("viewBox", [0, 0, width, height].join(" "));

// Arrow markers
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

vizCore.g = vizCore.svg.append("g")
  .attr("class", "zoom-layer");

// Build link selection
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
      return quantityScale(q);
    }
    return 1.5;
  })
  .attr("stroke-opacity", 0.6)
  .attr("marker-end", d => `url(#arrow-${d.type})`);

// Build node selection
vizCore.node = vizCore.g.append("g")
  .attr("class", "nodes")
  .selectAll("circle")
  .data(nodesData)
  .join("circle")
  .attr("class", d => {
    // e.g. node node-commodity
    const base = [`node`, `node-${d.type || 'unknown'}`];
    if (d.economic_roles) {
      d.economic_roles.forEach(r => base.push(`role-${r}`));
    }
    return base.join(' ');
  })
  .attr("r", d => {
    // Base on connections
    const c = d.connections || 0;
    const baseSize = 6 + Math.sqrt(c) * 2;
    return baseSize;
  })
  .attr("fill", d => {
    // If gender => override
    if (d.gender === "male") return genderNodeColors.male;
    if (d.gender === "female") return genderNodeColors.female;
    return vizCore.nodeColors[d.type] || "#999";
  })
  .attr("stroke", "#fff")
  .attr("stroke-width", 1.5);

// Node labels
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

// Force simulation
vizCore.simulation = d3.forceSimulation(nodesData)
  .force("link", d3.forceLink(linksData)
    .id(d => d.id)
    .distance(d => {
      if (d.flow_details) {
        const sRole = d.source?.economic_roles?.[0];
        const tRole = d.target?.economic_roles?.[0];
        if (sRole && tRole) {
          if (sRole === tRole) return 40;
          if ((sRole.includes('provider') && tRole.includes('recipient')) ||
              (sRole === 'creditor' && tRole === 'debtor') ||
              (tRole.includes('provider') && sRole.includes('recipient')) ||
              (tRole === 'creditor' && sRole === 'debtor')) {
            return 90;
          }
          return 150;
        }
      }
      return 80;
    })
  )
  .force("charge", d3.forceManyBody()
    .strength(d => {
      const base = -300;
      // If it has roles, stronger repulsion
      return d.economic_roles ? base * 1.5 : base;
    })
    .distanceMax(500)
  )
  .force("collide", d3.forceCollide()
    .radius(d => {
      const c = d.connections || 0;
      const baseRadius = 20 + Math.sqrt(c) * 2;
      return baseRadius;
    })
    .strength(0.9)
  )
  .on("tick", () => {
    vizCore.link
      .attr("x1", d => d.source.x)
      .attr("y1", d => d.source.y)
      .attr("x2", d => d.target.x)
      .attr("y2", d => d.target.y);

    vizCore.node
      .attr("cx", d => d.x)
      .attr("cy", d => d.y);

    vizCore.label
      .attr("x", d => d.x)
      .attr("y", d => d.y);
  });

// Zoom
vizCore.zoom = d3.zoom()
  .scaleExtent([0.2, 4])
  .on("zoom", (event) => {
    vizCore.g.attr("transform", event.transform);
    vizCore.label.style("display", event.transform.k > 1.2 ? "block" : "none");
  });
vizCore.svg.call(vizCore.zoom);

// Drag
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

vizCore.fitToContainer = function() {
  const bounds = vizCore.g.node().getBBox();
  if (!bounds.width || !bounds.height) return;

  const fullWidth = bounds.width;
  const fullHeight = bounds.height;
  const scale = 0.95 / Math.max(fullWidth / width, fullHeight / height);
  const transform = d3.zoomIdentity
    .translate(
      width/2 - (bounds.x + fullWidth/2)*scale,
      height/2 - (bounds.y + fullHeight/2)*scale
    )
    .scale(scale);

  vizCore.svg.transition()
    .duration(750)
    .call(vizCore.zoom.transform, transform);
};

window.addEventListener('resize', _.debounce(() => {
  const { width: newWidth, height: newHeight } = vizCore.getContainerDimensions();
  vizCore.svg
    .attr("width", newWidth)
    .attr("height", newHeight)
    .attr("viewBox", [0, 0, newWidth, newHeight].join(" "));
  vizCore.width = newWidth;
  vizCore.height = newHeight;
  vizCore.simulation.alpha(0.3).restart();
}, 250));

// BFS adjacency
buildAdjacency();

console.log("Visualization core setup complete");
