Bookkeeping Ontology bk: <https://gams.uni-graz.at/o:depcha.bookkeeping#>
Representation of economic transactions in historical financial sources for historical research.
Legend
isA: Class inheritance (e.g., A isA B means A inherits from B)
@: Property with datatype (e.g., name @string)
→: Object property/relationship (points to target class)
[min..max]: Cardinality constraint (e.g., [0..1] = optional single, [1..*] = one or more)
crm: CIDOC-CRM namespace
rea: REA model namespace
xsd: XML Schema datatypes
Transaction Framework
Transaction isA crm:E7_Activity, rea:EconomicEvent
  // Definition: A discrete economic event consisting of one or more resource transfers between economic agents, occurring at a specific time or place, documented through formal entries, where each transfer represents a distinct movement of economic value.
  • status → TransactionStatus [0..1]
  • consistsOf → Transfer [1..*]
  • when → crm:E52_Time-Span [0..1]
  • where → crm:E53_Place [0..1]
  • entry → Entry [1..1]

SubtotalTransaction isA Transaction 
  // Definition: A transaction that represents the aggregate economic value of a specified subset of other transactions, differentiated by explicit grouping criteria.
  • summarizes → Transaction [1..*] 
  • groupingCriteria @string [0..1]

TotalTransaction isA Transaction 
  // Definition: A transaction that represents the complete aggregate economic value of all constituent transactions within a defined scope, including their subtotals.
  • summarizes → Transaction [1..]  
  • includesSubtotals → SubtotalTransaction [0..]  
  • scope @string [0..1]  // describes what this total represents

Transfer isA crm:E7_Activity
  // Definition: An atomic economic event representing the reassignment of control over one or more economic resources from one economic agent to another, characterised by a direction and specific resources involved, occurring within the context of a defined transaction.
  • from → EconomicAgent [0..1] // economic resource FROM executing agent
  • to → EconomicAgent [0..1]  // economic resource TO executing age
  • transfers → EconomicResource [1..*]
  • sourceMention → AgentMention [0..*]
  • accountingRecord → AccountingRecord [0..*]

LiabilityTransfer isA Transfer
  // Definition: A transfer whose essential purpose is the extinction of a specific liability through the movement of economic resources from obligor to obligee.
  • settles → Liability [1..1]

ServiceDelivery isA Transfer
  // Definition: The concrete execution of a service by one economic agent for another, transforming a service right into delivered value through a specific activity
  • fulfills → ServiceRight [0..*]

Entry isA crm:E73_Information_Object, prov:Entity
  // Definition: An information object that documents a specific transaction through structured textual representation within a source document, with provenance tracking of its creation and interpretation.
  • text @string [1..1]
  • source → E31_Document [1..1]
  • prov:wasGeneratedBy → prov:Activity [1..1]  // The transcription/research activity
  • prov:wasAttributedTo → prov:Agent [1..*]    // Who created/interpreted this entry
  • prov:generatedAtTime @xsd:dateTime [1..1]   // When this entry was recorded/transcribed

AgentMention isA crm:E13_Attribute_Assignment
  // Definition: An attribute assignment that associates a textual reference to an economic agent in a source document with both its formal actor representation and its contextual role classification.
  • agentOf → EconomicAgent [1..1]  // Links to the formal economic agent representation
  • agent → crm:E39_Actor [1..1] // The actual actor mentioned or performing the action
  • entry → Entry [1..1] // The textual reference as found in the source
  • role → skos:Concept [1..1]  // The role classification of the agent (e.g., "Executor")

TransactionStatus isA skos:Concept
  // Definition: A concept that represents the state of a transaction's completion and verification in historical records, providing a controlled vocabulary for transaction processing states.
  • skos:prefLabel @string [1..1]
  • skos:definition @string [0..1]
  • skos:broader → TransactionStatus [0..]
  • skos:narrower → TransactionStatus [0..]
  • skos:altLabel @string [0..]

Agent Framework
EconomicAgent isA crm:E39_Actor, rea:EconomicAgent
  // Definition: An actor that has the capacity to control economic resources and participate in transfers, characterized by autonomous decision-making authority over economic resources and the ability to incur obligations.

