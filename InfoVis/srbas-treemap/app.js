/*************************************************
 * app.js - Final Code
 *
 * Fixes layering overlap:
 *  - Removes old <svg> before drawing a new treemap.
 *  - Ensures zoom transitions remove the old group.
 * Prevents label overflow:
 *  - Hides text if the rect is too small (both width & height).
 * Retains aggregator, search, export, net balance, year filtering,
 * toggle between Einnahmen/Ausgaben, etc.
 *************************************************/

document.addEventListener("DOMContentLoaded", () => {
  // 1) DOM References
  const yearFromSlider = document.getElementById("yearFromSlider");
  const yearToSlider = document.getElementById("yearToSlider");
  const yearFromValue = document.getElementById("yearFromValue");
  const yearToValue = document.getElementById("yearToValue");
  const filterButton = document.getElementById("filterButton");
  const toggleButton = document.getElementById("toggleButton");

  const aggregatorSlider = document.getElementById("aggregatorSlider");
  const aggregatorValue = document.getElementById("aggregatorValue");

  const searchBox = document.getElementById("searchBox");
  const searchButton = document.getElementById("searchButton");
  const exportButton = document.getElementById("exportButton");
  const netBalanceDiv = document.getElementById("netBalance");

  // 2) Data containers
  let allData = [];
  let filteredData = [];
  let colorScale;

  let showingEinnahmen = true;
  let aggregatorLimit = +aggregatorSlider.value || 35;

  // 3) Load JSON
  console.log("Loading sparql-result-accounts.json...");
  d3.json("sparql-result-accounts.json")
    .then(data => {
      if (!Array.isArray(data)) {
        console.warn("Data is not an array:", data);
        return;
      }
      console.log(`Data loaded. Total records: ${data.length}`);

      // Remove records lacking account_name
      const validData = data.filter(d => d.account_name !== undefined);
      console.log(`Records after removing undefined account_name: ${validData.length}`);

      allData = validData;
      filteredData = validData;

      // Distinct account_name
      const accountNames = Array.from(new Set(allData.map(d => d.account_name)));
      console.log(`Found ${accountNames.length} distinct account_name(s):`, accountNames);

      // Build color scale
      colorScale = d3.scaleOrdinal()
        .domain(accountNames)
        .range(d3.schemeTableau10);

      buildDynamicLegend(accountNames, colorScale);

      updateSliderLabels();
      createTreemap(transformDataToHierarchy(filteredData), colorScale);
      updateNetBalance(filteredData);

      // Sliders -> update text
      yearFromSlider.addEventListener("input", updateSliderLabels);
      yearToSlider.addEventListener("input", updateSliderLabels);

      // Filter
      filterButton.addEventListener("click", applyYearFilter);

      // Toggle
      toggleButton.addEventListener("click", () => {
        showingEinnahmen = !showingEinnahmen;
        toggleButton.textContent = showingEinnahmen
          ? "Show Ausgaben"
          : "Show Einnahmen";
        console.log(`Toggle pressed. Now showingEinnahmen=${showingEinnahmen}`);

        const hierarchy = transformDataToHierarchy(filteredData);
        createTreemap(hierarchy, colorScale);
        updateNetBalance(filteredData);
      });

      // Search
      searchButton.addEventListener("click", () => {
        const query = (searchBox?.value || "").trim().toLowerCase();
        if (!query) return;
        highlightSubaccounts(query);
      });

      // Export
      exportButton.addEventListener("click", () => {
        exportToCSV(filteredData);
      });

      // Aggregator slider
      aggregatorSlider.addEventListener("input", () => {
        aggregatorLimit = +aggregatorSlider.value;
        aggregatorValue.textContent = aggregatorLimit;
      });
      aggregatorSlider.addEventListener("change", () => {
        console.log(`Aggregator limit changed to ${aggregatorLimit}`);
        const hierarchy = transformDataToHierarchy(filteredData);
        createTreemap(hierarchy, colorScale);
      });

    })
    .catch(err => {
      console.error("Error loading JSON:", err);
    });

  // 4) Update year slider labels
  function updateSliderLabels() {
    yearFromValue.textContent = yearFromSlider.value;
    yearToValue.textContent = yearToSlider.value;
  }

  // 5) Apply year filter
  function applyYearFilter() {
    const fromVal = +yearFromSlider.value;
    const toVal = +yearToSlider.value;
    console.log(`Filtering data by [${fromVal}, ${toVal}]...`);

    filteredData = allData.filter(d => {
      const start = parseInt(d.year_from, 10);
      const end = parseInt(d.year_to, 10);
      if (isNaN(start) || isNaN(end)) return false;
      return (start >= fromVal && end <= toVal);
    });

    console.log(`Filtered data count: ${filteredData.length}`);
    const hierarchy = transformDataToHierarchy(filteredData);
    createTreemap(hierarchy, colorScale);
    updateNetBalance(filteredData);
  }

  // 6) Build hierarchy with aggregator
  function transformDataToHierarchy(data) {
    console.log(`Transforming ${data.length} records. showingEinnahmen=${showingEinnahmen}`);

    const root = {
      name: "Finanzen Basel",
      children: [
        { name: "Einnahmen", children: [] },
        { name: "Ausgaben", children: [] }
      ]
    };

    const nodeEinnahmen = root.children[0];
    const nodeAusgaben = root.children[1];

    data.forEach(row => {
      const isEinnahme = (row.path || "").includes("/bs_Einnahmen");
      const branchNode = isEinnahme ? nodeEinnahmen : nodeAusgaben;

      // Fallback territory, quarter
      const territory = "Stadt";
      const quarter = "No Quarter Info";

      let territoryNode = branchNode.children.find(c => c.name === territory);
      if (!territoryNode) {
        territoryNode = { name: territory, children: [] };
        branchNode.children.push(territoryNode);
      }

      let quarterNode = territoryNode.children.find(c => c.name === quarter);
      if (!quarterNode) {
        quarterNode = { name: quarter, children: [] };
        territoryNode.children.push(quarterNode);
      }

      const account = row.account_name;
      const subaccount = row.subaccount_name || "Unbekannt";

      let accNode = quarterNode.children.find(c => c.name === account);
      if (!accNode) {
        accNode = { name: account, children: [] };
        quarterNode.children.push(accNode);
      }

      let subNode = accNode.children.find(c => c.name === subaccount);
      if (!subNode) {
        subNode = { name: subaccount, size: 0, data: [] };
        accNode.children.push(subNode);
      }

      const rawVal = parseInt(row.subamount, 10) || parseInt(row.amount, 10) || 0;
      subNode.size += Math.abs(rawVal);
      subNode.data.push(row);
    });

    // Keep only relevant branch
    if (showingEinnahmen) {
      root.children = [nodeEinnahmen];
    } else {
      root.children = [nodeAusgaben];
    }

    // aggregator
    root.children.forEach(topBranch => {
      topBranch.children.forEach(territoryNode => {
        territoryNode.children.forEach(quarterNode => {
          quarterNode.children.forEach(accNode => {
            aggregateSmallSubaccounts(accNode, aggregatorLimit);
          });
        });
      });
    });

    return root;
  }

  function aggregateSmallSubaccounts(accNode, limit) {
    const subs = accNode.children;
    if (!subs || subs.length === 0) return;

    subs.sort((a, b) => (b.size || 0) - (a.size || 0));
    if (subs.length > limit) {
      const keep = subs.slice(0, limit);
      const remainder = subs.slice(limit);
      const othersNode = {
        name: "Others",
        children: remainder,
        size: remainder.reduce((sum, r) => sum + (r.size || 0), 0)
      };
      keep.push(othersNode);
      accNode.children = keep;
    }
  }

  // 7) Create Treemap
  function createTreemap(hierarchyData, colorScale) {
    console.log("Creating treemap with aggregatorLimit =", aggregatorLimit);

    // Remove old <svg> to avoid layering
    d3.select("#treemap").selectAll("svg").remove();

    const width = 1200;
    const height = 800;

    const root = d3.hierarchy(hierarchyData)
      .sum(d => d.size || 0)
      .sort((a, b) => (b.value || 0) - (a.value || 0));

    d3.treemap()
      .size([width, height])
      .padding(2)(root);

    const svg = d3.select("#treemap")
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .style("font-family", "sans-serif");

    let currentFocus = root;
    let view;

    const nodes = svg.selectAll("g")
      .data(root.descendants())
      .join("g")
      .attr("transform", d => `translate(${d.x0},${d.y0})`)
      .on("click", (event, d) => {
        event.stopPropagation();
        if (currentFocus !== d) {
          zoomIn(d);
        } else if (d.parent) {
          zoomIn(d.parent);
        }
      });

    nodes.append("rect")
      .attr("width", d => d.x1 - d.x0)
      .attr("height", d => d.y1 - d.y0)
      .attr("fill", d => {
        if (!d.parent) return "#ccc"; // root
        // Leaf => color by parent's name
        if (!d.children) return colorScale(d.parent.data.name);
        // Otherwise => color by node's name
        return colorScale(d.data.name);
      })
      .attr("stroke", "#fff")
      .attr("data-subaccount", d => (!d.children ? d.data.name.toLowerCase() : null));

    // Label text
    const label = nodes.append("text")
      .style("fill", "#fff")
      .style("font-size", "12px")
      .style("pointer-events", "none")
      .style("user-select", "none")
      .attr("dx", 4)
      .attr("dy", 14)
      .text(d => {
        // Skip label if rect is too small
        const rectWidth = d.x1 - d.x0;
        const rectHeight = d.y1 - d.y0;
        if (rectWidth < 50 || rectHeight < 15) {
          return ""; // hide text in small squares
        }
        if (!d.children) {
          return d.data.name;
        } else {
          const val = d.value || 0;
          return `${d.data.name} (${val})`;
        }
      });

    // Tooltip
    const tooltip = d3.select("body")
      .append("div")
      .attr("class", "tooltip")
      .style("opacity", 0);

    nodes
      .filter(d => !d.children) // only leaves
      .on("mouseover", (event, d) => {
        const total = d.value || 0;
        const row = d.data?.data?.[0] || {};
        const warning = row.warning ? `<div><strong>Warning:</strong> ${row.warning}</div>` : "";
        const subwarning = row.subwarning ? `<div><strong>Subwarning:</strong> ${row.subwarning}</div>` : "";

        tooltip
          .style("opacity", 1)
          .html(`
            <div style="font-weight:bold; margin-bottom:4px;">${d.data.name}</div>
            <div><strong>Summe:</strong> ${total.toLocaleString()}</div>
            <div><strong>Jahre:</strong> ${row.year_from || "-"} - ${row.year_to || ""}</div>
            <div><strong>Konto:</strong> ${row.account_name || ""}</div>
            <div><strong>Subkonto:</strong> ${row.subaccount_name || ""}</div>
            ${warning}
            ${subwarning}
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

    function zoomIn(d) {
      currentFocus = d;
      const transition = svg.transition()
        .duration(750)
        .tween("zoom", () => {
          const i = d3.interpolateZoom(
            view,
            [d.x0, d.y0, d.x1 - d.x0]
          );
          return t => zoomTo(i(t));
        });
    }

    function zoomTo(v) {
      const [x0, y0, w] = v;
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

    view = [root.x0, root.y0, root.x1 - root.x0];
  }

  // 8) Legend
  function buildDynamicLegend(accountNames, colorScale) {
    console.log("Building dynamic legend for:", accountNames);
    const legendContainer = d3.select("#dynamic-legend");
    legendContainer.selectAll("*").remove();

    accountNames.forEach(name => {
      const item = legendContainer
        .append("div")
        .attr("class", "legend-item");

      item.append("div")
        .attr("class", "legend-swatch")
        .style("background-color", colorScale(name));

      item.append("span").text(name);
    });
  }

  // 9) Search highlight
  function highlightSubaccounts(query) {
    d3.selectAll("[data-subaccount]")
      .style("stroke", "#fff")
      .style("stroke-width", 1);

    const matched = d3.selectAll(`[data-subaccount*="${query}"]`);
    matched
      .style("stroke", "black")
      .style("stroke-width", 3);

    console.log(`Highlighted ${matched.size()} subaccount(s) for "${query}".`);
  }

  // 10) Export CSV
  function exportToCSV(data) {
    if (!data || data.length === 0) {
      alert("No filtered data to export!");
      return;
    }
    const headers = ["year_from", "year_to", "account_name", "subaccount_name", "amount", "subamount"];
    const csvRows = [];
    csvRows.push(headers.join(","));

    data.forEach(row => {
      const rowVals = headers.map(h => `"${row[h] || ""}"`);
      csvRows.push(rowVals.join(","));
    });

    const csvContent = csvRows.join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.style.display = "none";
    a.href = url;
    a.download = "filtered_data.csv";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  // 11) Net balance
  function updateNetBalance(data) {
    if (!netBalanceDiv) return;
    let totalEinnahmen = 0;
    let totalAusgaben = 0;

    data.forEach(d => {
      if ((d.path || "").includes("/bs_Einnahmen")) {
        const val = parseInt(d.subamount, 10) || parseInt(d.amount, 10) || 0;
        totalEinnahmen += val;
      } else if ((d.path || "").includes("/bs_Ausgaben")) {
        const val = parseInt(d.subamount, 10) || parseInt(d.amount, 10) || 0;
        totalAusgaben += val;
      }
    });

    const net = totalEinnahmen + totalAusgaben;
    netBalanceDiv.textContent = `Net Balance: ${net.toLocaleString()}
(Einnahmen: ${totalEinnahmen.toLocaleString()} / Ausgaben: ${Math.abs(totalAusgaben).toLocaleString()})`;
  }

});
