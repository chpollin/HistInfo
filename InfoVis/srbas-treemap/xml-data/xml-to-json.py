import xml.etree.ElementTree as ET
import json
from typing import List, Dict, Union
from pathlib import Path
import sys

def clean_uri(uri: str) -> str:
    """Extract ID from URI string."""
    if not uri:
        return ""
    return uri.split('#')[-1] if '#' in uri else uri.split('/')[-1]

def convert_value_type(value: str) -> Union[int, float, str]:
    """Convert string values to appropriate types."""
    if not value or not isinstance(value, str):
        return value
    
    try:
        return int(value)
    except ValueError:
        try:
            return float(value)
        except ValueError:
            return value

class SparqlXmlConverter:
    def __init__(self):
        self.namespaces = {
            'sparql': 'http://www.w3.org/2001/sw/DataAccess/rf1/result',
            'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
        }
        
        # English translations for field names
        self.field_translations = {
            'von': 'year_from',
            'bis': 'year_to',
            'konto': 'account',
            'pfad': 'path',
            'betrag': 'amount',
            'subkonto': 'subaccount',
            'subbetrag': 'subamount',
            'objekt': 'object',
            'subkontoname': 'subaccount_name',
            'kontoname': 'account_name',
            'warnung': 'warning',
            'subwarnung': 'subwarning'
        }
        
        # Fields to exclude
        self.exclude_fields = {'as', 'assub'}

    def translate_field(self, field: str) -> str:
        """Translate field name to English."""
        return self.field_translations.get(field, field)

    def parse_xml(self, file_path: Union[str, Path]) -> List[Dict]:
        """Parse SPARQL XML results file and return structured data."""
        file_path = Path(file_path)
        
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")
        
        tree = ET.parse(file_path)
        root = tree.getroot()
        
        results = []
        for result in root.findall('.//sparql:result', self.namespaces):
            result_data = {}
            
            for child in result:
                # Get tag name without namespace
                tag = child.tag.split('}')[-1]
                
                # Skip excluded fields
                if tag in self.exclude_fields:
                    continue
                
                # Get English field name
                eng_tag = self.translate_field(tag)
                
                # Handle URI attributes - extract only the ID
                if 'uri' in child.attrib:
                    result_data[eng_tag] = clean_uri(child.attrib['uri'])
                else:
                    # Convert and store the value with appropriate type
                    result_data[eng_tag] = convert_value_type(child.text)
            
            results.append(result_data)
            
        return results

    def save_json(self, data: List[Dict], output_path: Union[str, Path]) -> None:
        """Save parsed data as JSON file."""
        output_path = Path(output_path)
        
        with output_path.open('w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

def main():
    """Main execution function with error handling."""
    try:
        if len(sys.argv) < 2:
            print("Usage: python xml-to-json.py <input_xml_file> [output_json_file]")
            sys.exit(1)
            
        input_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else input_file.replace('.xml', '.json')
        
        converter = SparqlXmlConverter()
        print(f"Parsing {input_file}...")
        
        results = converter.parse_xml(input_file)
        converter.save_json(results, output_file)
        
        print(f"Successfully converted {len(results)} results")
        print(f"Output saved to: {output_file}")
        
        # Print first result as example
        
        if results:
            print("\nExample of first converted entry:")
            print(json.dumps(results[0], indent=2, ensure_ascii=False))
        
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except ET.ParseError as e:
        print(f"Error: Invalid XML format - {e}")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()