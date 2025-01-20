import rdflib
import json
from rdflib import Namespace, RDF, URIRef, Literal

# ----------------------------------------------------------------------
# 1. CONFIG
# ----------------------------------------------------------------------
TTL_FILE = "srbas-rdf.ttl"         # Make sure this file is present and truly in UTF-8 (or change 'encoding')
OUTPUT_JSON = "accounts_hierarchy.json"

# If your data isn't truly UTF-8, adjust or remove the 'encoding' param:
GRAPH_ENCODING = "utf-8"

BK = Namespace("http://gams.uni-graz.at/rem/bookkeeping/")
SKOS = Namespace("http://www.w3.org/2004/02/skos/core#")

# We'll unify all accounts under a single "FAKE_ROOT" so we can have a single top-level node
FAKE_ROOT_URI = "srbas:ROOT"
FAKE_ROOT_LABEL = "ALL ACCOUNTS"

MISSING_PARENT_PREFIX = "srbas:missingParent/"

# ----------------------------------------------------------------------
# 2. LOAD THE RDF GRAPH (with explicit encoding, if needed)
# ----------------------------------------------------------------------
print(f"Loading {TTL_FILE} ...")
g = rdflib.Graph()
g.parse(TTL_FILE, format="turtle", encoding=GRAPH_ENCODING)
print(f"Loaded {len(g)} RDF triples.")

# ----------------------------------------------------------------------
# 3. GATHER ALL BK.ACCOUNT NODES
# ----------------------------------------------------------------------
# We'll create a dictionary accounts_by_uri, where each key is an account URI,
# and each value is a dict of:
#   {
#     "uri": ...,
#     "properties": { "rdfPropUri": [list_of_values], ... },
#     "parent_uri": ...,
#     "label": ...,
#     ...
#   }

accounts_by_uri = {}

def ensure_account_entry(uri_str):
    """Ensure we have a dict entry for this account URI."""
    if uri_str not in accounts_by_uri:
        accounts_by_uri[uri_str] = {
            "uri": uri_str,
            "properties": {},
            "parent_uri": None,   # We'll set this if we find bk:subAccountOf
            "label": None,        # We'll store a readable label
        }
    return accounts_by_uri[uri_str]

# Collect all accounts typed as BK.account
for acc_uri in g.subjects(RDF.type, BK.account):
    acc_uri_str = str(acc_uri)
    account_entry = ensure_account_entry(acc_uri_str)

    # For each predicate-object for this account, store them in "properties"
    for pred, obj in g.predicate_objects(acc_uri):
        pred_str = str(pred)
        val_str = None

        if isinstance(obj, Literal):
            # For possible text encoding issues, `obj.value` might be enough
            # but if you're certain there's double-encoding or something,
            # you could do a manual fix here. We'll assume it's correct now.
            val_str = str(obj.value)
        elif isinstance(obj, URIRef):
            val_str = str(obj)
        else:
            val_str = str(obj)

        if pred_str not in account_entry["properties"]:
            account_entry["properties"][pred_str] = []
        account_entry["properties"][pred_str].append(val_str)

    # If there's a skos:prefLabel, we store one as the "label" (pick first)
    labels = account_entry["properties"].get(str(SKOS.prefLabel), [])
    if labels:
        account_entry["label"] = labels[0]
    else:
        # fallback: use the URI as label
        account_entry["label"] = acc_uri_str

    # If there's a BK.subAccountOf, store the first as parent
    subof_list = account_entry["properties"].get(str(BK.subAccountOf), [])
    if subof_list:
        account_entry["parent_uri"] = subof_list[0]

# ----------------------------------------------------------------------
# 4. HANDLE MISSING PARENT REFERENCES
# ----------------------------------------------------------------------
missing_parent_nodes = {}

