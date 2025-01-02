////////////////////////////////////////////////////////////////////////////////
// node-details.js
// Node & Edge detail formatting and display
////////////////////////////////////////////////////////////////////////////////

// Helper Functions for Formatting
function formatProperty(label, value) {
    if (value === undefined || value === null || value === "") return "";
    return `<p><strong>${label}:</strong> ${value}</p>`;
}

function formatNames(namesArray) {
    if (!namesArray) return "";
    return namesArray
        .map(n => `${n.name}${n.type ? ` (${n.type})` : ""}`)
        .join(", ");
}

function formatLocation(loc) {
    if (!loc) return "";
    const parts = [];
    if (loc.settlement) parts.push(loc.settlement);
    if (loc.region) parts.push(loc.region);
    if (loc.full) return loc.full;
    return parts.join(", ");
}

function formatEvent(event) {
    if (!event || Object.keys(event).length === 0) return "";
    const parts = [];
    if (event.date) parts.push(`Date: ${event.date}`);
    if (event.location) parts.push(`Location: ${formatLocation(event.location)}`);
    return parts.join(", ");
}

// Type-specific Detail Builders
function buildPersonDetails(d) {
    return `
        ${formatProperty("Full Name", d.full)}
        <div class="mt-3">
            <h6>Names:</h6>
            ${formatProperty("Forenames", formatNames(d.forenames))}
            ${formatProperty("Surnames", formatNames(d.surnames))}
        </div>
        <div class="mt-3">
            <h6>Life Events:</h6>
            ${formatProperty("Birth", formatEvent(d.birth))}
            ${formatProperty("Death", formatEvent(d.death))}
        </div>
        ${formatProperty("Faith", d.faith)}
        ${formatProperty("Education", d.education?.join(", "))}
    `;
}

function buildLocationDetails(d) {
    return `
        ${formatProperty("Region", d.region)}
        ${formatProperty("Country", d.country)}
        ${formatProperty("Settlement Type", d.settlementType)}
        ${formatProperty("Population", d.population)}
    `;
}

function buildInstitutionDetails(d) {
    return `
        ${formatProperty("Institution Type", d.institutionType)}
        ${formatProperty("Founded", d.founded)}
        ${formatProperty("Location", d.location)}
        ${formatProperty("Affiliation", d.affiliation)}
    `;
}

function buildCommodityDetails(d) {
    return `
        ${formatProperty("Category", d.category)}
        ${formatProperty("Unit", d.unit)}
        ${formatProperty("Value", d.value)}
        ${formatProperty("Currency", d.currency)}
    `;
}

// Detail Display Functions
function displayNodeDetails(d) {
    let typeSpecificDetails = "";
    switch(d.type) {
        case "person": typeSpecificDetails = buildPersonDetails(d); break;
        case "location": typeSpecificDetails = buildLocationDetails(d); break;
        case "institution": typeSpecificDetails = buildInstitutionDetails(d); break;
        case "commodity": typeSpecificDetails = buildCommodityDetails(d); break;
    }

    const standardProps = new Set([
        'id', 'full', 'forenames', 'surnames', 'faith', 'type',
        'x', 'y', 'fx', 'fy', 'index', 'vx', 'vy', 'birth',
        'death', 'location'
    ]);
    
    const otherProps = Object.entries(d)
        .filter(([key]) => !standardProps.has(key))
        .map(([key, value]) => formatProperty(key, value))
        .join('');

    d3.select("#nodeDetails").html(`
        <h5>Node Details</h5>
        <div class="node-details-content">
            ${formatProperty("ID", d.id)}
            ${formatProperty("Name", d.name)}
            ${formatProperty("Type", d.type || "unknown")}
            ${typeSpecificDetails}
            ${otherProps ? '<h6 class="mt-3">Additional Properties</h6>' + otherProps : ''}
        </div>
    `);
}

function displayEdgeDetails(d) {
    d3.select("#edgeDetails").html(`
        <h5>Edge Details</h5>
        ${formatProperty("Transaction Type", d.transactionType)}
        ${formatProperty("Date", d.dateStr)}
        ${formatProperty("Note", d.note)}
        ${formatProperty("Source", d.source.id || d.source)}
        ${formatProperty("Target", d.target.id || d.target)}
    `);
}

window.nodeDetails = {
    displayNodeDetails,
    displayEdgeDetails
};