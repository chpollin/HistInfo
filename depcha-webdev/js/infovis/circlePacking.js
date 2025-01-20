/*    
 * author: Jakob Sonnberger
 * company: ZIM
 * purpose: Visualizing JSON data as Circle Packing
* last update: 02/2023
*/

function createCirclePacking(myJSON, myDivCSSSelector) {

    let myContainer = d3.select(myDivCSSSelector);

    // # Constructing Legend Div
    let myLegend = myContainer
        .append('div')
            .attr('id', 'myLegend')
            .style('margin-left', '55px')
            .style('margin-top', '10px');

    // ## Constructing Display Checkboxes
    let checkDebitDiv = myLegend
        .append('div')
            .classed('form-check', true);

    checkDebitDiv
        .append('input')
            .classed('form-check-input', true)
            .attr('type', 'checkbox')
            .attr('id', 'switchDebit')
            .style('background-color', 'orange')
            .attr('checked', 'checked')
            .on('change', function(){d3.selectAll('.debit').attr('visibility', this.checked ? 'visible' : 'hidden')});

    checkDebitDiv
        .append('label')
            .classed('form-check-label', true)
            .attr('for', 'switchDebit')
            .text('debit');

    let checkCreditDiv = myLegend
            .append('div')
                .classed('form-check', true);

    checkCreditDiv
            .append('input')
                .classed('form-check-input', true)
                .attr('type', 'checkbox')
                .attr('id', 'switchCredit')
                .attr('checked', 'checked')
                .style('background-color', 'cornflowerblue')
                .on('change', function(){d3.selectAll('.credit').attr('visibility', this.checked ? 'visible' : 'hidden')});

    checkCreditDiv
            .append('label')
                .classed('form-check-label', true)
                .attr('for', 'switchCredit')
                .text('credit');


    //parsing monetary values to float
    myJSON.forEach(d => {d.credit = parseFloat(d.credit);d.debit = parseFloat(d.debit)});

    let myCurrency = myJSON[0].unit;
    //console.log('Currency: ' + myCurrency);

    //--- Graph ---------------------------------------------------------------------------------------------------------------

    //chart dimensions
    const height = 600;
    const width = 600;

    let myDebits = myJSON.map(d => parseFloat(d.debit));
    
    let myCredits = myJSON.map(d => parseFloat(d.credit));

    let myMax  = d3.max(d3.merge([myDebits, myCredits]));

    //set SVG dimensions
    const mySVG = myContainer
        .append('svg')
            .attr('viewBox',[0, 0, width, height]);

    // set circle radia
    let getMyRadius = d3.scaleLinear()
        .domain([0, myMax])
        .range([0,100])  // circle radius will be between 0 and 100 px

    function circleMkr (sel, cat, color){
        sel
            .attr("cx", width / 2)
            .attr("cy", height / 2)
            .style("fill", color)
            .style("opacity", 1)
            .attr("n", d => d.date)
            .classed(cat, true)
            .on('mouseover', myMouseover)
            .on('mousemove', (event, d) => myMousemove(event, d.date + ' ' + cat + ': ' + myCurrencyFormat(d[cat], myCurrency)))
            .on('mouseleave', myMouseleave)
            .call(d3.drag() // call specific function when circle is dragged
                .on("start", dragStart)
                .on("drag", dragging)
                .on("end", dragEnd))
            .attr("r", d => getMyRadius(d[cat]));
    }

    //one group (g) for all circles & texts (to manage visibility)
    let g = mySVG
        .append('g');

    //create credit circles
    let myCreditCircles = g
            .selectAll('circleCredit')
                .data(myJSON)
                .join('circle')
                .call(circleMkr, 'credit', 'cornflowerblue');

    let myDebitCircles = g
            .selectAll('circleDebit')
                .data(myJSON)
                .join('circle')
                .call(circleMkr, 'debit', 'orange');

    //bring smaller circles to front if hidden by bigger circles
    myJSON.forEach(d => d.debit > d.credit ? d3.selectAll("circle.credit[n='" + d.date + "']").raise() : d3.select("circle.debit[n='" + d.date + "']").raise());

    //--- Captions ----------------------------------------------------------------------------------------------------------------
    let myCircleCaptions = g
        .selectAll('text')
        .data(myJSON)
        .join('text')
            .text(d => getMyRadius(d3.min([d.debit, d.credit])) > 20 ? d.date : '')
            .attr('x', width/2)
            .attr('y', height/2)
            .attr('text-anchor', 'middle')
            .attr('dominant-baseline', 'central')
            .attr("n", d => d.date)
            .style('font-size', d => getMyRadius(d3.min([d.debit, d.credit])/2.25) + 'px')
            .style('fill', 'white')
            .style('pointer-events', 'none');

    //default arrangement of circles
    let mySimulation = d3.forceSimulation()
        .force("center", d3.forceCenter().x(width / 2).y(height / 2)) // Attraction to the center of the svg area
        .force("charge", d3.forceManyBody().strength(5)) // Nodes are attracted one each other of value is > 0
        .force("collide", d3.forceCollide().strength(1).radius(d => getMyRadius(d3.max([d.credit, d.debit])))); // Force that avoids circle overlapping

    mySimulation
        .nodes(myJSON)
        .on("tick", function(d){
            myCreditCircles
                .attr("cx", d => d.x)
                .attr("cy", d => d.y);
            myDebitCircles
                .attr("cx", d => d.x)
                .attr("cy", d => d.y);
            myCircleCaptions
                .attr("x", d => d.x)
                .attr("y", d => d.y);
            //console.log(mySimulation.alpha());
        });

    //--- Tooltips ----------------------------------------------------------------------------------------------------------------

    //create (invisible) div for tooltips
    let myTooltip = myContainer
        .append('div')
            .style("position", "absolute")
            .style('display', 'none')
            .attr('class', 'myTooltip')
            .style('max-width', '200px')
            .style('background-color', 'FloralWhite')
            .style('font-size', '0.7em' )
            .style('padding', '5px')
            .style('pointer-events', 'none');

    function myMouseover() {
            myTooltip
                .style('display', 'block')
            d3.select(this)
                .style('stroke', 'black')
                .style('opacity', 0.5)
          };

    function myMousemove(myEvent, myTooltipText) {
    //set tooltip text & position (relative to pointer)
        myTooltip
            .text(myTooltipText)
            .style('left', myEvent.layerX + 'px')
            .style('top', myEvent.layerY - 30 + 'px');
    };

    function myMouseleave() {
        myTooltip
            .style('display', 'none');
        d3.select(this)
            .style('stroke', 'none')
            .style('opacity', 1);
    };

    // What happens when a circle is dragged?
    function dragStart(event, d) {
        event.active || mySimulation.alphaTarget(0.2).restart();
        d.fx = d.x;
        d.fy = d.y;
    }

    function dragging(event, d) {
        d.fx = event.x;
        d.fy = event.y;
        //set tooltip text & position (relative to pointer)
        myTooltip
            .style('left', (d3.pointer(event, mySVG.node())[0] + 20) + 'px')
            .style('top', (d3.pointer(event, mySVG.node())[1] + 50) + 'px');
    }

    function dragEnd(event, d) {
        event.active || mySimulation.alpha(1).alphaTarget(0);
        d.fx = null;
        d.fy = null;
    }
};