Individual isA EconomicAgent, crm:E21_Person
  // Definition: An economic agent that acts as a singular, indivisible decision-making entity, distinguished by direct and personal control over resources and obligations.

Group isA EconomicAgent, crm:E74_Group
  // Definition: An economic agent that operates through collective decision-making of multiple individuals, characterised by shared control over resources and joint responsibility for obligations.
Economic Resource Framework
EconomicResource isA crm:E72_Legal_Object, rea:EconomicResource
  // Definition: A quantifiable economic value under the control of an economic entity that can be transferred between entities and has defined economic characteristics.

PhysicalResource isA EconomicResource
  // Definition: A tangible economic resource that can be physically possessed and measured.
  • quantity @xsd:decimal [> 0]
  • unit → Unit [1..1]

EconomicGood isA PhysicalResource
  // Definition: Physical resources quantifiable in standardised units of measurement.

Money isA PhysicalResource
  // Definition: Physical medium of exchange and unit of account.
Rights and Liabilities
Right isA EconomicResource, crm:E30_Right
  // Definition: A legally binding claim to receive a specified service, representing both an economic resource that can be exchanged and a legal right that can be enforced within defined temporal bounds.
  • validityPeriod → crm:E52_Time-Span [0..1]

ActionRight isA Right
  // Definition: Transferable claim to perform quantifiable economic activities.

ClaimRight isA Right
  // Definition: Transferable claim to receive quantifiable economic resources.
  • resource → EconomicResource [1..1]

ServiceRight isA Right
  // Definition: A right that grants its holder the authority to receive specific services from a designated economic agent, where the service delivery constitutes the fulfilment of the right.

Liability isA crm:E28_Conceptual_Object
  // Definition: An economic obligation that involves a specified economic resource, an obligor who must transfer it, and an obligee who must receive it, bounded by temporal constraints.
  • obligor → EconomicAgent [1..1]
  • obligee → EconomicAgent [1..1]
  • dueDate @xsd:dateTime [0..1]
  • resource → EconomicResource [1..1]
Measurement Framework
Unit isA crm:E58_Measurement_Unit
  // Definition: A measurement unit that combines an identifying label with a specific dimensional type, serving as a standardised basis for quantifying economic resources.
  • label @string [1..1]          
  • type → UnitType [1..1]

UnitMention isA crm:E13_Attribute_Assignment
  // Definition: An attribute assignment that associates a textual expression of measurement in a source document with its formal unit definition and documentary context.
  • refersTo → Unit [1..1]       
  • source → E31_Document [1..1] 
  • text @string [1..1]

UnitType isA skos:Concept 
  // Definition: A concept that categorizes measurement units according to their fundamental dimensional nature, constrained to the exhaustive set of Length, Weight, Volume, Area, Currency, Time, or Count.
  • Length 
  • Weight 
  • Volume 
  • Area 
  • Currency 
  • Time 
  • Count

Conversion isA crm:E28_Conceptual_Object 
  // Definition: A conceptual object that defines the mathematical transformation between two specific units through a deterministic formula.
  • convertsFrom → Unit [1..1]   
  • convertsTo → Unit [1..1]     
  • formula @string [1..1]

MoneyAmount isA crm:E97_Monetary_Amount
  // Definition: A quantified economic value that is expressed in a specific currency unit, serving as a measure of economic worth in transactions and accounts.
  • value @xsd:decimal [> 0]
  • unit → Unit [1..1]

Accounting Framework

AccountingRecord isA crm:E73_Information_Object
  // Definition: An information object that documents an economic transfer through paired debit and credit entries, representing the bidirectional flow of economic value.
   • debit → AccountingEntry
   • credit → AccountingEntry
   • documents → Transfer [1..1]
   • period → crm:E52_Time-Span [0..1]

AccountingEntry isA crm:E73_Information_Object
  // Definition: An information object that represents one side of an economic value flow through a specific monetary amount, optionally enriched with textual description and categorical classification.
  • involves → MoneyAmount [1..1]
  • text @string [0..1]
  • category → AccountCategory [0..1]