def create_missing_parent_node(missing_uri):
    """
    Create or retrieve a placeholder node for a parent that doesn't exist in the dataset.
    """
    if missing_uri in missing_parent_nodes:
        return missing_parent_nodes[missing_uri]
    
    placeholder_uri = (MISSING_PARENT_PREFIX +
                       missing_uri.replace(":", "_").replace("/", "_"))
    placeholder_label = f"(Missing Parent) {missing_uri}"

    ensure_account_entry(placeholder_uri)
    placeholder_entry = accounts_by_uri[placeholder_uri]
    placeholder_entry["label"] = placeholder_label
    placeholder_entry["parent_uri"] = None   # Might remain top-level if no further parent known
    placeholder_entry["properties"]["missingParentOf"] = [missing_uri]

    missing_parent_nodes[missing_uri] = placeholder_uri
    return placeholder_uri

# For each known account, if its parent is missing, create a placeholder
for uri, acc in list(accounts_by_uri.items()):
    p = acc["parent_uri"]
    if p and p not in accounts_by_uri:
        # create placeholder
        placeholder = create_missing_parent_node(p)
        acc["parent_uri"] = placeholder

# ----------------------------------------------------------------------
# 5. ADD A "FAKE ROOT" FOR A SINGLE TOP-LEVEL
# ----------------------------------------------------------------------
ensure_account_entry(FAKE_ROOT_URI)
accounts_by_uri[FAKE_ROOT_URI]["label"] = FAKE_ROOT_LABEL
accounts_by_uri[FAKE_ROOT_URI]["parent_uri"] = None

# If an account has no parent, point it to the FAKE_ROOT (except itself)
for uri, acc in accounts_by_uri.items():
    if acc["parent_uri"] is None and uri != FAKE_ROOT_URI:
        acc["parent_uri"] = FAKE_ROOT_URI

# ----------------------------------------------------------------------
# 6. BUILD A NESTED HIERARCHY
# ----------------------------------------------------------------------
# We want a structure like:
# {
#   "name": "ALL ACCOUNTS",
#   "properties": {...}   # optional
#   "children": [
#       {
#         "name": "...",
#         "properties": {...}
#         "children": [...]
#       },
#       ...
#   ]
# }
#
# We'll also do an optional aggregator for e.g. "bk:amount" if we find any.

AMOUNT_PRED_URI = str(BK.amount)  # example property to sum up

def build_hierarchy(root_uri):
    """
    Recursively build a nested dict from accounts_by_uri.
    """
    node = accounts_by_uri[root_uri]

    # Gather children
    children_uris = [
        u for u, a in accounts_by_uri.items()
        if a["parent_uri"] == root_uri and u != root_uri
    ]
    child_nodes = [build_hierarchy(cu) for cu in children_uris]

    # We'll create a dictionary for the current node
    # "name": used by many D3 examples
    out = {
        "name": node["label"],
        # keep all properties if you want them in the final JSON
        "properties": node["properties"],
        "children": child_nodes,
    }

    # If you want to do an aggregator for "amount", we can sum the child's amounts + node's own amounts
    # Let's define node_amount as the sum of its BK.amount properties
    node_amount = 0.0
    amounts = node["properties"].get(AMOUNT_PRED_URI, [])
    for amt_str in amounts:
        try:
            node_amount += float(amt_str)
        except ValueError:
            pass  # if some are not numeric

    # Sum child amounts
    child_amount_sum = sum(child.get("aggregated_amount", 0.0) for child in child_nodes)
    total_amount = node_amount + child_amount_sum

    out["node_amount"] = node_amount
    out["aggregated_amount"] = total_amount

    return out

print("Building nested JSON hierarchy from FAKE_ROOT ...")
full_hierarchy = build_hierarchy(FAKE_ROOT_URI)

# ----------------------------------------------------------------------
# 7. SAVE TO JSON
# ----------------------------------------------------------------------
with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
    json.dump(full_hierarchy, f, ensure_ascii=False, indent=2)

print(f"Saved hierarchy with {len(accounts_by_uri)} accounts to {OUTPUT_JSON}")
