import rdflib
import json
from rdflib import Graph, Namespace, URIRef, RDF, Literal
from collections import defaultdict

# ----------------------------------------------------------------------
# 1. CONFIG
# ----------------------------------------------------------------------
TTL_FILE = "srbas-rdf.ttl"  # Change if needed
OUTPUT_JSON = "accounts_hierarchy.json"
GRAPH_ENCODING = "utf-8"    # Remove or change if not truly UTF-8

# URIs for classes / properties
ACCOUNT_CLASS_URI    = "http://gams.uni-graz.at/rem/bookkeeping/#account"
ENTRY_CLASS_URI      = "http://gams.uni-graz.at/rem/bookkeeping/#entry"
SUBACCOUNT_PRED_URI  = "http://gams.uni-graz.at/rem/bookkeeping/subAccountOf"
ACCOUNT_PRED_URI     = "http://gams.uni-graz.at/rem/bookkeeping/account"
MAINACCOUNT_PRED_URI = "http://gams.uni-graz.at/rem/bookkeeping/mainAccount"
AMOUNT_PRED_URI      = "http://gams.uni-graz.at/rem/bookkeeping/amount"
NUM_PRED_URI         = "http://gams.uni-graz.at/rem/bookkeeping/num"
ACCOUNTPATH_PRED_URI = "http://gams.uni-graz.at/rem/bookkeeping/accountPath"

SKOS = Namespace("http://www.w3.org/2004/02/skos/core#")

FAKE_ROOT_URI = "srbas:ROOT"
FAKE_ROOT_LABEL = "ALL ACCOUNTS"
MISSING_PARENT_PREFIX = "srbas:missingParent/"

# ----------------------------------------------------------------------
# 2. PARSE THE RDF
# ----------------------------------------------------------------------
print(f"[INFO] Loading {TTL_FILE} ...")
g = Graph()
g.parse(TTL_FILE, format="turtle", encoding=GRAPH_ENCODING)
print(f"[INFO] Loaded {len(g)} RDF triples from {TTL_FILE}.")

# Convert strings to URIRef for easy matching
ACCOUNT_CLASS   = URIRef(ACCOUNT_CLASS_URI)
ENTRY_CLASS     = URIRef(ENTRY_CLASS_URI)
SUBACCOUNT_PRED = URIRef(SUBACCOUNT_PRED_URI)
ACCOUNT_PRED    = URIRef(ACCOUNT_PRED_URI)
MAINACCOUNT_PRED= URIRef(MAINACCOUNT_PRED_URI)
AMOUNT_PRED     = URIRef(AMOUNT_PRED_URI)
NUM_PRED        = URIRef(NUM_PRED_URI)
ACCOUNTPATH_PRED= URIRef(ACCOUNTPATH_PRED_URI)

# ----------------------------------------------------------------------
# 3. STORE ACCOUNTS
# ----------------------------------------------------------------------
accounts_by_uri = {}

def ensure_account_entry(uri_str):
    if uri_str not in accounts_by_uri:
        accounts_by_uri[uri_str] = {
            "uri": uri_str,
            "parent_uri": None,
            "label": None,
            "properties": {},
            "node_amount": 0.0,  # We'll accumulate amounts here
        }
        # Log each time we create a new account entry
        print(f"[DEBUG] Created account entry: {uri_str}")
    return accounts_by_uri[uri_str]

# Gather all bk:account nodes
print("[INFO] Collecting bk:account nodes ...")
acc_count = 0
for acc_uri in g.subjects(RDF.type, ACCOUNT_CLASS):
    acc_count += 1
    acc_uri_str = str(acc_uri)
    entry = ensure_account_entry(acc_uri_str)

    # Collect all properties
    for pred, obj in g.predicate_objects(acc_uri):
        pred_str = str(pred)
        if isinstance(obj, Literal):
            val_str = str(obj.value) if obj.value is not None else str(obj)
        else:
            val_str = str(obj)
        entry["properties"].setdefault(pred_str, []).append(val_str)

    # If there's a skos:prefLabel, store as label
    labels = entry["properties"].get(str(SKOS.prefLabel), [])
    if labels:
        entry["label"] = labels[0]
    else:
        entry["label"] = acc_uri_str  # fallback label

    # If there's a subAccountOf, store the first as parent
    subs = entry["properties"].get(str(SUBACCOUNT_PRED), [])
    if subs:
        entry["parent_uri"] = subs[0]

print(f"[INFO] Found {acc_count} accounts of type {ACCOUNT_CLASS_URI}.")

# ----------------------------------------------------------------------
# 4. CREATE PLACEHOLDERS FOR MISSING PARENTS
# ----------------------------------------------------------------------
missing_parent_nodes = {}

def create_missing_parent_node(missing_uri):
    if missing_uri in missing_parent_nodes:
        return missing_parent_nodes[missing_uri]
    placeholder_uri = (
        MISSING_PARENT_PREFIX + 
        missing_uri.replace(":", "_").replace("/", "_")
    )
    placeholder_label = f"(Missing Parent) {missing_uri}"
    placeholder_acc = ensure_account_entry(placeholder_uri)
    placeholder_acc["label"] = placeholder_label
    placeholder_acc["parent_uri"] = None
    placeholder_acc["properties"].setdefault("missingParentOf", []).append(missing_uri)
    missing_parent_nodes[missing_uri] = placeholder_uri
    print(f"[WARNING] Creating missing parent node for {missing_uri} -> {placeholder_uri}")
    return placeholder_uri

