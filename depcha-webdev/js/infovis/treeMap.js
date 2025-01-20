/*    
 * author: Jakob Sonnberger
 * company: ZIM
 * purpose: Visualizing JSON data as Treemap
* last update: 03/2023
*/

function createTreeMap(myJSON, myDivCSSSelector) {

    let myContainer = d3.select(myDivCSSSelector);

    //--- Legend (checkboxes, radios etc. ) ---------------------------------------------------------------------------------------------------------------

    // # Constructing Legend Div
    let myLegend = myContainer
        .append('div')
            .attr('id', 'myLegend')
            .style('margin-left', '55px')
            .style('margin-top', '10px');
    
    // ## Constructing Display Checkboxes
    let radioCreditDiv = myLegend
        .append('div')
            .classed('form-check', true);
    
    let radioCredit = radioCreditDiv
        .append('input')
            .classed('form-check-input', true)
            .attr('type', 'radio')
            .attr('name', 'radioSwitch')
            .attr('id', 'radioCredit')
            .attr('checked', 'checked')
            .on('click', () => reDraw('credit', 'orange'));
    
    radioCreditDiv
        .append('label')
            .classed('form-check-label', true)
            .attr('for', 'radioCredit')
            .text('Credit');
    
    let radioDebitDiv = myLegend
        .append('div')
            .classed('form-check', true);
        
    let radioDebit = radioDebitDiv
        .append('input')
            .classed('form-check-input', true)
            .attr('type', 'radio')
            .attr('name', 'radioSwitch')
            .attr('id', 'radioDebit')
            .on('click', () => reDraw('debit', 'cornflowerblue'));

    radioDebitDiv
        .append('label')
            .classed('form-check-label', true)
            .attr('for', 'radioDebit')
            .text('Debit');

    //--- Graph ---------------------------------------------------------------------------------------------------------------
    
    //chart dimensions
    const height = 600;
    const width = 600;
    
    //set SVG dimensions
    let mySVG = myContainer
        .append('svg')
        .attr('viewBox',[0, 0, width, height])

    //parsing monetary values to float
    myJSON.forEach(d => {d.credit = parseFloat(d.credit);d.debit = parseFloat(d.debit)});

    let myCurrency = myJSON[0].unit;
    //console.log('Currency: ' + myCurrency);

    //creating hierarchy for treemap
    let root = d3.hierarchy(d3.group(myJSON, d => d.credit)).sum(d => d.credit);

    let myTreeMap = d3.treemap()
        .size([500, 500])
        .padding(2);
    
    function rectMkr(sel, color){
        sel
            .attr('x', d => d.x0 + 50)
            .attr('y', d => d.y0 + 50)
            .attr('height', d => d.y1 - d.y0)
            .attr('width', d => d.x1 - d.x0)
            .style('stroke', 'none')
            .style('fill', color)
            .on('click', (event, d) => setDatatableFilter(d.data.date));
    };
    
    //create rects (for credit first)
    mySVG
        .append('g')
        .classed('rects', true)
        .selectAll('rect')
            .data(myTreeMap(root).leaves())
            .join('rect')
            .call(rectMkr, 'orange')
            .on('mouseover', myMouseover)
            .on('mousemove', (event, d) => myMousemove(event, d.data.date + ': ' + myCurrencyFormat(d.data.credit, myCurrency)))
            .on('mouseleave', myMouseleave);
    
    function captMkr(sel){
        sel
            .attr('x', d =>  d.x0 + 50 + 5) //+ svg-margin + indenting
            .attr('y', d => d.y0 + 50 + 15) //+ svg-margin + indenting
            .text(d =>  d.data.date)
            .style('display', d => d.x1 - d.x0 > 40 && d.y1 - d.y0 > 20 ? 'block' : 'none') //show caption only if box-size > 40 x 20
            .attr('font-size', '0.7em')
            .attr('fill', 'white');
    };

    //create box captions (for credit first)
    mySVG
        .append('g')
        .classed('texts', true)
        .style('pointer-events', 'none')
        .selectAll('text')
            .data(root.leaves())
            .join('text')
            .call(captMkr);
    
    function myMouseover() {
            myTooltip
                .style('display', 'block')
            d3.select(this)
                .style('stroke', 'black')
                .style('opacity', 0.5)
          };
          
    //set tooltip text & position (relative to pointer)
    function myMousemove(myEvent, myTooltipText) {
        myTooltip
            .text(myTooltipText)
            .style('left', myEvent.layerX + 'px')
            .style('top', myEvent.layerY - 30 + 'px');
    };
    
    function myMouseleave() {
        myTooltip
            .style('display', 'none')
        d3.select(this)
            .style('stroke', 'none')
            .style('opacity', 1)
    };

    //--- Tooltips ----------------------------------------------------------------------------------------------------------------

    //create (invisible) div for tooltips
    let myTooltip = myContainer
        .append('div')
            .style("position", "absolute")
            .style('pointer-events', 'none')
            .style('display', 'none')
            .classed('myTooltip', true)
            .style('max-width', '200px')
            .style('background-color', 'FloralWhite')
            .style('font-size', '0.7em' )
            .style('padding', '5px')
            .style('pointer-events', 'none');
    
    //--- Graph update ----------------------------------------------------------------------------------------------------------------
    function reDraw(cat, color){
        root = d3.hierarchy(d3.group(myJSON, d => d[cat])).sum(d => d[cat]);
        mySVG
            .select('g.rects')
                .selectAll('rect')
                    .data(myTreeMap(root).leaves())        
                    .join(
                            enter => enter.call(rectMkr, color).append('rect'), 
                            update => update.transition().duration(1000).call(rectMkr, color), 
                            exit => exit.remove()
                        )
                    .on('mousemove', (event, d) => myMousemove(event, d.data.date + ': ' + myCurrencyFormat(d.data[cat], myCurrency)));
                
        mySVG
            .select('g.texts')
                .selectAll('text')
                    .data(myTreeMap(root).leaves())
                    .join(
                            enter => enter.call(captMkr).append('text'), 
                            update => update.transition().duration(1000).call(captMkr), 
                            exit => exit.remove()
                        );
    }
};