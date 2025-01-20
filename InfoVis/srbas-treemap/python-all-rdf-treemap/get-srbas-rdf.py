import logging
import requests
import xml.etree.ElementTree as ET
from rdflib import Graph, Namespace, RDF

# Configure logging for detailed output
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# Define relevant namespaces (adjust if needed)
SRBAS = Namespace("http://gams.uni-graz.at/srbas/")
BK    = Namespace("http://gams.uni-graz.at/rem/bookkeeping/")
DC    = Namespace("http://purl.org/dc/elements/1.1/")
SKOS  = Namespace("http://www.w3.org/2004/02/skos/core#")
TEI   = Namespace("http://www.tei-c.org/ns/1.0")
OA    = Namespace("http://www.w3.org/ns/oa#")

def fetch_sparql_xml(url):
    """
    Download the SPARQL results XML from the specified URL.
    Returns the raw XML text if successful, otherwise None.
    """
    try:
        logging.info(f"Fetching SPARQL XML from: {url}")
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to fetch SPARQL XML from {url}: {e}")
        return None

def parse_sparql_xml(xml_text):
    """
    Parse the downloaded SPARQL results XML (as text) to get a list of <identifier> elements.
    Returns a list of identifiers (e.g., ["o:srbas.1535", "o:srbas.1536", ...]).
    """
    identifiers = []
    try:
        root = ET.fromstring(xml_text)
        # The document uses the default namespace "http://www.w3.org/2001/sw/DataAccess/rf1/result"
        # We can define that namespace prefix for proper XPath.
        ns = {"ns": "http://www.w3.org/2001/sw/DataAccess/rf1/result"}
        
        # Each <result> node can have multiple child elements
        # We look for <identifier> in that namespace.
        for result_node in root.findall("ns:results/ns:result", ns):
            identifier_elem = result_node.find("ns:identifier", ns)
            if identifier_elem is not None and identifier_elem.text:
                identifiers.append(identifier_elem.text.strip())
                
        logging.info(f"Found {len(identifiers)} identifiers in the SPARQL XML.")
    except ET.ParseError as e:
        logging.error(f"Error parsing SPARQL XML: {e}")
    
    return identifiers

def parse_rdf_content(rdf_text, identifier):
    """
    Parse the RDF/XML content for a single Basel account book using rdflib.
    Extract metadata, account structures, and entries, returning a dict.
    """
    try:
        graph = Graph()
        # Parse RDF from text
        graph.parse(data=rdf_text, format="xml")
        
        logging.info(f"Successfully parsed RDF for identifier: {identifier}")
        
        # --------------------------------------------------------
        # 1) Extract book metadata (dc:date, srbas:from, tei:msIdentifier, etc.)
        # --------------------------------------------------------
        book_metadata = {}
        # We only check triples where the subject string includes the identifier
        # to find the main RDF resource for this book.
        
        # dc:date
        for s, p, o in graph.triples((None, DC.date, None)):
            if identifier in str(s):
                book_metadata["dc:date"] = str(o)
        
        # srbas:from
        for s, p, o in graph.triples((None, SRBAS.from_, None)):
            if identifier in str(s):
                book_metadata["srbas:from"] = str(o)
        
        # tei:msIdentifier
        for s, p, o in graph.triples((None, TEI.msIdentifier, None)):
            if identifier in str(s):
                book_metadata["tei:msIdentifier"] = str(o)
        
        logging.info(f"[{identifier}] Book metadata: {book_metadata}")
        
        # --------------------------------------------------------
        # 2) Extract account structure
        #    Each account has RDF.type = bk:account
        # --------------------------------------------------------
        account_structures = []
        
        for account in graph.subjects(RDF.type, BK.account):
            acc_info = {"uri": str(account)}
            
            # skos:prefLabel for the account label
            label = list(graph.objects(account, SKOS.prefLabel))
            if label:
                acc_info["label"] = str(label[0])
            
            # bk:accountPath
            path = list(graph.objects(account, BK.accountPath))
            if path:
                acc_info["accountPath"] = str(path[0])
            
            # bk:subAccountOf
            parent = list(graph.objects(account, BK.subAccountOf))
            if parent:
                acc_info["parent"] = str(parent[0])
            
            account_structures.append(acc_info)
        
        logging.info(f"[{identifier}] Found {len(account_structures)} accounts.")
        
        # --------------------------------------------------------
        # 3) Extract entries
        #    Each entry has RDF.type = bk:entry
        #    Each entry references bk:amount, bk:account, bk:mainAccount, bk:inhalt, etc.
        # --------------------------------------------------------
        entries = []
        
        for entry in graph.subjects(RDF.type, BK.entry):
            entry_info = {"uri": str(entry)}
            
            # Collect account references for this entry
            entry_accounts = graph.objects(entry, BK.account)
            entry_info["accounts"] = [str(acc) for acc in entry_accounts]
            
            # mainAccount
            main_account = list(graph.objects(entry, BK.mainAccount))
            if main_account:
                entry_info["mainAccount"] = str(main_account[0])
            
            # Amount details - could be a blank node or separate resource
            entry_amount_nodes = list(graph.objects(entry, BK.amount))
            for amt_node in entry_amount_nodes:
                num_list = list(graph.objects(amt_node, BK.num))
                unit_list = list(graph.objects(amt_node, BK.unit))
                as_list = list(graph.objects(amt_node, BK.as_))
                
                entry_info["amount_num"] = float(num_list[0]) if num_list else None
                entry_info["amount_unit"] = str(unit_list[0]) if unit_list else None
                entry_info["amount_as"] = str(as_list[0]) if as_list else None
            
            # inhalt (content of the entry)
            inhalt = list(graph.objects(entry, BK.inhalt))
            if inhalt:
                entry_info["content"] = str(inhalt[0])
            
            # Page reference: oa:hasTarget
            page_target = list(graph.objects(entry, OA.hasTarget))
            if page_target:
                entry_info["page_ref"] = str(page_target[0])
            
            entries.append(entry_info)
        
        logging.info(f"[{identifier}] Found {len(entries)} entries.")
        
        return {
            "identifier": identifier,
            "metadata": book_metadata,
            "accounts": account_structures,
            "entries": entries,
            "graph": graph  # Return the graph so we can merge it later
        }
    except Exception as e:
        logging.error(f"Error parsing RDF for {identifier}: {e}")
        return None

