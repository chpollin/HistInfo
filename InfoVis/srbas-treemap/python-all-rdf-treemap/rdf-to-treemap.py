"""
Dash App: Interactive Treemap for Basel Account Books Hierarchies
Using 'srbas-rdf.ttl' with over 1 million triples.

User Stories:
1) Exploratory Hierarchy - see the full hierarchical structure of accounts.
2) Category Filtering (Income/Expense/Unknown).
3) Scalability for large data.
4) Interactivity with Plotly Dash.

Steps:
1) Load srbas-rdf.ttl into an rdflib.Graph.
2) Identify all bk:account items; store them in a list/dict with label, parent, etc.
3) Handle missing parents by creating a placeholder node.
4) Build a unified "fake root" node so Plotly can display a single treemap.
5) Use Dash to create an interactive web UI with checkboxes for category filtering.
6) Display the treemap with Plotly; handle BFS to keep necessary parents included.
"""

import logging
import rdflib
from rdflib import Namespace, RDF
import dash
from dash import dcc, html, Input, Output
import plotly.express as px

# ---------------------------
# CONFIG AND LOGGING
# ---------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# Namespaces (adjust if needed)
BK = Namespace("http://gams.uni-graz.at/rem/bookkeeping/")
SKOS = Namespace("http://www.w3.org/2004/02/skos/core#")
SRBAS = Namespace("http://gams.uni-graz.at/srbas/")

# For large graphs, you may want to increase parser memory or use streaming, but
# for demonstration, we'll simply load the entire .ttl below.

TTL_FILE = "srbas-rdf.ttl"  # must exist in same folder


# ---------------------------
# 1. LOAD THE RDF GRAPH
# ---------------------------
logging.info(f"Loading {TTL_FILE}...")
g = rdflib.Graph()
g.parse(TTL_FILE, format="turtle")
logging.info(f"Graph has {len(g)} RDF triples.")


# ---------------------------
# 2. EXTRACT ACCOUNTS + HIERARCHY
# ---------------------------
logging.info("Extracting accounts and building hierarchy...")

# We'll collect each account as a dict:
#   {
#       "uri": "...",
#       "label": "Some Label",
#       "parent_uri": "...",
#       "category": "income"/"expense"/"unknown"
#   }
accounts_data = []

for acc_uri in g.subjects(RDF.type, BK.account):
    # label
    label = None
    for lbl in g.objects(acc_uri, SKOS.prefLabel):
        label = str(lbl)
        break
    
    # parent
    parent_uri = None
    for par in g.objects(acc_uri, BK.subAccountOf):
        parent_uri = str(par)
        break
    
    # (Optional) category. If the data doesn't have direct category properties,
    # we guess from label or path. Adjust logic as needed.
    category = "unknown"
    if label is not None:
        lower_label = label.lower()
        if "einnahm" in lower_label or "income" in lower_label:
            category = "income"
        elif "ausgab" in lower_label or "expense" in lower_label:
            category = "expense"
        # else remain "unknown"
    
    accounts_data.append({
        "uri": str(acc_uri),
        "label": label if label else str(acc_uri),
        "parent_uri": parent_uri,
        "category": category
    })

# Build dict for quick lookups
accounts_by_uri = {a["uri"]: a for a in accounts_data}

# For references to parent URIs that do not exist in the dataset,
# we'll create a placeholder node "Missing Parent"
MISSING_PARENT_PREFIX = "srbas:missingParent/"
missing_parent_nodes = {}  # key: the missing parent URI, value: placeholder node URI

def create_missing_parent_node(missing_uri):
    """
    Create or retrieve a placeholder node for a parent that does not exist in accounts_by_uri.
    """
    if missing_uri in missing_parent_nodes:
        return missing_parent_nodes[missing_uri]
    placeholder_uri = MISSING_PARENT_PREFIX + missing_uri.replace(":", "_").replace("/", "_")
    placeholder_label = f"(Missing Parent) {missing_uri}"
    # Insert into accounts_data
    placeholder_account = {
        "uri": placeholder_uri,
        "label": placeholder_label,
        "parent_uri": None,  # might chain if that parent is also missing
        "category": "unknown"
    }
    accounts_data.append(placeholder_account)
    accounts_by_uri[placeholder_uri] = placeholder_account
    missing_parent_nodes[missing_uri] = placeholder_uri
    return placeholder_uri

# If parent's not in accounts_by_uri and is not None, create a placeholder
for a in accounts_data:
    p = a["parent_uri"]
    if p is not None and p not in accounts_by_uri:
        placeholder = create_missing_parent_node(p)
        a["parent_uri"] = placeholder


# ---------------------------
# 3. PREPARE TREEMAP DATA
# ---------------------------
logging.info("Preparing treemap data for Plotly...")

