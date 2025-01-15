/**
 * data.js
 *
 * Description:
 *   Processes the 'wheatonNetwork' object (from wheaton-network.js) to
 *   build two arrays: nodesData and linksData. It infers node types (person,
 *   location, institution, commodity), merges roles, flow_details, and gender,
 *   and computes basic statistics like total nodes/edges for display.
 *
 * Responsibilities:
 *   - Extract unique node IDs from relationships.
 *   - Create node objects, label them by type, and merge additional
 *     info like gender, role arrays, or flow_details.
 *   - Create link objects with type, date, note, category, etc.
 *   - Count node connections for later sizing in D3.
 *   - Update DOM elements (#totalNodes, #totalEdges) with stats.
 *
 * Dependencies:
 *   - Must load after 'wheaton-network.js' (which defines 'wheatonNetwork').
 *   - Exports `nodesData` and `linksData` to the global scope for usage
 *     by filter-handler.js, vis-core.js, and vis-update.js.
 *
 * Author:
 *   [Your Name]
 * Date:
 *   [Year or version]
 */

console.log("Starting data processing...");

let nodesData = [];
let linksData = [];

try {
  // 1) Collect unique node IDs from the relationships array
  const nodeIDs = new Set();
  wheatonNetwork.relationships.forEach(rel => {
    if (rel.source) nodeIDs.add(rel.source);
    if (rel.target) nodeIDs.add(rel.target);
  });

  // 2) Create node objects
  nodesData = Array.from(nodeIDs).map(id => {
    let type = 'unknown';
    let name = id;

    // Basic type inference from ID
    if (id.startsWith('pers_')) {
      type = 'person';
      // Use ID to build a placeholder name
      name = id
        .replace('pers_', '')
        .replace(/([A-Z])/g, ' $1')
        .trim();
    }
    else if (id.includes('Residence') || id.endsWith('Massachusetts')) {
      type = 'location';
      name = id
        .replace('Residence', '')
        .replace(/([A-Z])/g, ' $1')
        .trim();
    }
    else if (id.includes('Academy') || id.includes('School') || id.includes('College')) {
      type = 'institution';
      name = id.replace(/([A-Z])/g, ' $1').trim();
    }
    else if (id.includes('Commodity') || id.startsWith('com_')) {
      type = 'commodity';
      name = id
        .replace('Commodity', '')
        .replace('com_', '')
        .replace(/([A-Z])/g, ' $1')
        .trim();
    }

    return {
      id,
      name,
      type,
      connections: 0,  // We'll increment this later
      roles: []         // We'll store "economic_roles" or other roles here
    };
  });

  // 3) Merge in full name / gender if available in wheatonNetwork.people
  nodesData.forEach(node => {
    if (node.type === 'person') {
      const p = wheatonNetwork.people[node.id];
      if (p) {
        if (p.full) {
          node.name = p.full;         // override placeholder name
        }
        if (p.gender) {
          node.gender = p.gender;     // "male" or "female"
        }
      }
    }
  });

  // 4) Build link objects & parse flow_details, economic_roles
  linksData = wheatonNetwork.relationships
    .filter(rel => rel.source && rel.target)
    .map(rel => {
      const linkObj = {
        source: rel.source,
        target: rel.target,
        type: rel.transactionType,
        date: rel.dateStr,
        note: rel.note,
        category: rel.category
      };

      // If we have flow_details (e.g., quantity, unit), copy them
      if (rel.flow_details) {
        linkObj.flow_details = { ...rel.flow_details };
      }
      // If we have economic_roles (mapping node IDs to roles), store them
      if (rel.economic_roles) {
        linkObj.economic_roles = { ...rel.economic_roles };
      }

      return linkObj;
    });

  // 5) Count connections
  //    Each link increments "connections" on its source & target nodes
  linksData.forEach(link => {
    const sNode = nodesData.find(n => n.id === link.source);
    const tNode = nodesData.find(n => n.id === link.target);
    if (sNode) sNode.connections++;
    if (tNode) tNode.connections++;
  });

  // 6) Associate roles with the nodes
  //    If a link has .economic_roles, we add these roles to the relevant nodes
  linksData.forEach(link => {
    if (!link.economic_roles) return;
    Object.entries(link.economic_roles).forEach(([nodeId, roleArray]) => {
      const nodeObj = nodesData.find(n => n.id === nodeId);
      if (nodeObj && Array.isArray(roleArray)) {
        roleArray.forEach(r => {
          if (!nodeObj.roles.includes(r)) {
            nodeObj.roles.push(r);
          }
        });
      }
    });
  });

  // 7) Summaries for debugging and stats
  const stats = {
    nodes: {
      total: nodesData.length,
      byType: nodesData.reduce((acc, n) => {
        acc[n.type] = (acc[n.type] || 0) + 1;
        return acc;
      }, {})
    },
    links: {
      total: linksData.length,
      byType: linksData.reduce((acc, l) => {
        acc[l.type] = (acc[l.type] || 0) + 1;
        return acc;
      }, {})
    }
  };

  console.log("Data processing complete:", stats);

  // 8) Update totals in HTML
  const totalNodesElem = document.getElementById('totalNodes');
  const totalEdgesElem = document.getElementById('totalEdges');
  if (totalNodesElem) totalNodesElem.textContent = stats.nodes.total;
  if (totalEdgesElem) totalEdgesElem.textContent = stats.links.total;

} catch (error) {
  console.error("Error processing data:", error);
}

// 9) Expose nodesData & linksData globally
window.nodesData = nodesData;
window.linksData = linksData;