def main():
    # ------------------------------------------------------------------
    # 1. FETCH and PARSE the SPARQL XML from the given URL
    # ------------------------------------------------------------------
    sparql_url = (
        "https://gams.uni-graz.at/archive/risearch"
        "?type=tuples&lang=sparql&format=Sparql&query="
        "http%3A%2F%2Ffedora%3A8380%2Farchive%2Fget%2Fcontext%3Asrbas%2FQUERY"
    )
    
    xml_text = fetch_sparql_xml(sparql_url)
    
    if not xml_text:
        logging.error("No SPARQL XML content retrieved. Exiting...")
        return
    
    identifiers = parse_sparql_xml(xml_text)
    
    # We'll store the extracted data in this list
    all_books_data = []
    
    # We also create a single, big rdflib.Graph to accumulate all RDF
    combined_graph = Graph()
    
    # ------------------------------------------------------------------
    # 2. FOR EACH IDENTIFIER, build the RDF URL, parse, and merge
    # ------------------------------------------------------------------
    for identifier in identifiers:
        # e.g. "https://gams.uni-graz.at/o:srbas.1535/RDF"
        rdf_url = f"https://gams.uni-graz.at/{identifier}/RDF"
        
        logging.info(f"Fetching RDF for identifier: {identifier} at {rdf_url}")
        
        try:
            response = requests.get(rdf_url, timeout=30)
            if response.status_code == 200:
                logging.info(f"Successfully retrieved RDF for {identifier}, parsing...")
                book_data = parse_rdf_content(response.text, identifier)
                
                if book_data:
                    # 2A) Accumulate data in all_books_data for downstream usage
                    all_books_data.append(book_data)
                    
                    # 2B) Merge the individual graph into our combined graph
                    combined_graph += book_data["graph"]
            else:
                logging.warning(
                    f"Failed to retrieve RDF for {identifier}, "
                    f"status code: {response.status_code}"
                )
        except requests.exceptions.RequestException as e:
            logging.error(f"Request error for {identifier}: {e}")
    
    # ------------------------------------------------------------------
    # 3. SAVE the combined RDF to a Turtle file named srbas-rdf.ttl
    # ------------------------------------------------------------------
    ttl_filename = "srbas-rdf.ttl"
    try:
        combined_graph.serialize(destination=ttl_filename, format="turtle")
        logging.info(f"All RDF data has been saved to {ttl_filename}")
    except Exception as e:
        logging.error(f"Could not serialize combined RDF to {ttl_filename}: {e}")
    
    # ------------------------------------------------------------------
    # 4. LOG a final summary
    # ------------------------------------------------------------------
    logging.info("Finished processing all RDF data.")
    logging.info(f"Total books parsed: {len(all_books_data)}")
    for book in all_books_data:
        logging.info(
            f"Identifier: {book['identifier']} | "
            f"Entries: {len(book['entries'])} | Accounts: {len(book['accounts'])}"
        )

if __name__ == "__main__":
    main()
