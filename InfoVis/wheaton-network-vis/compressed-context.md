# vis-core.js

## Primary Components

### Base Structure
- **Root SVG** 
  - hasProperty: width, height, viewBox
  - hasContainer: zoom-layer group
  - hasRelation: [parent, allVisualElements]

### Visual Elements Hierarchy
- **Zoom Layer Group**
  - hasProperty: transform matrix
  - hasChildren: [links, nodes, labels]
  - hasAction: zoomTransform

### Node System
- **Node Representation**
  - hasProperty: circle element
  - hasSize: baseRadius + sqrt(connections) * 2
  - hasMaxRadius: 15
  - hasRelation: [source, nodeData]
  - hasState: [normal, dragging]

## Event Management

### Zoom Behavior
- **Zoom Handler**
  - hasScale: [0.2, 4]
  - hasAction: transformGroup
  - hasEffect: labelVisibility
  - hasCondition: labels.display = k > 1.2

### Simulation Control
- **Force Management**
  - hasState: alpha
  - hasTarget: alphaTarget
  - hasAction: restart
  - hasRelation: [affects, nodePositions]


  # Visualization Core System
[previous structure remains...]

# vis-cupdate.js

## State Management

### Loading State
- **Overlay Controller** 
  - hasProperty: loading-overlay element
  - hasState: [visible, hidden]
  - hasAction: hideLoading
  - hasTransition: opacity 300ms

### Count Management
- **Node Type Counter**
  - hasAction: updateNodeTypeCounts
  - hasEffect: legend badges
  - hasDisplay: totalNodes

- **Visibility Counter**
  - hasAction: updateVisibleNodeCounts
  - hasMetrics: [visibleNodes, visibleEdges]
  - hasDisplay: counter elements

## Interactive Features

### Search System
- **Search Controller**
  - hasInput: searchInput element
  - hasAction: handleSearch
  - hasClear: clearSearch button
  - hasEffect: [nodeVisibility, linkVisibility]

### Filtering System
1. **Node Type Filters**
   - hasElements: legend-items
   - hasStates: [active, inactive]
   - hasEffect: [nodeDisplay, connectedLinks]

2. **Edge Type Filters**
   - hasElements: legend-item-filters
   - hasStates: [active, inactive]
   - hasEffect: linkDisplay

### Detail Display
- **Node Details**
  - hasTypes: [person, default]
  - hasProperties: [name, birth, death, faith]
  - hasDisplay: formatted HTML

- **Edge Details**
  - hasProperties: [type, source, target, date, note]
  - hasDisplay: formatted HTML

## Event Handlers

### Node Interactions
- **Hover Effects**
  - hasAction: showTooltip
  - hasHighlight: connectedElements
  - hasOpacity: [active: 1, inactive: 0.3]

- **Click Behavior**
  - hasAction: displayNodeDetails
  - hasEvent: stopPropagation

### Link Interactions
- **Hover Effects**
  - hasAction: showTooltip
  - hasStyle: [width: 3, opacity: 1]
  - hasReset: [width: 1.5, opacity: 0.6]

- **Click Behavior**
  - hasAction: displayEdgeDetails
  - hasEvent: stopPropagation

### Zoom Controls
- **Zoom Buttons**
  - zoomIn: scale 1.5
  - zoomOut: scale 0.75
  - resetZoom: fitToContainer

## Initialization

### Simulation Control
1. **Stability Check**
   - hasTimeout: 2000ms
   - hasAction: hideLoading
   - hasEffect: updateCounts

2. **Initial Setup**
   - updateNodeTypeCounts
   - updateVisibleNodeCounts