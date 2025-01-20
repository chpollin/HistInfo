#!/usr/bin/env python3
# app.py
import os
from flask import Flask, send_from_directory, Response

app = Flask(__name__)

@app.route("/")
def index():
    # Inline HTML + JavaScript for the D3 treemap app
    html_content = r"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Basel Accounts Treemap</title>
  <script src="https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"></script>
  <style>
    body {
      font-family: sans-serif;
      margin: 20px;
    }

    #controls {
      margin-bottom: 1rem;
    }
    #chart {
      position: relative;
      width: 1200px;
      height: 700px;
      border: 1px solid #ccc;
    }
    #breadcrumb {
      margin: 10px 0;
      font-size: 14px;
    }

    .node {
      position: absolute;
      border: 1px solid #fff;
      box-sizing: border-box;
      overflow: hidden;
      cursor: pointer;
    }
    .node:hover {
      outline: 3px solid gold;
    }
    .label {
      padding: 4px;
      font-size: 12px;
      pointer-events: none;
    }

    /* Tooltip */
    #tooltip {
      position: absolute;
      padding: 8px;
      background: rgba(0,0,0,0.7);
      color: #fff;
      border-radius: 4px;
      pointer-events: none;
      visibility: hidden;
      z-index: 10;
      font-size: 12px;
      max-width: 200px;
    }
  </style>
