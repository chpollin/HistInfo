import xml.etree.ElementTree as ET
from typing import Dict, List, Set, Optional
from dataclasses import dataclass, field
import json
import re

@dataclass
class EconomicFlow:
    flow_type: str  # 'service', 'commodity', or 'money'
    from_person: str
    to_person: str
    quantity: str
    unit: str
    description: str
    commodity_id: str = ''

@dataclass
class Transaction:
    entry_id: str
    date: str
    buyer: Optional[str]
    seller: Optional[str]
    service_provider: Optional[str]
    service_recipient: Optional[str]
    amount: str
    transaction_type: str
    note: str
    credit_entries: List[Dict] = field(default_factory=list)
    debit_entries: List[Dict] = field(default_factory=list)
    commodity_flows: List[EconomicFlow] = field(default_factory=list)
    service_flows: List[EconomicFlow] = field(default_factory=list)
    money_flows: List[EconomicFlow] = field(default_factory=list)
    economic_roles: Dict[str, List[str]] = field(default_factory=dict)

class WheatonNetworkAnalyzer:
    def __init__(self):
        self.ns = {'tei': 'http://www.tei-c.org/ns/1.0'}
        self.relationships = []
        self.people = {}
        self.locations = {}
        self.institutions = {}
        self.transactions = []
        self.commodities = {}
        self.processed_pairs = set()
        self.wheaton_id = "pers_wcdh002"  # Laban Morey Wheaton's ID

    def clean_text(self, text: str) -> str:
        """Clean and normalize text."""
        if not text:
            return ""
        return text.strip().replace('"', '\\"')

    def normalize_id(self, text: str) -> str:
        """Create a normalized ID from text."""
        if not text:
            return ""
        words = re.findall(r'[A-Za-z0-9]+', text)
        if not words:
            return ""
        return words[0] + ''.join(w.capitalize() for w in words[1:])

    def extract_date(self, elem: ET.Element, attrs: List[str] = None) -> str:
        """Extract date from element using multiple possible attributes."""
        if attrs is None:
            attrs = ['when', 'notBefore', 'notAfter']
        for attr in attrs:
            date_val = elem.get(attr, '')
            if date_val:
                return date_val
        return ""

    def add_relationship(self, source: str, target: str, rel_type: str, 
                         date: str = "", note: str = "", category: str = ""):
        """Add a social or other non-economic relationship to the network."""
        rel_pair = (source, target, rel_type)
        if rel_pair not in self.processed_pairs:
            self.relationships.append({
                "source": source,
                "target": target,
                "dateStr": date,
                "currencyOriginal": "",
                "transactionType": rel_type,
                "note": note,
                "category": category
            })
            self.processed_pairs.add(rel_pair)

    def extract_location(self, elem: ET.Element) -> Dict:
        """Extract location information from element."""
        location = {
            'settlement': '',
            'region': '',
            'geogName': '',
            'full': ''
        }
        
        settlement = elem.find('.//tei:settlement', self.ns)
        region = elem.find('.//tei:region', self.ns)
        geo_name = elem.find('.//tei:geogName', self.ns)
        
        if settlement is not None and settlement.text:
            location['settlement'] = self.clean_text(settlement.text)
        if region is not None and region.text:
            location['region'] = self.clean_text(region.text)
        if geo_name is not None and geo_name.text:
            location['geogName'] = self.clean_text(geo_name.text)
            
        parts = []
        if location['settlement']:
            parts.append(location['settlement'])
        if location['region']:
            parts.append(location['region'])
        location['full'] = ', '.join(parts)
        
        if location['full']:
            location_id = self.normalize_id(location['full'])
            self.locations[location_id] = {
                'name': location['full'],
                'settlement': location['settlement'],
                'region': location['region'],
                'geogName': location['geogName']
            }
        return location

    # -----------------------------------------------------------
    # Person (prosopographical) data
    # -----------------------------------------------------------
    def process_people(self, list_person: ET.Element):
        """Process all person entries and their relationships."""
        persons = list_person.findall('tei:person', self.ns)
        for person in persons:
            details = self.extract_person_details(person)
            person_id = details['id']
            self.people[person_id] = details
            
            # Then handle any marriage/residence/education/occupation
            self.process_marriage_relationships(person, person_id)
            self.process_residence_relationships(person, person_id)
            self.process_education_relationships(person, person_id)
            self.process_occupation_relationships(person, person_id)

    def extract_person_details(self, person: ET.Element) -> Dict:
        """Extract person details (name, birth, death, faith, etc.)."""
        details = {}
        details['id'] = person.get('{http://www.w3.org/XML/1998/namespace}id', '')

        # Name info
        name_info = self.extract_person_name(person)
        details.update(name_info)

        # Birth
        birth = person.find('.//tei:birth', self.ns)
        if birth is not None:
            details['birth'] = {
                'date': birth.get('when', ''),
                'location': self.extract_location(birth)
            }

        # Death
        death = person.find('.//tei:death', self.ns)
        if death is not None:
            details['death'] = {
                'date': death.get('when', ''),
                'location': self.extract_location(death)
            }

        # Education
        education = person.findall('.//tei:education', self.ns)
        if education:
            details['education'] = []
            for edu in education:
                if edu.text:
                    details['education'].append(self.clean_text(edu.text))

        # Faith
        faith = person.find('.//tei:faith', self.ns)
        if faith is not None and faith.text:
            details['faith'] = self.clean_text(faith.text)

        # [NEW] Gender from <sex>female</sex> or <sex>male</sex>
        sex_elem = person.find('.//tei:sex', self.ns)
        if sex_elem is not None and sex_elem.text:
            details['gender'] = self.clean_text(sex_elem.text).lower()

        return details

    def extract_person_name(self, person: ET.Element) -> Dict:
        """Extract individual's name components."""
        persName = person.find('.//tei:persName', self.ns)
        if persName is None:
            return {
                'full': '',
                'id': person.get('{http://www.w3.org/XML/1998/namespace}id', '')
            }

        name_data = {
            'full': '',
            'forenames': [],
            'surnames': [],
            'id': person.get('{http://www.w3.org/XML/1998/namespace}id', '')
        }

        for forename in persName.findall('.//tei:forename', self.ns):
            if forename.text:
                name_data['forenames'].append({
                    'name': self.clean_text(forename.text),
                    'type': forename.get('type', '')
                })

        for surname in persName.findall('.//tei:surname', self.ns):
            if surname.text:
                name_data['surnames'].append({
                    'name': self.clean_text(surname.text),
                    'type': surname.get('type', '')
                })

        forename_parts = [f['name'] for f in name_data['forenames']]
        surname_parts = [s['name'] for s in name_data['surnames']]
        name_data['full'] = ' '.join(forename_parts + surname_parts)
        return name_data

    def process_marriage_relationships(self, person: ET.Element, person_id: str):
        """Process marriage relationships (if present)."""
        marriage_state = person.find('.//tei:state[@type="married"]', self.ns)
        if marriage_state is not None:
            married_surname = person.find('.//tei:surname[@type="married"]', self.ns)
            if married_surname is not None and married_surname.text:
                self.add_relationship(
                    source=person_id,
                    target=f"Unknown{self.normalize_id(married_surname.text)}",
                    rel_type="marriage",
                    date=self.extract_date(marriage_state),
                    note="Marriage relationship",
                    category="social"
                )

    def process_residence_relationships(self, person: ET.Element, person_id: str):
        """Process known residences."""
        residences = person.findall('.//tei:residence', self.ns)
        for residence in residences:
            location = self.extract_location(residence)
            if location['full']:
                self.add_relationship(
                    source=person_id,
                    target=f"{self.normalize_id(location['full'])}Residence",
                    rel_type="residence",
                    date=self.extract_date(residence),
                    note=f"Resided in {location['full']}",
                    category="residence"
                )

    def process_education_relationships(self, person: ET.Element, person_id: str):
        """Process educational relationships."""
        education = person.findall('.//tei:education', self.ns)
        for edu in education:
            org_names = edu.findall('.//tei:orgName', self.ns)
            for org in org_names:
                if org is not None and org.text:
                    institution_name = self.clean_text(org.text)
                    institution_id = self.normalize_id(institution_name)
                    
                    self.institutions[institution_id] = {
                        'name': institution_name,
                        'type': 'education'
                    }
                    
                    self.add_relationship(
                        source=person_id,
                        target=institution_id,
                        rel_type="education",
                        date=self.extract_date(edu),
                        note=f"Educated at {institution_name}",
                        category="education"
                    )

    def process_occupation_relationships(self, person: ET.Element, person_id: str):
        """Process occupations."""
        occupations = person.findall('.//tei:occupation', self.ns)
        for occ in occupations:
            if occ.text:
                occupation_name = self.clean_text(occ.text)
                location = self.extract_location(occ)
                if location['full']:
                    target_id = self.normalize_id(f"{occupation_name}{location['full']}")
                    self.add_relationship(
                        source=person_id,
                        target=target_id,
                        rel_type="occupation",
                        note=f"{occupation_name} in {location['full']}",
                        category="occupation"
                    )
                else:
                    target_id = self.normalize_id(occupation_name)
                    self.add_relationship(
                        source=person_id,
                        target=target_id,
                        rel_type="occupation",
                        note=f"Occupation: {occupation_name}",
                        category="occupation"
                    )

    # -----------------------------------------------------------
    # Transactions (economic) data
    # -----------------------------------------------------------
    def process_transactions(self, root: ET.Element):
        """Scan rows for `bk:entry` and parse as transactions."""
        current_date = ""
        for row in root.findall('.//tei:row', self.ns):
            # Some ledgers put date info in a row with <date ana="bk:when">
            date_elem = row.find('.//tei:date[@ana="bk:when"]', self.ns)
            if date_elem is not None:
                current_date = date_elem.get('when', current_date)
                continue

            # If row is indeed a ledger entry
            if row.get('ana') == 'bk:entry':
                transaction = self.extract_transaction(row, current_date)
                self.transactions.append(transaction)
                self.add_relationship_from_transaction(transaction)

    def add_relationship_from_transaction(self, transaction: Transaction):
        """
        Create direct relationships from transactions,
        but replace Wheaton with specialized "virtual" nodes.
        """

        def build_wheaton_node_id(flow_type: str, commodity_id: str, description: str) -> str:
            """
            Return a node name like "wheatonCommodity_c_shirting"
            or "wheatonService_c_wagonrental".
            """
            if flow_type == "commodity":
                suffix = commodity_id if commodity_id else "GenericCommodity"
                return f"wheatonCommodity_{suffix}"
            elif flow_type == "service":
                suffix = commodity_id if commodity_id else "GenericService"
                return f"wheatonService_{suffix}"
            elif flow_type == "credit":
                return "wheatonCreditOrDebit"
            else:
                return "wheatonOther"

        def add_economic_relationship(source: str, target: str, flow_type: str, details: Dict):
            """Append a relationship into self.relationships."""
            if not source or not target:
                return
            self.relationships.append({
                "source": source,
                "target": target,
                "dateStr": transaction.date,
                "currencyOriginal": transaction.amount,
                "transactionType": flow_type,
                "note": details.get('note', ''),
                "category": "economic",
                "economic_roles": {
                    source: details.get('source_role', []),
                    target: details.get('target_role', [])
                },
                "flow_details": details
            })

        # Commodity flows
        for flow in transaction.commodity_flows:
            src = flow.from_person
            tgt = flow.to_person
            if src == self.wheaton_id:
                src = build_wheaton_node_id("commodity", flow.commodity_id, flow.description)
            if tgt == self.wheaton_id:
                tgt = build_wheaton_node_id("commodity", flow.commodity_id, flow.description)
            add_economic_relationship(
                src,
                tgt,
                "commodity",
                {
                    "note": f"Commodity transfer: {flow.description}",
                    "source_role": ["commodity_provider"] if src else [],
                    "target_role": ["commodity_recipient"] if tgt else [],
                    "quantity": flow.quantity,
                    "unit": flow.unit,
                    "commodity_id": flow.commodity_id
                }
            )

        # Service flows
        for flow in transaction.service_flows:
            src = flow.from_person
            tgt = flow.to_person
            if src == self.wheaton_id:
                src = build_wheaton_node_id("service", flow.commodity_id, flow.description)
            if tgt == self.wheaton_id:
                tgt = build_wheaton_node_id("service", flow.commodity_id, flow.description)
            add_economic_relationship(
                src,
                tgt,
                "service",
                {
                    "note": f"Service provision: {flow.description}",
                    "source_role": ["service_provider"] if src else [],
                    "target_role": ["service_recipient"] if tgt else [],
                    "quantity": flow.quantity,
                    "unit": flow.unit,
                    "commodity_id": flow.commodity_id
                }
            )

        # Credit/debit
        for credit in transaction.credit_entries:
            for debit in transaction.debit_entries:
                c_person = credit["person"]
                d_person = debit["person"]
                if c_person == self.wheaton_id:
                    c_person = build_wheaton_node_id("credit", "", "WheatonCredit")
                if d_person == self.wheaton_id:
                    d_person = build_wheaton_node_id("credit", "", "WheatonDebit")
                add_economic_relationship(
                    c_person,
                    d_person,
                    "credit",
                    {
                        "note": "Credit-Debit relationship",
                        "source_role": ["creditor"],
                        "target_role": ["debtor"]
                    }
                )

    def extract_transaction(self, entry: ET.Element, date: str) -> Transaction:
        """
        Extract transaction data from a <row ana="bk:entry"> element.
        Summation for multiple bk:money measures, numeric parsing of commodity/service.
        """
        entry_id = entry.get('{http://www.w3.org/XML/1998/namespace}id', '')
        transaction_data = {
            'buyer': None,
            'seller': None,
            'service_provider': None,
            'service_recipient': None,
            'money_amount': "0.00",
            'credit_entries': [],
            'debit_entries': [],
            'commodity_flows': [],
            'service_flows': [],
            'money_flows': [],
            'economic_roles': {},
            'notes': []
        }

        # Identify all persons in the transaction
        all_names = {}
        for cell in entry.findall('tei:cell', self.ns):
            name_elem = cell.find('.//tei:name', self.ns)
            if name_elem is not None:
                person_ref = name_elem.get('ref', '').replace('#', '')
                ana_type = name_elem.get('ana', '')  # e.g. 'bk:to'
                if person_ref:
                    all_names[person_ref] = ana_type

        # If only 1 named person, assume the other is LMW
        if len(all_names) == 1:
            sole_ref = list(all_names.keys())[0]
            sole_ana = all_names[sole_ref]
            if sole_ana == "bk:to":
                all_names[self.wheaton_id] = "bk:from"
            elif sole_ana == "bk:from":
                all_names[self.wheaton_id] = "bk:to"

        # Parse row's <cell> elements
        for cell in entry.findall('tei:cell', self.ns):
            # [NEW] sum all <measure ana="bk:money">
            money_total = 0.0
            for money_elem in cell.findall('.//tei:measure[@ana="bk:money"]', self.ns):
                q_str = money_elem.get('quantity', '0.0').strip()
                try:
                    q_val = float(q_str)
                except ValueError:
                    q_val = 0.0
                money_total += q_val

            if money_total > 0:
                curr_amount = float(transaction_data['money_amount'])
                curr_amount += money_total
                transaction_data['money_amount'] = f"{curr_amount:.2f}"

            if cell.text and cell.text.strip():
                transaction_data['notes'].append(cell.text.strip())

            # Find credit/debit markers
            debits = cell.findall('.//*[@ana="bk:debit"]', self.ns)
            credits = cell.findall('.//*[@ana="bk:credit"]', self.ns)

            # If we find a name in the same cell, that name is the person
            name_elem = cell.find('.//tei:name', self.ns)
            person_ref = ""
            if name_elem is not None:
                person_ref = name_elem.get('ref', '').replace('#', '')

            if person_ref:
                for _ in credits:
                    transaction_data['credit_entries'].append({"person": person_ref})
                for _ in debits:
                    transaction_data['debit_entries'].append({"person": person_ref})

            # Commodity measures
            for commodity in cell.findall('.//tei:measure[@ana="bk:commodity"]', self.ns):
                seller = next((p for p, a in all_names.items() if a == 'bk:from'), "")
                buyer  = next((p for p, a in all_names.items() if a == 'bk:to'), "")

                q_str = commodity.get('quantity', '0').strip()
                try:
                    q_val = float(q_str)
                except ValueError:
                    q_val = 0.0

                flow = EconomicFlow(
                    flow_type='commodity',
                    from_person=seller,
                    to_person=buyer,
                    quantity=f"{q_val}",
                    unit=commodity.get('unit', ''),
                    description=commodity.text.strip() if commodity.text else '',
                    commodity_id=commodity.get('commodity', '').replace('#', '')
                )
                transaction_data['commodity_flows'].append(flow)

            # Service measures
            for service in cell.findall('.//tei:measure[@ana="bk:service"]', self.ns):
                provider = next((p for p, a in all_names.items() if a == 'bk:from'), "")
                recipient = next((p for p, a in all_names.items() if a == 'bk:to'), "")

                svc_str = service.get('quantity', '0').strip()
                try:
                    svc_val = float(svc_str)
                except ValueError:
                    svc_val = 0.0

                flow = EconomicFlow(
                    flow_type='service',
                    from_person=provider,
                    to_person=recipient,
                    quantity=f"{svc_val}",
                    unit=service.get('unit', ''),
                    description=service.text.strip() if service.text else '',
                    commodity_id=service.get('commodity','').replace('#','')
                )
                transaction_data['service_flows'].append(flow)

        # Decide transaction type
        if transaction_data['commodity_flows']:
            transaction_type = "commodity"
        elif transaction_data['service_flows']:
            transaction_type = "service"
        elif transaction_data['credit_entries'] or transaction_data['debit_entries']:
            transaction_type = "credit"
        else:
            transaction_type = "other"

        return Transaction(
            entry_id=entry_id,
            date=date,
            buyer=transaction_data['buyer'],
            seller=transaction_data['seller'],
            service_provider=transaction_data['service_provider'],
            service_recipient=transaction_data['service_recipient'],
            amount=transaction_data['money_amount'],
            transaction_type=transaction_type,
            note=' '.join(transaction_data['notes']),
            credit_entries=transaction_data['credit_entries'],
            debit_entries=transaction_data['debit_entries'],
            commodity_flows=transaction_data['commodity_flows'],
            service_flows=transaction_data['service_flows'],
            money_flows=transaction_data['money_flows'],
            economic_roles=transaction_data['economic_roles']
        )

    # -----------------------------------------------------------
    # Counting Economic Roles
    # -----------------------------------------------------------
    def calculate_economic_roles(self) -> Dict:
        """
        Count how many unique individuals appear with each role,
        after we've built self.relationships.
        """
        role_counts = {
            "service_providers": set(),
            "service_recipients": set(),
            "commodity_providers": set(),
            "commodity_recipients": set(),
            "creditors": set(),
            "debtors": set()
        }

        for relationship in self.relationships:
            econ_roles = relationship.get('economic_roles', {})
            for person, roles in econ_roles.items():
                for role in roles:
                    if role == "service_provider":
                        role_counts["service_providers"].add(person)
                    elif role == "service_recipient":
                        role_counts["service_recipients"].add(person)
                    elif role == "commodity_provider":
                        role_counts["commodity_providers"].add(person)
                    elif role == "commodity_recipient":
                        role_counts["commodity_recipients"].add(person)
                    elif role == "creditor":
                        role_counts["creditors"].add(person)
                    elif role == "debtor":
                        role_counts["debtors"].add(person)

        return {k: len(v) for k, v in role_counts.items()}

    def generate_network(self, filename: str):
        """Generate JSON/JS file with all network data."""
        print("\nDebug - Economic Roles Present:")
        for relationship in self.relationships:
            econ_roles = relationship.get('economic_roles', {})
            if econ_roles:
                print(f"Economic Roles: {econ_roles}")
                print(f"Flow Type: {relationship['transactionType']}")

        role_statistics = self.calculate_economic_roles()
        print("\nRole Statistics:", role_statistics)

        network_data = {
            "relationships": self.relationships,
            "people": self.people,
            "locations": self.locations,
            "institutions": self.institutions,
            "commodities": self.commodities,
            "statistics": {
                "totalTransactions": len(self.transactions),
                "uniquePeople": len(self.people),
                "uniqueLocations": len(self.locations),
                "uniqueCommodities": len(self.commodities),
                "economicRoles": role_statistics
            }
        }

        js_content = [
            "// Generated from TEI XML - Wheaton Network",
            "const wheatonNetwork = " + json.dumps(network_data, indent=2) + ";",
            "",
            "// Export for Node.js or browser",
            "if (typeof module !== 'undefined' && module.exports) {",
            "  module.exports = wheatonNetwork;",
            "} else if (typeof window !== 'undefined') {",
            "  window.wheatonNetwork = wheatonNetwork;",
            "}"
        ]

        with open(filename, 'w', encoding='utf-8') as f:
            f.write('\n'.join(js_content))

def main():
    file_path = "wheaton-tei.xml"  # Adjust as needed
    analyzer = WheatonNetworkAnalyzer()

    try:
        print("Loading TEI XML data from local file...")
        tree = ET.parse(file_path)
        root = tree.getroot()

        # 1) Prosopographical data
        list_person = root.find('.//tei:listPerson', analyzer.ns)
        if list_person is not None:
            print("Processing prosopographical data...")
            analyzer.process_people(list_person)

        # 2) Economic transactions
        print("Processing economic transactions...")
        analyzer.process_transactions(root)

        # 3) Generate final network
        output_file = 'wheaton-network.js'
        analyzer.generate_network(output_file)

        # Print role stats
        print("\nNetwork Statistics:")
        stats = analyzer.calculate_economic_roles()
        for role, count in stats.items():
            print(f"- {role.replace('_', ' ').title()}: {count}")
        print(f"\nOutput written to {output_file}")

    except ET.ParseError as e:
        print(f"Error parsing XML: {e}")
    except Exception as e:
        print(f"Error processing network: {e}")
        raise e

if __name__ == "__main__":
    main()