AccountCategory isA skos:Concept
  // Definition: A concept that defines a specific type of economic value flow within a hierarchical classification system, characterized by a preferred label and optional explanatory elements
  • skos:prefLabel @string [1..1] 
  • skos:definition @string [0..1]
  • skos:broader → AccountCategory [0..]
  • skos:narrower → AccountCategory [0..] 
  • skos:altLabel @string [0..]
Temporal-Spatial Context Framework

crm:E52_Time-Span
  • crm:P86_falls_within_(contains) → crm:E52_Time-Span
  • crm:P78_is_identified_by_(identifies) → crm:E49_Time_Appellation
  • crm:P81_ongoing throughout → crm:E61_Time_Primitive
  • crm:P82_at_some_time_within → crm:E61_Time_Primitive

crm:E53_Place
  • P89_falls_within_(contains) → E53_Place
  • P87_is_identified by_(identifies) → E44_Place_Appellation
  • P168_place_is_defined_by → E94_Space_Primitive

Example
´´´
@prefix bk: <https://gams.uni-graz.at/o:depcha.bookkeeping#> .
@prefix crm: <http://www.cidoc-crm.org/cidoc-crm/> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix rea: <http://www.example.org/rea#> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix : <https://gams.uni-graz.at/context:depcha#> .

### Agents
:merchantGuild a bk:Group, crm:E74_Group, rea:EconomicAgent ;
    rdfs:label "Merchant Guild of Venice"@en ;
    crm:P76_has_contact_point "Rialto Market, Venice" .

:tailor a bk:Individual, crm:E21_Person, rea:EconomicAgent ;
    rdfs:label "Master Tailor Giovanni"@en ;
    crm:P76_has_contact_point "San Marco District, Venice" .

### Resources
:grainSack a bk:EconomicGood, bk:PhysicalResource, crm:E72_Legal_Object, rea:EconomicResource ;
    rdfs:label "Sack of Grain"@en ;
    bk:quantity "50.0"^^xsd:decimal ;
    bk:unit :weightUnit .

:weightUnit a bk:Unit, crm:E58_Measurement_Unit ;
    rdfs:label "Venetian Pound"@en ;
    bk:label "VenetianPound" ;
    bk:type :WeightType .

:WeightType a bk:UnitType, skos:Concept ;
    skos:prefLabel "Weight"@en ;
    skos:inScheme :unitTypeScheme .

:unitTypeScheme a skos:ConceptScheme ;
    rdfs:label "Unit Type Classification"@en .

:florinCurrency a bk:Unit, crm:E58_Measurement_Unit ;
    rdfs:label "Florin"@en ;
    bk:label "Florin" ;
    bk:type :CurrencyType .

:CurrencyType a bk:UnitType, skos:Concept ;
    skos:prefLabel "Currency"@en ;
    skos:inScheme :unitTypeScheme .

### Time Period
:year1540 a crm:E52_Time-Span ;
    crm:P78_is_identified_by :year1540_label ;
    crm:P81_ongoing_throughout "1540"^^xsd:gYear ;
    crm:P82_at_some_time_within "1540"^^xsd:gYear .

:year1540_label a crm:E49_Time_Appellation ;
    rdfs:label "Year 1540"@en .

### Rights and Claims
:annualClaimRight a bk:ClaimRight, bk:Right, crm:E30_Right, bk:EconomicResource ;
    rdfs:label "Annual Grain Delivery Right"@en ;
    bk:resource :grainSack ;
    bk:validityPeriod :year1540 .

:serviceRightTailoring a bk:ServiceRight, bk:Right, crm:E30_Right, bk:EconomicResource ;
    rdfs:label "Tailoring Service Right"@en ;
    bk:validityPeriod :year1540 .

:liabilityToTailor a bk:Liability, crm:E28_Conceptual_Object ;
    rdfs:label "Payment Liability to Tailor"@en ;
    bk:obligor :merchantGuild ;
    bk:obligee :tailor ;
    bk:dueDate "1540-12-31T23:59:59Z"^^xsd:dateTime ;
    bk:resource :moneyDebt .

