////////////////////////////////////////////////////////////////////////////////
// vis-update.js
// BFS highlight, node/edge tooltips, detail panels,
// plus fix to restore original arrow/edge thickness after mouseout,
// and link label support for quantities.
////////////////////////////////////////////////////////////////////////////////

// Export an object to hold any shared functions
window.vizUpdate = {};

// Track whether the force simulation has stabilized
let isSimulationStable = false;

// Reference the loading overlay (for fade-out on load)
const loadingOverlay = document.querySelector('.loading-overlay');

/**
 * Hide the loading overlay with a small fade-out effect
 */
vizUpdate.hideLoading = function() {
  if (loadingOverlay) {
    loadingOverlay.style.opacity = '0';
    setTimeout(() => {
      loadingOverlay.style.display = 'none';
    }, 300);
  }
};

/**
 * Helper: Calculate the link's original stroke width (matching vis-core.js).
 */
function getOriginalStrokeWidth(d) {
  if (d.flow_details && d.flow_details.quantity && vizCore.quantityScale) {
    const q = parseFloat(d.flow_details.quantity) || 0;
    return vizCore.quantityScale(q);  // revert to scaled thickness
  }
  return 1.5; // fallback if no quantity
}

/**
 * BFS highlight from a single node, up to 'maxHops' distance.
 * Uses vizCore.multiSourceBFS([nodeId], maxHops).
 */
function highlightMultiHop(d, maxHops = 2) {
  // Run multi-source BFS from the clicked node
  const visitedIds = vizCore.multiSourceBFS([d.id], maxHops);

  // Highlight visited nodes, dim all others
  vizCore.node.attr("opacity", node =>
    visitedIds.has(node.id) ? 1 : 0.15
  );

  // Highlight links only if both endpoints are visited
  vizCore.link.attr("opacity", link => {
    const sId = (typeof link.source === 'object') ? link.source.id : link.source;
    const tId = (typeof link.target === 'object') ? link.target.id : link.target;
    return (visitedIds.has(sId) && visitedIds.has(tId)) ? 0.8 : 0.1;
  });

  // Dim link labels accordingly
  vizCore.linkLabel.attr("fill-opacity", link => {
    const sId = (typeof link.source === 'object') ? link.source.id : link.source;
    const tId = (typeof link.target === 'object') ? link.target.id : link.target;
    return (visitedIds.has(sId) && visitedIds.has(tId)) ? 1 : 0.1;
  });
}

/**
 * Clear BFS highlights, restoring normal opacities for all nodes, links, labels
 */
function clearHighlight() {
  vizCore.node.attr("opacity", 1);
  vizCore.link.attr("opacity", 0.6);
  vizCore.linkLabel.attr("fill-opacity", 1);
}

/**
 * Display node details in #nodeDetails (skipping some internal fields)
 */
vizUpdate.displayNodeDetails = function(d) {
  const detailsDiv = document.getElementById('nodeDetails');
  if (!detailsDiv) return;

  // Fields to skip from displayed data
  const skipFields = new Set(["index","vx","vy","fx","fy","x","y","connections"]);

  let html = `<div class="details-content">`;
  html += `<h6>${d.name || d.id}</h6>`;

  Object.entries(d).forEach(([k, v]) => {
    if (skipFields.has(k)) return;
    let valStr = (typeof v === 'object')
      ? `<pre style="margin:0;">${JSON.stringify(v, null, 2)}</pre>`
      : v;
    html += `
      <div class="detail-item">
        <span class="detail-label">${k}:</span>
        <span class="detail-value">${valStr}</span>
      </div>`;
  });

  html += `</div>`;
  detailsDiv.innerHTML = html;
};

/**
 * Display edge details in #edgeDetails (showing source, target, date, note, etc.)
 */
vizUpdate.displayEdgeDetails = function(d) {
  const detailsDiv = document.getElementById('edgeDetails');
  if (!detailsDiv) return;

  let html = `<div class="details-content">`;
  html += `<h6>${d.type} ${d.flow_details ? 'Flow' : 'Relationship'}</h6>`;

  // Source & target (fallback to ID if no name)
  const sName = d.source.name || d.source.id || d.source;
  const tName = d.target.name || d.target.id || d.target;
  html += `
    <div class="detail-item">
      <span class="detail-label">From:</span>
      <span>${sName}</span>
    </div>
    <div class="detail-item">
      <span class="detail-label">To:</span>
      <span>${tName}</span>
    </div>`;

  // Optional date/note
  if (d.date) {
    html += `
      <div class="detail-item">
        <span class="detail-label">Date:</span>
        <span>${d.date}</span>
      </div>`;
  }
  if (d.note) {
    html += `
      <div class="detail-item">
        <span class="detail-label">Note:</span>
        <span>${d.note}</span>
      </div>`;
  }

  // flow_details if present
  if (d.flow_details) {
    Object.entries(d.flow_details).forEach(([k, val]) => {
      html += `
        <div class="detail-item">
          <span class="detail-label">${k}:</span>
          <span>${val}</span>
        </div>`;
    });
  }

  html += `</div>`;
  detailsDiv.innerHTML = html;
};

