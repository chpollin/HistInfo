# Wheaton Network Data Documentation

## Overview
This document provides a comprehensive breakdown of the Wheaton Network dataset structure, which captures historical social, economic, and educational relationships primarily in 19th century Massachusetts.

## Data Structure

### 1. Root Level Organization
```javascript
{
  "relationships": [...],  // Array of relationship entries
  "people": {...},         // Object containing person records
  "locations": {...},      // Object containing location data
  "commodities": {},       // Empty in current dataset
  "statistics": {...}      // Statistical summaries
}
```

### 2. Relationships Array
Each entry represents a connection or transaction between entities.

#### Basic Structure
```javascript
{
  "source": String,           // ID of initiating entity (e.g., "pers_wcdh001")
  "target": String,           // ID of receiving entity
  "dateStr": String,         // Date in YYYY-MM-DD format
  "currencyOriginal": String, // Monetary amount if applicable
  "transactionType": String,  // Type of relationship
  "note": String,            // Descriptive text
  "category": String,        // Broad classification
  "economic_roles": {...},    // Present for economic transactions
  "flow_details": {...}       // Details for economic transactions
}
```

#### Transaction Types
- `marriage`: Matrimonial relationships
- `residence`: Living location records
- `education`: Educational affiliations
- `occupation`: Professional roles
- `service`: Service provisions
- `commodity`: Good exchanges

#### Categories
- `social`: Social relationships
- `residence`: Housing/location information
- `education`: Educational connections
- `economic`: Financial/business transactions

#### Economic Roles Structure
```javascript
"economic_roles": {
  "[entity_id]": [
    // Possible roles:
    // "service_provider"
    // "service_recipient"
    // "commodity_provider"
    // "commodity_recipient"
    // "creditor"
    // "debtor"
  ]
}
```

#### Flow Details Structure
```javascript
"flow_details": {
  "note": String,          // Transaction description
  "source_role": [String], // Role of source entity
  "target_role": [String], // Role of target entity
  "quantity": String,      // Amount
  "unit": String,          // Unit of measure
  "commodity_id": String   // Type of commodity
}
```

### 3. People Object
Individual records for each person in the network.

#### Structure
```javascript
{
  "id": String,           // Format: "pers_wcdhXXX"
  "full": String,         // Full name
  "forenames": [{         // Array of given names
    "name": String,
    "type": String        // "first", "middle", or "initial"
  }],
  "surnames": [{          // Array of surnames
    "name": String,
    "type": String        // "birth", "married", or empty
  }],
  "birth": {
    "date": String,       // YYYY-MM-DD format
    "location": {
      "settlement": String,
      "region": String,
      "geogName": String,
      "full": String
    }
  },
  "death": {              // Same structure as birth
    "date": String,
    "location": {...}
  },
  "education": [String],  // Educational background
  "faith": String,        // Religious affiliation
  "gender": String        // "male" or "female"
}
```

### 4. Locations Object
Geographic location records.

#### Structure
```javascript
{
  "name": String,         // Full location name
  "settlement": String,   // Town/city
  "region": String,       // State/province
  "geogName": String     // Geographic identifier
}
```

### 5. Statistics Object
Network-wide metrics.

#### Structure
```javascript
{
  "totalTransactions": Number,     // Total recorded transactions
  "uniquePeople": Number,          // Distinct individuals
  "uniqueLocations": Number,       // Distinct places
  "uniqueCommodities": Number,     // Different commodities
  "economicRoles": {
    "service_providers": Number,
    "service_recipients": Number,
    "commodity_providers": Number,
    "commodity_recipients": Number,
    "creditors": Number,
    "debtors": Number
  }
}
```

## Transaction Categories

### Service Types
1. Work Services
   - Manual labor
   - Professional services
   - Educational services

2. Rental Services
   - Property rentals
   - Equipment rentals
   - Animal rentals

3. Transportation Services
   - Carting
   - Delivery services

### Commodity Types
1. Agricultural Products
   - Rye
   - Corn
   - Potatoes
   - Other grains

2. Manufactured Goods
   - Nails
   - Tools
   - Household items
   - Books
   - Paper products

3. Consumables
   - Food items
   - Beverages
   - Household supplies

4. Building Materials
   - Lumber
   - Construction supplies
   - Hardware

5. Textiles and Clothing
   - Fabric
   - Finished clothing
   - Shoes
   - Accessories

## Temporal Coverage
- Primary Period: 1820s-1830s
- Earliest Record: 1737
- Latest Record: 1918

## Geographic Coverage

### Primary Locations
Massachusetts:
- Norton
- Uxbridge
- Sutton
- Boston
- Taunton

### Other Areas
- Other New England locations
- Occasional records from other regions

## Network Statistics
Current dataset contains:
- 1124 total transactions
- 718 unique individuals
- 47 unique locations
- Economic role distribution:
  * 7 service providers
  * 28 service recipients
  * 139 commodity providers
  * 72 commodity recipients
  * 0 creditors
  * 1 debtor

## Analysis Capabilities
This dataset enables research into:
1. Social Network Analysis
   - Family relationships
   - Community connections
   - Professional networks

2. Economic Patterns
   - Trade relationships
   - Service provisions
   - Commodity flows

3. Geographic Mobility
   - Residential patterns
   - Migration trends
   - Community development

4. Educational Networks
   - School affiliations
   - Educational patterns
   - Institution relationships

5. Professional Activities
   - Occupational patterns
   - Business relationships
   - Service networks

6. Religious Connections
   - Faith affiliations
   - Religious community patterns