:moneyDebt a bk:Money, bk:PhysicalResource, bk:EconomicResource, crm:E72_Legal_Object ;
    rdfs:label "Monetary Debt"@en ;
    bk:quantity "100.0"^^xsd:decimal ;
    bk:unit :florinCurrency .

### Transaction Status
:transactionStatusScheme a skos:ConceptScheme ;
    rdfs:label "Transaction Status Classification"@en .

:completedStatus a bk:TransactionStatus, skos:Concept ;
    skos:prefLabel "Completed"@en ;
    skos:definition "The transaction is fully settled and verified in the records."@en ;
    skos:inScheme :transactionStatusScheme .

### Transactions
:annualTotalTransaction a bk:TotalTransaction, bk:Transaction, crm:E7_Activity, rea:EconomicEvent ;
    rdfs:label "Annual Settlement 1540"@en ;
    bk:status :completedStatus ;
    bk:consistsOf :transfer1, :transfer2, :liabilitySettlement, :serviceDeliveryAction ;
    bk:when :year1540 ;
    bk:where :venice ;
    bk:entry :annualEntry ;
    bk:summarizes :januaryToJuneSubtotal, :julyToDecemberSubtotal ;
    bk:includesSubtotals :januaryToJuneSubtotal, :julyToDecemberSubtotal ;
    bk:scope "Final yearly settlement of accounts 1540" .

:januaryToJuneSubtotal a bk:SubtotalTransaction, bk:Transaction, crm:E7_Activity, rea:EconomicEvent ;
    rdfs:label "January-June Subtotal 1540"@en ;
    bk:consistsOf :transfer1 ;
    bk:summarizes :transfer1 ;
    bk:groupingCriteria "Jan-Jun 1540" .

:julyToDecemberSubtotal a bk:SubtotalTransaction, bk:Transaction, crm:E7_Activity, rea:EconomicEvent ;
    rdfs:label "July-December Subtotal 1540"@en ;
    bk:consistsOf :transfer2 ;
    bk:summarizes :transfer2 ;
    bk:groupingCriteria "Jul-Dec 1540" .

### Transfers
:transfer1 a bk:Transfer, crm:E7_Activity ;
    rdfs:label "First Grain Transfer"@en ;
    bk:from :merchantGuild ;
    bk:to :tailor ;
    bk:transfers :grainSack ;
    bk:sourceMention :agentMentionGuild, :agentMentionTailor ;
    bk:accountingRecord :transfer1Record .

:transfer2 a bk:Transfer, crm:E7_Activity ;
    rdfs:label "Second Grain Transfer"@en ;
    bk:from :merchantGuild ;
    bk:to :tailor ;
    bk:transfers :grainSack ;
    bk:sourceMention :agentMentionGuild, :agentMentionTailor ;
    bk:accountingRecord :transfer2Record .

:liabilitySettlement a bk:LiabilityTransfer, bk:Transfer, crm:E7_Activity ;
    rdfs:label "Liability Settlement"@en ;
    bk:from :merchantGuild ;
    bk:to :tailor ;
    bk:transfers :moneyDebt ;
    bk:settles :liabilityToTailor ;
    bk:sourceMention :agentMentionGuild, :agentMentionTailor ;
    bk:accountingRecord :liabilityRecord .

:serviceDeliveryAction a bk:ServiceDelivery, bk:Transfer, crm:E7_Activity ;
    rdfs:label "Tailoring Service Delivery"@en ;
    bk:from :tailor ;
    bk:to :merchantGuild ;
    bk:fulfills :serviceRightTailoring ;
    bk:sourceMention :agentMentionGuild, :agentMentionTailor ;
    bk:accountingRecord :serviceRecord .

### Source Documents and Entries
:annualLedger a crm:E31_Document ;
    rdfs:label "Venice Merchant Guild Annual Ledger 1540"@en .

:transcriptionActivity a prov:Activity ;
    rdfs:label "Ledger Transcription"@en ;
    prov:startedAtTime "2021-01-01T09:00:00Z"^^xsd:dateTime ;
    prov:endedAtTime "2021-01-01T17:00:00Z"^^xsd:dateTime ;
    prov:wasAssociatedWith :researcherAgent .

