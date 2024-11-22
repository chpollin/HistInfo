# **Bookkeeping Ontology \[bk:\]**

Representation of economic transactions in historical financial sources for historical research.

## **Legend**

* isA: Class inheritance (e.g., A isA B means A inherits from B)  
* @: Property with datatype (e.g., name @string)  
* →: Object property/relationship (points to target class)  
* \[min..max\]: Cardinality constraint (e.g., \[0..1\] \= optional single, \[1..\*\] \= one or more)  
* crm: CIDOC-CRM namespace  
* rea: REA model namespace  
* xsd: XML Schema datatypes

## **Transaction Framework**

**Transaction** isA crm:E7\_Activity, rea:EconomicEvent  
  // Definition: A discrete economic event consisting of one or more resource transfers between economic agents, occurring at a specific time or place, documented through formal entries, where each transfer represents a distinct movement of economic value.  
  • status → TransactionStatus \[0..1\]  
  • consistsOf → Transfer \[1..\*\]  
  • when → crm:E52\_Time-Span \[0..1\]  
  • where → crm:E53\_Place \[0..1\]  
  • entry → Entry \[1..1\]

**SubtotalTransaction** isA Transaction   
  // Definition: A transaction that represents the aggregate economic value of a specified subset of other transactions, differentiated by explicit grouping criteria.  
  • summarizes → Transaction \[1..\*\]   
  • groupingCriteria @string \[0..1\]

**TotalTransaction** isA Transaction   
  // Definition: A transaction that represents the complete aggregate economic value of all constituent transactions within a defined scope, including their subtotals.  
  • summarizes → Transaction \[1..*\]*    
  *• includesSubtotals → SubtotalTransaction \[0..*\]    
  • scope @string \[0..1\]  // describes what this total represents

**Transfer** isA crm:E7\_Activity  
  // Definition: An atomic economic event representing the reassignment of control over one or more economic resources from one economic agent to another, characterised by a direction and specific resources involved, occurring within the context of a defined transaction.  
  • from → EconomicAgent \[0..1\]  
  • to → EconomicAgent \[0..1\]  
  • transfers → EconomicResource \[1..\*\]  
  • by → AgentMention \[0..1\]  
  • accountingRecord → AccountingRecord \[0..\*\]

**LiabilityTransfer** isA Transfer  
  // Definition: A transfer whose essential purpose is the extinction of a specific liability through the movement of economic resources from obligor to obligee.  
  • settles → Liability \[1..1\]

**ServiceDelivery** isA Transfer  
  // Definition: The concrete execution of a service by one economic agent for another, transforming a service right into delivered value through a specific activity  
  • fulfills → ServiceRight \[0..\*\]

**Entry** isA crm:E73\_Information\_Object  
  // Definition: An information object that documents a specific transaction through structured textual representation within a source document.  
  • text @string  
  • source → Document \[1..1\]

**AgentMention** isA crm:E13\_Attribute\_Assignment  
  // Definition: An attribute assignment that associates a textual reference to an economic agent in a source document with both its formal actor representation and its contextual role classification.  
  • agentOf → EconomicAgent \[1..1\]  // Links to the formal economic agent representation  
  • agent → crm:E39\_Actor \[1..1\] // The actual actor mentioned or performing the action  
  • entry → Entry \[1..1\] // The textual reference as found in the source  
  • agentType → skos:Concept \[1..1\]  // The role classification of the agent (e.g., "SourceReference", "ActingAgent", "Executor")

## **Agent Framework**

**EconomicAgent** isA crm:E39\_Actor, rea:EconomicAgent  
  // Definition: An actor that has the capacity to control economic resources and participate in transfers, characterized by autonomous decision-making authority over economic resources and the ability to incur obligations.

**Individual** isA EconomicAgent, crm:E21\_Person  
  // Definition: An economic agent that acts as a singular, indivisible decision-making entity, distinguished by direct and personal control over resources and obligations.

**Group** isA EconomicAgent, crm:E74\_Group  
  // Definition: An economic agent that operates through collective decision-making of multiple individuals, characterised by shared control over resources and joint responsibility for obligations.

## **Economic Resource Framework**

**EconomicResource** isA crm:E72\_Legal\_Object, rea:EconomicResource  
  // Definition: A quantifiable economic value under the control of an economic entity that can be transferred between entities and has defined economic characteristics.

**PhysicalResource** isA EconomicResource  
  // Definition: A tangible economic resource that can be physically possessed and measured.  
  • quantity @xsd:decimal \[\> 0\]  
  • unit → Unit \[1..1\]

**EconomicGood** isA PhysicalResource  
  // Definition: Physical resources quantifiable in standardised units of measurement.

