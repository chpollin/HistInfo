/*    
 * author: Jakob Sonnberger
 * company: ZIM
 * purpose: Visualizing depcha JSON data as Linechart
* last update: 06/2022
*/

function createLineChart(myJSON, myDivCSSSelector) {

    /* //ACHTUNG: Visualsierung auf 18.Jhd 1740 - 1800 beschränkt!!! 
    myJSON = myJSON.filter(d => d.date >= 1740 && d.date <= 1800); */
    
    let myCurrency = myJSON[0].unit;
    //console.log('Currency: ' + myCurrency);

    //sort JSON entries by date
    myJSON = myJSON.sort((a, b) => parseInt(a.date) - parseInt(b.date));

	//chart dimensions
	const height = 600;
	const width = 800;

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
            .attr('for', 'switchCredit')
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
                .attr('for', 'switchDebit')
                .text('credit');

    // ## Constructing Scale switch
    let mySwitchScaleDiv = myLegend
        .append('div')
            .classed('form-check form-switch', true);
    
    mySwitchScaleDiv
        .append('input')
            .classed('form-check-input', true)
            .attr('type', 'checkbox')
            .attr('id', 'switchScale')
            .on('change', function(){
                //...switching scale & switch label...
                [y, y1] = [y1, y];
                [scaleLabel, scaleLabel1] = [scaleLabel1, scaleLabel];
                
                //...transform  y-position of circles...
                mySVG
                    .selectAll('circle.credit')
                    .transition().duration(1000).ease(d3.easeBack)
                    .attr('cy', (item, index) => y(item.credit));
                    
                mySVG
                    .selectAll('circle.debit').
                    transition().duration(1000).ease(d3.easeBack)
                    .attr('cy', (item, index) => y(item.debit));
                    
                //...transform y-position of paths...
                mySVG
                    .selectAll('path.credit')
                    .transition().duration(1000).ease(d3.easeBack)
                    .attr('d', d3.area()
                        .x(d => x(d.date))
                        .y0(y(0))//close area
                        .y1(d => y(d.credit)))
                    
                mySVG
                    .selectAll('path.debit').
                    transition().duration(1000).ease(d3.easeBack)
                    .attr('d', d3.area()
                        .x(d => x(d.date))
                        .y0(y(0))//close area
                        .y1(d => y(d.debit)))
                
                //...transform y-Axis...
                mySVG.select('g.yAxis')
                    .transition().duration(1000).ease(d3.easeBack)
                    .call(d3.axisLeft(y).tickFormat(d => myCurrencyFormat(d, myCurrency)));
                    
                //...and change label of switch
                mySwitchScaleLabel
                    .text(scaleLabel);
            });

    let mySwitchScaleLabel = mySwitchScaleDiv
        .append('label')
            .attr('id', 'switchScaleLabel')
            .classed('form-check-label', true)
            .attr('for', 'switchScale')
            .text('exponential scale');

	let mySVG = d3.select(myDivCSSSelector)
		.append('svg')
            .attr('viewBox',[0, 0, width, height]);
		
    let myDebits = myJSON.map(d => parseFloat(d.debit));
    
    let myCredits = myJSON.map(d => parseFloat(d.credit));
    
    let myDates = myJSON.map(d => d.date);
    
    //linear scaling for x-Axis
	let x = d3.scaleLinear()
        .domain(d3.extent(myDates))
        .range([75, width - 50]);
    
    //exponential scaling for y-Axis
    let y = d3.scalePow()
        .exponent(0.25)
        .domain([0, d3.max(d3.merge([myDebits, myCredits]))]) //geht das einfacher?
        .range([height - 50,50]);
    
    let scaleLabel = 'exponential scale';
    
    let y1 = d3.scaleLinear()
        .domain([0, d3.max(d3.merge([myDebits, myCredits]))]) //geht das einfacher?
        .range([height - 50,50]);
        
    let scaleLabel1 = 'linear scale';

    function circleMkr(sel, cat, color){
        sel
            .classed(cat, true)
            .attr("cx", d => x(d.date))
            .attr("cy", d => y(d[cat]))
            .attr("r", 5)
            .style('opacity', 0.5)
            .attr('stroke', color)
            .attr('stroke-width', 2.5)
            .attr('fill', color)
            .on('mouseover', myMouseover)
            .on('mousemove', (event, d) => myMousemove(event, d.date + ' ' + cat + ': ' + myCurrencyFormat(d[cat], myCurrency)))
            .on('mouseleave', myMouseleave);
    }

    //Credit circles
    mySVG
        .append("g")
            .selectAll("circle")
            .data(myJSON)
            .join("circle")
            .call(circleMkr, 'credit', 'cornflowerblue')
    
    //Debit circles
    mySVG
        .append("g")
            .selectAll("circle")
            .data(myJSON)
            .join("circle")
                .call(circleMkr, 'debit', 'orange');

    function pathMkr(sel, cat, color, fillColor){
        sel
            .style('pointer-events', 'none')
            .classed(cat, true)
            .datum(myJSON)
            .style('opacity', 0.5)
            .attr('stroke', color)
            .attr('stroke-width', 2.5)
            .attr('fill', fillColor)
            .attr('d', d3.area()
			    .x(d => x(d.date))
			    .y0(y(0))//close area
			    .y1(d => y(d[cat])))
    }

    //Credit path
    mySVG
        .append('path')
        .call(pathMkr, 'credit', 'cornFlowerBlue', '#e8effc');

    //Debit path
	mySVG
        .append('path')
        .call(pathMkr, 'debit', 'orange', '#FFEDCC');


    //x-Axis
    mySVG
       .append('g')
       .attr('transform', `translate(0, ${height - 50})`)
       .classed('xAxis', true)
       .call(d3.axisBottom(x)
           .tickFormat(d3.format(".0f")))//removes separator and leading 0 from values(years)	
           .selectAll('text')
                .style('text-anchor', 'start')
                .attr('transform', 'rotate(45)');
                
    //y-Axis
    mySVG
	    .append('g')
            .attr('transform', `translate(75, 0)`)
            .classed('yAxis', true)
            .call(d3.axisLeft(y).tickFormat(d => myCurrencyFormat(d, myCurrency)));
    
    //--- Tooltips ----------------------------------------------------------------------------------------------------------------

    //create (invisible) div for tooltips
    let myTooltip = myContainer
        .append('div')
            .style("position", "absolute")
            .style('display', 'none')
            .classed('myTooltip', true)
            .style('max-width', '200px')
            .style('background-color', 'FloralWhite')
            .style('font-size', '0.7em' )
            .style('padding', '5px')
            .style('pointer-events', 'none');
            
    function myMouseover() {
        myTooltip
            .style('display', 'block')
        d3.select(this)
            .style('opacity', 1);
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
            .style('opacity', 0.5)
    };
};