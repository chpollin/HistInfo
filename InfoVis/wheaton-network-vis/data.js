// data.js
console.log("Starting data processing...");

let nodesData = [];
let linksData = [];

try {
    const nodeIDs = new Set();
    wheatonNetwork.relationships.forEach(rel => {
        if (rel.source) nodeIDs.add(rel.source);
        if (rel.target) nodeIDs.add(rel.target);
    });

    nodesData = Array.from(nodeIDs).map(id => {
        let type = 'unknown';
        let name = id;

        if (id.startsWith('pers_')) {
            type = 'person';
            // placeholder name
            name = id.replace('pers_', '').replace(/([A-Z])/g, ' $1').trim();
        }
        else if (id.includes('Residence') || id.endsWith('Massachusetts')) {
            type = 'location';
            name = id.replace('Residence','').replace(/([A-Z])/g, ' $1').trim();
        }
        else if (id.includes('Academy') || id.includes('School') || id.includes('College')) {
            type = 'institution';
            name = id.replace(/([A-Z])/g, ' $1').trim();
        }
        else if (id.includes('Commodity') || id.startsWith('com_')) {
            type = 'commodity';
            name = id.replace('Commodity','').replace('com_','').replace(/([A-Z])/g, ' $1').trim();
        }

        return {
            id,
            name,
            type,
            connections: 0
        };
    });

    // Merge in full name / gender if available
    nodesData.forEach(node => {
        if (node.type === 'person') {
            const p = wheatonNetwork.people[node.id];
            if (p) {
                if (p.full) node.name = p.full;
                if (p.gender) node.gender = p.gender; // "male" or "female"
            }
        }
    });

    linksData = wheatonNetwork.relationships
        .filter(rel => rel.source && rel.target)
        .map(rel => ({
            source: rel.source,
            target: rel.target,
            type: rel.transactionType,
            date: rel.dateStr,
            note: rel.note,
            category: rel.category
        }));

    // Count connections
    linksData.forEach(link => {
        const sNode = nodesData.find(n => n.id === link.source);
        const tNode = nodesData.find(n => n.id === link.target);
        if (sNode) sNode.connections++;
        if (tNode) tNode.connections++;
    });

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

    document.getElementById('totalNodes').textContent = stats.nodes.total;
    document.getElementById('totalEdges').textContent = stats.links.total;

} catch (error) {
    console.error("Error processing data:", error);
}

window.nodesData = nodesData;
window.linksData = linksData;