**Money** isA PhysicalResource  
  // Definition: Physical medium of exchange and unit of account.

## **Rights and Liabilities**

**Right** isA EconomicResource, crm:E30\_Right  
  // Definition: A legally binding claim to receive a specified service, representing both an economic resource that can be exchanged and a legal right that can be enforced within defined temporal bounds.  
  • validityPeriod → crm:E52\_Time-Span \[0..1\]

**ActionRight** isA Right  
  // Definition: Transferable claim to perform quantifiable economic activities.

**ClaimRight** isA Right  
  // Definition: Transferable claim to receive quantifiable economic resources.  
  • resource → EconomicResource \[1..1\]

**ServiceRight** isA Right  
  // Definition: A right that grants its holder the authority to receive specific services from a designated economic agent, where the service delivery constitutes the fulfilment of the right.

**Liability**  
  // Definition: An economic obligation that involves a specified economic resource, an obligor who must transfer it, and an obligee who must receive it, bounded by temporal constraints.  
  • obligor → EconomicAgent \[1..1\]  
  • obligee → EconomicAgent \[1..1\]  
  • dueDate @xsd:dateTime \[0..1\]  
  • resource → EconomicResource \[1..1\]

## **Measurement Framework**

**Unit** isA crm:E58\_Measurement\_Unit  
  // Definition: A measurement unit that combines an identifying label with a specific dimensional type, serving as a standardised basis for quantifying economic resources.  
  • label @string \[1..1\]            
  • type → UnitType \[1..1\]

**UnitMention** isA crm:E13\_Attribute\_Assignment \#  
  // Definition: An attribute assignment that associates a textual expression of measurement in a source document with its formal unit definition and documentary context.  
  • refersTo → Unit \[1..1\]         
  • source → E31\_Document \[1..1\]   
  • context → E13\_Context \[0..1\]   
  • text @string \[1..1\]

**UnitType** isA skos:Concept   
  // Definition: A concept that categorizes measurement units according to their fundamental dimensional nature, constrained to the exhaustive set of Length, Weight, Volume, Area, Currency, Time, or Count.  
  • Length   
  • Weight   
  • Volume   
  • Area   
  • Currency   
  • Time   
  • Count

**Conversion** isA crm:E28\_Conceptual\_Object   
  // Definition: A conceptual object that defines the mathematical transformation between two specific units through a deterministic formula.  
  • convertsFrom → Unit \[1..1\]     
  • convertsTo → Unit \[1..1\]       
  • formula @string \[1..1\]

**MoneyAmount** isA crm:E97\_Monetary\_Amount  
  // Definition: A quantified economic value that is expressed in a specific currency unit, serving as a measure of economic worth in transactions and accounts.  
  • value @xsd:decimal \[\> 0\]  
  • unit → Unit \[1..1\]

**Accounting Framework**

**AccountingRecord** isA crm:E73\_Information\_Object  
  // Definition: An information object that documents an economic transfer through paired debit and credit entries, representing the bidirectional flow of economic value.  
   • debit →AccountingEntry  
   •  credit → AccountingEntry  
   • documents → Transfer \[1..1\]  
   • period → crm:E52\_Time-Span \[0..1\]

**AccountingEntry** isA crm:E73\_Information\_Object  
  // Definition: An information object that represents one side of an economic value flow through a specific monetary amount, optionally enriched with textual description and categorical classification.  
  • involves → MoneyAmount \[1..1\]  
  • text @string \[0..1\]  
  • category → AccountCategory \[0..1\]

**AccountCategory** isA skos:Concept  
  // Definition: A concept that defines a specific type of economic value flow within a hierarchical classification system, characterized by a preferred label and optional explanatory elements  
  • prefLabel @string \[1..1\]   
  • definition @string \[0..1\]  
  • broader → AccountCategory \[0..\]  
  • narrower → AccountCategory \[0..\]   
  • notation @string \[0..1\]   
  • altLabel @string \[0..\]  
  • scopeNote @string \[0..\]

**Temporal-Spatial Context Framework**

crm:E52\_Time-Span  
  • crm:P86\_falls\_within\_(contains) → crm:E52\_Time-Span  
  • crm:P78\_is\_identified\_by\_(identifies) → crm:E49\_Time\_Appellation  
  • crm:P81\_ongoing throughout → crm:E61\_Time\_Primitive  
  • crm:P82\_at\_some\_time\_within → crm:E61\_Time\_Primitive

crm:E53\_Place  
  • P89\_falls\_within\_(contains) → E53\_Place  
  • P87\_is\_identified by\_(identifies) → E44\_Place\_Appellation  
  • P168\_place\_is\_defined\_by → E94\_Space\_Primitive