Below is a **detailed** `README.md` that explains every facet of your D3 treemap dashboard—covering the **file structure**, **data format**, **installation/usage** instructions, and **features** such as year filtering, aggregator logic, subaccount search, CSV export, and more.

```markdown
# Basel Historical Financial Data Visualization

**A user‐friendly dashboard** for visualizing Basel’s 16th‐century financial accounts (1535–1610), featuring:
- **Treemap** representation of `Einnahmen` (revenue) vs. `Ausgaben` (expenditure).
- **Year‐range** filtering via sliders.
- **Aggregator** logic to prevent a clutter of tiny subaccounts.
- **Search** to highlight specific subaccounts.
- **CSV export** of the filtered dataset.
- **Net balance** display (Einnahmen minus Ausgaben).

## Table of Contents
1. [Project Overview](#project-overview)
2. [File Structure](#file-structure)
3. [Data Format](#data-format)
4. [Installation & Setup](#installation--setup)
5. [Usage](#usage)
   - [Year Filter](#year-filter)
   - [Toggle Einnahmen/Ausgaben](#toggle-einnahmenausgaben)
   - [Aggregator Slider](#aggregator-slider)
   - [Search Subaccount](#search-subaccount)
   - [Export CSV](#export-csv)
   - [Net Balance](#net-balance)
   - [Treemap Zooming](#treemap-zooming)
6. [How It Works Internally](#how-it-works-internally)
   - [Hierarchy Building](#hierarchy-building)
   - [Aggregator Logic](#aggregator-logic)
   - [Zoom Transitions](#zoom-transitions)
7. [Further Customization](#further-customization)
8. [Troubleshooting](#troubleshooting)
9. [License](#license)

---

## Project Overview
Historians often need an **interactive** way to explore city‐state financial records. This project uses **D3.js** to create a **zoomable treemap** showing Basel’s “year accounts” from 1535 to 1610, with features to:
- Filter data by year range.
- Distinguish **Einnahmen** (revenues) vs. **Ausgaben** (expenditures).
- Control how many subaccounts appear before rolling the remainder into “Others.”
- Search by subaccount name.
- Export the currently displayed data as a CSV.
- Display the net balance for further analysis.

---

## File Structure
Three core files make up this application:

1. **`index.html`**  
   - Defines the **dashboard layout**: a left pane for controls and a right pane for the treemap + legend.
   - Loads **D3** from the CDN and then runs **`app.js`**.

2. **`style.css`**  
   - Provides styling for the layout, controls, tooltips, legend, and treemap.
   - Implements a **responsive** 2‐pane design and ensures consistent color scheme & typography.

3. **`app.js`**  
   - The main **JavaScript logic**:
     - Loads `sparql-result-accounts.json`.
     - Builds the treemap hierarchy (aggregator lumps small subaccounts).
     - Wires up **year slider**, **aggregator slider**, **search**, **export** button, **toggle** button, and **zoom** transitions.
     - Displays tooltips, net balance, color legend, etc.

Additionally, you must have a **data file** named **`sparql-result-accounts.json`** in the same directory (or adjust the path inside `app.js`).

---

## Data Format
The JSON file (e.g., `sparql-result-accounts.json`) expects an **array** of records. Each record should have:

```json
{
  "year_from": 1535,
  "year_to": 1536,
  "path": "/bs_Einnahmen/bs_StadtEinnahmen",
  "amount": 7300336,
  "subamount": 485253,
  "account_name": "Einnahmen Stadt",
  "subaccount_name": "Allgemeine Einnahmen",
  ...
}
```

- **`year_from`, `year_to`**: Integers specifying the date range.  
- **`path`**: A string that includes either `"/bs_Einnahmen"` or `"/bs_Ausgaben"`.  
- **`account_name`**: Typically `"Einnahmen Stadt"` or `"Ausgaben Stadt"`.  
- **`subaccount_name`**: The subcategory.  
- **`amount`, `subamount`**: Possibly negative for Ausgaben; code takes absolute values for the treemap size.

Any fields not recognized (like `warning` or `subwarning`) will appear in the tooltip if present.

---

## Installation & Setup

1. **Download or Clone** this repository.
2. Ensure you have the following files in the same directory:
   - `index.html`
   - `style.css`
   - `app.js`
   - `sparql-result-accounts.json` (or a JSON file with a similar structure).
3. **Open `index.html`** in your web browser (Chrome, Firefox, or similar).  
   - No local server is strictly required, but using a simple local server (e.g. Python’s `http.server`) can avoid any local file restrictions.

---

## Usage

### Year Filter
- Two sliders (`From` and `To`) let you define a year range between **1535** and **1610**.
- After adjusting them, click the **Filter** button to apply changes.  
- The treemap updates to show records where `(year_from >= FromSliderValue && year_to <= ToSliderValue)`.

### Toggle Einnahmen/Ausgaben
- By default, the treemap shows **Einnahmen**.  
- Click **Show Ausgaben** to switch. The button text toggles between “Show Ausgaben” and “Show Einnahmen.”

### Aggregator Slider
- “Subaccounts to Show” slider (default **35**) controls how many subaccounts appear within each account node.  
- If a node has more children than the chosen limit, the **smallest** ones are grouped under a single “Others” node.  
  - This prevents clutter from many tiny rectangles.  
- Changing this slider *on the fly* triggers a rebuild of the treemap so you can experiment with different thresholds.

### Search Subaccount
- Enter any text in the **Search subaccount...** box and hit **Search**.  
- All subaccount rectangles whose name contains that text (case‐insensitive) get a **black outline**.  
- This helps quickly locate items like “Schenkwein” or “Kornkauf” in the treemap.

### Export CSV
- Click the **Export CSV** button to download the **currently filtered** data.  
- The exported file (`filtered_data.csv`) includes columns like: `year_from, year_to, account_name, subaccount_name, amount, subamount`.

### Net Balance
- Under “Net Balance” you see something like:  
  ```
  Net Balance: 18,827,063,807
  (Einnahmen: 24,486,329,250 / Ausgaben: 6,659,265,443)
  ```
- **Net** = (Sum of all Einnahmen) + (Sum of all Ausgaben) (noting that Ausgaben might be negative in the data).  
- This automatically updates after you filter by year, change aggregator limit, or toggle Einnahmen/Ausgaben.

### Treemap Zooming
- If you **click** on a tile that has children (e.g., an account or “Others” node), you zoom **in** to that group.  
- Clicking again on the same node or on the heading (the parent) **zooms out**.  
- This behavior stems from the **D3** transition logic in `createTreemap()`.

---

## How It Works Internally

### Hierarchy Building
1. **`transformDataToHierarchy()`** organizes each record into a nested structure:
   - Root: “Finanzen Basel”
   - One child: “Einnahmen” or “Ausgaben”
   - Then “Stadt” territory (hardcoded fallback)
   - Then “No Quarter Info” (placeholder if quarter is missing)
   - Then “account_name”
   - Then “subaccount_name”
2. **`.sum(d => d.size)`** sums up amounts in the D3 hierarchy for the treemap layout.

### Aggregator Logic
- For each account node, if the number of subaccounts is above `aggregatorLimit`, the smallest subaccounts are replaced by a node named **“Others.”**  
- “Others” can be a single leaf if you want a combined total, or a mini hierarchy so users can **drill in** and see leftover subaccounts.

### Zoom Transitions
- Clicking a node that has children triggers the **zoomIn** function, which transitions the view to show that node’s bounding box.  
- The **old group** is removed after the transition, ensuring no “yellow overlap.”

---

## Further Customization

- **Territory or Quarter Fields**: If your data includes a real `row.territory` or `row.quarter`, update `transformDataToHierarchy()` to nest them properly instead of the fallback strings “Stadt” / “No Quarter Info.”  
- **Color Scale**: Currently we color by `d.data.name` (i.e., the parent node’s name). You can refine or define a custom palette.  
- **Tooltips**: Expand them to show more fields from your JSON, or even link out to external references.  
- **Performance**: For extremely large data sets, consider *only* loading or aggregating relevant records in memory.

---

## Troubleshooting

**1. Overlapping Colors or Double Layers**  
- Make sure `d3.select("#treemap").selectAll("svg").remove();` is called before drawing a new treemap.  
- Verify the zoom transition code calls `.remove()` on the old group.

**2. No Data Visible**  
- Check your year range is valid. If `(year_from >= yearToSliderValue)`, you might have 0 records.  
- Confirm your data path includes `"/bs_Einnahmen"` or `"/bs_Ausgaben"`; otherwise they’re filtered out.

**3. CSV Exports an Empty File**  
- Possibly you used a year filter or aggregator limit that yields no rows.  
- Ensure the final `filteredData` array is non‐empty.

**4. “Others” Is Huge**  
- Means a large portion of subaccounts are smaller than the top N threshold. Lower the aggregator limit or turn off aggregator logic for debugging.