#!/usr/bin/env python3
import xml.etree.ElementTree as ET
import json
from typing import List, Dict, Union
from pathlib import Path
import sys

def clean_uri(uri: str) -> str:
    """Extract ID from a URI string, taking the part after '#' or the last slash."""
    if not uri:
        return ""
    return uri.split('#')[-1] if '#' in uri else uri.split('/')[-1]

def convert_value_type(value: str) -> Union[int, float, str]:
    """Attempt to convert string values to int or float; fallback to str if not possible."""
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
        
        # Fields to exclude (like 'as', 'assub')
        self.exclude_fields = {'as', 'assub'}

    def translate_field(self, field: str) -> str:
        """Translate field name to English if a mapping exists."""
        return self.field_translations.get(field, field)

    def parse_xml(self, file_path: Union[str, Path]) -> List[Dict]:
        """Parse one SPARQL XML results file and return a list of records."""
        file_path = Path(file_path)
        
        if not file_path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")
        
        tree = ET.parse(file_path)
        root = tree.getroot()
        
        results = []
        # Each <result> block in the sparql XML
        for result in root.findall('.//sparql:result', self.namespaces):
            result_data = {}
            
            for child in result:
                # Get tag name without the namespace
                tag = child.tag.split('}')[-1]
                
                # Skip excluded fields
                if tag in self.exclude_fields:
                    continue
                
                # Translate the field name
                eng_tag = self.translate_field(tag)
                
                # If there's a URI attribute, extract only the ID
                if 'uri' in child.attrib:
                    result_data[eng_tag] = clean_uri(child.attrib['uri'])
                else:
                    # Otherwise, parse the text content, converting to int/float if possible
                    result_data[eng_tag] = convert_value_type(child.text)
            
            results.append(result_data)
            
        return results

    def save_json(self, data: List[Dict], output_path: Union[str, Path]) -> None:
        """Save parsed data as a JSON file with UTF-8 encoding."""
        output_path = Path(output_path)
        with output_path.open('w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

def main():
    """Main function: parse one or more SPARQL XML files into a single JSON."""
    try:
        if len(sys.argv) < 2:
            print("Usage: python xml-to-json.py <input_xml_file1> [<input_xml_file2> ...] [output_json_file]")
            sys.exit(1)
        
        # Gather arguments
        input_files = []
        output_file = None

        # Identify which arguments look like .xml vs .json
        for arg in sys.argv[1:]:
            if arg.lower().endswith('.xml'):
                input_files.append(arg)
            elif arg.lower().endswith('.json'):
                output_file = arg
            else:
                # Could handle unknown file extensions differently, or assume it's an input
                # For simplicity, let's assume it's an input file if not .json
                input_files.append(arg)

        if not input_files:
            print("No input XML files specified.")
            sys.exit(1)
        
        # If no explicit output_file was given, guess from the first input file
        if not output_file:
            first_xml = Path(input_files[0])
            output_file = first_xml.with_suffix('.json').name  # e.g. "sparql-result-accounts.json"

        converter = SparqlXmlConverter()

        all_results = []
        for xml_file in input_files:
            print(f"Parsing {xml_file}...")
            partial_results = converter.parse_xml(xml_file)
            print(f"  Found {len(partial_results)} results in {xml_file}")
            all_results.extend(partial_results)

        # Now we have a merged list of all results
        converter.save_json(all_results, output_file)
        
        print(f"\nSuccessfully converted/merged {len(all_results)} total results.")
        print(f"Output saved to: {output_file}")
        
        # Print a sample result if we have any
        if all_results:
            print("\nExample of first converted entry:")
            print(json.dumps(all_results[0], indent=2, ensure_ascii=False))
        
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
