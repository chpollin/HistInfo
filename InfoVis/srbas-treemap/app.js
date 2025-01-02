/*************************************************
 * app.js - Final Improved Version
 *
 * Handles:
 * 1) Loading sparql-result-accounts.json
 * 2) Filtering by year range (yearFromSlider, yearToSlider)
 * 3) Toggle between "Einnahmen" and "Ausgaben"
 * 4) Handling negative amounts by taking absolute value
 * 5) Skips records with undefined account_name (or you can rename them)
 * 6) Zoomable treemap with color legend + hover tooltips
 *************************************************/

document.addEventListener("DOMContentLoaded", () => {
    // DOM references
    const yearFromSlider = document.getElementById("yearFromSlider");
    const yearToSlider = document.getElementById("yearToSlider");
    const yearFromValue = document.getElementById("yearFromValue");
    const yearToValue = document.getElementById("yearToValue");
    const filterButton = document.getElementById("filterButton");
    const toggleButton = document.getElementById("toggleButton");
  
    // Data containers
    let allData = [];
    let filteredData = [];
    let colorScale;
  
    // Start by showing "Einnahmen" (true)
    let showingEinnahmen = true;
  
    // 1) Load JSON data
    console.log("Loading sparql-result-accounts.json...");
    d3.json("sparql-result-accounts.json")
      .then(data => {
        if (!Array.isArray(data)) {
          console.warn("Data is not an array. Check JSON format:", data);
          return;
        }
        console.log(`Data loaded. Total records: ${data.length}`);
  
        // 1A) Filter out any records where account_name is undefined
        const validData = data.filter(d => d.account_name !== undefined);
        console.log(`Records after removing undefined account_name: ${validData.length}`);
  
        allData = validData;
        filteredData = validData;
  
        // Distinct account_name for color scale
        const accountNames = Array.from(new Set(allData.map(d => d.account_name)));
        console.log(`Found ${accountNames.length} distinct account_name(s):`, accountNames);
  
        // Build color scale
        colorScale = d3.scaleOrdinal()
          .domain(accountNames)
          .range(d3.schemeTableau10);
  
        // Build dynamic legend
        buildDynamicLegend(accountNames, colorScale);
  
        // Initial treemap
        updateSliderLabels();
        createTreemap(transformDataToHierarchy(filteredData), colorScale);
  
        // Sliders -> update numeric labels
        yearFromSlider.addEventListener("input", updateSliderLabels);
        yearToSlider.addEventListener("input", updateSliderLabels);
  
        // Filter button
        filterButton.addEventListener("click", applyYearFilter);
  
        // Toggle button
        toggleButton.addEventListener("click", () => {
          showingEinnahmen = !showingEinnahmen;
          toggleButton.textContent = showingEinnahmen
            ? "Show Ausgaben"
            : "Show Einnahmen";
          console.log(`Toggle pressed. Now showingEinnahmen=${showingEinnahmen}`);
  
          // Rebuild hierarchy + treemap
          const hierarchy = transformDataToHierarchy(filteredData);
          createTreemap(hierarchy, colorScale);
        });
      })
      .catch(err => {
        console.error("Error loading JSON:", err);
      });
  
    /**
     * Update numeric labels near the sliders
     */
    function updateSliderLabels() {
      yearFromValue.textContent = yearFromSlider.value;
      yearToValue.textContent = yearToSlider.value;
    }
  
    /**
     * Filter the data by year range
     */
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
    }
  
    /**
     * Transform data -> a hierarchy with two top-level children:
     *  "Einnahmen" and "Ausgaben"
     */
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
        // /bs_Einnahmen => isEinnahme, else Ausgaben
        const isEinnahme = (row.path || "").includes("/bs_Einnahmen");
        const branchNode = isEinnahme ? nodeEinnahmen : nodeAusgaben;
  
        // Group by account_name
        let accNode = branchNode.children.find(c => c.name === row.account_name);
        if (!accNode) {
          accNode = {
            name: row.account_name,
            children: []
          };
          branchNode.children.push(accNode);
        }
  
        // Group by subaccount_name
        let subNode = accNode.children.find(c => c.name === row.subaccount_name);
        if (!subNode) {
          subNode = {
            name: row.subaccount_name || "Unbekannt",
            size: 0,
            data: []
          };
          accNode.children.push(subNode);
        }
  
        // Sum absolute value of subamount or amount if negative
        const rawVal = parseInt(row.subamount, 10) || parseInt(row.amount, 10) || 0;
        const val = Math.abs(rawVal);
        subNode.size += val;
        subNode.data.push(row);
      });
  
      // Keep only the relevant branch
      if (showingEinnahmen) {
        root.children = [nodeEinnahmen];
      } else {
        root.children = [nodeAusgaben];
      }
  
      return root;
    }
  
    /**
     * Create or update the zoomable treemap
     */
    function createTreemap(hierarchyData, colorScale) {
      console.log("Creating treemap with hierarchy:", hierarchyData);
  
      // Clear old
      d3.select("#treemap").selectAll("svg").remove();
  
      // A bigger area to fill screen
      const width = 1200;
      const height = 800;
  
      // Build d3 hierarchy
      const root = d3.hierarchy(hierarchyData)
        .sum(d => d.size)
        .sort((a, b) => b.value - a.value);
  
      d3.treemap()
        .size([width, height])
        .padding(2)(root);
  
      // Append SVG
      const svg = d3.select("#treemap")
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .style("font-family", "sans-serif");
  
      let currentFocus = root;
      let view;
  
      // Groups for each node
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
  
      // Rectangles
      nodes.append("rect")
        .attr("width", d => d.x1 - d.x0)
        .attr("height", d => d.y1 - d.y0)
        .attr("fill", d => {
          // Root => grey
          if (!d.parent) return "#ccc";
          // Leaves => color by parent's name
          if (!d.children) {
            return colorScale(d.parent.data.name);
          }
          // Internal => color by its own name
          return colorScale(d.data.name);
        })
        .attr("stroke", "#fff");
  
      // Leaf labels
      const label = nodes
        .filter(d => !d.children)
        .append("text")
        .attr("dx", 4)
        .attr("dy", 14)
        .style("fill", "#fff")
        .style("font-size", "12px")
        .style("pointer-events", "none")
        .style("user-select", "none")
        .text(d => d.data.name);
  
      // Tooltip
      const tooltip = d3.select("body")
        .append("div")
        .attr("class", "tooltip");
  
      nodes
        .filter(d => !d.children) // leaves
        .on("mouseover", (event, d) => {
          const total = d.value;
          const row = d.data?.data?.[0] || {};
          tooltip
            .style("opacity", 1)
            .html(`
              <div style="font-weight:bold; margin-bottom:4px;">${d.data.name}</div>
              <div><strong>Summe:</strong> ${total}</div>
              <div><strong>Jahre:</strong> ${row.year_from || ""} - ${row.year_to || ""}</div>
              <div><strong>Konto:</strong> ${row.account_name || ""}</div>
              <div><strong>Subkonto:</strong> ${row.subaccount_name || ""}</div>
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
  
      /**
       * Zoom on click
       */
      function zoomIn(d) {
        currentFocus = d;
        const transition = svg.transition()
          .duration(750)
          .tween("zoom", () => {
            const i = d3.interpolateZoom(
              view,
              [currentFocus.x0, currentFocus.y0, currentFocus.x1 - currentFocus.x0]
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
  
      // Initialize default view
      view = [root.x0, root.y0, root.x1 - root.x0];
    }
  
    // Build a dynamic legend from distinct account_names
    function buildDynamicLegend(accountNames, colorScale) {
      console.log("Building dynamic legend for these accountNames:", accountNames);
      const legendContainer = d3.select("#dynamic-legend");
      legendContainer.selectAll("*").remove(); // Clear old
  
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
  });
  