/***************************************************************
 * app.js - Unified Einnahmen/Ausgaben in One Treemap
 * 
 * Key improvements:
 *  1. Two top-level children: "Einnahmen" + "Ausgaben."
 *  2. No aggregator / "Others" node.
 *  3. Year filtering is dynamically triggered by sliders (no filter btn).
 *  4. Distinct color scales: Blue for Einnahmen, Orange for Ausgaben.
 *  5. A "Reset Zoom" link in the breadcrumb to jump back to the root.
 *  6. Net balance is clearer: Net, total incomes, total expenses, color-coded.
 ***************************************************************/

document.addEventListener("DOMContentLoaded", () => {
  // DOM References
  const yearFromSlider = document.getElementById("yearFromSlider");
  const yearToSlider = document.getElementById("yearToSlider");
  const yearFromValue = document.getElementById("yearFromValue");
  const yearToValue = document.getElementById("yearToValue");

  const searchBox = document.getElementById("searchBox");
  const searchButton = document.getElementById("searchButton");
  const exportButton = document.getElementById("exportButton");
  const netBalanceDiv = document.getElementById("netBalance");
  const breadcrumbContainer = document.getElementById("breadcrumb");
  const legendContainer = document.getElementById("dynamic-legend");

  // Data placeholders
  let allData = [];
  let filteredData = [];

  // Global references for zooming
  let globalRoot = null;
  let currentFocus = null;
  let view = null; // For zoom transitions

  // Debounce for year sliders
  let filterDebounce = null;

  console.log("Loading data from sparql-result-accounts.json...");
  d3.json("sparql-result-accounts.json")
    .then(data => {
      if (!Array.isArray(data)) {
        console.error("Data is not an array. Check JSON structure.", data);
        return;
      }
      // Filter out records with no account_name
      allData = data.filter(d => d.account_name);
      console.log(`Total valid records: ${allData.length}`);

      // Initial filter: everything
      filteredData = [...allData];

      // Build color scale based on parent = "Einnahmen" or "Ausgaben"
      // We can do a small dictionary for top-level:
      //   "Einnahmen": d3.scaleOrdinal(d3.schemeBlues[9]),
      //   "Ausgaben": d3.scaleOrdinal(d3.schemeOranges[9])
      // But let's keep it simpler: if it's under Einnahmen, pick from a blue scale,
      // if under Ausgaben, pick from orange scale.
      // We'll do a function to decide the color.
      function colorForNode(d) {
        // If the parent's name = "Einnahmen", we use a blues scale
        // If the parent's name = "Ausgaben", we use an orange scale
        // If it's root, return a neutral color
        if (!d.parent) return "#ccc";
        const topName = d.ancestors()[1]?.data?.name; // The second ancestor is "Einnahmen" or "Ausgaben"
        if (topName === "Einnahmen") {
          return d3.schemeBlues[5][(d.depth % 5)]; 
        } else if (topName === "Ausgaben") {
          return d3.schemeOranges[5][(d.depth % 5)];
        }
        return "#ccc";
      }

      // We won't build a legend for each subaccount. Instead, we can just show:
      //   - Blue squares = Einnahmen
      //   - Orange squares = Ausgaben
      // So let's manually add two legend items:
      legendContainer.innerHTML = "";
      makeLegendItem("Einnahmen (blue)", "#4299e1"); // or any representative color
      makeLegendItem("Ausgaben (orange)", "#ed8936");

      // Build the initial treemap
      updateSliderLabels();
      createTreemap(transformToUnifiedHierarchy(filteredData), colorForNode);
      updateNetBalance(filteredData);

      // Year slider changes => dynamic filter
      yearFromSlider.addEventListener("input", onYearSliderChange);
      yearToSlider.addEventListener("input", onYearSliderChange);

      // Search
      searchButton.addEventListener("click", () => {
        const query = (searchBox.value || "").trim().toLowerCase();
        if (!query) return;
        highlightSubaccounts(query);
      });

      // Export CSV
      exportButton.addEventListener("click", () => {
        exportToCSV(filteredData);
      });

    })
    .catch(err => console.error("Error fetching data:", err));

  /* 1) Transform Data => Two Branches: "Einnahmen" & "Ausgaben" */
  function transformToUnifiedHierarchy(data) {
    // Build a root with children: [ {name: "Einnahmen"}, {name: "Ausgaben"} ]
    const root = {
      name: "Finanzen Basel",
      children: [
        { name: "Einnahmen", children: [] },
        { name: "Ausgaben", children: [] }
      ]
    };
    const nodeIncome = root.children[0];
    const nodeExpense = root.children[1];

    data.forEach(row => {
      // Check if row belongs to Einnahmen or Ausgaben
      const isIncome = (row.path || "").includes("/bs_Einnahmen");
      const branchNode = isIncome ? nodeIncome : nodeExpense;

      // Add an account node if not present
      const accountName = row.account_name;
      let accountNode = branchNode.children.find(c => c.name === accountName);
      if (!accountNode) {
        accountNode = { name: accountName, children: [] };
        branchNode.children.push(accountNode);
      }

      // Add subaccount
      const subName = row.subaccount_name || "Unbekannt";
      let subNode = accountNode.children.find(s => s.name === subName);
      if (!subNode) {
        subNode = { name: subName, size: 0, data: [] };
        accountNode.children.push(subNode);
      }

      // We'll store absolute value for the rectangle size
      const rawVal = parseInt(row.subamount, 10) || parseInt(row.amount, 10) || 0;
      subNode.size += Math.abs(rawVal);
      subNode.data.push(row);
    });

    return root;
  }

  /* 2) Create Treemap */
  function createTreemap(hierarchyData, colorFunc) {
    // Wipe previous svg
    d3.select("#treemap").selectAll("svg").remove();

    // Build a D3 hierarchy
    globalRoot = d3.hierarchy(hierarchyData)
      .sum(d => d.size || 0)
      .sort((a, b) => (b.value || 0) - (a.value || 0));

    // Layout
    const width = 1200;
    const height = 800;

    d3.treemap()
      .size([width, height])
      .padding(2)(globalRoot);

    const svg = d3.select("#treemap")
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .style("font-family", "sans-serif");

    currentFocus = globalRoot;
    view = [globalRoot.x0, globalRoot.y0, globalRoot.x1 - globalRoot.x0];

    // Update breadcrumb with a "Reset Zoom" link
    updateBreadcrumb(globalRoot);

    // Add group for each node
    const nodes = svg.selectAll("g")
      .data(globalRoot.descendants())
      .join("g")
      .attr("transform", d => `translate(${d.x0},${d.y0})`)
      .on("click", (event, d) => {
        event.stopPropagation();
        if (currentFocus !== d) {
          zoomIn(d, svg);
        } else if (d.parent) {
          zoomIn(d.parent, svg);
        }
      });

    // Rect
    nodes.append("rect")
      .attr("width", d => d.x1 - d.x0)
      .attr("height", d => d.y1 - d.y0)
      .attr("fill", d => colorFunc(d))
      .attr("stroke", "#fff")
      .attr("data-subaccount", d => (!d.children ? d.data.name.toLowerCase() : null));

    // Label
    const label = nodes.append("text")
      .style("fill", "#fff")
      .style("font-size", "12px")
      .style("pointer-events", "none")
      .style("user-select", "none")
      .attr("dx", 4)
      .attr("dy", 14)
      .text(d => {
        const w = d.x1 - d.x0;
        const h = d.y1 - d.y0;
        if (w < 50 || h < 15) return "";
        if (!d.children) {
          return d.data.name;
        }
        return `${d.data.name} (${d.value})`;
      });

    // Tooltip
    const tooltip = d3.select("body").append("div")
      .attr("class", "tooltip")
      .style("opacity", 0);

    nodes
      .filter(d => !d.children)
      .on("mouseover", (event, d) => {
        const val = d.value || 0;
        const row = (d.data.data && d.data.data[0]) ? d.data.data[0] : {};
        tooltip
          .style("opacity", 1)
          .html(`
            <div style="font-weight:bold;">${d.data.name}</div>
            <div>Sum: ${val.toLocaleString()}</div>
            <div>Year range: ${row.year_from} - ${row.year_to}</div>
            <div>Account: ${row.account_name || ""}</div>
            <div>Subacct: ${row.subaccount_name || ""}</div>
          `);
      })
      .on("mousemove", (event) => {
        tooltip
          .style("left", `${event.pageX + 10}px`)
          .style("top", `${event.pageY + 10}px`);
      })
      .on("mouseout", () => {
        tooltip.style("opacity", 0);
      });

    // Zoom functions
    function zoomIn(d, svg) {
      currentFocus = d;
      updateBreadcrumb(d); // update breadcrumb
      svg.transition()
        .duration(750)
        .tween("zoom", () => {
          const i = d3.interpolateZoom(view, [d.x0, d.y0, d.x1 - d.x0]);
          return t => zoomTo(i(t), nodes, label);
        });
    }
  }

  function zoomTo(v, nodes, label) {
    if (!nodes) {
      // If not yet rendered
      return;
    }
    const [x0, y0, w] = v;
    const width = 1200;
    const k = width / w;
    view = v;

    nodes
      .attr("transform", node => {
        return `translate(${(node.x0 - x0) * k},${(node.y0 - y0) * k})`;
      })
      .select("rect")
      .attr("width", node => (node.x1 - node.x0) * k)
      .attr("height", node => (node.y1 - node.y0) * k);

    label
      .attr("dx", 4 * k)
      .attr("dy", 14 * k)
      .style("font-size", `${12 * k}px`);
  }

  /* 3) Year Slider => Dynamic Filter */
  function onYearSliderChange() {
    updateSliderLabels();
    if (filterDebounce) clearTimeout(filterDebounce);
    filterDebounce = setTimeout(() => {
      applyYearFilter();
    }, 300);
  }

  function updateSliderLabels() {
    yearFromValue.textContent = yearFromSlider.value;
    yearToValue.textContent = yearToSlider.value;
  }

  function applyYearFilter() {
    const fromVal = +yearFromSlider.value;
    const toVal = +yearToSlider.value;
    filteredData = allData.filter(d => {
      const s = parseInt(d.year_from, 10);
      const e = parseInt(d.year_to, 10);
      if (isNaN(s) || isNaN(e)) return false;
      return s >= fromVal && e <= toVal;
    });
    createTreemap(transformToUnifiedHierarchy(filteredData), d => colorByTopParent(d));
    updateNetBalance(filteredData);
  }

  // For the dynamic coloring in applyYearFilter, replicate colorForNode logic:
  function colorByTopParent(d) {
    if (!d.parent) return "#ccc";
    const topName = d.ancestors()[1]?.data?.name;
    if (topName === "Einnahmen") {
      return d3.schemeBlues[5][(d.depth % 5)];
    } else if (topName === "Ausgaben") {
      return d3.schemeOranges[5][(d.depth % 5)];
    }
    return "#ccc";
  }

  /* 4) Update Net Balance */
  function updateNetBalance(data) {
    if (!netBalanceDiv) return;
    let totalIncome = 0;
    let totalExpense = 0;

    data.forEach(row => {
      const val = parseInt(row.subamount, 10) || parseInt(row.amount, 10) || 0;
      if ((row.path || "").includes("/bs_Ausgaben")) {
        // Typically negative or we treat it as negative
        totalExpense += val;
      } else {
        totalIncome += val;
      }
    });

    const net = totalIncome + totalExpense;
    netBalanceDiv.innerHTML = `
      <div>
        <strong>Net:</strong> ${net.toLocaleString()}
      </div>
      <div>
        <strong>Incomes:</strong> ${totalIncome.toLocaleString()}
      </div>
      <div>
        <strong>Expenses:</strong> ${Math.abs(totalExpense).toLocaleString()}
      </div>
    `;

    // Color code
    if (net < 0) {
      netBalanceDiv.style.color = "red";
    } else {
      netBalanceDiv.style.color = "green";
    }
  }

  /* 5) Search highlight */
  function highlightSubaccounts(query) {
    // reset stroke
    d3.selectAll("[data-subaccount]")
      .style("stroke", "#fff")
      .style("stroke-width", 1);

    const matched = d3.selectAll(`[data-subaccount*="${query}"]`);
    matched
      .style("stroke", "black")
      .style("stroke-width", 3);

    console.log(`Highlighted ${matched.size()} subaccount(s) for "${query}".`);
  }

  /* 6) Export CSV */
  function exportToCSV(data) {
    if (!data || data.length === 0) {
      alert("No filtered data to export!");
      return;
    }
    const headers = [
      "year_from", "year_to", "account_name", "subaccount_name", "amount", "subamount"
    ];
    const csvRows = [headers.join(",")];
    data.forEach(row => {
      const rowVals = headers.map(h => `"${row[h] || ""}"`);
      csvRows.push(rowVals.join(","));
    });
    const csvContent = csvRows.join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);

    const fn = `basel_data_${yearFromSlider.value}-${yearToSlider.value}.csv`;
    const a = document.createElement("a");
    a.style.display = "none";
    a.href = url;
    a.download = fn;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  /* 7) Breadcrumb with "Reset Zoom" link */
  function updateBreadcrumb(node) {
    if (!breadcrumbContainer) return;
    breadcrumbContainer.innerHTML = ""; // clear

    // “Reset Zoom” link:
    const resetLink = document.createElement("a");
    resetLink.textContent = "Reset Zoom";
    resetLink.style.cursor = "pointer";
    resetLink.style.marginRight = "1rem";
    resetLink.onclick = () => {
      if (globalRoot && currentFocus !== globalRoot) {
        // Zoom back to root
        zoomIn(globalRoot);
      }
    };
    breadcrumbContainer.appendChild(resetLink);

    // Then show the chain of ancestors
    const chain = node.ancestors().reverse().map(d => d.data.name);
    const breadcrumbText = document.createElement("span");
    breadcrumbText.textContent = "Hierarchy: " + chain.join(" > ");
    breadcrumbContainer.appendChild(breadcrumbText);
  }

  // Access the zoomIn logic from above
  function zoomIn(d) {
    if (!globalRoot) return;
    const svg = d3.select("#treemap svg");
    // We'll reconstruct the nodes selection for the new zoom
    const nodes = svg.selectAll("g");
    const label = nodes.select("text");
    const i = d3.interpolateZoom(view, [d.x0, d.y0, d.x1 - d.x0]);
    currentFocus = d;
    updateBreadcrumb(d);
    svg.transition()
      .duration(750)
      .tween("zoom", () => {
        return t => zoomTo(i(t), nodes, label);
      });
  }

  // Helper to build two manual legend items
  function makeLegendItem(text, color) {
    const item = document.createElement("div");
    item.className = "legend-item";

    const swatch = document.createElement("div");
    swatch.className = "legend-swatch";
    swatch.style.backgroundColor = color;
    item.appendChild(swatch);

    const span = document.createElement("span");
    span.textContent = text;
    item.appendChild(span);

    legendContainer.appendChild(item);
  }
});
