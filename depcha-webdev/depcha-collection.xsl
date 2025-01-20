<?xml version="1.0" encoding="UTF-8"?>

<!--
    Project: GAMS Projekttemplate
    Company: ZIM-ACDH (Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities)
 -->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:s="http://www.w3.org/2001/sw/DataAccess/rf1/result" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:lido="http://www.lido-schema.org"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    xmlns:depcha="https://gams.uni-graz.at/o:depcha.ontology#" exclude-result-prefixes="#all">

    <!--
        - This is included via static
        <xsl:include href="/lib/3.0/gamsJS/1.x/gamsjs_wippets/widget_injection.xsl"/>
    -->

    <xsl:include href="depcha-static.xsl"/>

    <!--<xsl:output method="xml" doctype-system="about:legacy-compat" encoding="UTF-8" indent="no"/>-->

    <xsl:template name="content">

        <xsl:variable name="RESULTS" select="//s:result"/>
        <xsl:variable name="CONTEXT" select="//s:result[1]/s:cid"/>
        <xsl:variable name="DC" select="document(concat('/', $CONTEXT, '/DC'))"/>

        <script src="{concat($projectRootPath, 'lib\filesaver\FileSaver.min.js')}"><xsl:text> </xsl:text></script>
        <script src="{concat($projectRootPath, 'lib\jszip\jszip.min.js')}"><xsl:text> </xsl:text></script>
        <script src="{concat($projectRootPath, 'js\depcha-collection.js')}"><xsl:text> </xsl:text></script>

        <div class="py-3 bg-light">
            <div class="container">
                <div class="row row-cols-2 row-cols-md-2 row-cols-sm-1">
                    <div class="col-md-1">
                        <div class="card">
                            <div class="card-body>">
                                <div class="row py-2">
                                    <xsl:variable name="teiHeader" select="/t:TEI/t:teiHeader"/>
                                    <a class="btn" style="outline:none; box-shadow: none;"
                                        href="/archive/objects/context:depcha/methods/sdef:Context/get?mode=collections"
                                            ><svg xmlns="http://www.w3.org/2000/svg" width="16"
                                            height="16" fill="currentColor"
                                            class="bi bi-skip-backward" viewBox="0 0 16 16">
                                            <path
                                                d="M.5 3.5A.5.5 0 0 1 1 4v3.248l6.267-3.636c.52-.302 1.233.043 1.233.696v2.94l6.267-3.636c.52-.302 1.233.043 1.233.696v7.384c0 .653-.713.998-1.233.696L8.5 8.752v2.94c0 .653-.713.998-1.233.696L1 8.752V12a.5.5 0 0 1-1 0V4a.5.5 0 0 1 .5-.5zm7 1.133L1.696 8 7.5 11.367V4.633zm7.5 0L9.196 8 15 11.367V4.633z"
                                            />
                                        </svg><br/>Collections Overview</a>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-7">
                        <h3> Collection </h3>
                        <h4>
                            <xsl:value-of select="$RESULTS[1]/s:container"/>
                        </h4>
                        <p class="small"> The following <span class="fw-bold"><xsl:value-of
                                    select="count(distinct-values(//s:result/s:pid/@uri))"/>
                                objects</span> are part of the <span class="fst-italic"
                                    ><xsl:value-of select="$RESULTS[1]/s:container"/></span>
                            collection. </p>
                    </div>
                    <div class="col-md-4">
                        <div class="card">
                            <div class="card-body">
                                <dl class="row small">
                                    <!--<dt class="col-sm-8">Objects </dt>
                                    <dd class="col-sm-4">
                                        <xsl:value-of
                                            select="count(distinct-values(//s:result/s:pid/@uri))"/>
                                    </dd>
                                    <dt class="col-sm-8">Transactions in Collection </dt>
                                    <dd class="col-sm-4">
                                        <xsl:value-of select="0"/>
                                    </dd>-->
                                    <xsl:if
                                        test="$DC//dc:date or $DC//dc:coverage or $DC//dc:language">
                                        <dt class="col-md-4">Scope </dt>
                                        <dd class="col-md-8">
                                            <xsl:value-of
                                                select="$DC//dc:date | $DC//dc:coverage | $DC//dc:language"
                                                separator=" | "/>
                                        </dd>
                                    </xsl:if>
                                    <xsl:if test="$DC//dc:source">
                                        <dt class="col-md-4">Source</dt>
                                        <dd class="col-md-8">
                                            <xsl:choose>
                                                <xsl:when
                                                  test="starts-with($DC//dc:source, 'http') or starts-with($DC//dc:source, 'www')">
                                                  <a target="_blank">
                                                  <xsl:attribute name="href">
                                                  <xsl:value-of select="$DC//dc:source"/>
                                                  </xsl:attribute>
                                                  <xsl:value-of select="$DC//dc:source"/>
                                                  </a>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                  <xsl:value-of select="$DC//dc:source"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </dd>
                                    </xsl:if>
                                    <xsl:if test="$DC//dc:contributor">
                                        <dt class="col-md-4">Editor </dt>
                                        <dd class="col-md-8">
                                            <xsl:for-each select="$DC//dc:contributor">
                                                <xsl:value-of select="."/>
                                                <xsl:if test="position() != last()">
                                                  <xsl:text> | </xsl:text>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </dd>
                                    </xsl:if>
                                    <xsl:if test="$DC//dc:subject">
                                        <dt class="col-md-4">Subject </dt>
                                        <dd class="col-md-8">
                                            <xsl:for-each select="$DC//dc:subject">
                                                <xsl:value-of select="."/>
                                                <xsl:if test="position() != last()">
                                                  <xsl:text> | </xsl:text>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </dd>
                                    </xsl:if>
                                </dl>
                            </div>

                        </div>

                    </div>
                </div>
            </div>
            <!-- ///////////////////////////////////////////////////// -->
            <!-- builds the navigation between dashboard head and body -->
            <div class="my-3">
                <ul class="nav justify-content-md-center">
                    <li class="nav-item">
                        <xsl:variable name="QUERY_PARAM"
                            select="concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '&gt;')"/>
                        <a class="btn btn-outline-dark"
                            href="{concat('/archive/objects/query:depcha.dashboard/methods/sdef:Query/get?params=', $QUERY_PARAM)}"
                            >Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <div class="dropdown">
                            <button class="btn btn-outline-dark dropdown-toggle"
                                id="dropdownMenuButton1" data-bs-toggle="dropdown"
                                aria-expanded="false">Download</button>
                            <ul class="dropdown-menu" aria-labelledby="dropdownMenuButton1">
                                <xsl:if test="//s:model[contains(@uri, 'cm:TEI')]">
                                    <li>
                                        <a href="#" class="dropdown-item"
                                            onclick="TEIzipAndDownload(event)">All XML/TEI</a>
                                    </li>
                                </xsl:if>
                                <li>
                                    <a href="#" class="dropdown-item"
                                        onclick="RDFzipAndDownload(event)">All XML/RDF</a>
                                </li>
                            </ul>
                        </div>

                    </li>
                </ul>
            </div>
            <div class="container">
                <div class="row row-cols-1 row-cols-sm-2 row-cols-md-3 g-3">
                    <xsl:for-each-group select="//s:result" group-by="s:pid/@uri">
                        <xsl:sort select="s:date"/>
                        <xsl:sort select="s:title" data-type="text"/>
                        <script>
                            myContext = '<xsl:value-of select="s:cid[1]"/>';
                            <xsl:choose>
                                <xsl:when test="contains(s:model/@uri, 'cm:TEI')">
                                    myTEIs.push('<xsl:value-of select="concat(s:identifier[1], '/TEI_SOURCE')"/>');
                                    myRDFs.push('<xsl:value-of select="concat(s:identifier[1], '/RDF')"/>');
                                </xsl:when>
                                <xsl:otherwise>
                                    myRDFs.push('<xsl:value-of select="concat(s:identifier[1], '/ONTOLOGY')"/>');
                                </xsl:otherwise>
                            </xsl:choose>
                        </script>

                        <xsl:variable name="PID"
                            select="substring-after(current-grouping-key(), 'info:fedora/')"/>

                        <!-- card created from /context:depcha/METADATA  -->
                        <div class="col">
                            <div class="card">
                                <div class="card-body">
                                    <!-- dc:title -->
                                    <xsl:if test="current-group()/s:title[text()]">
                                        <h5 class="fw-bold">
                                            <xsl:for-each
                                                select="distinct-values(current-group()/s:title[text()])">
                                                <xsl:value-of select="."/>
                                                <xsl:if test="position() != last()">
                                                  <br/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </h5>
                                    </xsl:if>
                                    <hr/>

                                    <!--                                    <!-\- #Desciption -\->
                                    <!-\- ##dc:description -\->
                                    <xsl:if test="current-group()/s:description[text()]">
                                        <dl class="row">
                                            <dt class="col-sm-3 text-muted">Description</dt>
                                            <dd class="col-sm-9">
                                                <xsl:for-each
                                                  select="distinct-values(current-group()/s:description[text()])">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="position() != last()">
                                                    <br/>
                                                  </xsl:if>
                                                </xsl:for-each>
                                            </dd>
                                        </dl>
                                    </xsl:if>-->

                                    <!-- #Scope -->
                                    <xsl:if
                                        test="s:date[text()] or s:coverage[text()] or s:language[text()]">
                                        <dl class="row">
                                            <dt class="col-sm-3 text-muted">Scope</dt>
                                            <dd class="col-sm-9">
                                                <!-- ##dc:date -->
                                                <xsl:if test="s:date[text()]">
                                                  <xsl:for-each
                                                  select="distinct-values(s:date[text()])">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="position() != last()">
                                                  <xsl:text>, </xsl:text>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </xsl:if>
                                                <!-- ##dc:coverage -->
                                                <xsl:if test="s:coverage[text()]">
                                                  <br/>
                                                  <xsl:for-each
                                                  select="distinct-values(s:coverage[text()])">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="position() != last()">
                                                  <xsl:text>, </xsl:text>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </xsl:if>
                                                <!-- ##dc:language -->
                                                <xsl:if test="s:language[text()]">
                                                  <br/>
                                                  <xsl:for-each
                                                  select="distinct-values(s:language[text()])">
                                                  <xsl:choose>
                                                  <xsl:when test="string-length(.) = 2">
                                                  <xsl:call-template name="langeCodeToText">
                                                  <xsl:with-param name="code" select="."/>
                                                  </xsl:call-template>
                                                  </xsl:when>
                                                  <xsl:otherwise>
                                                  <xsl:value-of select="."/>
                                                  </xsl:otherwise>
                                                  </xsl:choose>
                                                  <xsl:if test="position() != last()">
                                                  <xsl:text>, </xsl:text>
                                                  </xsl:if>
                                                  </xsl:for-each>
                                                </xsl:if>
                                            </dd>
                                        </dl>
                                    </xsl:if>

                                    <!-- #Source -->
                                    <!-- dc:source -->
                                    <xsl:if test="s:source[text()]">
                                        <dl class="row">
                                            <dt class="col-sm-3 text-muted">Source</dt>
                                            <dd class="col-sm-9">
                                                <xsl:for-each
                                                  select="distinct-values(s:source[text()])">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="position() != last()">
                                                  <br/>
                                                  </xsl:if>
                                                </xsl:for-each>
                                            </dd>
                                        </dl>
                                    </xsl:if>

                                    <!-- #Editor -->
                                    <!-- ##dc:contributor -->
                                    <xsl:if test="s:contributor[text()]">
                                        <dl class="row">
                                            <dt class="col-sm-3 text-muted">Editor</dt>
                                            <dd class="col-sm-9">
                                                <xsl:for-each
                                                  select="distinct-values(s:contributor[text()])">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="position() != last()">
                                                  <xsl:text> / </xsl:text>
                                                  </xsl:if>
                                                </xsl:for-each>
                                            </dd>
                                        </dl>
                                    </xsl:if>

                                    <!-- #Subject -->
                                    <!-- ##dc:subject -->
                                    <xsl:if test="s:subject[text()]">
                                        <dl class="row">
                                            <dt class="col-sm-3 text-muted">Subject</dt>
                                            <dd class="col-sm-9">
                                                <xsl:for-each
                                                  select="distinct-values(s:subject[text()])">
                                                  <xsl:value-of select="."/>
                                                  <xsl:if test="position() != last()">
                                                  <xsl:text>, </xsl:text>
                                                  </xsl:if>
                                                </xsl:for-each>
                                            </dd>
                                        </dl>
                                    </xsl:if>

                                    <div class="small">
                                        <a
                                            href="{concat('https://gams.uni-graz.at/', s:identifier)}"
                                            class="small link-dark mx-2"
                                            title="Permalink of the Collection:">
                                            <i class="fas fa-link ">
                                                <xsl:text> </xsl:text>
                                            </i>
                                            <span class="small ms-3">
                                                <xsl:value-of
                                                  select="concat('https://gams.uni-graz.at/', s:identifier)"
                                                />
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
                                                  select="format-dateTime(s:lastModifiedDate, '[D].[M].[Y]')"
                                                />
                                            </span>
                                        </span>
                                        <br/>
                                        <span title="{'Number of transactions'}" class="mx-2">
                                            <i class="fas fa-exchange-alt">
                                                <xsl:text> </xsl:text>
                                            </i>
                                            <xsl:text> </xsl:text>
                                            <span  class="small ms-3 transactions_count">
                                                <xsl:attribute name="data-pid" select="$PID"/>
                                            </span>
                                        </span>
                                    </div>
                                </div>
                                <!-- card footer -->
                                <div class="card-footer d-flex justify-content-center">
                                    <div class="btn-group">
                                        <xsl:choose>
                                            <!-- for TEI objects -->
                                            <xsl:when test="contains(s:model/@uri, 'cm:TEI')">
                                                <a href="{concat('/', $PID)}"
                                                  class="btn btn btn-outline-dark"
                                                  title="The edition view of the XML/TEI">
                                                  <xsl:text>Edition</xsl:text>
                                                </a>
                                                <a href="{concat('/', $PID, '/RDF')}"
                                                  class="btn btn btn-outline-dark"
                                                  title="The XML/RDF source">
                                                  <xsl:text>RDF</xsl:text>
                                                </a>
                                                <a href="{concat('/', $PID, '/TEI_SOURCE')}"
                                                  class="btn btn btn-outline-dark"
                                                  title="The XML/TEI source">
                                                  <xsl:text>XML/TEI</xsl:text>
                                                </a>
                                            </xsl:when>
                                            <!-- for RDF objects (Ontology in gams3)-->
                                            <xsl:otherwise>
                                                <a href="{concat('/', $PID)}"
                                                  class="btn btn btn-outline-dark"
                                                  title="The transactions view created from XML/RDF">
                                                  <xsl:text>Transactions</xsl:text>
                                                </a>
                                                <a href="{concat('/', $PID, '/ONTOLOGY')}"
                                                  class="btn btn btn-outline-dark"
                                                  title="The XML/RDF Source">
                                                  <xsl:text>RDF</xsl:text>
                                                </a>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </xsl:for-each-group>
                </div>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>
