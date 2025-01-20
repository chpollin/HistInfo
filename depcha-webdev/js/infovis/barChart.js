/*    
 * author: Jakob Sonnberger
 * company: ZIM
 * purpose: Visualizing depcha JSON data as DataTable and Barchart
* last update: 03/2023
*/

function createBarChart(myJSON, myDivCSSSelector) {

    //sort JSON entries by date
    myJSON = myJSON.sort((a, b) => parseInt(a.date) - parseInt(b.date));

    let myCurrency = myJSON[0].unit;
    //console.log('Currency: ' + myCurrency);

    let myDebits = myJSON.map(d => parseFloat(d.debit));
    
    let myCredits = myJSON.map(d => parseFloat(d.credit));

    let myMax  = d3.max(d3.merge([myDebits, myCredits]));
    
    let myDates = myJSON.map(d => d.date);
	
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
            .on('change', function(){d3.selectAll('rect.debit').attr('visibility', this.checked ? 'visible' : 'hidden')});
    
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
                .on('change', function(){d3.selectAll('rect.credit').attr('visibility', this.checked ? 'visible' : 'hidden')});
        
    checkCreditDiv
            .append('label')
                .classed('form-check-label', true)
                .attr('for', 'switchDebit')
                .text('credit');

    let checkBalanceDiv = myLegend
        .append('div')
            .classed('form-check', true);
    
    checkBalanceDiv
            .append('input')
                .classed('form-check-input', true)
                .attr('type', 'checkbox')
                .attr('id', 'switchBalance')
                .attr('checked', 'checked')
                .style('background-color', 'black')
                .on('change', function(){d3.selectAll('.balance').attr('visibility', this.checked ? 'visible' : 'hidden')});
        
    checkBalanceDiv
            .append('label')
                .classed('form-check-label', true)
                .attr('for', 'switchBalance')
                .text('balance');

    // ## Constructing Scale switch
    let mySwitchScaleDiv = myLegend
        .append('div')
            .classed('form-check form-switch', true);
    
    let mySVG = myContainer
        .append('svg')
            .attr('viewBox',[0, 0, width, height]);
    
    mySwitchScaleDiv
        .append('input')
            .classed('form-check-input', true)
            .attr('type', 'checkbox')
            .attr('id', 'switchScale')
            .on('change', function(){
                //...switching scale & switch label...
                [y, y1] = [y1, y];
                [scaleLabel, scaleLabel1] = [scaleLabel1, scaleLabel];
                
                //...transform height and y-position (as y-position is calculatet from height) of rects...
                mySVG
                    .selectAll('rect.credit')
                    .transition().duration(1000).ease(d3.easeBack)
                    .attr('height', d => y(0) - y(d.credit))
                    .attr('y', d => y(d.credit));
                    
                mySVG
                    .selectAll('rect.debit')
                    .transition().duration(1000).ease(d3.easeBack)
                    .attr('height', d => y(0) - y(d.debit));
                
                mySVG
                    .selectAll('circle')
                    .transition().duration(1000).ease(d3.easeBack)
                    .attr('cy', d => y(d.credit - d.debit));
                
                mySVG
                    .selectAll('path.balance')
                    .transition().duration(1000).ease(d3.easeBack)
                    .attr('d', d3.line()
                        .x(d => x(d.date) + barWidth/2)
                        .y(d => y(d.credit - d.debit))
                        .curve(d3.curveMonotoneX)//experimentell?
                    );
                
                //...transform y-Axis...
                mySVG.select('g.yAxis')
                    .transition().duration(1000).ease(d3.easeBack)
                    .call(d3.axisLeft(y)
                        .tickFormat(d => myCurrencyFormat(d, myCurrency)));
                    
                //...and change label of switch
                switchScaleLabel
                    .text(scaleLabel);
            });

    let switchScaleLabel = mySwitchScaleDiv
        .append('label')
            .attr('id', 'switchScaleLabel')
            .classed('form-check-label', true)
            .attr('for', 'switchScale')
            .text('exponential scale');
    
    //bandscaling for x-Axis
    let x = d3.scaleBand()
        .domain(myDates)
        .range([75, width - 50])
        .padding(0.2);

    //exponential scaling for y-Axis    
    let y = d3.scalePow()
        .exponent(0.25)
        .domain([-myMax, myMax])
        .range([height - 50,50]);
    
    let scaleLabel = 'exponential scale';
    
    //linear scaling for y-Axis 
    let y1 = d3.scaleLinear()
        .domain([-myMax, myMax])
        .range([height - 50,50]);
    
    let scaleLabel1 = 'linear scale';

    //Rects
    
    //bar width limited to 50
    let barWidth = d3.min([x.bandwidth(), 50]);

    function rectMkr(sel, cat, color){
        sel
            .classed(cat, true)
            .attr('n', d => d.date)
            .attr('fill', color)
            .attr('x', d => x(d.date))
            .attr('height', d => y(0) - y(d[cat]))
            .attr('width', barWidth)
            .on('mouseover', function(event, d){
                myTooltip
                    .style('display', 'block')
                d3.select(this)
                    .style('stroke', 'black')
                    .style('opacity', 0.5);
            })
            .on('click', (event, d) => setDatatableFilter(d.date))
            .on('mousemove', (event, d) => myMousemove(event, d.date + ' ' + cat + ': ' + myCurrencyFormat(d[cat], myCurrency)))
            .on('mouseleave', function(){
                myTooltip
                    .style('display', 'none')
                d3.select(this)
                    .style('stroke', 'none')
                    .style('opacity', 1);
            });
    }

    //...Credit rects
	mySVG
        .append('g')
            .selectAll('rect')
            .data(myJSON)
            .join('rect')
                .attr('y', d => y(d.credit))
                .call(rectMkr, 'credit', 'cornFlowerBlue');
            
    //...Debit rects
	mySVG
        .append('g')
            .selectAll('rect')
            .data(myJSON)
            .join('rect')
                .attr('y', y(0))
                .call(rectMkr, 'debit', 'orange');
    
    //balance path
    mySVG
        .append('g')
            .append('path')
                .classed('balance', true)
                .datum(myJSON)
                .attr('d', d3.line()
                    .x(d => x(d.date) + barWidth/2)
                    .y(d => y(d.credit - d.debit))
                    .curve(d3.curveMonotoneX)//experimentell?
                )
                .style('fill', 'none')
                .style('stroke', 'black')
                .style('stroke-width', 2)
                //.style('stroke-dasharray', ('2, 2'))
                .style('pointer-events', 'none');

    //balance circles
	mySVG
        .append('g')
            .classed('gcircles', true)
            .selectAll('circle')
            .data(myJSON)
            .join('circle')
                .classed('balance', true)
                .attr('cx', d => x(d.date) + barWidth/2)
                .attr('cy', d => y(d.credit - d.debit))
                .attr('r', barWidth/4)
                .style('fill', d => d.credit - d.debit < 0 ? 'OrangeRed' : 'RebeccaPurple')
                .on('mouseover', function(event, d){
                    myTooltip
                        .style('display', 'block')
                    d3.select(this)
                        .style('stroke', 'black')
                        .style('opacity', 0.5);
                })
                .on('mousemove', (event, d) => {myMousemove(event, d.date + ' ' + 'balance: ' + myCurrencyFormat(d.credit - d.debit, myCurrency))})
                .on('mouseleave', function(){
                    myTooltip
                        .style('display', 'none')
                    d3.select(this)
                        .style('stroke', 'none')
                        .style('opacity', 1);
                });
    
    //x-Axis
/*     mySVG
        .append('g')
            .attr('transform', `translate(0, ${height - 50})`)
            .classed('xAxis', true)
            .call(d3.axisBottom(x)
                .tickFormat(d3.format(".0f")))//removes separator and leading 0 from values(years)	
                .selectAll('text')
                        .style('text-anchor', 'middle')
                        //.filter((d, i) => i%5!=0) //showing only every 5th label
                        .filter((d, i) => d%5!=0) //showing only labels divisable by 5
                            .style('display', 'none'); */
                
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
            .style('pointer-events', 'none')
            .style("position", "absolute")
            .style('display', 'none')
            .classed('myTooltip', true)
            .style('max-width', '200px')
            .style('background-color', 'FloralWhite')
            .style('font-size', '0.7em' )
            .style('padding', '5px');
          
    //set tooltip text & position (relative to pointer)
    function myMousemove(myEvent, myTooltipText) {
        myTooltip
            .text(myTooltipText)
            .style('left', myEvent.layerX + 'px')
            .style('top', myEvent.layerY - 30 + 'px');
    };
};