:researcherAgent a prov:Agent, crm:E21_Person ;
    rdfs:label "Dr. Maria Researcher"@en ;
    crm:P76_has_contact_point "University of Venice" .

:annualEntry a bk:Entry, crm:E73_Information_Object, prov:Entity ;
    rdfs:label "Annual Settlement Entry"@en ;
    bk:text "Annual settlement transaction recorded in the ledger for year 1540" ;
    bk:source :annualLedger ;
    prov:wasGeneratedBy :transcriptionActivity ;
    prov:wasAttributedTo :researcherAgent ;
    prov:generatedAtTime "2021-01-01T12:00:00Z"^^xsd:dateTime .

### Agent Roles and Mentions
:agentRoleScheme a skos:ConceptScheme ;
    rdfs:label "Agent Role Classification"@en .

:executorRole a skos:Concept ;
    skos:prefLabel "Executor"@en ;
    skos:definition "Agent executing the transaction"@en ;
    skos:inScheme :agentRoleScheme .

:agentMentionGuild a bk:AgentMention, crm:E13_Attribute_Assignment ;
    rdfs:label "Guild Mention in Entry"@en ;
    bk:agentOf :merchantGuild ;
    bk:agent :merchantGuildActor ;
    bk:entry :annualEntry ;
    bk:role :executorRole .

:merchantGuildActor a crm:E39_Actor ;
    rdfs:label "Merchant Guild as Referenced in Source"@en .

:agentMentionTailor a bk:AgentMention, crm:E13_Attribute_Assignment ;
    rdfs:label "Tailor Mention in Entry"@en ;
    bk:agentOf :tailor ;
    bk:agent :tailorActor ;
    bk:entry :annualEntry ;
    bk:role :executorRole .

:tailorActor a crm:E39_Actor ;
    rdfs:label "Tailor as Referenced in Source"@en .

### Accounting Records
:accountCategoryScheme a skos:ConceptScheme ;
    rdfs:label "Account Category Classification"@en .

:transfer1Record a bk:AccountingRecord, crm:E73_Information_Object ;
    rdfs:label "First Transfer Record"@en ;
    bk:documents :transfer1 ;
    bk:debit :transfer1Debit ;
    bk:credit :transfer1Credit ;
    bk:period :year1540 .

:transfer1Debit a bk:AccountingEntry, crm:E73_Information_Object ;
    rdfs:label "First Transfer Debit Entry"@en ;
    bk:involves :transfer1MoneyAmount ;
    bk:text "Debit entry for first grain transfer" ;
    bk:category :assetCategory .

:transfer1Credit a bk:AccountingEntry, crm:E73_Information_Object ;
    rdfs:label "First Transfer Credit Entry"@en ;
    bk:involves :transfer1MoneyAmount ;
    bk:text "Credit entry for first grain transfer" ;
    bk:category :liabilityCategory .

:transfer1MoneyAmount a bk:MoneyAmount, crm:E97_Monetary_Amount ;
    rdfs:label "First Transfer Amount"@en ;
    bk:value "100.0"^^xsd:decimal ;
    bk:unit :florinCurrency .

:transfer2Record a bk:AccountingRecord, crm:E73_Information_Object ;
    rdfs:label "Second Transfer Record"@en ;
    bk:documents :transfer2 ;
    bk:debit :transfer2Debit ;
    bk:credit :transfer2Credit ;
    bk:period :year1540 .

:transfer2Debit a bk:AccountingEntry, crm:E73_Information_Object ;
    rdfs:label "Second Transfer Debit Entry"@en ;
    bk:involves :transfer2MoneyAmount ;
    bk:text "Debit entry for second grain transfer" ;
    bk:category :expenseCategory .

:transfer2Credit a bk:AccountingEntry, crm:E73_Information_Object ;
    rdfs:label "Second Transfer Credit Entry"@en ;
    bk:involves :transfer2MoneyAmount ;
    bk:text "Credit entry for second grain transfer" ;
    bk:category :revenueCategory .