# For each account, if its parent is unknown, create a placeholder
print("[INFO] Checking for missing parents ...")
missing_count = 0
for uri, acc_dict in list(accounts_by_uri.items()):
    p = acc_dict["parent_uri"]
    if p and p not in accounts_by_uri:
        missing_count += 1
        placeholder = create_missing_parent_node(p)
        acc_dict["parent_uri"] = placeholder
print(f"[INFO] Created {missing_count} placeholders for missing parents.")

# ----------------------------------------------------------------------
# 5. SINGLE "FAKE ROOT"
# ----------------------------------------------------------------------
fake_root = ensure_account_entry(FAKE_ROOT_URI)
fake_root["label"] = FAKE_ROOT_LABEL
fake_root["parent_uri"] = None

top_level_count = 0
for uri, acc_dict in accounts_by_uri.items():
    if acc_dict["parent_uri"] is None and uri != FAKE_ROOT_URI:
        acc_dict["parent_uri"] = FAKE_ROOT_URI
        top_level_count += 1
print(f"[INFO] Attached {top_level_count} root-level accounts under {FAKE_ROOT_URI}.")

# ----------------------------------------------------------------------
# 6. HELPER: DETECT IF ACCOUNT IS AN EXPENSE
# ----------------------------------------------------------------------
def is_expense_account(uri_str):
    """
    Return True if the account path property (bk:accountPath)
    starts with '/bs_Ausgaben'.
    """
    acc = accounts_by_uri.get(uri_str)
    if not acc:
        return False
    path_vals = acc["properties"].get(ACCOUNTPATH_PRED_URI, [])
    for p in path_vals:
        if p.startswith("/bs_Ausgaben"):
            return True
    return False

# ----------------------------------------------------------------------
# 7. ACCUMULATE AMOUNTS
# ----------------------------------------------------------------------
print("[INFO] Gathering bk:entry nodes and their amounts ...")
amounts_by_account = defaultdict(float)

entry_count = 0
numeric_amt_count = 0

for entry_uri in g.subjects(RDF.type, ENTRY_CLASS):
    entry_count += 1
    # Each entry might have 1+ amounts
    for amt_node in g.objects(entry_uri, AMOUNT_PRED):
        # Then find numeric "num"
        for num_val in g.objects(amt_node, NUM_PRED):
            try:
                val = float(num_val)
                numeric_amt_count += 1
            except ValueError:
                val = 0.0
                print(f"[WARNING] Non-numeric amount {num_val} in entry {entry_uri}")

            # This entry references 1+ accounts
            # We check both 'account' and possibly 'mainAccount'
            # to gather the correct recipients.
            accts_found = False

            # account references
            for acct_uri in g.objects(entry_uri, ACCOUNT_PRED):
                accts_found = True
                acct_str = str(acct_uri)
                if is_expense_account(acct_str):
                    amounts_by_account[acct_str] += (-val)
                else:
                    amounts_by_account[acct_str] += val

            # mainAccount references
            for main_uri in g.objects(entry_uri, MAINACCOUNT_PRED):
                accts_found = True
                main_str = str(main_uri)
                if is_expense_account(main_str):
                    amounts_by_account[main_str] += (-val)
                else:
                    amounts_by_account[main_str] += val

            if not accts_found:
                print(f"[WARNING] Entry {entry_uri} has an amount but no account or mainAccount link?")

print(f"[INFO] Found {entry_count} entry nodes, with {numeric_amt_count} numeric amounts total.")

# Add totals into each account's 'node_amount'
print("[INFO] Updating account node_amount values ...")
for acct_uri_str, total in amounts_by_account.items():
    ensure_account_entry(acct_uri_str)
    accounts_by_uri[acct_uri_str]["node_amount"] += total
    # Optional debug logging:
    # print(f"  -> {acct_uri_str} updated by {total:.2f}, total now {accounts_by_uri[acct_uri_str]['node_amount']:.2f}")

# ----------------------------------------------------------------------
# 8. RECURSIVE BUILD
# ----------------------------------------------------------------------
def build_hierarchy(uri_str):
    node_data = accounts_by_uri[uri_str]
    # Gather children
    children_uris = [
        u for u, obj in accounts_by_uri.items()
        if obj["parent_uri"] == uri_str and u != uri_str
    ]
    # Recursively build child nodes
    child_nodes = [build_hierarchy(cu) for cu in children_uris]

    out = {
        "name": node_data["label"],
        "properties": node_data["properties"],
        "children": child_nodes,
    }
    this_amt = node_data["node_amount"]
    child_sum = sum(ch["aggregated_amount"] for ch in child_nodes)
    out["node_amount"] = this_amt
    out["aggregated_amount"] = this_amt + child_sum
    return out

print("[INFO] Building nested JSON hierarchy ...")
full_hierarchy = build_hierarchy(FAKE_ROOT_URI)

# ----------------------------------------------------------------------
# 9. WRITE JSON
# ----------------------------------------------------------------------
print(f"[INFO] Writing final JSON to {OUTPUT_JSON} ...")
with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
    json.dump(full_hierarchy, f, ensure_ascii=False, indent=2)

print(f"[INFO] Done! Wrote {OUTPUT_JSON} with top-level = '{FAKE_ROOT_LABEL}'.")