</head>
<body>
  <h1>Basel Account Books: D3 Treemap</h1>
  <p>Click a rectangle to zoom in; click again near the top to zoom out.</p>

  <!-- We have no "year" slider, since your JSON is a single hierarchy. -->
  <div id="controls">
    <input type="text" id="searchInput" placeholder="Search category..." />
    <button id="exportBtn">Export Visible Data</button>
  </div>

  <div id="breadcrumb"></div>
  <div id="chart"></div>
  <div id="tooltip"></div>

  <script>
    // ------------------------------------------------------------------
    // 1) (Optional) Define a color scale if you have type + administration 
    //    in your data. Otherwise, fallback to a single color.
    //    For demonstration, let's map "Revenue|City", etc. 
    //    If you don't store that in your data, you'll get fallbackColor.
    // ------------------------------------------------------------------
    const colorMap = {
      "Revenue|City": "#6baed6",
      "Revenue|Territorial": "#3182bd",
      "Expenditure|City": "#9e9ac8",
      "Expenditure|Territorial": "#756bb1"
    };
    const fallbackColor = "#ccc";

    function getNodeColor(d) {
      // If your data doesn't have "type" or "administration", remove this
      const t = d.data.type || "";
      const a = d.data.administration || "";
      const key = t + "|" + a;
      return colorMap[key] || fallbackColor;
    }

    // We'll store the entire single-hierarchy JSON in memory.
    let hierarchyData = null;
    let currentNode = null;

    // Reference to the search box + other elements
    const searchInput = document.getElementById("searchInput");
    const exportBtn = document.getElementById("exportBtn");
    const chartDiv = d3.select("#chart");
    const breadcrumb = d3.select("#breadcrumb");
    const tooltip = d3.select("#tooltip");

    // ------------------------------------------------------------------
    // 2) Fetch the single hierarchy JSON (accounts_hierarchy.json)
    // ------------------------------------------------------------------
    d3.json("/accounts_hierarchy.json").then(data => {
      hierarchyData = data;
      updateAndRender();
    });

    // ------------------------------------------------------------------
    // 3) Filter + Build Hierarchy
    // ------------------------------------------------------------------
    function filterAndBuildHierarchy(rootData, query) {
      // We'll do a recursive filter by "name" if you provide a search query
      function filterNode(node) {
        const childArray = node.children || [];
        const filteredKids = childArray.map(filterNode).filter(d => d !== null);

        const nameMatches = node.name.toLowerCase().includes(query.toLowerCase());
        if (!query || nameMatches || filteredKids.length > 0) {
          // Return a new node with the filtered children
          return {
            ...node,
            children: filteredKids
          };
        } else {
          return null;
        }
      }

      // Because your JSON root is shaped like: { name, properties, children: [...] }
      // we start from that single root. Then we apply the filtering.
      return filterNode(rootData);
    }

    function updateAndRender() {
      if (!hierarchyData) return;

      const query = searchInput.value.trim().toLowerCase();
      const filteredRootData = filterAndBuildHierarchy(hierarchyData, query);
      if (!filteredRootData) {
        // If everything is filtered out, display nothing
        chartDiv.selectAll(".node").remove();
        breadcrumb.text("(No matches)");
        return;
      }

      // Convert to D3 hierarchy
      const root = d3.hierarchy(filteredRootData)
        .sum(d => d.node_amount || 0)
        .sort((a,b) => b.value - a.value);

      // Layout
      const width = chartDiv.node().offsetWidth;
      const height = chartDiv.node().offsetHeight;
      d3.treemap()
        .size([width, height])
        .padding(2)(root);

      currentNode = root;
      renderTreemap(root);
    }

    // ------------------------------------------------------------------
    // 4) Render Treemap
    // ------------------------------------------------------------------
    function renderTreemap(root) {
      chartDiv.selectAll(".node").remove(); // remove old nodes

      const selection = chartDiv
        .selectAll(".node")
        .data(root.descendants(), d => d.data.name);

      const enterNodes = selection.enter().append("div")
        .attr("class", "node")
        .style("left", d => d.x0 + "px")
        .style("top", d => d.y0 + "px")
        .style("width", d => (d.x1 - d.x0) + "px")
        .style("height", d => (d.y1 - d.y0) + "px")
        .style("background", getNodeColor)
        .on("click", (event, d) => {
          // If we clicked the same node again (and it's not root), zoom out
          if (currentNode === d && d.parent) {
            zoom(root);
          } else {
            zoom(d);
          }
          event.stopPropagation();
        })
        .on("mousemove", (event, d) => {
          const [mouseX, mouseY] = d3.pointer(event);
          tooltip
            .style("left", (mouseX + 20) + "px")
            .style("top", mouseY + "px");

          // Basic info
          let tooltipHTML = `<strong>${d.data.name}</strong><br/>`;
          if (d.data.type) tooltipHTML += `Type: ${d.data.type}<br/>`;
          if (d.data.administration) tooltipHTML += `Admin: ${d.data.administration}<br/>`;
          if (d.data.node_amount != null) {
            tooltipHTML += `Amount: ${d.data.node_amount.toFixed(2)}<br/>`;
          }
          else {
            tooltipHTML += `(aggregated or 0)`;
          }
          tooltipHTML += "<small>(Click to zoom)</small>";

          tooltip.html(tooltipHTML);
          tooltip.style("visibility", "visible");
        })
        .on("mouseleave", () => {
          tooltip.style("visibility", "hidden");
        });

      // Add label
      enterNodes.append("div")
        .attr("class", "label")
        .text(d => d.data.name);

      selection.exit().remove();
    }

    // ------------------------------------------------------------------
    // 5) Zoom + Breadcrumb
    // ------------------------------------------------------------------
    function zoom(targetNode) {
      currentNode = targetNode;
      const x0 = targetNode.x0;
      const y0 = targetNode.y0;
      const x1 = targetNode.x1;
      const y1 = targetNode.y1;

      const width = chartDiv.node().offsetWidth;
      const height = chartDiv.node().offsetHeight;
      const kx = width / (x1 - x0);
      const ky = height / (y1 - y0);

      chartDiv.selectAll(".node").transition()
        .duration(750)
        .style("left", d => (d.x0 - x0) * kx + "px")
        .style("top", d => (d.y0 - y0) * ky + "px")
        .style("width", d => (d.x1 - d.x0) * kx + "px")
        .style("height", d => (d.y1 - d.y0) * ky + "px");

      updateBreadcrumb(targetNode);
    }

    function updateBreadcrumb(node) {
      let path = node.ancestors().reverse();
      // The top is "ALL ACCOUNTS" so if you prefer to hide that from the breadcrumb, skip the first element
      if (path.length && path[0].data.name === "ALL ACCOUNTS") {
        path = path.slice(1);
      }
      const pathStr = path.map(d => d.data.name).join(" > ");
      breadcrumb.text(pathStr || "(No selection)");
    }

    // ------------------------------------------------------------------
    // 6) Search & Export
    // ------------------------------------------------------------------
    searchInput.addEventListener("input", () => {
      updateAndRender();
    });

    exportBtn.addEventListener("click", () => {
      // Export the currently filtered hierarchy as JSON
      const query = searchInput.value.trim();
      const filtered = filterAndBuildHierarchy(hierarchyData, query) || {};
      const blob = new Blob([JSON.stringify(filtered, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);

      const a = document.createElement("a");
      a.href = url;
      a.download = "FilteredHierarchy.json";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });
  </script>
</body>
</html>
"""
    return Response(html_content, mimetype="text/html")

@app.route("/accounts_hierarchy.json")
def serve_hierarchy():
    # Send the single JSON hierarchy.  Must exist in the same directory as app.py
    return send_from_directory(os.path.dirname(os.path.abspath(__file__)),
                               "accounts_hierarchy.json",
                               mimetype="application/json")

if __name__ == "__main__":
    app.run(debug=True, port=5000)