/**
 * Node hover & click logic:
 *  - mouseover => show tooltip (with name/type/gender)
 *  - mousemove => reposition tooltip
 *  - mouseout => hide tooltip
 *  - click => BFS highlight + show node details
 */
vizCore.node
  .on("mouseover", (event, d) => {
    const tooltip = d3.select("#tooltip");
    let content = `<strong>${d.name || d.id}</strong><br/>Type: ${d.type}`;
    if (d.gender) content += `<br/>Gender: ${d.gender}`;
    tooltip
      .style("visibility", "visible")
      .html(content);
  })
  .on("mousemove", (event) => {
    const tooltip = d3.select("#tooltip");
    const [x, y] = d3.pointer(event, document.body);
    tooltip
      .style("top", `${y + 10}px`)
      .style("left", `${x + 10}px`);
  })
  .on("mouseout", () => {
    d3.select("#tooltip").style("visibility", "hidden");
  })
  .on("click", (event, d) => {
    highlightMultiHop(d, 2);
    vizUpdate.displayNodeDetails(d);
    event.stopPropagation();
  });

/**
 * Link hover & click logic:
 *  - mouseover => show tooltip (type, date, note, quantity),
 *    temporarily enlarge link
 *  - mousemove => reposition tooltip
 *  - mouseout => revert stroke width, hide tooltip
 *  - click => show edge details
 */
vizCore.link
  .on("mouseover", (event, d) => {
    const tooltip = d3.select("#tooltip");
    let content = `<strong>${d.type}</strong><br/>From: ${d.source.name}<br/>To: ${d.target.name}`;
    if (d.date) content += `<br/>Date: ${d.date}`;
    if (d.note) content += `<br/>Note: ${d.note}`;

    if (d.flow_details && d.flow_details.quantity) {
      content += `<br/>Edge is thicker because quantity=${d.flow_details.quantity}`;
    }

    tooltip
      .style("visibility", "visible")
      .html(content);

    // Enlarge link on hover
    d3.select(event.target)
      .attr("stroke-width", 3)
      .attr("stroke-opacity", 1);
  })
  .on("mousemove", (event) => {
    const tooltip = d3.select("#tooltip");
    const [x, y] = d3.pointer(event, document.body);
    tooltip
      .style("top", `${y + 10}px`)
      .style("left", `${x + 10}px`);
  })
  .on("mouseout", (event, d) => {
    d3.select("#tooltip").style("visibility", "hidden");
    // revert link to original thickness
    d3.select(event.target)
      .attr("stroke-width", getOriginalStrokeWidth(d))
      .attr("stroke-opacity", 0.6);
  })
  .on("click", (event, d) => {
    vizUpdate.displayEdgeDetails(d);
    event.stopPropagation();
  });

/**
 * Clicking on the body => clear BFS highlight, restoring normal opacities
 */
d3.select("body").on("click", () => {
  clearHighlight();
});

/**
 * Zoom controls: 'zoomIn', 'zoomOut', 'resetZoom'
 */
document.getElementById("zoomIn").addEventListener("click", () => {
  vizCore.svg.transition().duration(500)
    .call(vizCore.zoom.scaleBy, 1.5);
});
document.getElementById("zoomOut").addEventListener("click", () => {
  vizCore.svg.transition().duration(500)
    .call(vizCore.zoom.scaleBy, 0.75);
});
document.getElementById("resetZoom").addEventListener("click", () => {
  vizCore.fitToContainer();
});

/**
 * Force simulation "end" => hide loading overlay if not done
 */
vizCore.simulation.on("end", () => {
  isSimulationStable = true;
  vizUpdate.hideLoading();
  console.log("Force simulation stabilized");
});

// Fallback if the simulation takes too long
setTimeout(() => {
  if (!isSimulationStable) {
    console.log("Taking longer than expected, removing loading screen");
    vizUpdate.hideLoading();
  }
}, 2000);

console.log("vis-update.js loaded with BFS highlight, thick-edge reversion, and link label support for quantities");
