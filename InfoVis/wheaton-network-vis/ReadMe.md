# Wheaton Network Visualization

## Project Overview
An interactive network visualization tool for exploring historical relationships in the Wheaton College dataset. This application visualizes complex relationships between people, locations, institutions, and commodities through an interactive force-directed graph.

## Technical Stack
- **D3.js** (v7) - Core visualization library
- **Bootstrap** (v5.3.0) - UI framework
- **Lodash** (v4.17.21) - Utility functions

## Project Structure
```
wheaton-network/
├── index.html              # Main HTML file
├── css/
│   └── style.css          # Styling
├── js/
│   ├── wheaton-network.js     # Source data
│   ├── data.js               # Data processing
│   ├── visualization-core.js  # D3.js setup
│   ├── node-details.js       # Node/edge details
│   ├── filter-handler.js     # Filter functionality
│   └── visualization-update.js # Update logic
└── README.md
```

## Core Components

### 1. Data Processing (data.js)
- Processes raw network data into D3.js compatible format
- Handles node type inference
- Calculates network metrics
- Features:
  - Node type detection
  - Connection counting
  - Data sanitization
  - Statistics calculation

### 2. Core Visualization (visualization-core.js)
- Manages D3.js force simulation
- Handles node and link rendering
- Features:
  - Force-directed layout
  - Zoom and pan
  - Drag functionality
  - Node/link styling
  - Tooltips

### 3. Filter Handler (filter-handler.js)
- Manages filtering functionality
- Updates visualization based on filters
- Features:
  - Multi-select filters
  - Show/hide functionality
  - Filter state management
  - Dynamic updates

### 4. Node Details (node-details.js)
- Handles node and edge detail display
- Manages interaction events
- Features:
  - Detail panel updates
  - Connected node highlighting
  - Information formatting

## Features

### Visualization
- Force-directed graph layout
- Interactive nodes and edges
- Color-coded node types:
  - Person (Blue)
  - Location (Green)
  - Institution (Orange)
  - Commodity (Purple)
- Color-coded relationship types:
  - Marriage (Pink)
  - Residence (Purple)
  - Education (Blue)
  - Commodity (Orange)
  - Service (Brown)

### Interaction
- Zoom and pan
- Node dragging
- Hover tooltips
- Click details
- Filter toggles
- Search functionality

### Data Display
- Network statistics
- Node/Edge type legends
- Detailed information panels
- Connection highlighting

## Setup Instructions

1. **Environment Setup**
   ```bash
   # Using Python
   python -m http.server 5500
   
   # Or using Node.js
   npx http-server
   ```

2. **File Structure Setup**
   - Create project directories
   - Place files in appropriate locations
   - Ensure proper file permissions

3. **Dependencies**
   - Add required CDN links
   - Verify script loading order
   - Check for version compatibility

## Usage Guide

### Basic Navigation
1. Use mouse wheel to zoom
2. Click and drag background to pan
3. Drag nodes to reposition
4. Click nodes/edges for details

### Filtering
1. Use filter buttons to show/hide relationships
2. Multiple filters can be active
3. "Show All" resets filters
4. Statistics update automatically

### Search
1. Type in search box to find nodes
2. Clear button resets search
3. Results update in real-time

### Details
1. Click nodes for detailed information
2. Click edges for relationship details
3. Connected nodes highlight automatically

## Customization

### Visual Styling
- Modify style.css for appearance changes
- Adjust node/edge colors in visualization-core.js
- Customize tooltip content

### Layout
- Adjust force simulation parameters
- Modify node spacing
- Change initial positioning

### Data Display
- Customize detail panel format
- Modify tooltip content
- Adjust statistics display

## Performance Considerations

### Optimization
- Debounced search and filter operations
- Efficient D3.js selections
- Optimized force simulation parameters

### Browser Support
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Troubleshooting

### Common Issues
1. **Visualization not appearing**
   - Check console for errors
   - Verify data loading
   - Check container dimensions

2. **Performance issues**
   - Adjust force simulation parameters
   - Reduce number of visible elements
   - Check browser performance

3. **Filter not working**
   - Verify event listeners
   - Check filter state management
   - Console log filter operations

## Contributing
1. Fork repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## License
MIT License - See LICENSE file for details