FAKE_ROOT_URI = "srbas:ROOT"
FAKE_ROOT_LABEL = "ALL ACCOUNTS"

treemap_data = []  # each item is {"id", "label", "parent", "category"}
id_set = set()     # keep track of IDs we've added

# Add the single fake root node
treemap_data.append({
    "id": FAKE_ROOT_URI,
    "label": FAKE_ROOT_LABEL,
    "parent": "",   # no parent
    "category": "root"
})
id_set.add(FAKE_ROOT_URI)

# Populate child nodes
for a in accounts_data:
    node_id = a["uri"]
    node_label = a["label"]
    node_parent = a["parent_uri"] if a["parent_uri"] else FAKE_ROOT_URI
    node_cat = a["category"]

    treemap_data.append({
        "id": node_id,
        "label": node_label,
        "parent": node_parent,
        "category": node_cat
    })
    id_set.add(node_id)


# ---------------------------
# 4. BUILD DASH APP
# ---------------------------
app = dash.Dash(__name__)
app.title = "Basel Accounts Treemap"

app.layout = html.Div([
    html.H1("Basel Account Books: Treemap of Account Hierarchies"),
    html.Div("Use the checkboxes to filter which categories of accounts are shown."),
    dcc.Checklist(
        id="category-filter",
        options=[
            {"label": "Income", "value": "income"},
            {"label": "Expense", "value": "expense"},
            {"label": "Unknown", "value": "unknown"}
        ],
        value=["income", "expense", "unknown"],  # default: show all
        inline=True
    ),
    dcc.Graph(id="treemap-graph", style={"width": "100%", "height": "80vh"})
], style={"margin": "0 auto", "maxWidth": "1200px"})


# ---------------------------
# 5. CALLBACK FOR TREEMAP
# ---------------------------
@app.callback(
    Output("treemap-graph", "figure"),
    [Input("category-filter", "value")]
)
def update_treemap(selected_categories):
    """
    Filter the nodes by the chosen categories, but keep:
    - The FAKE ROOT
    - Any placeholder nodes or parents needed to preserve hierarchy
    """
    if not selected_categories:
        # if no categories selected, show an empty figure or just the root
        fig = px.treemap()
        fig.update_layout(margin=dict(t=30, l=0, r=0, b=0))
        return fig
    
    # 1) Filter out nodes not matching any selected category
    #    but keep "root" or "missing parent" nodes that might be needed in the chain.
    # We'll do an initial pass for all nodes with category in selected_categories or category == "root".
    initial_nodes = []
    for node in treemap_data:
        c = node["category"]
        if c == "root" or c.startswith("missingParent"):  # treat placeholders as unknown but keep them
            initial_nodes.append(node)
        elif c in selected_categories:
            initial_nodes.append(node)
    
    # 2) BFS: ensure if a node is included, its parent is included. 
    #    If not included, we add the parent. We'll do iterative expansions until stable.
    included_ids = {n["id"] for n in initial_nodes}
    changed = True
    while changed:
        changed = False
        # for every node in initial_nodes, if it has a parent not in included_ids,
        # we find that parent in treemap_data and add it.
        newly_included = []
        for n in initial_nodes:
            p_id = n["parent"]
            # if there's a parent and not in included_ids, try to add it
            if p_id and p_id not in included_ids:
                # find the parent node in treemap_data
                parent_node = next((x for x in treemap_data if x["id"] == p_id), None)
                if parent_node:
                    newly_included.append(parent_node)
                    included_ids.add(p_id)
        if newly_included:
            initial_nodes.extend(newly_included)
            changed = True

    # Now "initial_nodes" contains all nodes consistent with the filtering
    # plus any parents needed for the hierarchy.
    # But we might also need to ensure children of forced placeholders are included if they are valid.
    # Actually, in a typical top-down hierarchy, ensuring children remain is not mandatory 
    # for the treemap to render. 
    
    # We'll build the figure
    fig_data = initial_nodes
    
    fig = px.treemap(
        fig_data,
        names="label",
        parents="parent",
        ids="id",
        # use a trivial 1 for "value" or you can sum amounts if available
        values=[1]*len(fig_data),
        color="category",
        color_discrete_map={
            "root": "lightgrey",
            "income": "#2ca02c",
            "expense": "#d62728",
            "unknown": "#9467bd"
        }
    )
    fig.update_traces(root_color="lightgrey")
    fig.update_layout(
        margin=dict(t=30, l=0, r=0, b=0),
        hovermode=False
    )
    return fig


# ---------------------------
# 6. RUN THE APP
# ---------------------------
if __name__ == "__main__":
    logging.info("Starting Dash app. Open http://127.0.0.1:8050 in your browser.")
    app.run_server(debug=True)