:transfer2MoneyAmount a bk:MoneyAmount, crm:E97_Monetary_Amount ;
    rdfs:label "Second Transfer Amount"@en ;
    bk:value "50.0"^^xsd:decimal ;
    bk:unit :florinCurrency .

:liabilityRecord a bk:AccountingRecord, crm:E73_Information_Object ;
    rdfs:label "Liability Settlement Record"@en ;
    bk:documents :liabilitySettlement ;
    bk:debit :liabilityDebit ;
    bk:credit :liabilityCredit ;
    bk:period :year1540 .

:liabilityDebit a bk:AccountingEntry, crm:E73_Information_Object ;
    rdfs:label "Liability Settlement Debit Entry"@en ;
    bk:involves :liabilityMoneyAmount ;
    bk:category :liabilityCategory .

:liabilityCredit a bk:AccountingEntry, crm:E73_Information_Object ;
    rdfs:label "Liability Settlement Credit Entry"@en ;
    bk:involves :liabilityMoneyAmount ;
    bk:category :assetCategory .

:liabilityMoneyAmount a bk:MoneyAmount, crm:E97_Monetary_Amount ;
    rdfs:label "Liability Settlement Amount"@en ;
    bk:value "100.0"^^xsd:decimal ;
    bk:unit :florinCurrency .

:serviceRecord a bk:AccountingRecord, crm:E73_Information_Object ;
    rdfs:label "Service Delivery Record"@en ;
    bk:documents :serviceDeliveryAction ;
    bk:debit :serviceDebit ;
    bk:credit :serviceCredit ;
    bk:period :year1540 .

:serviceDebit a bk:AccountingEntry, crm:E73_Information_Object ;
    rdfs:label "Service Delivery Debit Entry"@en ;
    bk:involves :serviceMoneyAmount ;
    bk:category :expenseCategory .

:serviceCredit a bk:AccountingEntry, crm:E73_Information_Object ;
    rdfs:label "Service Delivery Credit Entry"@en ;
    bk:involves :serviceMoneyAmount ;
    bk:category :revenueCategory .

:serviceMoneyAmount a bk:MoneyAmount, crm:E97_Monetary_Amount ;
    rdfs:label "Service Delivery Amount"@en ;
    bk:value "10.0"^^xsd:decimal ;
    bk:unit :florinCurrency .

### Account Categories
:assetCategory a bk:AccountCategory, skos:Concept ;
    skos:prefLabel "Assets"@en ;
    skos:definition "Resources owned by or owed to the economic agent"@en ;
    skos:inScheme :accountCategoryScheme .
    
:liabilityCategory a bk:AccountCategory, skos:Concept ;
    skos:prefLabel "Liabilities"@en ;
    skos:definition "Obligations owed by the economic agent"@en ;
    skos:inScheme :accountCategoryScheme .

:expenseCategory a bk:AccountCategory, skos:Concept ;
    skos:prefLabel "Expenses"@en ;
    skos:definition "Costs incurred in economic activities"@en ;
    skos:inScheme :accountCategoryScheme .

:revenueCategory a bk:AccountCategory, skos:Concept ;
    skos:prefLabel "Revenue"@en ;
    skos:definition "Income earned from economic activities"@en ;
    skos:inScheme :accountCategoryScheme .

### Place
:venice a crm:E53_Place ;
    rdfs:label "Venice"@en ;
    crm:P87_is_identified_by :veniceAppellation .

:veniceAppellation a crm:E44_Place_Appellation ;
    rdfs:label "Venice, Republic of Venice"@en .

### Unit Conversion
:currencyConversion a bk:Conversion, crm:E28_Conceptual_Object ;
    rdfs:label "Florin to Ducat Conversion"@en ;
    bk:convertsFrom :florinCurrency ;
    bk:convertsTo :ducatCurrency ;
    bk:formula "value_in_florins * 1.2 = value_in_ducats" .

:ducatCurrency a bk:Unit, crm:E58_Measurement_Unit ;
    rdfs:label "Venetian Ducat"@en ;
    bk:label "Ducat" ;
    bk:type :CurrencyType .
´´´

