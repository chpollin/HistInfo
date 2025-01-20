<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    Project: depcha
    Company: ZIM-ACDH (Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities)
    Author: Christopher Pollin
    Last update: 2022
 -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
    xmlns:s="http://www.w3.org/2001/sw/DataAccess/rf1/result" xmlns="http://www.w3.org/1999/xhtml"
    xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dc="http://purl.org/dc/elements/1.1/"
    exclude-result-prefixes="#all">

    <!--<xsl:output method="xml" doctype-system="about:legacy-compat" encoding="UTF-8" indent="no"/>-->


    <xsl:include href="depcha-static.xsl"/>

    <!-- ///////////////////// -->
    <!-- CONTENT -->
    <xsl:template name="content">
        <div class="py-3 bg-light">
            <div class="container-fluid">
                <div class="row">



                    <div class="col-2 sidebar-column" style="z-index: 1; height: 90vh">
                        <!--Sidebar-->
                        <div class="sticky-top overflow-auto">
                            <nav id="ontology-sidebar" class="collapse d-lg-block">
                                <div class="position-sticky">
                                    <div class="list-group mx-3 mt-4">
                                        <!-- Collapse Classes -->
                                        <a
                                            class="list-group-item list-group-item-action py-2 fw-bold"
                                            aria-current="true" data-bs-toggle="collapse"
                                            href="#classes-list" aria-expanded="true"
                                            aria-controls="classes-list" id="classes">
                                            <span>Classes</span>
                                        </a>
                                        <!-- Classes List -->
                                        <ul id="classes-list" class="collapse list-group bg-light">
                                            <xsl:for-each-group
                                                select="//owl:Class[rdfs:label[@xml:lang = 'en']]"
                                                group-by="@rdf:about">
                                                <xsl:sort select="rdfs:label[@xml:lang = 'en']"/>
                                                <xsl:variable name="UPPER_POSITION"
                                                  select="position()"/>
                                                <!-- skip sub unit classes -->
                                                <xsl:if
                                                  test="not(contains(rdfs:label[@xml:lang = 'en'], 'Unit of '))">
                                                  <li class="list-group-item py-1"
                                                  data-bs-parent="#classes">
                                                  <a
                                                  href="{concat('#', substring-after(current-grouping-key(), '#'))}"
                                                  class="nav-link small">
                                                  <xsl:value-of
                                                  select="rdfs:label[@xml:lang = 'en']"/>
                                                  </a>
                                                  </li>
                                                </xsl:if>
                                            </xsl:for-each-group>
                                        </ul>


                                        <!-- Collapse Properties -->
                                        <a
                                            class="list-group-item list-group-item-action py-2 fw-bold"
                                            aria-current="true" data-bs-toggle="collapse"
                                            href="#properties-list" aria-expanded="true"
                                            aria-controls="properties-list" id="properties">
                                            <span>Properties</span>
                                        </a>
                                        <!-- Properties List -->
                                        <ul id="properties-list"
                                            class="collapse list-group bg-light">
                                            <xsl:for-each-group
                                                select="//owl:ObjectProperty[rdfs:label[@xml:lang = 'en']] | //owl:DatatypeProperty[rdfs:label[@xml:lang = 'en']]"
                                                group-by="@rdf:about">
                                                <xsl:sort select="rdfs:label[@xml:lang = 'en']"
                                                  data-type="text"/>
                                                <li class="list-group-item py-1"
                                                  data-bs-parent="#properties">
                                                  <a
                                                  href="{concat('#', substring-after(current-grouping-key(), '#'))}"
                                                  class="nav-link small">
                                                  <xsl:value-of
                                                  select="rdfs:label[@xml:lang = 'en']"/>

                                                  </a>
                                                </li>
                                            </xsl:for-each-group>
                                        </ul>

                                    </div>
                                </div>
                            </nav>
                        </div>
                    </div>





                    <div class="col-sm-9 p-3 min-vh-100 card">
                        <div class="row row-cols-2 row-cols-md-2 row-cols-sm-1">
                            <!-- header left -->
                            <div class="col-4">
                                <h2>
                                    <xsl:value-of select="rdf:RDF/owl:Ontology/dc:title"/>
                                </h2>
                                <p>
                                    <xsl:text>Base-URL: https://gams.uni-graz.at/o:depcha.bookkeeping#</xsl:text>
                                    <button
                                        onclick="copyText('https://gams.uni-graz.at/o:depcha.bookkeeping#')"
                                        type="button"
                                        class="btn btn-sm ms-2"
                                        title="Copy to Clipboard: https://gams.uni-graz.at/o:depcha.bookkeeping#">
                                        <i class="fa fa-clone" style="pointer-events: none">
                                            <xsl:text> </xsl:text>
                                        </i>
                                    </button>
                                </p>
                            </div>
                            <div class="col-8">
                                <div id="{concat('a', //dc:description[1]/generate-id())}">
                                    <div>
                                        <h3 id="ontology_description" class="text-center">
                                            <button class="btn btn-outline-dark collapsed"
                                                type="button" data-bs-toggle="collapse"
                                                data-bs-target="#p_ontology_description"
                                                aria-expanded="false" aria-controls="collapseTwo">
                                                <xsl:text>Description</xsl:text>
                                            </button>
                                            <a href="/o:depcha.bookkeeping/ONTOLOGY"
                                                class="btn btn btn-outline-dark"
                                                title="XML/RDF source of the ontology">
                                                <xsl:text>RDF</xsl:text>
                                            </a>
                                            <a
                                                href="https://service.tib.eu/webvowl/#iri=https://gams.uni-graz.at/o:depcha.bookkeeping/ONTOLOGY"
                                                target="_blank" class="btn btn btn-outline-dark"
                                                title="WebVowl">
                                                <xsl:text>WebVowl</xsl:text>
                                            </a>
                                        </h3>
                                        <p class="text-center">
                                            <xsl:value-of
                                                select="rdf:RDF/owl:Ontology/owl:versionInfo"/>
                                            <xsl:text> by </xsl:text>
                                            <xsl:for-each select="//dc:creator">
                                                <xsl:value-of select="."/>
                                                <xsl:if test="not(last() = position())">
                                                  <xsl:text> / </xsl:text>
                                                </xsl:if>
                                            </xsl:for-each>
                                            <xsl:text>. </xsl:text>
                                            <xsl:value-of select="//dc:date[1]"/>
                                            <xsl:text>.</xsl:text>
                                        </p>

                                        <div id="p_ontology_description"
                                            class="accordion-collapse collapse">
                                            <p class="accordion-body">
                                                <xsl:value-of select="//dc:description[1]"/>
                                            </p>
                                        </div>
                                    </div>
                                </div>
                                <!--<h4></h4>
                                <p>
                                    <xsl:value-of select="normalize-space(rdf:RDF/owl:Ontology/dc:description)"/>
                                </p>-->
                            </div>
                        </div>
                        <div id="classes" class="anchor">
                            <div class="row">
                                <h3 class="col-10">Classes</h3>
                            </div>
                            <xsl:for-each-group select="//owl:Class[rdfs:label[@xml:lang = 'en']]"
                                group-by="(@rdf:about)">
                                <xsl:sort select="rdfs:label[@xml:lang = 'en']" data-type="text"/>
                                <div class="m-3 anchor"
                                    id="{substring-after(current-grouping-key(), '#')}">
                                    <h4>
                                        <xsl:value-of select="rdfs:label[@xml:lang = 'en']"/>
                                        <button onclick="copyText('{current-grouping-key()}')"
                                            type="button" class="btn btn-sm"
                                            style="float:right"
                                            title="Copy to Clipboard: {current-grouping-key()}">
                                            <i class="fa fa-clone" style="pointer-events: none">
                                                <xsl:text> </xsl:text>
                                            </i>
                                        </button>
                                    </h4>
                                    <xsl:call-template name="createTable"/>
                                </div>
                            </xsl:for-each-group>
                        </div>
                        <div id="properties" class="anchor">
                            <h3>Properties</h3>
                            <xsl:for-each-group
                                select="//owl:ObjectProperty[@rdf:about][rdfs:label] | //owl:DatatypeProperty[@rdf:about]"
                                group-by="(@rdf:about)">
                                <xsl:sort select="rdfs:label[@xml:lang = 'en']" data-type="text"/>
                               
                                <div class="m-3 anchor"
                                    id="{substring-after(current-grouping-key(), '#')}">
                                    <h4>
                                        <xsl:value-of select="rdfs:label[@xml:lang='en']"/>
                                        <button onclick="copyText('{current-grouping-key()}')"
                                            type="button" class="btn btn-sm"
                                            style="float:right"
                                            title="Copy to Clipboard: {current-grouping-key()}">
                                            <i class="fa fa-clone" style="pointer-events: none">
                                                <xsl:text> </xsl:text>
                                            </i>
                                        </button>
                                    </h4>
                                    <xsl:call-template name="createTable"/>
                                </div>
                            </xsl:for-each-group>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>


    <!-- ///////////////////////////////////////////////////////////// -->
    <!-- createTable -->
    <xsl:template name="createTable">
        <div class="table-responsive">
            <table class="table" id="{current-grouping-key()}">
                <tbody>
                    <xsl:if test="rdfs:subClassOf">
                        <tr class="d-flex">
                            <td class="col-2 fw-bold text-truncate" title="Subclass of">Subclass
                                of</td>
                            <td class="col-10">
                                <xsl:for-each select="rdfs:subClassOf/@rdf:resource">
                                    <a href="{.}">
                                        <xsl:choose>
                                            <xsl:when test="contains(., 'cidoc-crm')">
                                                <xsl:value-of
                                                  select="substring-after(., 'cidoc-crm/')"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:variable name="currentClass" select="."/>
                                                <xsl:value-of
                                                  select="//owl:Class[@rdf:about = $currentClass]/rdfs:label[@xml:lang = 'en']"
                                                />
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </a>
                                    <xsl:if test="not(position() = last())">
                                        <br class="my-1"/>
                                    </xsl:if>
                                </xsl:for-each>
                            </td>
                        </tr>
                    </xsl:if>
                    <!-- DESCRIPTION -->
                    <xsl:if test="rdfs:comment">
                        <tr class="d-flex">
                            <td class="col-2 fw-bold text-truncate" title="Description"
                                >Description</td>
                            <td class="col-10">
                                <xsl:value-of select="rdfs:comment[@xml:lang = 'en']"/>
                            </td>
                        </tr>
                    </xsl:if>
                    <!-- seeAlso -->
                    <xsl:if test="rdfs:seeAlso/@rdf:resource">
                        <tr class="d-flex">
                            <td class="col-2 fw-bold text-truncate" title="seeAlso">seeAlso</td>
                            <td class="col-10">
                                <xsl:for-each select="rdfs:seeAlso/@rdf:resource">
                                    <a href="{.}" target="_blank">
                                        <xsl:value-of
                                            select="substring-before(substring-after(., '.'), '/')"
                                        />
                                    </a>
                                </xsl:for-each>
                            </td>
                        </tr>
                    </xsl:if>
                    <!-- DOMAIN -->
                    <xsl:variable name="Domain"
                        select="rdfs:domain/@rdf:resource | //owl:ObjectProperty[rdfs:domain/@rdf:resource = current-grouping-key()]"/>
                    <xsl:if test="$Domain">
                        <tr class="d-flex">
                            <td class="col-2 fw-bold text-truncate" title="Domain">Domain</td>
                            <td class="col-10">
                                <xsl:for-each
                                    select="//owl:Class[@rdf:about = $Domain]/rdfs:label[@xml:lang = 'en']">
                                    <a href="{concat('#', substring-after(../@rdf:about, '#'))}">
                                        <xsl:if test="position() &gt; 1">
                                            <xsl:attribute name="class" select="'ms-5'"/>
                                        </xsl:if>
                                        <xsl:value-of select="."/>
                                    </a>
                                    <xsl:text> </xsl:text>
                                </xsl:for-each>
                                <xsl:for-each select="$Domain/rdfs:label[@xml:lang = 'en']">
                                    <a href="{concat('#', substring-after(../@rdf:about, '#'))}">
                                        <xsl:if test="position() &gt; 1">
                                            <xsl:attribute name="class" select="'ms-5'"/>
                                        </xsl:if>
                                        <xsl:value-of select="."/>
                                    </a>
                                    <xsl:text> </xsl:text>
                                </xsl:for-each>
                            </td>
                        </tr>
                    </xsl:if>
                    <!-- RANGE -->
                    <xsl:variable name="Range"
                        select="rdfs:range/@rdf:resource | //owl:ObjectProperty[rdfs:range/@rdf:resource = current-grouping-key()]"/>
                    <xsl:if test="$Range">
                        <tr class="d-flex">
                            <td class="col-2 fw-bold text-truncate" title="Range">Range</td>
                            <td class="col-10">
                                <xsl:choose>
                                    <xsl:when
                                        test="//owl:Class[@rdf:about = $Range]/rdfs:label[@xml:lang = 'en']">
                                        <xsl:for-each
                                            select="//owl:Class[@rdf:about = $Range]/rdfs:label[@xml:lang = 'en']">
                                            <a
                                                href="{concat('#', substring-after(../@rdf:about, '#'))}">
                                                <xsl:if test="position() &gt; 1">
                                                  <xsl:attribute name="class" select="'ms-5'"/>
                                                </xsl:if>
                                                <xsl:value-of select="."/>
                                            </a>
                                            <xsl:text> </xsl:text>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:when test="$Range/rdfs:label[@xml:lang = 'en']">
                                        <xsl:for-each select="$Range/rdfs:label[@xml:lang = 'en']">
                                            <a
                                                href="{concat('#', substring-after(../@rdf:about, '#'))}">
                                                <xsl:if test="position() &gt; 1">
                                                  <xsl:attribute name="class" select="'ms-5'"/>
                                                </xsl:if>
                                                <xsl:value-of select="."/>
                                            </a>
                                            <xsl:text> </xsl:text>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:for-each select="$Range">
                                            <a href="{.}">
                                                <xsl:if test="position() &gt; 1">
                                                  <xsl:attribute name="class" select="'ms-5'"/>
                                                </xsl:if>
                                                <xsl:value-of select="substring-after(., '#')"/>
                                            </a>
                                        </xsl:for-each>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                        </tr>
                    </xsl:if>
                </tbody>
            </table>
        </div>
    </xsl:template>




</xsl:stylesheet>
