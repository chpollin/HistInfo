////////////////////////////////////////////////////////////////////////////////
// vis-update.js
// BFS highlight, node/edge tooltips, detail panels, with explanation for thick edges
////////////////////////////////////////////////////////////////////////////////

window.vizUpdate = {};

let isSimulationStable = false;
const loadingOverlay = document.querySelector('.loading-overlay');

vizUpdate.hideLoading = function() {
  if (loadingOverlay) {
    loadingOverlay.style.opacity = '0';
    setTimeout(() => {
      loadingOverlay.style.display = 'none';
    }, 300);
  }
};

function highlightMultiHop(d, maxHops = 2) {
  const visitedIds = vizCore.getMultiHopNeighbors(d.id, maxHops);

  // Node highlight
  vizCore.node.attr("opacity", node => visitedIds.has(node.id) ? 1 : 0.15);

  // Link highlight if both ends visited
  vizCore.link.attr("opacity", link => {
    const sId = (typeof link.source === 'object') ? link.source.id : link.source;
    const tId = (typeof link.target === 'object') ? link.target.id : link.target;
    return (visitedIds.has(sId) && visitedIds.has(tId)) ? 0.8 : 0.1;
  });
}

function clearHighlight() {
  vizCore.node.attr("opacity", 1);
  vizCore.link.attr("opacity", 0.6);
}

vizUpdate.displayNodeDetails = function(d) {
  const detailsDiv = document.getElementById('nodeDetails');
  if (!detailsDiv) return;

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

vizUpdate.displayEdgeDetails = function(d) {
  const detailsDiv = document.getElementById('edgeDetails');
  if (!detailsDiv) return;

  let html = `<div class="details-content">`;
  html += `<h6>${d.type} ${d.flow_details ? 'Flow' : 'Relationship'}</h6>`;

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

  // Show flow_details if present
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

// Node hover
vizCore.node
  .on("mouseover", (event, d) => {
    const tooltip = d3.select("#tooltip");
    let content = `<strong>${d.name || d.id}</strong><br/>Type: ${d.type}`;
    if (d.gender) content += `<br/>Gender: ${d.gender}`;
    tooltip.style("visibility", "visible").html(content);
  })
  .on("mousemove", (event) => {
    const tooltip = d3.select("#tooltip");
    const [x, y] = d3.pointer(event, document.body);
    tooltip
      .style("top", (y+10) + "px")
      .style("left", (x+10) + "px");
  })
  .on("mouseout", () => {
    d3.select("#tooltip").style("visibility", "hidden");
  })
  .on("click", (event, d) => {
    highlightMultiHop(d, 2);
    vizUpdate.displayNodeDetails(d);
    event.stopPropagation();
  });

// Link hover
vizCore.link
  .on("mouseover", (event, d) => {
    const tooltip = d3.select("#tooltip");
    let content = `<strong>${d.type}</strong><br/>From: ${d.source.name}<br/>To: ${d.target.name}`;

    if (d.date) content += `<br/>Date: ${d.date}`;
    if (d.note) content += `<br/>Note: ${d.note}`;

    // If thick => quantity => explain
    if (d.flow_details && d.flow_details.quantity) {
      content += `<br/>Edge is thicker because quantity=${d.flow_details.quantity}`;
    }

    tooltip.style("visibility", "visible").html(content);
    d3.select(event.target)
      .attr("stroke-width", 3)
      .attr("stroke-opacity", 1);
  })
  .on("mousemove", (event) => {
    const tooltip = d3.select("#tooltip");
    const [x, y] = d3.pointer(event, document.body);
    tooltip
      .style("top", (y+10) + "px")
      .style("left", (x+10) + "px");
  })
  .on("mouseout", (event) => {
    d3.select("#tooltip").style("visibility", "hidden");
    d3.select(event.target)
      .attr("stroke-width", 1.5)
      .attr("stroke-opacity", 0.6);
  })
  .on("click", (event, d) => {
    vizUpdate.displayEdgeDetails(d);
    event.stopPropagation();
  });

// Click background => clear BFS
d3.select("body").on("click", () => {
  clearHighlight();
});

// Zoom controls
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

// End => hide loading
vizCore.simulation.on("end", () => {
  isSimulationStable = true;
  vizUpdate.hideLoading();
  console.log("Force simulation stabilized");
});

// Fallback
setTimeout(() => {
  if (!isSimulationStable) {
    console.log("Taking longer than expected, removing loading screen");
    vizUpdate.hideLoading();
  }
}, 2000);

console.log("vis-update.js loaded with BFS highlight, thick-edge explanation, full name display");
