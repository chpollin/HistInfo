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
    xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
    xmlns:dc="http://purl.org/dc/elements/1.1/" exclude-result-prefixes="#all">

    <!--<xsl:output method="xml" doctype-system="about:legacy-compat" encoding="UTF-8" indent="no"/>-->


    <xsl:include href="depcha-static.xsl"/>

    <!-- ///////////////////// -->
    <!-- tutorial -->
    <xsl:template name="content">
        <!-- tutorial body -->
        <div class="py-3 bg-light">
            <div class="container-fluid">
                <div class="row">
                    <div class="col-sm-3 col-xl-2 sidebar-column" style="z-index: 1; height: 90vh">
                        <!--Sidebar-->
                        <div class="sticky-top overflow-auto">
                            <nav id="tutorial-sidebar" class="collapse d-lg-block">
                                <div class="position-sticky">
                                    <div class="list-group mx-3 mt-4">
                                       
                                        <!-- Collapse subchapters if available -->
                                        <xsl:for-each
                                            select="//t:div[@xml:id = 'tutorial']/t:div[@xml:id]">
                                            <xsl:variable name="UPPER_POSITION" select="position()"/>
                                            <a href="{concat('#', @xml:id, '-list')}"
                                                class="list-group-item list-group-item-action py-2 fw-bold"
                                                aria-current="true" data-bs-toggle="collapse"
                                                aria-expanded="true"
                                                aria-controls="{concat(@xml:id, '-list')}"
                                                id="{t:head}" onclick="{concat('window.location.href=&quot;#', @xml:id ,'&quot;;')}">
                                                <span class="small">
                                                  <xsl:value-of
                                                  select="concat($UPPER_POSITION, '. ', t:head)"/>
                                                </span>
                                            </a>
                                            <xsl:if
                                                test="t:div">
                                                <ul id="{concat(@xml:id, '-list')}"
                                                  class="collapse list-group bg-light">
                                                  <xsl:for-each
                                                  select="./t:div">
                                                  <li class="list-group-item py-1"
                                                  data-bs-parent="{concat('#', ../t:head)}">
                                                  <a href="{concat('#', @xml:id)}"
                                                  class="nav-link small">
                                                  <xsl:value-of
                                                  select="concat($UPPER_POSITION, '.', position(), '. ', t:head)"
                                                  />
                                                  </a>
                                                  </li>
                                                  </xsl:for-each>
                                                </ul>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </div>
                                </div>
                            </nav>
                        </div>
                    </div>

                    <div class="col-sm-9 col-xl-10 p-3 min-vh-100 card">
                        <div class="row">
                            <!-- header left -->
                            <div>
                                <h2>
                                    <xsl:text>Tutorial</xsl:text>
                                </h2>
                            </div>
                           <!-- <!-\- header right -\->
                            <div class="col-8">
                                <xsl:text> </xsl:text>
                            </div>-->
                        </div>
                        <xsl:apply-templates select="//t:body"/>
                    </div>
                </div>
            </div>
        </div>
        <!-- Bootstrap core JS-->
        <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.3.1/highlight.min.js"><xsl:text> </xsl:text></script>
        <script>hljs.highlightAll();</script>
       
    </xsl:template>

    <!-- templates for TUTORIAL tutorial -->
    <xsl:template match="t:figure">
        <xsl:variable name="POSITION" select="count(preceding::t:code[@rend = 'block']) + 1"/>
        <figure class="figure container my-4">
            <img src="{concat('/', $teipid, '/', t:graphic/@xml:id)}" class="img-fluid d-block mx-auto" alt="{t:caption}"
                width="500" height="500"/>
            <xsl:if test="t:caption">
                <figcaption class="figure-caption text-center">
                    <xsl:value-of select="concat('Figure ', $POSITION, ': ', t:caption)"/>
                </figcaption>
            </xsl:if>
        </figure>
    </xsl:template>

    <xsl:template match="t:ref">
        <a class="link-dark" target="_blank">
            <xsl:if test="@target">
                <xsl:attribute name="href" select="@target"/>
            </xsl:if>
            <xsl:apply-templates/>
        </a>
    </xsl:template>

    <!--  -->
    <xsl:template match="t:span[@type = 'tooltip']">
        <span style="text-decoration: underline dotted">
            <xsl:if test="t:note">
                <xsl:attribute name="title" select="normalize-space(t:note)"/>
            </xsl:if>
            <xsl:apply-templates select="*[not(local-name() = 'note')]"/>
        </span>
    </xsl:template>

    <!--  -->
    <xsl:template match="t:ab[t:code[@rend = 'block']]">
        <xsl:variable name="POSITION" select="count(preceding::t:code[@rend = 'block']) + 1"/>
        <div class="border mb-3">
            <div class="nav p-2 justify-content-end">
                <a class="btn btn-outline-dark btn-sm" type="button"
                    onclick="copy(document.getElementById('{generate-id()}'))">Copy</a>
            </div>
            <div class="tab-content mb-4">
                <div class="tab-pane active" role="tabpanel">
                    <pre class="grey lighten-3 mb-0 line-numbers overflow-auto" style="max-height: 500px;">
                    <code id="{generate-id()}">
                        <xsl:value-of select="t:code[@rend = 'block']"/>
                    </code>
                </pre>
                    <xsl:if test="t:caption">
                        <figcaption class="figure-caption text-center">
                            <xsl:value-of
                                select="concat('Code Snippet ', $POSITION, ': ', normalize-space(t:caption))"
                            />
                        </figcaption>
                    </xsl:if>
                </div>
            </div>
        </div>
    </xsl:template>

    <!--  -->
    <xsl:template match="t:div[@xml:id]">
        <div id="{@xml:id}">
            <xsl:choose>
                <xsl:when test="t:head = 'Introduction'">
                    <xsl:attribute name="class" select="'anchor'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="class" select="'mt-5 anchor'"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <!--  -->
    <xsl:template match="t:p[@xml:id]">
        <p id="{@xml:id}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <!--  -->
    <xsl:template match="t:p | t:ab">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <!--  -->
    <xsl:template match="t:code">
        <code>
            <xsl:call-template name="rend"/>
            <xsl:apply-templates/>
        </code>
    </xsl:template>

    <!--  -->
    <xsl:template match="t:hi">
        <span>
            <xsl:call-template name="rend"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="t:list">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>

    <xsl:template match="t:item">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>

    <xsl:template match="t:table">
        <div class="my-2 table-responsive">
            <xsl:apply-templates select="t:head"/>
            <table class="table">
                <tbody>
                    <xsl:apply-templates select="t:row"/>
                </tbody>
            </table>
        </div>
    </xsl:template>

    <xsl:template match="t:row">
        <tr>
            <xsl:apply-templates/>
        </tr>
    </xsl:template>

    <xsl:template match="t:cell">
        <td>
            <xsl:apply-templates/>
        </td>
    </xsl:template>

    <xsl:template match="t:head">
        <xsl:variable name="depth" select="count(ancestor::t:div) + 2"/>
        <xsl:element name="h{$depth}">
            <xsl:attribute name="class"><xsl:text>pt-4</xsl:text></xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="rend">
        <xsl:if test="@rend">
            <xsl:choose>
                <xsl:when test="@rend = 'bold'">
                    <xsl:attribute name="class">
                        <xsl:text>fw-bold</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@rend = 'italic'">
                    <xsl:attribute name="class">
                        <xsl:text>fst-italic</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@rend = 'underline'">
                    <xsl:attribute name="class">
                        <xsl:text>text-decoration-underline</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@rend = 'attribute'">
                    <xsl:attribute name="class">
                        <xsl:text>hljs-attr</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="@rend = 'element'">
                    <xsl:attribute name="class">
                        <xsl:text>hljs-name</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>
