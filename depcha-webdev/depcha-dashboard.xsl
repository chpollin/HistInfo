<?xml version="1.0" encoding="UTF-8"?>

<!--
    Project: GAMS Projekttemplate
    Company: ZIM-ACDH (Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities)
 -->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:s="http://www.w3.org/2001/sw/DataAccess/rf1/result" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:lido="http://www.lido-schema.org"
    xmlns:depcha="https://gams.uni-graz.at/o:depcha.ontology#"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/" exclude-result-prefixes="#all">

    <xsl:include href="depcha-static.xsl"/>

    <!-- GLOBAL VARIABLES -->
    <!-- ///////////////////////////////////// -->
    <xsl:variable name="RESULTS" select="//s:results/s:result"/>
    <xsl:variable name="FIRST_RESULT" select="//s:results/s:result[1]"/>
    <xsl:variable name="CONTEXT">
        <xsl:value-of
            select="substring-after($FIRST_RESULT/s:query/@uri, 'https://gams.uni-graz.at/')"/>
    </xsl:variable>
    <xsl:variable name="Query_URL"
        select="encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '&gt;'))"/>
    <xsl:variable name="PIDS">
        <xsl:text>[</xsl:text>
        <xsl:for-each select="//s:result/s:dataset">
            <xsl:text>&apos;</xsl:text>
            <xsl:value-of select="if (contains(@uri, '#Dataset')) then (substring-after(substring-before(@uri, '#Dataset'), '.at/')) else (substring-after(substring-before(@uri, '.dataset'), '.at/'))"/>
            <xsl:text>&apos;</xsl:text>
            <xsl:if test="position()!=last()">
                <xsl:text>, </xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
    </xsl:variable>
    <!-- this variables contains the distinct number of * in an element; sparql xml result, groupby + sum -->
    <xsl:variable name="groupByContainer">
        <xsl:for-each-group select="$RESULTS" group-by="s:dataset/@uri">
            <xsl:for-each select="s:numberOfTransactions">
                <xsl:element name="numberOfTransactions">
                    <xsl:value-of select="
                            if (./text()) then
                                normalize-space(./text())
                            else
                                0"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each select="s:numberOfTransfers">
                <xsl:element name="numberOfTransfers">
                    <xsl:value-of select="
                        if (./text()) then
                        normalize-space(./text())
                        else
                        0"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each select="s:numberOfEconomicGoods">
                <xsl:element name="numberOfEconomicGoods">
                    <xsl:value-of select="
                            if (./text()) then
                                normalize-space(./text())
                            else
                                0"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each select="s:numberOfEconomicAgents">
                <xsl:element name="numberOfEconomicAgents">
                    <xsl:value-of select="
                            if (./text()) then
                                normalize-space(./text())
                            else
                                0"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each select="s:numberOfAccounts">
                <xsl:element name="numberOfAccounts">
                    <xsl:value-of select="
                        if (./text()) then
                        normalize-space(./text())
                        else
                        0"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:for-each select="s:numberOfPlaces">
                <xsl:element name="numberOfPlaces">
                    <xsl:value-of select="
                            if (./text()) then
                                normalize-space(./text())
                            else
                                0"/>
                </xsl:element>
            </xsl:for-each>
        </xsl:for-each-group>
    </xsl:variable>


    <xsl:variable name="TRANSACTIONS_COUNT">
        <xsl:choose>
            <xsl:when test="sum($groupByContainer//*:numberOfTransactions) &gt; 0">
                <xsl:value-of select="sum($groupByContainer//*:numberOfTransactions)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'0'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    
<!--    <xsl:variable name="TRANSFERS_COUNT">
        <xsl:choose>
            <xsl:when test="sum($groupByContainer//*:numberOfTransfers) &gt; 0">
                <xsl:value-of select="sum($groupByContainer//*:numberOfTransfers)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'0'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>-->
    
    <xsl:variable name="GOODS_COUNT">
        <xsl:choose>
            <xsl:when test="sum($groupByContainer//*:numberOfEconomicGoods) &gt; 0">
                <xsl:value-of select="sum($groupByContainer//*:numberOfEconomicGoods)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'0'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="AGENTS_COUNT">
        <xsl:choose>
            <xsl:when test="sum($groupByContainer//*:numberOfEconomicAgents) &gt; 0">
                <xsl:value-of select="sum($groupByContainer//*:numberOfEconomicAgents)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'0'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="ACCOUNTS_COUNT">
        <xsl:choose>
            <xsl:when test="sum($groupByContainer//*:numberOfAccounts) &gt; 0">
                <xsl:value-of select="sum($groupByContainer//*:numberOfAccounts)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'0'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="PLACES_COUNT">
        <xsl:choose>
            <xsl:when test="sum($groupByContainer//*:numberOfPlaces) &gt; 0">
                <xsl:value-of select="sum($groupByContainer//*:numberOfPlaces)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'0'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:template name="content">
        
<!--        <script>
            console.log('numberOfTransactions: ' + <xsl:value-of select="$TRANSACTIONS_COUNT"/>);
            console.log('numberOfTransfers: ' + <xsl:value-of select="$TRANSFERS_COUNT"/>);
            console.log('numberOfEconomicAgents: ' + <xsl:value-of select="$AGENTS_COUNT"/>);
            console.log('numberOfEconomicGoods: ' + <xsl:value-of select="$GOODS_COUNT"/>);
            console.log('numberOfPlaces: ' + <xsl:value-of select="$PLACES_COUNT"/>);
        </script>-->

        <xsl:variable name="PID_URI" select="$FIRST_RESULT/s:dataset/@uri"/>
        <xsl:variable name="CONTEXT_URI" select="$FIRST_RESULT/s:query/@uri"/>
        <xsl:variable name="CONTEXT_DC" select="document(concat('/', $CONTEXT, '/DC'))"/>
        <xsl:variable name="CONTEXT_METADATA" select="document(concat('/', $CONTEXT, '/METADATA'))"/>


        <!-- ///////////////////////////////////////////////////// -->
        <!-- dashboard header -->
        <div class="m-2">
            <div class="py-3 bg-light" id="dashboardHead">
                    <div class="row row-cols-2 row-cols-md-2 row-cols-sm-1">
                        <div class="col-4 py-1 px-4">
                            <h2>
                                <xsl:value-of select="$CONTEXT_DC//dc:title"/>
                            </h2>
                            <hr/>
                            <p>
                                <xsl:value-of select="$CONTEXT_DC//dc:description"/>
                            </p>
                        </div>
                        <div class="col-8">
                            <div class="card">
                                <div class="card-body pb-0">
                                    <dl class="row small">
                                        <xsl:if
                                            test="$CONTEXT_DC//dc:date/text() or $CONTEXT_DC//dc:coverage/text() or $CONTEXT_DC//dc:language/text()">
                                            <dt class="col-sm-3 text-muted">Scope</dt>
                                            <dd class="col-sm-9">
                                                <xsl:for-each select="$CONTEXT_DC//(dc:date|dc:coverage|dc:language)/text()">
                                                    <xsl:value-of select="."/>
                                                    <xsl:if test="position() != last()">
                                                        <xsl:text> | </xsl:text>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </dd>
                                        </xsl:if>
                                        <xsl:if test="$CONTEXT_DC//dc:source/text()">
                                            <dt class="col-sm-3 text-muted">Source</dt>
                                            <dd class="col-sm-9">
                                                <xsl:value-of select="$CONTEXT_DC//dc:source"
                                                  separator=" | "/>
                                            </dd>
                                        </xsl:if>
                                        <xsl:if test="$CONTEXT_DC//dc:contributor/text()">
                                            <dt class="col-sm-3 text-muted">Editor</dt>
                                            <dd class="col-sm-9">
                                                <xsl:value-of select="$CONTEXT_DC//dc:contributor"
                                                  separator=" | "/>
                                            </dd>
                                        </xsl:if>
                                        <xsl:if test="$CONTEXT_DC//dc:subject/text()">
                                            <dt class="col-sm-3 text-muted">Subject</dt>
                                            <dd class="col-sm-9">
                                                <xsl:value-of select="$CONTEXT_DC//dc:subject"
                                                  separator=" | "/>
                                            </dd>
                                        </xsl:if>
                                    </dl>
                                </div>
                                <div class="card-footer">
                                    <div class="small">
                                        <a href="{$CONTEXT_URI}" class="small link-dark mx-2"
                                            title="{concat('Permalink of the Collection: ', $CONTEXT_URI)}">
                                            <i class="fas fa-link ">
                                                <xsl:text> </xsl:text>
                                            </i>
                                            <span class="small ms-3">
                                                <xsl:value-of select="$CONTEXT_URI"/>
                                            </span>
                                        </a>
                                        <br/>
                                        <span title="{'Last modified'}" class="mx-2">
                                            <i class="fas fa-calendar-week">
                                                <xsl:text> </xsl:text>
                                            </i>
                                            <xsl:text> </xsl:text>
                                            <span class="small ms-3">
                                                <xsl:value-of
                                                  select="format-dateTime($CONTEXT_METADATA//s:result[1]/s:lastModifiedDate, '[D].[M].[Y]')"
                                                />
                                            </span>
                                        </span>
                                        <br/>
                                        <span title="{'Number of transactions'}" class="mx-2">
                                            <i class="fas fa-exchange-alt">
                                                <xsl:text> </xsl:text>
                                            </i>
                                            <xsl:text> </xsl:text>
                                            <span class="small ms-3">
                                                <xsl:value-of
                                                    select="$TRANSACTIONS_COUNT"
                                                />
                                            </span>
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
            </div>

            <!-- ///////////////////////////////////////////////////// -->
            <!-- builds the navigation between dashboard head and body -->
            <div class="my-3" id="dashboardNav">
                <ul class="nav justify-content-md-center">
                    <li class="nav-item">
                        <a class="btn btn-outline-dark active" role="tab" id="dashboard-tab"
                            data-bs-toggle="tab" data-bs-target="#dashboard"
                            aria-controls="dashboard" aria-selected="true">Dashboard</a>
                    </li>
                    <xsl:if test="$GOODS_COUNT &gt; 0">
                    <li class="nav-item">
                        <a class="btn btn-outline-dark" role="tab" id="goods-tab"
                            data-bs-toggle="tab" data-bs-target="#goods" aria-controls="goods"
                            aria-selected="false"
                            onclick="jsonResult_to_IndexList('{$CONTEXT_URI}', 'goods-index-content', 'query:depcha.dashboard.index.economicgoods')"
                            > Economic Goods <span class="badge rounded-pill bg-dark">
                                <xsl:value-of select="$GOODS_COUNT"/>
                            </span>
                        </a>
                    </li>
                    </xsl:if>
                    <xsl:if test="$AGENTS_COUNT &gt; 0">
                     <li class="nav-item">
                         <a class="btn btn-outline-dark" role="tab" id="agents-tab"
                             data-bs-toggle="tab" data-bs-target="#agents" aria-controls="agents"
                             aria-selected="false"
                             onclick="jsonResult_to_IndexList('{$CONTEXT_URI}', 'agents-index-content', 'query:depcha.dashboard.index.economicagents')"
                             > Economic Agents <span class="badge rounded-pill bg-dark">
                                 <xsl:value-of select="$AGENTS_COUNT"/>
                             </span>
                         </a>
                     </li>
                    </xsl:if>
                    <xsl:if test="$ACCOUNTS_COUNT &gt; 0">
                        <li class="nav-item">
                            <a class="btn btn-outline-dark" role="tab" id="accounts-tab"
                                data-bs-toggle="tab" data-bs-target="#accounts" aria-controls="accounts"
                                aria-selected="false"
                                onclick="jsonResult_to_IndexList('{$CONTEXT_URI}', 'accounts-index-content', 'query:depcha.dashboard.index.accounts')"
                                > Accounts <span class="badge rounded-pill bg-dark">
                                    <xsl:value-of select="$ACCOUNTS_COUNT"/>
                                </span>
                            </a>
                        </li>
                    </xsl:if>
                    <li class="nav-item">
                        <a class="btn btn-outline-dark" role="tab" id="units-tab"
                            data-bs-toggle="tab" data-bs-target="#units" aria-controls="units"
                            aria-selected="false"
                            onclick="jsonResult_to_IndexList('{$CONTEXT_URI}', 'units-index-content', 'query:depcha.dashboard.index.units')"
                            > Currencies and Units<!-- <span class="badge rounded-pill bg-dark">
                                <xsl:value-of select="sum($groupByContainer//*:numberOfPlaces)"
                                />
                            </span>-->
                        </a>
                    </li>
                    <xsl:if test="$PLACES_COUNT &gt; 0">
                        <li class="nav-item">
                            <a class="btn btn-outline-dark" role="tab" id="places-tab"
                                data-bs-toggle="tab" data-bs-target="#places" aria-controls="places"
                                aria-selected="false"
                                onclick="jsonResult_to_IndexList('{$CONTEXT_URI}', 'places-index-content', 'query:depcha.dashboard.index.places')"
                                > Places <span class="badge rounded-pill bg-dark">
                                    <xsl:value-of select="$PLACES_COUNT"
                                    />
                                </span>
                            </a>
                        </li>
                    </xsl:if>
                    <li class="nav-item">
                        <a class="btn btn-outline-dark"
                            href="{substring-after($CONTEXT_URI, 'https://gams.uni-graz.at')}"
                            >Collection</a>
                    </li>
                    <!--<li class="nav-item">
                        <div class="dropdown">
                            <button class="btn btn-outline-dark dropdown-toggle"
                                id="dropdownMenuButton1" data-bs-toggle="dropdown"
                                aria-expanded="false"> Export </button>
                            <ul class="dropdown-menu" aria-labelledby="dropdownMenuButton1">
                                <li>
                                    <a class="dropdown-item" href="#">CSV</a>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="#">RDF Dump of the Collection</a>
                                </li>
                            </ul>
                        </div>

                    </li>-->
                </ul>
            </div>

            <!-- ///////////////////////////////////////////////////// -->
            <!-- dashboard body -->
            <div>
                <xsl:choose>
                    <!-- RESULTS FOR DASHBOARD -->
                    <xsl:when test="$FIRST_RESULT">
                        <div class="tab-content">
                            <div role="tabpanel" id="dashboard" class="tab-pane fade show active"
                                aria-labelledby="dashboard-tab">
                                <xsl:call-template name="getDashboard"/>
                            </div>
                            <div role="tabpanel" id="goods" class="tab-pane fade"
                                aria-labelledby="goods-tab">
                                <div class="card">
                                    <div class="card-header">
                                        <h5 class="card-title">Economic Goods <span
                                                class="badge rounded-pill bg-dark">
                                                <xsl:value-of
                                                  select="$GOODS_COUNT"
                                                /></span></h5>
                                    </div>
                                    <div class="card-body">
                                        <div id="goods-index-content">
                                            <xsl:text> </xsl:text>
                                            <!-- this is created by depcha-dashboard-index.js -->
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div role="tabpanel" id="agents" class="tab-pane fade"
                                aria-labelledby="agents-tab">
                                <div class="card">
                                    <div class="card-header">
                                        <h5 class="card-title">Economic Agents <span
                                                class="badge rounded-pill bg-dark">
                                                <xsl:value-of
                                                  select="$AGENTS_COUNT"
                                                /></span>
                                        </h5>
                                    </div>
                                    <div class="card-body">
                                        <div id="agents-index-content">
                                            <xsl:text> </xsl:text>
                                            <!-- this is created by depcha-dashboard-index.js -->
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div role="tabpanel" id="accounts" class="tab-pane fade"
                                aria-labelledby="accounts-tab">
                                <div class="card">
                                    <div class="card-header">
                                        <h5 class="card-title">Accounts <span
                                            class="badge rounded-pill bg-dark">
                                            <xsl:value-of
                                                select="$ACCOUNTS_COUNT"
                                            /></span>
                                        </h5>
                                    </div>
                                    <div class="card-body">
                                        <div id="accounts-index-content">
                                            <xsl:text> </xsl:text>
                                            <!-- this is created by depcha-dashboard-index.js -->
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div role="tabpanel" id="units" class="tab-pane fade"
                                aria-labelledby="units-tab">
                                <div class="card">
                                    <div class="card-header">
                                        <h5 class="card-title">Currencies and Units</h5>
                                    </div>
                                    <div class="card-body">
                                        <div id="units-index-content">
                                            <!-- this is created by depcha-dashboard-index.js -->
                                            <xsl:text> </xsl:text>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div role="tabpanel" id="places" class="tab-pane fade"
                                aria-labelledby="places-tab">
                                <div class="card">
                                    <div class="card-header">
                                        <h5 class="card-title">Places <span
                                                class="badge rounded-pill bg-dark"><xsl:value-of
                                                  select="$PLACES_COUNT"
                                                /></span></h5>
                                    </div>
                                    <div class="card-body">
                                        <div id="places-index-content">
                                            <!-- this is created by depcha-dashboard-index.js -->
                                            <xsl:text> </xsl:text>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </xsl:when>
                    <!-- NO RESULTS FOR DASHBOARD -->
                    <xsl:otherwise>
                        <p>
                            <xsl:text>Error: sry no results found :/</xsl:text>
                        </p>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
            <script src="{concat($projectRootPath, 'js/infovis/treeMap.js')}"><xsl:text> </xsl:text></script>
            <script src="{concat($projectRootPath, 'js/infovis/controller.js')}"><xsl:text> </xsl:text></script>
            <script src="{concat($projectRootPath, 'js/infovis/barChart.js')}"><xsl:text> </xsl:text></script>
            <script src="{concat($projectRootPath, 'js/infovis/lineChart.js')}"><xsl:text> </xsl:text></script>
            <script src="{concat($projectRootPath, 'js/infovis/circlePacking.js')}"><xsl:text> </xsl:text></script>
            <script>
                treeMapOnLoad('query:depcha.infovis.aggregation.year', '<xsl:value-of select="$CONTEXT"/>');
            </script>
        </div>
    </xsl:template>

    <!-- ////////////////// -->
    <!-- ... -->
    <xsl:template name="getDashboard">
        <div class="row">
            <div class="col-md-7" id="transactionsCol">
                <!--<div class="row">
                    <div class="col-md-4">
                        <div class="card small">
                            <ul class="list-group">
                                <li
                                    class="list-group-item d-flex justify-content-between align-items-center"
                                    title="Absolut number of all transactions in the collection">
                                    Transactions
                                </li>
                                <li
                                    class="list-group-item d-flex justify-content-between align-items-center"
                                    title="Absolut number of all economic agents in the collection">
                                    xxx </li>
                                <li
                                    class="list-group-item d-flex justify-content-between align-items-center"
                                    title="Absolut number of all economic assets in the collection">
                                    xxx </li>
                            </ul>
                            <div class="card-footer">
                                <h6 class="card-title">Transactions</h6>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card">
                            <div class="card-body">
                                <p>a</p>
                            </div>
                            <div class="card-footer">
                                <h6 class="card-title">Units of Measurment</h6>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="card">
                            <div class="card-body">
                                <ul>
                                    <xsl:for-each-group select="$RESULTS" group-by="s:unit_label">
                                        <li>
                                            <xsl:value-of select="current-grouping-key()"/>
                                        </li>
                                    </xsl:for-each-group>
                                </ul>
                            </div>
                            <div class="card-footer">
                                <h6 class="card-title">Currencies</h6>
                            </div>
                        </div>
                    </div>
                </div>-->
                <div class="row">
                    <div class="col-md-12">
                        <div class="card">
                            <div class="card-header">
                                <div class="row">
                                    <div class="col-10">
                                        <h5 class="card-title">
                                            <xsl:text>Transactions </xsl:text> 
                                            <span class="badge rounded-pill bg-dark">
                                                <xsl:value-of select="$TRANSACTIONS_COUNT"/>
                                            </span>
                                        </h5>
                                    </div>
                                    <div class="text-end col-2">
                                        <a type="button" class="link-dark"
                                            onclick="resize_trans()">
                                            <i id="transactionsSwitch"
                                              class="bi bi-arrows-fullscreen">&#8203;</i>
                                        </a>
                                    </div>
                                </div>
                            </div>
                            <div class="card-body">

                                <div class="table-responsive">
                                    <div class="d-flex align-items-center" id="loading_spinner">
                                        <strong>Loading...</strong>
                                        <div class="spinner-border ms-auto" role="status"
                                            aria-hidden="true" style="width: 5rem; height: 5rem;">
                                            <xsl:text> </xsl:text>
                                        </div>
                                    </div>
                                    <div id="showOutput">
                                        <table class="table small" id="data_table"
                                            style="width:100%">
                                            <!-- is build in depcha-datatable.js -->
                                            <xsl:text> </xsl:text>

                                        </table>
                                    </div>

                                    <xsl:variable name="CURRENCIES">
                                        <xsl:text>[</xsl:text>
                                        <xsl:for-each-group select="$RESULTS" group-by="s:unit/@uri">
                                            <xsl:text>'</xsl:text>
                                            <xsl:value-of
                                                select="substring-after(current-grouping-key(), '#')"/>
                                            <xsl:text>'</xsl:text>
                                            <xsl:if test="not(position() = last())">
                                                <xsl:text>,</xsl:text>
                                            </xsl:if>
                                        </xsl:for-each-group>
                                        <xsl:text>]</xsl:text>
                                    </xsl:variable>

                                    <script>
                                        load_all_transactions(<xsl:value-of select="'&quot;query:depcha.transactions&quot;'"/>, <xsl:value-of select="$PIDS"/>, <xsl:value-of select="concat('&quot;', $CONTEXT, '&quot;')"/>);
                                    </script>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <!-- ///////////////////////////// -->
            <!-- INFO VIS -->
            <!-- $1|<https://gams.uni-graz.at/o:depcha.ssps.1485> -->
            <div class="col-md-5" id="visualizationsCol">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header">
                            <div class="row">
                                <ul class="nav small col-11 d-flex justify-content-center">
                                    <li class="nav-item p-0">
                                        <xsl:variable name="PARAM"
                                            select="encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '&gt;'))"/>
                                        <xsl:variable name="QUERY_NAME"
                                            select="'query:depcha.infovis.aggregation.year'"/>
                                        <a class="btn btn-sm btn-outline-dark active" role="tab"
                                            id="dashboard-tab" data-bs-toggle="tab"
                                            data-bs-target="#dashboard" aria-controls="dashboard"
                                            aria-selected="true"
                                            onclick="switch_infovis_view('#depcha_treemap', '{concat('/archive/objects/', $QUERY_NAME, '/methods/sdef:Query/getJSON?params=', $PARAM)}', 'treemap')"
                                            >Treemap</a>
                                    </li>
                                    <li class="nav-item p-0">
                                        <xsl:variable name="PARAM"
                                            select="encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '&gt;'))"/>
                                        <xsl:variable name="QUERY_NAME"
                                            select="'query:depcha.infovis.aggregation.year'"/>
                                        <a class="btn btn-sm btn-outline-dark" role="tab"
                                            id="dashboard-tab" data-bs-toggle="tab"
                                            data-bs-target="#dashboard" aria-controls="dashboard"
                                            aria-selected="true"
                                            onclick="switch_infovis_view('#depcha_barchart', '{concat('/archive/objects/', $QUERY_NAME, '/methods/sdef:Query/getJSON?params=', $PARAM)}', 'barchart')"
                                            >Bar Chart</a>
                                    </li>
                                    <li class="nav-item p-0">
                                        <xsl:variable name="PARAM"
                                            select="encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '&gt;'))"/>
                                        <xsl:variable name="QUERY_NAME"
                                            select="'query:depcha.infovis.aggregation.year'"/>
                                        <a class="btn btn-sm btn-outline-dark" role="tab"
                                            id="dashboard-tab" data-bs-toggle="tab"
                                            data-bs-target="#dashboard" aria-controls="dashboard"
                                            aria-selected="true"
                                            onclick="switch_infovis_view('#depcha_circlepacking', '{concat('/archive/objects/', $QUERY_NAME, '/methods/sdef:Query/getJSON?params=', $PARAM)}', 'circlepacking')"
                                            >Circle Packing</a>
                                    </li>
                                    <li class="nav-item p-0">
                                        <xsl:variable name="PARAM"
                                            select="encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '&gt;'))"/>
                                        <xsl:variable name="QUERY_NAME"
                                            select="'query:depcha.infovis.aggregation.year'"/>
                                        <a class="btn btn-sm btn-outline-dark" role="tab"
                                            id="dashboard-tab" data-bs-toggle="tab"
                                            data-bs-target="#dashboard" aria-controls="dashboard"
                                            aria-selected="true"
                                            onclick="switch_infovis_view('#depcha_linechart', '{concat('/archive/objects/', $QUERY_NAME, '/methods/sdef:Query/getJSON?params=', $PARAM)}', 'linechart')"
                                            >Line Chart</a>
                                    </li>
                                </ul>
                                <div class="text-end col-1">
                                    <a type="button" class="link-dark" onclick="resize_vis()">
                                        <i id="visualizationsSwitch" class="bi bi-arrows-fullscreen"
                                            >&#8203;</i>
                                    </a>
                                </div>
                            </div>
                        </div>
                        <!-- InfoViz container -->
                        <div class="svg-container overflow-auto p-3" id="infovis_dashboard">
                            <div class="text-center" id="dashboar_loading_spinner">
                                <div class="spinner-border ms-auto" role="status" aria-hidden="true"
                                    style="width: 17.5rem; height: 17.5rem;">
                                    <xsl:text> </xsl:text>
                                </div>
                            </div>
                            <div id="depcha_treemap">
                                <xsl:text> </xsl:text>
                            </div>
                            <div id="depcha_barchart" class="d-none">
                                <xsl:text> </xsl:text>
                            </div>
                            <div id="depcha_circlepacking" class="d-none">
                                <xsl:text> </xsl:text>
                            </div>
                            <div id="depcha_linechart" class="d-none">
                                <xsl:text> </xsl:text>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- transaction card -->
        <!--<div class="col-4">
            <div class="border mt-0 small">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col-10">
                            <div title="Distinct number of all Transactions" class="font-weight-bold"><xsl:text>Transactions </xsl:text><i class="fas fa-info-circle small"><xsl:text> </xsl:text></i></div>
                            <div title="Distinct number of all economic subjects" class="font-weight-bold"><xsl:text>Subjects </xsl:text><i class="fas fa-info-circle small"><xsl:text> </xsl:text></i></div>
                            <div title="Distinct number of all economic objects (commodities, services, monetary values)" class="font-weight-bold"><xsl:text>Objects </xsl:text><i class="fas fa-info-circle small"><xsl:text> </xsl:text></i></div>
                        </div>
                        <div class="col-2">
                            <!-\-<div class="badge badge-light badge-pill">
                                <xsl:value-of select="if ($QUERY_OVERVIEW_COUNT/s:transaction &gt; 0 ) then $QUERY_OVERVIEW_COUNT/s:transaction else '0'"/>
                            </div>
                            <div class="badge badge-light badge-pill">
                                <xsl:value-of select="if ($QUERY_OVERVIEW_COUNT/s:economic_subject &gt; 0 ) then $QUERY_OVERVIEW_COUNT/s:economic_subject else '0'"/>
                            </div>
                            <div class="badge badge-light badge-pill">
                                <xsl:value-of select="if ($QUERY_OVERVIEW_SUM_ECONOMIC_OBJECT &gt; 0 ) then $QUERY_OVERVIEW_SUM_ECONOMIC_OBJECT else '0'"/>
                            </div>-\->
                        </div>
                    </div>
                </div>
                <div class="card-footer">
                    <span class="font-weight-bold">Total</span>
                </div>
            </div>
        </div>
        <!-\- SUBJECT CARD -\->
        <div class="col-4">
            <div class="border mt-0 small">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col-6">
                            <div class="mb-0" title="Number of unique Economic Subjects">Unique</div>
                        </div>
                        <!-\-<div class="col-auto">
                            <div><xsl:value-of select="if ($QUERY_INDEX_OBJECTS_DISTINCT_COUNT &gt; 0 ) then $QUERY_INDEX_OBJECTS_DISTINCT_COUNT else '0'"/></div>
                        </div>-\->
                    </div>
                </div>
                <div class="card-footer">
                    <span class="font-weight-bold">Subjects</span>
                </div>
            </div>
        </div>-->
    </xsl:template>

    <!-- /////////////////////////////// -->

    <xsl:template name="create_indexlist_view">
        <xsl:param name="QUERY_INDEX_RESULTS"/>
        <xsl:param name="h6"/>
        <xsl:param name="SEARCH_QUERY"/>

        <xsl:if test="$QUERY_INDEX_RESULTS">
            <div class="row">
                <div class="col-6">
                    <div class="shadow mr-3">
                        <div class="card-body">
                            <p class="text-center text-monospace">
                                <xsl:value-of select="0"/>
                            </p>
                            <xsl:for-each-group select="$QUERY_INDEX_RESULTS"
                                group-by="s:group/@uri">
                                <xsl:sort select="s:count" data-type="number" order="descending"/>
                                <div class="list-group-item list-group-item-action border-top">
                                    <a class="arrow" data-toggle="collapse"
                                        href="{concat('#c' , generate-id())}">
                                        <i>
                                            <xsl:text>▼ </xsl:text>
                                        </i>
                                        <xsl:value-of select="s:name"/>
                                    </a>
                                    <br/>
                                    <xsl:variable name="QUERY_URL_WHERE"
                                        select="concat('/archive/objects/', $SEARCH_QUERY, '/methods/sdef:Query/get?params=', encode-for-uri(concat('$1%7C&lt;', current-grouping-key(), '&gt;')))"/>
                                    <a href="{$QUERY_URL_WHERE}" class="text-muted" target="blank_">
                                        <xsl:value-of select="s:count"/>
                                        <xsl:text> Transactions </xsl:text>
                                        <i class="fas fa-search">
                                            <xsl:text> </xsl:text>
                                        </i>
                                    </a>
                                    <div class="collapse" id="{concat('c' , generate-id())}">
                                        <div class="card card-body">
                                            <table class="table table-sm">
                                                <tbody>
                                                  <!-- iterating over all properties and there literal|uri -->
                                                  <xsl:for-each select="current-group()">
                                                  <xsl:sort select="s:prop/@uri"/>
                                                  <xsl:variable name="Property" select="s:prop/@uri"/>
                                                  <xsl:if
                                                  test="not($Property = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type')">
                                                  <tr>
                                                  <th class="col-4">
                                                  <xsl:value-of select="s:prop/@uri"/>
                                                  </th>
                                                  <td class="col-8">
                                                  <xsl:value-of select="normalize-space(s:value)"/>
                                                  <xsl:text> </xsl:text>
                                                  </td>
                                                  </tr>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </xsl:for-each-group>
                        </div>
                    </div>
                </div>
                <div class="col-6">
                    <p>
                        <xsl:text>lorem</xsl:text>
                    </p>
                </div>
            </div>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
