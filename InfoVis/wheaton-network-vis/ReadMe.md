# Wheaton Network Visualization

A digital humanities project that uses **D3.js** to explore financial and social relationships found in Laban Morey Wheaton’s Day Book (1828–1859). The interface provides **filterable network graphs**, **interactive BFS expansions**, **role-based** node classification, **date‐range** controls, **link label support** for quantities, and an overall refined UI for a more professional look. Research questions focus on **community structures**, **economic transactions**, and **credit arrangements** in 19th-century Massachusetts.

---

## Table of Contents
1. [Data Flow](#data-flow)  
2. [Installation & Setup](#installation--setup)  
3. [Usage](#usage)  
4. [Epic: Social Networks and Community Relationships](#epic-social-networks-and-community-relationships)  
5. [Filtering Logic](#filtering-logic)  
6. [Edge Labels & Thick Links](#edge-labels--thick-links)  
7. [BFS & Adjacency](#bfs--adjacency)  
8. [Side Panel & Details](#side-panel--details)  
9. [Future Enhancements](#future-enhancements)  
10. [Specification of Fixes & Implementations Not Yet Implemented](#specification-of-fixes--implementations-not-yet-implemented)  
11. [Author & Acknowledgments](#author--acknowledgments)  
12. [Additional Notes on Improvements](#additional-notes-on-improvements)

---

## Data Flow

1. **`wheaton-network.js`**  
   - Exposes `wheatonNetwork` with `people`, `relationships`, etc.

2. **`data.js`**  
   - Processes `wheatonNetwork.relationships` → creates `nodesData`, `linksData`.  
   - Attaches roles, flow details, calculates stats.  
   - Exports them globally for subsequent files.

3. **`filter-handler.js`**  
   - Tracks active filters in `filterState`.  
   - `updateVisualization()` toggles node/edge visibility, calls BFS expansions.  
   - Defines or calls methods like `showNodeDetails` / `showEdgeDetails` for the side panel.

4. **`vis-core.js`**  
   - Sets up D3 force simulation.  
   - Builds BFS adjacency.  
   - Adds node/edge + label elements (including link label support for quantities).  
   - Zoom & pan, arrow markers, collisions.  
   - Hides loading overlay at the end of initialization.

5. **`vis-update.js`**  
   - Extends behavior with BFS highlight on node click (multi-hop expansions), thick‐edge reversion on mouseout, tooltips, and side panel detail displays.

---

## Installation & Setup

1. **Clone** or **download** the repository.  
2. **Open** `index.html` in your browser (use a local server if needed).  
3. The page should display the left filter sidebar and a loading spinner over the main D3 canvas.  
4. After the data loads and the force simulation stabilizes, the spinner hides, revealing the full interactive network.

---

## Usage

1. **Filters**  
   - Toggle **node types** (location, institution, commodity).  
   - Toggle **edge types** (marriage, commodity, service).  
   - Use the **date slider** to show only relationships within a selected year range.  
   - **BFS expansions** by gender or commodity role: click a node to highlight multi‐hop neighbors.

2. **Side Panel**  
   - Click a node → node details appear (e.g., name, gender, roles).  
   - Click an edge → transaction info, e.g., “10 lbs. clover seed,” date, note, etc.

3. **Edge Labels**  
   - Always visible at the midpoint of each edge. For example, “10.0 pounds” in green text.  
   - **Thicker edges** for larger quantities (e.g., 100 lbs. vs. 5 lbs.).

4. **Zoom & Pan**  
   - Scroll or pinch to zoom in/out.  
   - Drag the background or nodes to reposition them.  
   - **Zoom In/Out/Reset** buttons at the top-right corner of the network container.

---

## Epic: Social Networks and Community Relationships

**Reference: 4.6.4.1 Epic 1**

This epic addresses historical **community structures** revealed through economic transactions, **credit arrangements**, and labour exchanges documented in Laban Morey Wheaton’s Day Book. By integrating TEI‐encoded data (gender, occupation, familial ties, and more), we can reconstruct a fuller socio-economic picture of Norton (and nearby communities) between 1828 and 1859.

#### User Stories

| As a ...             | I want to ...                                                                    | So that I can …                                                |
|----------------------|-----------------------------------------------------------------------------------|-----------------------------------------------------------------|
| *social historian*   | *view transaction networks between individuals and organisations in Norton*       | *identify the key economic relationships in the community*      |
| *social historian*   | *filter networks by personal relationships (gender, marriage, family ties)*       | *find how family connections shaped business patterns*          |
| *social historian*   | *filter networks by institutional relationships (affiliations, roles)*            | *discover how organisational ties influenced economic exchange* |
| *social historian*   | *see network changes between 1828-1859*                                           | *track how community business relationships developed over time*|
| *social historian*   | *compare business activities between different community groups*                  | *map economic cooperation and division in Norton*               |
| *social historian*   | *view how men and women participated differently in credit and trade networks*    | *reveal gender patterns in Norton's economic life*              |

**Why This Matters**  
- **Family Ties**: Potentially highlight how local genealogical connections influenced who sold or bought from whom.  
- **Institutional Roles**: Show how membership in churches, schools, or businesses shaped credit practices.  
- **Temporal Shifts**: Compare early (1828–1830) vs. later (1850s) networks as the community expanded or changed.

---

## Filtering Logic

- **`filterState`** tracks toggles for node types, edge types, categories, roles, date range, BFS expansions by gender, etc.  
- **`updateVisualization()`** merges these conditions (like node/edge types or date range) to hide/show elements in the network, re-running the force simulation with the resulting subgraph.  
- **BFS expansions** occur if you toggle male/female or explicitly expand from a node, highlighting multi-hop neighbors.

---

## Edge Labels & Thick Links

1. **Edge Labels**  
   - Each link has a `<text>` element at its midpoint, showing `flow_details.quantity + unit` (e.g. “10.0 pounds”) or `commodity_id` if applicable.  
   - Color-coded in green by default, but you can adjust in `style.css`.

2. **Thick Links**  
   - A `quantityScale(q)` sets stroke width from 1.5 (min) up to 10 (max) based on `flow_details.quantity`.  
   - On mouseover, the link is temporarily enlarged to `stroke-width: 3`; on mouseout, it **reverts** to its original thickness by referencing `vizCore.quantityScale`.

---

## BFS & Adjacency

1. **Adjacency** in `vis-core.js`  
   - `buildAdjacency()` populates a `vizCore.adjacency` map from each link’s source → target and vice versa.

2. **Single‐Node BFS**  
   - `getMultiHopNeighbors(startId, maxHops)` returns a set of visited node IDs by BFS from one node.

3. **Multi‐Source BFS**  
   - `multiSourceBFS([startId1, startId2, ...], maxHops)` merges BFS results from multiple starting nodes.

4. **Use Cases**  
   - Highlight the “connected subgraph” around female nodes or commodity providers (2 hops or more).

---

## Side Panel & Details

- **Node**  
  - The left side panel (or `#nodeDetails`) shows name, type, gender, roles, etc.  
  - TEI references or genealogical data can be added if you expand your dataset.

- **Edge**  
  - The right side panel (or `#edgeDetails`) shows transaction data: commodity type, quantity, date, note, etc.  
  - Hovering over an edge reveals a tooltip; clicking an edge displays its extended details.

Tooltips provide a **short** version on hover; the side panel is **more detailed** on click.

---

## Future Enhancements

1. **Family Relationship Data**  
   - Add parent-child or sibling edges, enabling genealogical BFS expansions.  
2. **Advanced Occupation & Role Filtering**  
   - If occupation data is present, parse it, and let users filter by “teacher,” “farmer,” “blacksmith,” etc.  
3. **Animated Timeline**  
   - Step year by year (1828–1859) to watch the network’s evolution over time.  
4. **Cash vs. Credit vs. Barter**  
   - Distinguish the method of payment for deeper local economic analysis.

---

## Specification of Fixes & Implementations Not Yet Implemented

1. **Consolidated Family Ties**  
   - We have marriage edges, but other familial relationships (parent-child, siblings) remain to be added from genealogical sources.

2. **Role Filters**  
   - Occupation roles might exist only in text form. No structured “occupation filter” is yet provided (must parse TEI for details).

3. **Payment Method**  
   - Currently “commodity,” “service,” etc. can be toggled, but a dedicated “paymentMethod” filter (cash, credit, labor) is not yet implemented.

4. **Edge Label Rotation**  
   - Midpoint text is plain horizontal. Using `<textPath>` for angled labeling remains unimplemented.

5. **Genealogical BFS**  
   - BFS expansions by extended family lines is intended, but not yet fully integrated.

These **unimplemented** items remain in the project backlog and reflect known user stories or future expansions.

---

## Author & Acknowledgments
- **Primary Author**: Christopher Pollin  
- **Contact**: [christopher.pollin@dhcraft.org](mailto:christopher.pollin@dhcraft.org)  
- **Special Thanks**:
  - **Kathryn Tomasek** for TEI XML modeling approaches.  
  - D3.js, noUiSlider, Lodash, and other library authors for enabling the core technology.

---

## Additional Notes on Improvements

- **Refined UI Layout**: The updated HTML (`index.html`) and CSS (`style.css`) ensure a more professional, consistent design. Filters remain in the left sidebar; the main D3 canvas is in a flexible right pane.  
- **Clean BFS Logic**: `vis-core.js` exports BFS adjacency building, letting `filter-handler.js` or `vis-update.js` easily run expansions without genealogical placeholders.  
- **Link Label & Thickness**: The project now integrates link label offset logic and thickness scaling. On hover, edges are temporarily enlarged, and on mouseout they revert correctly.  
- **No Advanced Genealogical/Occupational Data**: The codebase remains open to future expansions (such as genealogical BFS or advanced occupation filters), but by default focuses on **commodity**, **service**, and **marriage** edges, plus standard BFS expansions (e.g., by gender or roles).