<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:functx="http://www.functx.com" xmlns:gn="http://www.geonames.org/ontology#"
	xmlns:gams="https://gams.uni-graz.at/o:gams-ontology#"
	xmlns:huc="https://gams.uni-graz.at/o:depcha.huc-ontology#" xmlns:time="http://www.w3.org/2006/time#"
	xmlns:schema="https://schema.org/" xmlns:bk="https://gams.uni-graz.at/o:depcha.bookkeeping#"
	xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:t="http://www.tei-c.org/ns/1.0"
	xmlns:depcha="https://gams.uni-graz.at/o:depcha.ontology#"
	xmlns:void="http://rdfs.org/ns/void#">
	<xsl:strip-space elements="*"/>
	<!-- VARIABLES -->
	<!-- //////////////////////////////// -->
	<!-- global Variables -->
	<xsl:variable name="teiHeader" select="/t:TEI/t:teiHeader"/>
	<xsl:variable name="BASE-URL" select="'https://gams.uni-graz.at/'"/>
	<xsl:variable name="TEI-PID" select="//t:publicationStmt/t:idno[@type = 'PID']"/>
	<xsl:variable name="CONTEXT" select="
			if (contains($teiHeader//t:publicationStmt/t:ref[@type = 'context'][1]/@target, 'info:fedora/')) then
				(substring-after($teiHeader//t:publicationStmt/t:ref[@type = 'context'][1]/@target, 'info:fedora/'))
			else
				($teiHeader//t:publicationStmt/t:ref[@type = 'context'][1]/@target)"/>
	<xsl:variable name="LIST_PERSON" select="//t:listPerson[@ana = 'depcha:index'][1]"/>
	<xsl:variable name="LIST_ORG" select="//t:listOrg[@ana = 'depcha:index'][1]"/>
	<xsl:variable name="LIST_PLACE" select="//t:listPlace[@ana = 'depcha:index'][1]"/>
	<xsl:variable name="LIST_ACCOUNTS" select="//t:taxonomy[@ana = 'bk:account'][1] | //t:taxonomy[@ana = 'bk:rubrics'][1]"/>
	<xsl:variable name="ACCOUNHOLDER-URI" select="concat($BASE-URL, $CONTEXT, '#', //*[tokenize(@ana, ' ') = 'depcha:accountHolder']/@xml:id)"/>
	<!--  -->
	<xsl:variable name="quot" select="'&quot;'"/>
	<!-- BK URI -->
	<xsl:variable name="BK_URI">
		<xsl:choose>
			<xsl:when test="//t:listPrefixDef/t:prefixDef/@ident = 'bk'">
				<xsl:value-of
					select="substring-before(//t:listPrefixDef/t:prefixDef/@replacementPattern, '$')"
				/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>Log: "t:listPrefixDef/t:prefixDef/@ident = 'bk'" is
					missing</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- all bk:entry -->
	<xsl:variable name="ALL_BK_ENTRY" select="//t:text//*[tokenize(@ana, ' ') = 'bk:entry']"/>
	<!-- main -->
	<xsl:template match="/">
		<rdf:RDF>
			<xsl:choose>
				<!-- check if the TEI has a PID -->
				<xsl:when test="$TEI-PID">
					<xsl:copy>
						<!-- this variable contains the whole rdf document -->
						<xsl:variable name="RDF_RESULT">
							<xsl:call-template name="get_RDF_RESULT"/>
						</xsl:variable>
						<!-- this variable contains the whole rdf document + depcha:Dataset which contains aggregation statments about the rdf document -->
						<xsl:variable name="RDF_RESULT_DEPCHA_DATASET">
							<xsl:call-template name="get_RDF_RESULT_DEPCHA_DATASET">
								<xsl:with-param name="RDF_RESULT" select="$RDF_RESULT"/>
							</xsl:call-template>
						</xsl:variable>
						<!-- prints the depcha dataset -->
						<xsl:copy-of select="$RDF_RESULT_DEPCHA_DATASET"/>
						<!--  -->
						<xsl:copy-of select="$RDF_RESULT"/>
					</xsl:copy>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>ERROR: No PID defined in idno/@type="PID"</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</rdf:RDF>
	</xsl:template>
	<xsl:template name="get_RDF_RESULT_DEPCHA_DATASET">
		<xsl:param name="RDF_RESULT"/>
		<!-- ////////////////// -->
		<!-- bk:Dataset: aggregations of bk:Transactions etc. -->
		<xsl:variable name="DATASET-URI" select="concat($BASE-URL, $TEI-PID, '.dataset')"/>
		<depcha:Dataset rdf:about="{$DATASET-URI}">
			<gams:isMemberOfCollection rdf:resource="{concat($BASE-URL, $CONTEXT)}"/>
			<gams:isPartOf rdf:resource="{concat($BASE-URL, $TEI-PID)}"/>
			<!-- depcha:numberOfTransactions -->
			<depcha:numberOfTransactions>
				<xsl:value-of select="count(//$RDF_RESULT/bk:Transaction)"/>
			</depcha:numberOfTransactions>
			<!-- depcha:numberOfTransactions -->
			<depcha:numberOfTransfers>
				<xsl:value-of select="count(//$RDF_RESULT/bk:Transaction/bk:consistsOf/bk:Transfer)"/>
			</depcha:numberOfTransfers>
			<!-- depcha:numberOfEconomicAgents -->
			<depcha:numberOfEconomicAgents>
				<xsl:value-of select="count(//$RDF_RESULT/bk:EconomicAgent) + count(//$RDF_RESULT/bk:Group) + count(//$RDF_RESULT/bk:Individual) + count(//$RDF_RESULT/bk:Organisation)"/>
			</depcha:numberOfEconomicAgents>
			<!-- -->
			<depcha:numberOfMonetaryValues>
				<xsl:value-of select="count(//$RDF_RESULT/bk:Transaction//bk:Money[1])"/>
			</depcha:numberOfMonetaryValues>
			<depcha:numberOfEconomicGoods>
				<xsl:value-of
					select="count(//$RDF_RESULT/bk:Transaction//bk:Commodity) + count(//$RDF_RESULT/bk:Transaction//bk:Service) + count(//$RDF_RESULT/bk:Transaction//bk:Right)"
				/>
			</depcha:numberOfEconomicGoods>
			<!-- depcha:numberOfPlaces -->
			<depcha:numberOfPlaces>
				<xsl:value-of select="count(//$RDF_RESULT//*:Place)"/>
			</depcha:numberOfPlaces>
			<!-- depcha:numberOfAccounts -->
			<depcha:numberOfAccounts>
				<xsl:value-of select="count(//$RDF_RESULT/bk:Account)"/>
			</depcha:numberOfAccounts>	
			<!-- depcha:numberOfSubTotals -->
			<xsl:if test="//$RDF_RESULT/bk:SubTotalTransaction[1]">
				<depcha:numberOfSubTotals>
					<xsl:value-of select="count(//$RDF_RESULT/bk:SubTotalTransaction)"/>
				</depcha:numberOfSubTotals>
			</xsl:if>
			<!-- depcha:numberOfTotals -->
			<xsl:if test="//$RDF_RESULT/bk:TotalTransaction[1]">
				<depcha:numberOfTotals>
					<xsl:value-of select="count(//$RDF_RESULT/bk:TotalTransaction)"/>
				</depcha:numberOfTotals>
			</xsl:if>
			<!--  -->
			<xsl:if test="//t:teiHeader//*[tokenize(@ana, ' ') = 'depcha:accountHolder']">
				<depcha:accountHolder rdf:resource="{$ACCOUNHOLDER-URI}"/>
			</xsl:if>
			<xsl:variable name="MAIN_CURRENCY_URI"
				select="concat($BASE-URL, $CONTEXT, '#', encode-for-uri(//t:teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@ana = 'depcha:mainCurrency']/@xml:id))"/>
			<xsl:variable name="MAIN_CURRENCY_LABEL"
				select="//t:teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@ana = 'depcha:mainCurrency']/t:label[1]"/>
			<xsl:choose>
				<xsl:when
					test="//t:teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@type = 'currency']">
					<!-- depcha:unit  -->
					<xsl:for-each
						select="//t:teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@type = 'currency']">
						<depcha:currency rdf:resource="{concat($BASE-URL, $CONTEXT, '#', encode-for-uri(@xml:id))}"/>
						<xsl:if test="@ana = 'depcha:mainCurrency'">
							<depcha:isMainCurrency rdf:resource="{$MAIN_CURRENCY_URI}"/>
						</xsl:if>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message>
						<xsl:text>Error: Please add a @type='currency' to t:unitDef</xsl:text>
					</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:variable name="CONVERSIONS">
				<xsl:for-each select="//$RDF_RESULT//huc:Conversion[huc:convertsFrom/@rdf:resource = $MAIN_CURRENCY_URI]">
					<currency uri="{huc:convertsTo/@rdf:resource}" divisor="{number(substring-after(huc:formula, 'div '))}"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:for-each-group select="//$RDF_RESULT/bk:Transaction/bk:when"
				group-by="substring(., 1, 4)">
				<xsl:variable name="currentYear" select="current-grouping-key()"/>
				<xsl:variable name="TRANSACTIONS"
					select="//bk:Transaction[contains(bk:when, $currentYear)]"/>
				<!-- @rdf:resource is accountHolder -->
				<xsl:variable name="TRANSACTIONS-REVENUE"
					select="$TRANSACTIONS/bk:consistsOf/bk:Transfer[bk:to/@rdf:resource = $ACCOUNHOLDER-URI]"/>
				<!-- @rdf:resource is accountHolder -->
				<xsl:variable name="TRANSACTIONS-EXPENSES"
					select="$TRANSACTIONS/bk:consistsOf/bk:Transfer[bk:from/@rdf:resource = $ACCOUNHOLDER-URI]"/>
				<!-- depcha:Aggregation -->
				<depcha:aggregates>
					<depcha:Aggregation
						rdf:about="{concat($DATASET-URI, '.aggre#', $currentYear)}">
						<depcha:date>
							<xsl:value-of select="$currentYear"/>
						</depcha:date>
						<bk:unit>
							<xsl:value-of select="$MAIN_CURRENCY_LABEL"/>
						</bk:unit>
						<xsl:variable name="REVENUE">
							<position currency="{$MAIN_CURRENCY_URI}" amount="{sum($TRANSACTIONS-REVENUE//bk:Money[bk:unit/@rdf:resource = $MAIN_CURRENCY_URI]/bk:quantity)}"/>
							<xsl:for-each select="$CONVERSIONS/currency">
								<xsl:variable name="myuri" select="@uri"/>
								<xsl:variable name="mydivisor" select="@divisor"/>
								<position currency="{$myuri}" amount="{sum($TRANSACTIONS-REVENUE//bk:Money[bk:unit/@rdf:resource = $myuri]/bk:quantity) div $mydivisor}"/>
							</xsl:for-each>
						</xsl:variable>
						<depcha:revenue>
							<xsl:value-of select="sum($REVENUE/position/@amount)"/>
						</depcha:revenue>
						<xsl:variable name="EXPENSES">
							<position currency="{$MAIN_CURRENCY_URI}" amount="{sum($TRANSACTIONS-EXPENSES//bk:Money[bk:unit/@rdf:resource = $MAIN_CURRENCY_URI]/bk:quantity)}"/>
							<xsl:for-each select="$CONVERSIONS/currency">
								<xsl:variable name="myuri" select="@uri"/>
								<xsl:variable name="mydivisor" select="@divisor"/>
								<position currency="{$myuri}" amount="{sum($TRANSACTIONS-EXPENSES//bk:Money[bk:unit/@rdf:resource = $myuri]/bk:quantity) div $mydivisor}"/>
							</xsl:for-each>
						</xsl:variable>
						<depcha:expenses>
							<xsl:value-of select="sum($EXPENSES/position/@amount)"/>
						</depcha:expenses>
					</depcha:Aggregation>
				</depcha:aggregates>
			</xsl:for-each-group>
		</depcha:Dataset>
	</xsl:template>
	<xsl:template name="get_RDF_RESULT">
		<!-- ////////////////// -->
		<!-- void:Dataset, metadata -->
		<void:Dataset rdf:about="{concat($BASE-URL, $TEI-PID)}">
			<dc:rights>https://creativecommons.org/licenses/by/4.0/</dc:rights>
			<dc:publisher>Department of Digital Humanities, University of
				Graz</dc:publisher>
			<xsl:choose>
				<xsl:when test="//t:teiHeader//t:msDesc">
					<xsl:variable name="msItem"
						select="//t:teiHeader//t:msDesc/t:msContents/t:msItem[1]"/>
					<xsl:if test="$msItem">
						<xsl:if test="$msItem/t:docAuthor">
							<dc:creator>
								<xsl:value-of select="$msItem/t:docAuthor"/>
							</dc:creator>
						</xsl:if>
						<xsl:if test="$msItem/t:docDate">
							<dc:date>
								<xsl:value-of select="$msItem/t:docDate"/>
							</dc:date>
						</xsl:if>
						<xsl:for-each select="$msItem/t:textLang/t:lang">
							<dc:language>
								<xsl:value-of select="."/>
							</dc:language>
						</xsl:for-each>
					</xsl:if>
					<xsl:if test="//t:teiHeader//t:msDesc/t:msIdentifier">
						<xsl:variable name="msIdentifier"
							select="//t:teiHeader//t:msDesc/t:msIdentifier"/>
						<xsl:if test="$msIdentifier/t:msName">
							<dc:title>
								<xsl:value-of select="$msIdentifier/t:msName"/>
							</dc:title>
						</xsl:if>
						<dc:source>
							<xsl:for-each select="$msIdentifier/*">
								<xsl:value-of select="normalize-space(.)"/>
								<xsl:choose>
									<xsl:when test="not(position() = last())">
										<xsl:text>, </xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text> </xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</dc:source>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message>Log: Missing msDesc to fill void:Dataset</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
		</void:Dataset>
		<!-- ////////////////// -->
		<!-- create bk:Transaction -->
		<xsl:apply-templates select="$ALL_BK_ENTRY"/>
		<!-- ////////////////// -->
		<!-- create bk:Sum -->
		<!--<xsl:apply-templates select="//t:text//*[tokenize(@ana, ' ') = 'bk:sum']"/>-->
		<!-- ////////////////// -->
		<!-- create bk:TotalTransaction -->
		<xsl:apply-templates select="//t:text//*[tokenize(@ana, ' ') = 'bk:total']"/>
		<!-- ////////////////// -->
		<!-- create bk:SubTotalTransaction -->
		<xsl:apply-templates select="//t:text//*[tokenize(@ana, ' ') = 'bk:subtotal']"/>
		<!-- ////////////////// -->
		<!-- create bk:EconomicAgent, bk:Account -->
		<xsl:choose>
			<xsl:when test="$LIST_PERSON/t:person | $LIST_PERSON/t:personGrp | $LIST_ORG/t:org | $LIST_ACCOUNTS">
				<xsl:apply-templates select="$LIST_PERSON/t:person | $LIST_PERSON/t:personGrp"/>
				<xsl:apply-templates select="$LIST_ORG/t:org"/>
				<!-- skip list account -->
			</xsl:when>
			<xsl:when
				test="//.[tokenize(@ana, ' ') = 'bk:to']/@ref | //.[tokenize(@ana, ' ') = 'bk:from']/@ref">
				<xsl:message>Log: bk:EconomicAgent is extracted from data, because no listPerson is
					available or tagged with @ana = 'depcha:index'</xsl:message>
				<xsl:for-each-group
					select="//.[tokenize(@ana, ' ') = 'bk:to'] | //.[tokenize(@ana, ' ') = 'bk:from']"
					group-by="@ref">
					<xsl:variable name="Between-URI">
						<xsl:choose>
							<xsl:when test="contains(current-grouping-key(), '#')">
								<xsl:value-of
									select="concat($BASE-URL, $CONTEXT, current-grouping-key())"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of
									select="concat($BASE-URL, $CONTEXT, '#', current-grouping-key())"
								/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="BK_ECONOMIC_AGENT_SUBCLASS">
						<xsl:call-template name="BK_ECONOMIC_AGENT_SUBCLASS_CHOOSE"/>
					</xsl:variable>
					<xsl:element name="{$BK_ECONOMIC_AGENT_SUBCLASS}">
						<xsl:attribute name="rdf:about" select="$Between-URI"/>
						<xsl:choose>
							<xsl:when test="*">
								<xsl:apply-templates select="."/>
								<!-- create from all name elements one rdfs:label string -->
								<!--<rdfs:label>
									<xsl:for-each select="*">
										<xsl:value-of select="normalize-space(.)"/>
										<xsl:if test="not(position() = last())">
											<xsl:text> </xsl:text>
										</xsl:if>
									</xsl:for-each>
								</rdfs:label>-->
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates select="."/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:element>
				</xsl:for-each-group>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each-group
					select="//*[tokenize(@ana, ' ') = 'bk:to'] | //*[tokenize(@ana, ' ') = 'bk:from']"
					group-by=".">
					<xsl:variable name="BK_ECONOMIC_AGENT_SUBCLASS">
						<xsl:call-template name="BK_ECONOMIC_AGENT_SUBCLASS_CHOOSE"/>
					</xsl:variable>
					<xsl:element name="{$BK_ECONOMIC_AGENT_SUBCLASS}">
						<xsl:attribute name="rdf:about" select="concat($BASE-URL, $CONTEXT, '#', encode-for-uri(translate(.,' ','')))"/>
						<rdfs:label>
							<xsl:value-of select="normalize-space(.)"/>
						</rdfs:label>
					</xsl:element>
				</xsl:for-each-group>
			</xsl:otherwise>
		</xsl:choose>
		<!-- ////////////////////////// -->
		<!-- INDICES -->
		<!-- ////////////////////////// -->
		<!-- taxonomy of commodities depcha:index to SKOS -->
		<xsl:apply-templates select="$teiHeader//t:taxonomy[tokenize(@ana, ' ') = 'depcha:index']"/>
		<!-- taxonomy of accounting classes to SKOS -->
		<xsl:apply-templates select="$teiHeader//t:taxonomy[tokenize(@ana, ' ') = 'bk:account'] | $teiHeader//t:taxonomy[tokenize(@ana, ' ') = 'bk:rubrics']"/>
		<!-- ////////////////////////// -->
		<!-- bk:where - Index - Places -->
		<xsl:apply-templates select="$teiHeader//t:listPlace[@ana = 'depcha:index']/t:place"/>
		<!-- ////////////////////////// -->
		<!-- listOrg to schema:Organization -->
		<xsl:apply-templates select="$teiHeader//t:listOrg[@ana = 'depcha:index']/t:org"/>
		<!-- ////////////////////////// -->
		<xsl:apply-templates select="//t:unitDef"/>
	</xsl:template>
	<!--//////////////////////////////////////// -->
	<!-- This called template creates a URI for an entity. it returns a valid URI with a '#' and a lower-case id.
        * it also handles internal or external URI in @ref etc.
        * id can come from a @xml:id, @ref or @corresp.
        * if no id exists it is created by concating and normalizing the text node
        return: https://gams.uni-graz.at/o:depcha.schlandersberger.1#commodity.4.7 -->
	<xsl:template name="build_URI_for_rdf_about_resource">
		<xsl:param name="BASE_URL"/>
		<xsl:param name="PID"/>
		<xsl:param name="ID"/>
		<xsl:choose>
			<!-- ID is a URI -->
			<!-- todo: is there a better way to check of a URI; do i have to check for internal or external URIs? -->
			<xsl:when test="starts-with($ID, 'https') or starts-with($ID, 'http')">
				<xsl:value-of select="$ID"/>
			</xsl:when>
			<!-- case: @ref="#commodity.1" -->
			<xsl:when test="contains($ID, '#')">
				<xsl:value-of select="concat($BASE-URL, $PID, normalize-space(lower-case($ID)))"/>
			</xsl:when>
			<!-- case: @xml:id="commodity.1" -->
			<xsl:when test="$ID">
				<xsl:value-of
					select="concat($BASE-URL, $PID, '#', encode-for-uri(normalize-space(lower-case($ID))))"
				/>
			</xsl:when>
			<!-- case: no @* -->
			<xsl:when test="text()">
				<xsl:value-of
					select="concat($BASE-URL, $PID, '#', encode-for-uri(normalize-space(lower-case(.))))"
				/>
			</xsl:when>
			<!-- no URI created -->
			<xsl:otherwise>
				<xsl:value-of select="concat($BASE-URL, $PID, '#error')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ####################################### -->
	<!-- transforming listOrg to schema:Organization -->
	<xsl:template match="t:listOrg[@ana = 'depcha:index']/t:org">
		<xsl:variable name="ORG-URI">
			<xsl:call-template name="build_URI_for_rdf_about_resource">
				<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
				<xsl:with-param name="PID" select="$CONTEXT"/>
				<xsl:with-param name="ID" select="@xml:id"/>
			</xsl:call-template>
		</xsl:variable>
		<bk:Organisation rdf:about="{$ORG-URI}">
			<xsl:if test="t:orgName[1] | t:name[1]">
				<schema:name>
					<xsl:value-of select="normalize-space(t:orgName[1] | t:name[1])"/>
				</schema:name>
				<rdfs:label>
					<xsl:value-of select="normalize-space(t:orgName[1] | t:name[1])"/>
				</rdfs:label>
			</xsl:if>
			<xsl:if test="t:settlement">
				<schema:containedInPlace>
					<xsl:value-of select="t:settlement"/>
				</schema:containedInPlace>
			</xsl:if>
			<xsl:if test="t:region">
				<schema:containedInPlace>
					<xsl:value-of select="t:region"/>
				</schema:containedInPlace>
			</xsl:if>
		</bk:Organisation>
	</xsl:template>
	<!-- ####################################### -->
	<!-- transforming listPlace to schema:Place -->
	<xsl:template match="t:listPlace[@ana = 'depcha:index']/t:place">
		<xsl:variable name="PLACE_URI">
			<xsl:call-template name="build_URI_for_rdf_about_resource">
				<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
				<xsl:with-param name="PID" select="$CONTEXT"/>
				<xsl:with-param name="ID" select="@xml:id"/>
			</xsl:call-template>
		</xsl:variable>
		<schema:Place rdf:about="{$PLACE_URI}">
			<xsl:if test="t:placeName">
				<rdfs:label>
					<xsl:value-of select="normalize-space(t:placeName[1])"/>
				</rdfs:label>
				<schema:name>
					<xsl:value-of select="normalize-space(t:placeName[1])"/>
				</schema:name>
			</xsl:if>
			<xsl:if test="t:location/t:country">
				<schema:containedInPlace>
					<xsl:value-of select="t:location/t:country"/>
				</schema:containedInPlace>
			</xsl:if>
			<xsl:if test="t:location/t:settlement">
				<schema:containedInPlace>
					<xsl:value-of select="t:location/t:settlement"/>
				</schema:containedInPlace>
			</xsl:if>
			<!-- t:geo - longitude, latitude -->
			<xsl:choose>
				<xsl:when test="contains(t:location/t:geo, ',')">
					<schema:longitude>
						<xsl:value-of
							select="normalize-space(substring-before(t:location/t:geo, ','))"/>
					</schema:longitude>
					<schema:latitude>
						<xsl:value-of
							select="normalize-space(substring-after(t:location/t:geo, ','))"/>
					</schema:latitude>
				</xsl:when>
				<xsl:when test="contains(t:location/t:geo, ' ')">
					<schema:longitude>
						<xsl:value-of
							select="normalize-space(substring-before(t:location/t:geo, ' '))"/>
					</schema:longitude>
					<schema:latitude>
						<xsl:value-of
							select="normalize-space(substring-after(t:location/t:geo, ' '))"/>
					</schema:latitude>
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</schema:Place>
	</xsl:template>
	<!-- ####################################### -->
	<!-- mapping t:unitDef to http://www.ontology-of-units-of-measure.org/resource/om-2/Unit -->
	<xsl:template match="t:unitDef">
		<!-- huc = "https://gams.uni-graz.at/o:depcha.huc-ontology" -->
		<xsl:variable name="Unit_URI" select="concat($BASE-URL, $CONTEXT, '#', encode-for-uri(@xml:id))"/>
		<huc:HistoricalUnit rdf:about="{$Unit_URI}">
			<xsl:if test="t:label[1]">
				<rdfs:label>
					<xsl:value-of select="t:label[1]"/>
				</rdfs:label>
			</xsl:if>
			<huc:definedBy>
				<huc:Context rdf:about="{concat($Unit_URI, '.context')}">
					<xsl:if test="t:label[1]">
						<rdfs:label>
							<xsl:value-of select="concat('Context of the historical unit ', t:label[1])"/>
						</rdfs:label>
					</xsl:if>
					<!-- rdfs:comment -->
					<xsl:if test="t:desc">
						<rdfs:comment>
							<xsl:value-of select="t:desc"/>
						</rdfs:comment>
					</xsl:if>
					<!-- huc:atPlace -->
					<xsl:if test="t:country | t:region">
						<huc:atPlace>
							<xsl:value-of select="t:country | t:region"/>
						</huc:atPlace>
					</xsl:if>
					<!-- huc:atTime -->
					<xsl:if test="@from or @to or @when">
						<huc:atTime>
							<time:TemporalEntity rdf:about="{concat($Unit_URI, '.context.time')}">
								<xsl:if test="@from">
									<time:hasBeginning>
										<xsl:value-of select="@from"/>
									</time:hasBeginning>
								</xsl:if>
								<xsl:if test="@to">
									<time:hasEnd>
										<xsl:value-of select="@to"/>
									</time:hasEnd>
								</xsl:if>
								<xsl:if test="@when">
									<time:hasTime>
										<xsl:value-of select="@when"/>
									</time:hasTime>
								</xsl:if>
							</time:TemporalEntity>
						</huc:atTime>
					</xsl:if>
					<!-- huc:documentedBy -->
					<xsl:if test="@source">
						<xsl:choose>
							<xsl:when test="contains(@source, 'http')">
								<huc:documentedBy rdf:resource="{@source}"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:comment>build url from @source="#"</xsl:comment>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>					
					<!-- huc:certainty; todo: can be more complex; -->
					<xsl:if test="@cert">
						<huc:certainty>
							<xsl:value-of select="@cert"/>
						</huc:certainty>
					</xsl:if>
				</huc:Context>
			</huc:definedBy>
			<!-- huc:NormalizedUnit -->
			<xsl:if test="@ref">
				<huc:isNormalizedThrough>
					<xsl:attribute name="rdf:resource">
						<xsl:choose>
							<xsl:when test="contains(@ref, 'wd:')">
								<xsl:value-of select="concat('http://www.wikidata.org/entity/', substring-after(@ref, 'wd:'))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="@ref"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</huc:isNormalizedThrough>
			</xsl:if>
			<xsl:if test="@type">
				<!-- or rdf:type ? -->
				<huc:type>
					<xsl:attribute name="rdf:resource">
						<xsl:choose>
							<xsl:when test="@type = 'weight' or @type = 'mass'">
								<xsl:value-of select="'https://www.wikidata.org/entity/Q3647172'"/>
							</xsl:when>
							<xsl:when test="@type = 'currency'">
								<xsl:value-of select="'https://www.wikidata.org/entity/Q8142'"/>
							</xsl:when>
							<xsl:when test="@type = 'volume' or @type = 'capacity'">
								<xsl:value-of select="'https://www.wikidata.org/entity/Q1302471'"/>
							</xsl:when>
							<xsl:when test="@type = 'length'">
								<xsl:value-of select="'https://www.wikidata.org/entity/Q1978718'"/>
							</xsl:when>
							<xsl:when test="@type = 'surface' or @type = 'area'">
								<xsl:value-of select="'https://www.wikidata.org/entity/Q1371562'"/>
							</xsl:when>
							<xsl:when test="@type = 'time'">
								<xsl:value-of select="'https://www.wikidata.org/entity/Q1790144'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat('https://gams.uni-graz.at/context:depcha#', @type)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</huc:type>
			</xsl:if>
		</huc:HistoricalUnit>
		<!-- -->
		<xsl:for-each select="t:conversion">
			<xsl:variable name="CONVERSION_URI" select="concat($Unit_URI, '.conversion')"/>
			<huc:Conversion rdf:about="{concat($CONVERSION_URI, '.', position())}">
				<xsl:if test="@fromUnit">
					<huc:convertsFrom rdf:resource="{concat($BASE-URL, $CONTEXT, '#', encode-for-uri(substring-after(@fromUnit, '#')))}"/>
				</xsl:if>
				<xsl:if test="@toUnit">
					<huc:convertsTo rdf:resource="{concat($BASE-URL, $CONTEXT, '#', encode-for-uri(substring-after(@toUnit, '#')))}"/>
				</xsl:if>
				<xsl:if test="@formula">
					<huc:formula>
						<xsl:value-of select="@formula"/>
					</huc:formula>
				</xsl:if>
			</huc:Conversion>
		</xsl:for-each>
		
	</xsl:template>
	<!-- ####################################### -->
	<!-- mapping tei:taxonomy to skos  -->
	<xsl:template match="*[tokenize(@ana, ' ') = 'depcha:index']">
		<skos:ConceptScheme rdf:about="{concat($BASE-URL, $CONTEXT, '#Taxonomy')}">
			<xsl:if test="t:gloss">
				<rdfs:label>
					<xsl:value-of select="normalize-space(t:gloss)"/>
				</rdfs:label>
			</xsl:if>
			<xsl:if test="t:desc">
				<dc:description>
					<xsl:value-of select="normalize-space(t:desc)"/>
				</dc:description>
			</xsl:if>
			<!-- hasTopConcepts -->
			<xsl:for-each select="t:category">
				<skos:hasTopConcept>
					<xsl:attribute name="rdf:resource">
						<xsl:call-template name="build_URI_for_rdf_about_resource">
							<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
							<xsl:with-param name="ID" select="@xml:id"/>
							<xsl:with-param name="PID" select="$CONTEXT"/>
						</xsl:call-template>
					</xsl:attribute>
				</skos:hasTopConcept>
			</xsl:for-each>
		</skos:ConceptScheme>
		<xsl:apply-templates select="t:category"/>
	</xsl:template>
	<!-- ////////////////////////// -->
	<!-- mapping tei:taxonomy/t:category to skos.Concept  -->
	<xsl:template match="t:category">
		<xsl:variable name="ConceptorBKAccount">
			<xsl:choose>
				<xsl:when test="ancestor::t:taxonomy[@ana = 'bk:account'] | ancestor::t:taxonomy[@ana = 'bk:rubrics']">
					<xsl:value-of select="'bk:Account'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'skos:Concept'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{$ConceptorBKAccount}">
			<xsl:attribute name="rdf:about">
				<xsl:call-template name="build_URI_for_rdf_about_resource">
					<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
					<xsl:with-param name="PID" select="$CONTEXT"/>
					<xsl:with-param name="ID" select="@xml:id"/>
				</xsl:call-template>
			</xsl:attribute>
			<skos:inScheme rdf:resource="{concat($BASE-URL, $CONTEXT)}"/>
			<xsl:for-each select="t:category">
				<skos:narrower>
					<xsl:attribute name="rdf:resource">
						<xsl:call-template name="build_URI_for_rdf_about_resource">
							<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
							<xsl:with-param name="ID" select="@xml:id"/>
							<xsl:with-param name="PID" select="$CONTEXT"/>
						</xsl:call-template>
					</xsl:attribute>
				</skos:narrower>
			</xsl:for-each>
			<xsl:for-each select="parent::t:category">
				<skos:broader>
					<xsl:attribute name="rdf:resource">
						<xsl:call-template name="build_URI_for_rdf_about_resource">
							<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
							<xsl:with-param name="ID" select="@xml:id"/>
							<xsl:with-param name="PID" select="$CONTEXT"/>
						</xsl:call-template>
					</xsl:attribute>
				</skos:broader>
			</xsl:for-each>
			<xsl:if test="t:catDesc/t:term">
				<skos:prefLabel>
					<xsl:if test="t:catDesc/t:term/@xml:lang">
						<xsl:attribute name="xml:lang" select="t:catDesc/t:term/@xml:lang"/>
					</xsl:if>
					<xsl:value-of select="normalize-space(t:catDesc/t:term)"/>
				</skos:prefLabel>
			</xsl:if>
			<xsl:if test="t:catDesc/t:gloss | t:catDesc/t:term | t:gloss">
				<rdfs:label>
					<xsl:choose>
						<xsl:when test="t:catDesc/t:term[1]">
							<xsl:value-of select="t:catDesc/t:term[1]"/>
						</xsl:when>
						<xsl:when test="t:catDesc/t:gloss[1]">
							<xsl:value-of select="t:catDesc/t:gloss[1]"/>
						</xsl:when>
						<xsl:when test="t:gloss[1]">
							<xsl:value-of select="t:gloss[1]"/>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
				</rdfs:label>
			</xsl:if>
			<xsl:if test="t:catDesc/t:term/@ref">
				<!-- here get the prefix for wikidata -->
				<xsl:choose>
					<xsl:when test="contains(t:catDesc/t:term/@ref, 'wd:')">
						<skos:relatedMatch
							rdf:resource="{concat('https://www.wikidata.org/wiki/', t:catDesc/t:term/@ref)}"
						/>
					</xsl:when>
					<xsl:otherwise>
						<skos:relatedMatch rdf:resource="{t:catDesc/t:term/@ref}"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
			<xsl:if
				test="//*[tokenize(@ana, ' ') = 'depcha:accountHolder'] and ($ConceptorBKAccount = 'bk:account' or $ConceptorBKAccount = 'bk:rubrics')">
				<depcha:accountHolder
					rdf:resource="{concat($BASE-URL, $CONTEXT, '#', //*[tokenize(@ana, ' ') = 'depcha:accountHolder'][1]/@xml:id)}"
				/>
			</xsl:if>
		</xsl:element>
		<!-- /// -->
		<xsl:apply-templates select="t:category"/>
	</xsl:template>
	<!-- ////////////////////////// -->
	<!-- goes through all @ana='bk:entry' -->
	<xsl:template match="t:text//*[tokenize(@ana, ' ') = 'bk:entry']">
		<!--  bk:from -->
		<xsl:variable name="bk_From">
			<xsl:call-template name="getFromTO">
				<xsl:with-param name="Direction" select="'bk:from'"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- bk:to -->
		<xsl:variable name="bk_To">
			<xsl:call-template name="getFromTO">
				<xsl:with-param name="Direction" select="'bk:to'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="Transaction-ID" select="concat($BASE-URL, $TEI-PID, '#T', position())"/>
		<xsl:variable name="bk_EconomicAsset" select="
				.//.[tokenize(@ana, ' ') = 'bk:money'] | .//.[tokenize(@ana, ' ') = 'bk:service'] |
				.//.[tokenize(@ana, ' ') = 'bk:commodity'] | .//.[tokenize(@ana, ' ') = 'bk:right'] | .//.[tokenize(@ana, ' ') = 'bk:tax']
				| .//.[tokenize(@ana, ' ') = 'bk:governmentTransfer']"/>
		<!-- bk:transaction -->
		<bk:Transaction rdf:about="{$Transaction-ID}">
			<xsl:call-template name="getBasicProperties">
				<xsl:with-param name="URI" select="$Transaction-ID"/>
			</xsl:call-template>
			<!-- for each bk:measurable grouped by @commodity: there is a transfer for all bk_measurable entities. $ + sh are in the same transfer -->
			<xsl:for-each-group select="$bk_EconomicAsset" group-by="@ana">
				<xsl:choose>
					<!-- case 1 -->
					<!-- if a bk:EconomicAsset as an additional bk:each iterate over all bk:to | bk:from inside the curren bk:entry to create a bk:Transfer with the current bk:EconomicAsset -->
					<xsl:when test=".[tokenize(current-grouping-key(), ' ') = 'bk:each']">
						<xsl:variable name="Current_EconomicAssets" select="."/>
						<xsl:for-each
							select="..//*[tokenize(@ana, ' ') = 'bk:to'] | ..//*[tokenize(@ana, ' ') = 'bk:from']">
							<xsl:variable name="Transfer-ID"
								select="concat($Transaction-ID, 'T', position())"/>
							<bk:consistsOf>
								<xsl:message>Log: bk:each</xsl:message>
								<xsl:call-template name="create_bk_Transfer">
									<xsl:with-param name="Transfer-ID"
										select="concat($Transaction-ID, 'T', position())"/>
									<xsl:with-param name="bk_EconomicAsset"
										select="$bk_EconomicAsset"/>
								</xsl:call-template>
							</bk:consistsOf>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<bk:consistsOf>
							<xsl:call-template name="create_bk_Transfer">
								<xsl:with-param name="Transfer-ID"
									select="concat($Transaction-ID, 'T', position())"/>
								<xsl:with-param name="bk_EconomicAsset"
									select="current-grouping-key()"/>
								<xsl:with-param name="number_of_economic_units"
									select="count(current-group())"/>
							</xsl:call-template>
						</bk:consistsOf>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each-group>
			<!-- /// bk:status -->
			<!-- e.g.: transactionStatus pp. ; in full -->
			<xsl:for-each select=".//.[tokenize(@ana, ' ') = 'bk:status']">
				<bk:status>
					<xsl:value-of select="normalize-space(.)"/>
				</bk:status>
			</xsl:for-each>
			<xsl:call-template name="bookedOn_credit_debit"/>
			<!-- /////////////////////////////////////// -->
			<!-- bk:where -->
			<xsl:for-each-group select=".//.[tokenize(@ana, ' ') = 'bk:where']" group-by="@ref">
				<bk:where>
					<xsl:attribute name="rdf:resource">
						<xsl:call-template name="build_URI_for_rdf_about_resource">
							<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
							<xsl:with-param name="PID" select="$CONTEXT"/>
							<xsl:with-param name="ID" select="@ref"/>
						</xsl:call-template>
					</xsl:attribute>
				</bk:where>
			</xsl:for-each-group>
			<!-- /// bk:addUp -->
			<!-- connection of a bk:Transaction to a bk:Total  -->
			<xsl:if test="following::*[tokenize(@ana, ' ') = 'bk:total'] and @corresp">
				<bk:addUp rdf:resource="{concat($BASE-URL, $TEI-PID, @corresp)}"/>
			</xsl:if>
		</bk:Transaction>
	</xsl:template>
	
	<!-- //////////////////////////////////// -->
	<!-- templates mapping to foaf and schema -->
	<xsl:template match="t:listPerson[@ana = 'depcha:index'][1]/t:person">
		<xsl:variable name="Between-URI" select="concat($BASE-URL, $CONTEXT, '#', @xml:id)"/>
		<xsl:variable name="BK_ECONOMIC_AGENT_SUBCLASS">
			<xsl:call-template name="BK_ECONOMIC_AGENT_SUBCLASS_CHOOSE"/>
		</xsl:variable>
		<xsl:element name="{$BK_ECONOMIC_AGENT_SUBCLASS}">
			<xsl:attribute name="rdf:about" select="$Between-URI"/>
			<xsl:apply-templates>
				<xsl:with-param name="Between-URI" select="$Between-URI"/>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>
	<!-- bk:group -->
	<xsl:template match="t:listPerson[@ana = 'depcha:index'][1]/t:personGrp">
		<xsl:variable name="Between-URI" select="concat($BASE-URL, $CONTEXT, '#', @xml:id)"/>
		<bk:Group rdf:about="{$Between-URI}">
			<xsl:apply-templates>
				<xsl:with-param name="Between-URI" select="$Between-URI"/>
			</xsl:apply-templates>
		</bk:Group>
	</xsl:template>
	<!-- t:note todo: -->
	<xsl:template match="t:note"/>
	<!-- t:persName -->
	<xsl:template match="t:persName">
		<xsl:if test="position() = 1">
			<xsl:choose>
				<xsl:when test="*">
					<xsl:call-template name="handle_names"/>
				</xsl:when>
				<xsl:otherwise>
					<rdfs:label>
						<xsl:value-of select="normalize-space(.)"/>
					</rdfs:label>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<xsl:template match="t:orgName">
		<rdfs:label>
			<xsl:variable name="ORGNAME">
				<xsl:apply-templates/>
			</xsl:variable>
			<xsl:value-of select="normalize-space($ORGNAME)"/>
		</rdfs:label>
	</xsl:template>
	<xsl:template match="t:desc">
		<dc:description>
			<xsl:apply-templates/>
		</dc:description>
	</xsl:template>
	<xsl:template match="t:forename">
		<schema:givenName>
			<xsl:value-of select="normalize-space(.)"/>
		</schema:givenName>
	</xsl:template>
	<xsl:template match="t:surname">
		<schema:familyName>
			<xsl:value-of select="normalize-space(.)"/>
		</schema:familyName>
	</xsl:template>
	<xsl:template match="t:genName"/>
	<xsl:template match="t:roleName"/>
	<xsl:template match="t:nameLink"/>
	<xsl:template match="t:gloss"/>
	<xsl:template match="t:name">
		<!--  -->
		<xsl:call-template name="handle_names"/>
		<!-- apply templates if children exist -->
		<xsl:if test="*">
			<xsl:apply-templates select="*"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="t:name/t:placeName">
		<depcha:placeName>
			<xsl:value-of select="."/>
		</depcha:placeName>
	</xsl:template>
	<xsl:template match="t:addName">
		<schema:additionalName>
			<xsl:value-of select="normalize-space(.)"/>
		</schema:additionalName>
	</xsl:template>
	<!-- affiliation -->
	<xsl:template match="t:affiliation">
		<schema:affiliation>
			<xsl:value-of select="normalize-space(.)"/>
		</schema:affiliation>
	</xsl:template>
	<!-- t:placeName -->
	<xsl:template match="t:placeName">
		<depcha:placeName>
			<xsl:value-of select="normalize-space(.)"/>
		</depcha:placeName>
	</xsl:template>
	<xsl:template match="t:idno[@type]"> </xsl:template>
	<!-- state -->
	<xsl:template match="t:state">
		<xsl:param name="Between-URI"/>
		<!--<xsl:choose>
            <xsl:when test="@type = 'married'">
                
                <schema:MarryAction rdf:about="{concat($Between-URI, 'PMA')}">
                    <xsl:if test="@notBefore">
                        <schema:startTime>
                            <xsl:value-of select="@notBefore"/>
                        </schema:startTime>
                    </xsl:if>
                    <xsl:if test="@notAfter">
                        <schema:endTime>
                            <xsl:value-of select="@notAfter"/>
                        </schema:endTime>
                    </xsl:if>
                </schema:MarryAction>
            </xsl:when>
            <xsl:otherwise>
                <!-\- todo -\->
                <t:state>
                    <xsl:value-of select="@*"/>
                </t:state>
            </xsl:otherwise>
        </xsl:choose>-->
	</xsl:template>
	<!-- faith -->
	<xsl:template match="t:faith">
		<t:faith>
			<xsl:value-of select="normalize-space(.)"/>
		</t:faith>
	</xsl:template>
	<!-- residence -->
	<xsl:template match="t:residence">
		<schema:homeLocation>
			<xsl:value-of select="normalize-space(.)"/>
		</schema:homeLocation>
	</xsl:template>
	<!-- residence -->
	<xsl:template match="t:education">
		<schema:knowsAbout>
			<xsl:value-of select="normalize-space(.)"/>
		</schema:knowsAbout>
	</xsl:template>
	<!-- occupation -->
	<xsl:template match="t:occupation">
		<schema:hasOccupation>
			<xsl:value-of select="normalize-space(.)"/>
		</schema:hasOccupation>
	</xsl:template>
	<!-- sex -->
	<xsl:template match="t:sex">
		<xsl:choose>
			<xsl:when test="@value">
				<xsl:choose>
					<xsl:when test="@value = 'male'">
						<schema:gender rdf:resource="https://schema.org/Male"/>
					</xsl:when>
					<xsl:when test="@value = 'female'">
						<schema:gender rdf:resource="https://schema.org/Female"/>
					</xsl:when>
					<xsl:when test="@value = 1">
						<schema:gender rdf:resource="https://schema.org/Male"/>
					</xsl:when>
					<xsl:when test="@value = 2">
						<schema:gender rdf:resource="https://schema.org/Female"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="text() = 'male'">
				<schema:gender rdf:resource="https://schema.org/Male"/>
			</xsl:when>
			<xsl:when test="text() = 'female'">
				<schema:gender rdf:resource="https://schema.org/Female"/>
			</xsl:when>
			<xsl:otherwise>
				<schema:gender>
					<xsl:apply-templates/>
				</schema:gender>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- birth -->
	<xsl:template match="t:birth">
		<schema:birthDate>
			<xsl:choose>
				<xsl:when test="@when">
					<xsl:value-of select="@when"/>
				</xsl:when>
				<!-- todo -->
				<xsl:when test="@notBefore">
					<xsl:value-of select="@notBefore"/>
				</xsl:when>
				<!-- todo -->
				<xsl:when test="@notAfter">
					<xsl:value-of select="@notAfter"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(.)"/>
				</xsl:otherwise>
			</xsl:choose>
		</schema:birthDate>
	</xsl:template>
	<xsl:template match="t:birth/t:placeName">
		<schema:birthPlace>
			<xsl:if test="t:settlement">
				<xsl:value-of select="t:settlement"/>
			</xsl:if>
			<xsl:text> </xsl:text>
			<xsl:if test="t:settlement">
				<xsl:value-of select="t:region"/>
			</xsl:if>
		</schema:birthPlace>
	</xsl:template>
	<!-- death -->
	<xsl:template match="t:death">
		<schema:deathDate>
			<xsl:choose>
				<xsl:when test="@when">
					<xsl:value-of select="@when"/>
				</xsl:when>
				<!-- todo -->
				<xsl:when test="@notBefore">
					<xsl:value-of select="@notBefore"/>
				</xsl:when>
				<!-- todo -->
				<xsl:when test="@notAfter">
					<xsl:value-of select="@notAfter"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(.)"/>
				</xsl:otherwise>
			</xsl:choose>
		</schema:deathDate>
	</xsl:template>
	<xsl:template match="t:death/t:placeName">
		<schema:deathPlace>
			<xsl:if test="t:settlement">
				<xsl:value-of select="t:settlement"/>
			</xsl:if>
			<xsl:text> </xsl:text>
			<xsl:if test="t:settlement">
				<xsl:value-of select="t:region"/>
			</xsl:if>
		</schema:deathPlace>
	</xsl:template>
	<!-- ////////////////////////////////////////////////////////////////////// -->
	<!-- ////////////////////////////////////////////////////////////////////// -->
	<!-- CALLED TEMPLATES -->
	<!-- this template gets bk:from or bk:to as parameter an go through some cases in TEI files where this @ana from or to can exist  -->
	<xsl:template name="getFromTO">
		<xsl:param name="Direction"/>
		<xsl:choose>
			<!-- inside the current entry -->
			<xsl:when test=".//.[tokenize(@ana, ' ') = $Direction][not(local-name() = 'measure')]">
				<xsl:value-of
					select=".//.[tokenize(@ana, ' ') = $Direction][not(local-name() = 'measure')]"/>
			</xsl:when>
			<!-- if there is no bk_from in the current entry and in the header go to the first preceding-sibling and look for a bk_to -->
			<xsl:when
				test="preceding-sibling::*[not(tokenize(@ana, ' ') = 'bk:entry')][1]//*[@ana = $Direction]">
				<xsl:value-of
					select="preceding-sibling::*[not(tokenize(@ana, ' ') = 'bk:entry')][1]//*[@ana = $Direction]"
				/>
			</xsl:when>
			<xsl:when test="preceding::*[tokenize(@ana, ' ') = $Direction][1]">
				<xsl:call-template name="getRefwithHash">
					<xsl:with-param name="Path"
						select="preceding::*[tokenize(@ana, ' ') = $Direction][1]"/>
				</xsl:call-template>
			</xsl:when>
			<!-- in the TEI header -->
			<xsl:when test="$teiHeader//.[tokenize(@ana, ' ') = $Direction]">
				<xsl:value-of select="$teiHeader//.[tokenize(@ana, ' ') = $Direction]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>Anonymous</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- same as above, just for @ref  -->
	<xsl:template name="getFromTO_ref">
		<xsl:param name="Direction"/>
		<xsl:choose>
			<!-- not t:measure elements -->
			<xsl:when test="..//*[tokenize(@ana, ' ') = $Direction][not(local-name() = 'measure')]">
				<xsl:choose>
					<xsl:when
						test="..//*[tokenize(@ana, ' ') = $Direction][not(local-name() = 'measure')]/@ref">
						<xsl:call-template name="getRefwithHash">
							<xsl:with-param name="Path"
								select="..//.[tokenize(@ana, ' ') = $Direction][not(local-name() = 'measure')]/@ref"
							/>
						</xsl:call-template>
					</xsl:when>
					<!-- otherweise generate a id from the string -->
					<xsl:otherwise>
						<xsl:value-of
							select="concat('#', encode-for-uri(translate(..//*[tokenize(@ana, ' ') = $Direction][not(local-name() = 'measure')], ' ', '')))"
						/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:message>Log: bk:from|bk:to was extracted inside the entry</xsl:message>
			</xsl:when>
			<xsl:when
				test="../preceding-sibling::*[not(tokenize(@ana, ' ') = 'bk:entry')][1]//*[@ana = $Direction]/@ref">
				<xsl:call-template name="getRefwithHash">
					<xsl:with-param name="Path"
						select="../preceding-sibling::*[not(tokenize(@ana, ' ') = 'bk:entry')][1]//*[@ana = $Direction]/@ref"
					/>
				</xsl:call-template>
				<xsl:message>Log: bk:from|bk:to was extracted from the
					preceding-sibling</xsl:message>
			</xsl:when>
			<!-- there is a acnestor bk:from or bk:to -->
			<xsl:when test="../ancestor::*[tokenize(@ana, ' ') = $Direction][1]//@ref">
				<xsl:call-template name="getRefwithHash">
					<xsl:with-param name="Path"
						select="../ancestor::*[tokenize(@ana, ' ') = $Direction][1]//@ref"/>
				</xsl:call-template>
				<xsl:message>Log: bk:from|bk:to was extracted from an ancestor the
					entry</xsl:message>
			</xsl:when>
			<!-- there is a bk:account or bk:rubric as an ancestor  -->
			<xsl:when test="ancestor::*[tokenize(@ana, ' ') = 'bk:account'][1] | ancestor::*[tokenize(@ana, ' ') = 'bk:rubric'][1]">
				<xsl:variable name="rubric" select="ancestor::*[tokenize(@ana, ' ') = 'bk:account'][1] | ancestor::*[tokenize(@ana, ' ') = 'bk:rubric'][1]"/>
				<xsl:choose>
					<xsl:when test="//t:taxonomy[tokenize(@ana, ' ') = 'bk:rubrics']">
						<xsl:choose>
							<xsl:when test="contains($rubric/@corresp, '#')">
								<xsl:value-of select="$rubric/@corresp"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat('#', $rubric/@corresp)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of
							select="ancestor::*[tokenize(@ana, ' ') = 'bk:account'][1]/@ref | ancestor::*[tokenize(@ana, ' ') = 'bk:account'][1]/@corresp | ancestor::*[tokenize(@ana, ' ') = 'rubric'][1]/@ref | ancestor::*[tokenize(@ana, ' ') = 'rubric'][1]/@corresp"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$teiHeader//.[tokenize(@ana, ' ') = $Direction]/@ref">
				<xsl:call-template name="getRefwithHash">
					<xsl:with-param name="Path"
						select="$teiHeader//.[tokenize(@ana, ' ') = $Direction]/@ref"/>
				</xsl:call-template>
				<xsl:message>Log: bk:from|bk:to was extracted from the teiHeader</xsl:message>
			</xsl:when>
			<!-- // the last option is to but the depcha:accountHolder as direction -->
			<xsl:when
				test="$LIST_PERSON//t:person[tokenize(@ana, ' ') = 'depcha:accountHolder']/@xml:id | $LIST_ORG/t:org[tokenize(@ana, ' ') = 'depcha:accountHolder']/@xml:id">
				<xsl:call-template name="getRefwithHash">
					<xsl:with-param name="Path"
						select="$LIST_PERSON//.[tokenize(@ana, ' ') = 'depcha:accountHolder']/@xml:id | $LIST_ORG/t:org[tokenize(@ana, ' ') = 'depcha:accountHolder']/@xml:id"
					/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>#anonymous</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ////////////////////////// -->
	<!-- This template returns the value of a @ref and checks if its starts with a '#', and adds it if it does not exist.  -->
	<xsl:template name="get_XML_ID_after_Hash">
		<xsl:param name="Path"/>
		<xsl:choose>
			<xsl:when test="contains(current-grouping-key(), '#')">
				<xsl:value-of select="substring-after(current-grouping-key(), '#')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="current-grouping-key()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ////////////////////////// -->
	<!-- This template returns the value of a @ref and checks if its starts with a '#', and adds it if it does not exist.  -->
	<xsl:template name="getRefwithHash">
		<xsl:param name="Path"/>
		<xsl:choose>
			<xsl:when test="contains($Path[1], '#')">
				<xsl:value-of select="normalize-space($Path[1])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space(concat('#', $Path[1]))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ////////////////////////// -->
	<!-- returns: bk:unit object property with build URI
         error: if no @unit | @unitRef exists define a default "piece" unit -->
	<xsl:template name="create_bk_unit">
		<xsl:choose>
			<xsl:when test="@unitRef | @unit">
				<bk:unit>
					<xsl:attribute name="rdf:resource">
						<xsl:call-template name="build_URI_for_rdf_about_resource">
							<xsl:with-param name="PID" select="$CONTEXT"/>
							<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
							<xsl:with-param name="ID" select="
									if (@unitRef) then
										@unitRef
									else
										@unit"/>
						</xsl:call-template>
					</xsl:attribute>
				</bk:unit>
			</xsl:when>
			<xsl:when test="t:measure/@unit">
				<bk:unit>
					<xsl:value-of select="t:measure/@unit"/>
				</bk:unit>
			</xsl:when>
			<xsl:otherwise>
				<bk:unit>piece</bk:unit>
				<xsl:message>Error: no @unitRef or @unit in bk:Measurable -- added default
					"piece"</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ////////////////////////// -->
	<!-- get @commodity -->
	<xsl:template name="create_bk_classified">
		<xsl:if test="@commodity and not(@commodity = 'currency')">
			<bk:classified>
				<xsl:attribute name="rdf:resource">
					<xsl:call-template name="build_URI_for_rdf_about_resource">
						<xsl:with-param name="PID" select="$CONTEXT"/>
						<xsl:with-param name="BASE_URL" select="$BASE-URL"/>
						<xsl:with-param name="ID" select="@commodity"/>
					</xsl:call-template>
				</xsl:attribute>
			</bk:classified>
		</xsl:if>
	</xsl:template>
	<!-- ////////////////////////// -->
	<!-- get @quantity -->
	<xsl:template name="create_bk_quantity">
		<xsl:choose>
			<xsl:when test="@quantity">
				<bk:quantity>
					<xsl:value-of select="@quantity"/>
				</bk:quantity>
			</xsl:when>
			<xsl:when test="t:measure/@quantity">
				<bk:quantity>
					<xsl:value-of select="t:measure/@quantity"/>
				</bk:quantity>
			</xsl:when>
			<xsl:otherwise>
				<bk:quantity>
					<xsl:value-of select="1"/>
				</bk:quantity>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ///////////////// -->
	<!-- get bk:when -->
	<xsl:template name="getWhen">
		<xsl:param name="URI"/>
		<xsl:choose>
			<!-- bk:when is inside  bk:entry -->
			<xsl:when test=".//t:date[@ana = 'bk:when'][1]/@when">
				<bk:when>
					<xsl:value-of select=".//t:date[@ana = 'bk:when'][1]/@when"/>
				</bk:when>
			</xsl:when>
			<!-- the parent element as a child head, that contains the bk:when -->
			<xsl:when test="..//*:head//.[@ana = 'bk:when'][1]/@when">
				<bk:when>
					<xsl:value-of select="..//*:head//.[@ana = 'bk:when'][1]/@when"/>
				</bk:when>
			</xsl:when>
			<!-- a bk:total or bk:subtotal can be inside an depcha:totalContainer; all bk:entry sum p to this bk:total; this means all transactions must have the same date  -->
			<xsl:when test="./ancestor::*[tokenize(@ana, ' ') = 'depcha:totalContainer']//*[tokenize(@ana, ' ') = 'bk:when']">
				<!-- TODO: generate from to with earliest and latest date -->
				<xsl:for-each-group select="./ancestor::*[tokenize(@ana, ' ') = 'depcha:totalContainer']//*[tokenize(@ana, ' ') = 'bk:when']" group-by="@when">
					<xsl:if test="position() = last()">
						<bk:when>
							<xsl:value-of select="current-grouping-key()"/>
						</bk:when>
					</xsl:if>
				</xsl:for-each-group>	
			</xsl:when>
			<!-- if a preceding element contains a bk:when as descendant -->
			<xsl:when test="preceding::t:*[1]//.[tokenize(@ana, ' ') = 'bk:when'][1]/@when">
				<bk:when>
					<xsl:value-of
						select="preceding::t:*[1]//.[tokenize(@ana, ' ') = 'bk:when'][1]/@when"/>
				</bk:when>
			</xsl:when>
			<!-- a preceding t:date -->
			<xsl:when test="descendant::t:date[@ana = 'bk:when'][1]/@when">
				<bk:when>
					<xsl:value-of select="descendant::t:date[@ana = 'bk:when'][1]/@when"/>
				</bk:when>
			</xsl:when>
			<!-- todo: -->
			<xsl:when test=".//.[@ana = 'bk:when'][1]/@from">
				<bk:when>
					<xsl:value-of select=".//.[@ana = 'bk:when'][1]/@from"/>
				</bk:when>
			</xsl:when>
			<!-- there is only one bk:when in the document -->
			<!-- taxrolls -->
			<!--<xsl:when test="//.//.[@ana = 'bk:when'][1] and not(//.//.[@ana = 'bk:when'][2])">
				<bk:when>
					<xsl:value-of select="//.//.[@ana = 'bk:when'][1]/@when"/>
				</bk:when>
			</xsl:when>-->
			<!-- year from origdate@from (srbas workaround) -->
			<xsl:when test="//t:msDesc//t:origDate/@from">
				<bk:when>
					<xsl:value-of select="tokenize(//t:msDesc//t:origDate/@from, '-')[1]"/>
				</bk:when>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>Warning: bk:when was not found in transaction <xsl:value-of
					select="$URI"/></xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ///////////////// -->
	<!-- bk:Sum -->
	<xsl:template match="//t:text//*[tokenize(@ana, ' ') = 'bk:sum']">
		<!-- /////////// -->
		<!--  BK:FROM -->
		<xsl:variable name="bk_From">
			<xsl:call-template name="getFromTO">
				<xsl:with-param name="Direction" select="'bk:from'"/>
			</xsl:call-template>
		</xsl:variable>
		<!--  BK:TO @ref -->
		<xsl:variable name="bk_From_ref">
			<xsl:call-template name="getFromTO_ref">
				<xsl:with-param name="Direction" select="'bk:from'"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- /////////// -->
		<!-- BK:TO -->
		<xsl:variable name="bk_To">
			<xsl:call-template name="getFromTO">
				<xsl:with-param name="Direction" select="'bk:to'"/>
			</xsl:call-template>
		</xsl:variable>
		<!--  BK:TO @ref -->
		<xsl:variable name="bk_To_ref">
			<xsl:call-template name="getFromTO_ref">
				<xsl:with-param name="Direction" select="'bk:to'"/>
			</xsl:call-template>
		</xsl:variable>
		<!--<xsl:variable name="Position"
            select="count(preceding::node()[tokenize(@ana, ' ') = 'bk:sum'])"/>-->
		<!-- , $Position -->
		<!--<xsl:variable name="TOTAL-URI" select="concat($BASE-URL, $TEI-PID, '#S')"/>-->
		<!--<bk:Sum rdf:about="{$TOTAL-URI}">

            <xsl:variable name="Transfer-ID" select="concat($TOTAL-URI, 'S', position())"/>

            <xsl:for-each select=".//.[tokenize(@ana, ' ') = 'bk:money']">
                <bk:consistsOf>
                    <bk:Transfer rdf:about="{$Transfer-ID}">
                        <bk:from rdf:resource="{concat($BASE-URL, $TEI-PID, $bk_From_ref)}"/>
                        <bk:to rdf:resource="{concat($BASE-URL, $TEI-PID, $bk_To_ref)}"/>
                        <bk:transfers>
                            <bk:Money rdf:about="{concat($TOTAL-URI, 'M', position())}">
                                <xsl:call-template name="create_bk_quantity"/>
                                <xsl:call-template name="create_bk_unit"/>
                            </bk:Money>
                        </bk:transfers>
                    </bk:Transfer>
                </bk:consistsOf>
            </xsl:for-each>

            <xsl:call-template name="getBasicProperties"/>
        </bk:Sum>-->
	</xsl:template>
	<!-- ///////////////// -->
	<!-- bk:Total -->
	<xsl:template
		match="t:text//*[tokenize(@ana, ' ') = 'bk:total'] | t:text//*[tokenize(@ana, ' ') = 'bk:subtotal']">
		<!-- /////////// -->
		<!--  BK:FROM -->
		<xsl:variable name="bk_From">
			<xsl:call-template name="getFromTO">
				<xsl:with-param name="Direction" select="'bk:from'"/>
			</xsl:call-template>
		</xsl:variable>
		<!--  BK:TO @ref -->
		<xsl:variable name="bk_From_ref">
			<xsl:call-template name="getFromTO_ref">
				<xsl:with-param name="Direction" select="'bk:from'"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- /////////// -->
		<!-- BK:TO -->
		<xsl:variable name="bk_To">
			<xsl:call-template name="getFromTO">
				<xsl:with-param name="Direction" select="'bk:to'"/>
			</xsl:call-template>
		</xsl:variable>
		<!--  BK:TO @ref -->
		<xsl:variable name="bk_To_ref">
			<xsl:call-template name="getFromTO_ref">
				<xsl:with-param name="Direction" select="'bk:to'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="TOTAL-URI">
			<xsl:choose>
				<!-- if bk:Total or bk:Subtotal has an xml:id -->
				<xsl:when test="@xml:id">
					<xsl:value-of select="concat($BASE-URL, $TEI-PID, '#', @xml:id)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="@ana = 'bk:total'">
							<xsl:value-of
								select="concat($BASE-URL, $TEI-PID, '#', 'Total', position())"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of
								select="concat($BASE-URL, $TEI-PID, '#', 'Subtotal', position())"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- /// -->
		<xsl:element
			name="{if(.[tokenize(@ana, ' ') = 'bk:total']) then ('bk:TotalTransaction') else ('bk:SubTotalTransaction')}">
			<xsl:attribute name="rdf:about" select="$TOTAL-URI"/>
			<xsl:for-each select=".//.[tokenize(@ana, ' ') = 'bk:money']">
				<bk:comprises>
					<bk:Money rdf:about="{concat($TOTAL-URI, 'M', position())}">
						<xsl:call-template name="create_bk_quantity"/>
						<xsl:call-template name="create_bk_unit"/>
					</bk:Money>
				</bk:comprises>
			</xsl:for-each>
			<!-- getBasicProperties -->
			<xsl:call-template name="getBasicProperties">
				<xsl:with-param name="URI" select="$TOTAL-URI"/>
			</xsl:call-template>
			<!-- booking -->
			<xsl:call-template name="bookedOn_credit_debit"/>
		</xsl:element>
	</xsl:template>
	<xsl:template name="prepareMoney_Currency_Conversion">
		<xsl:param name="mainCurrency"/>
		<xsl:param name="bk_when"/>
		<xsl:param name="bk_Entry"/>
		<xsl:param name="currentYear"/>
		<xsl:if test="substring($bk_when/bk:when, 1, 4) = $currentYear">
			<xsl:variable name="ALL_MONEY_IN_YEAR" select=".//*[tokenize(@ana, ' ') = 'bk:money']"/>
			<xsl:choose>
				<xsl:when test="$ALL_MONEY_IN_YEAR/@quantity">
					<!-- main currency; bk:Money 1 -->
					<money>
						<xsl:value-of
							select="sum($ALL_MONEY_IN_YEAR[@unit = $mainCurrency/@xml:id, $mainCurrency/t:label][1]/@quantity)"
						/>
					</money>
					<xsl:for-each select="$mainCurrency/t:conversion/@formula">
						<money>
							<xsl:value-of select="
									sum($ALL_MONEY_IN_YEAR[@unit = substring-after(@toUnit, '#')][1]/@quantity)
									div number(substring-after(@formula, '$fromUnit div '))"/>
						</money>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message>Error: No bk:money with @quantity to aggregate</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
			
			<!-- bk:to of bk:entry of a specific bk:when-->
			<xsl:if test=".//*[tokenize(@ana, ' ') = 'bk:to'][1]/@ref">
				<to>
					<!-- todo [1] ? -->
					<xsl:value-of select=".//*[tokenize(@ana, ' ') = 'bk:to'][1]/@ref"/>
				</to>
			</xsl:if>
			<!-- bk:from of bk:entry of a specific bk:when-->
			<xsl:if test=".//*[tokenize(@ana, ' ') = 'bk:from'][1]/@ref">
				<from>
					<!-- todo [1] ? -->
					<xsl:value-of select=".//*[tokenize(@ana, ' ') = 'bk:from'][1]/@ref"/>
				</from>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<!-- /////////////////// -->
	<!--<xsl:template name="aggregatesBetween">
        <xsl:param name="DatasetURI"/>
        <xsl:param name="Between_Id"/>
        <xsl:param name="currentYear"/>
        <xsl:param name="mainCurrency"/>
        <xsl:param name="bk:Entry"/>

        <!-\-  -\->
        <xsl:variable name="bk:service" select="$bk:Entry//*[tokenize(@ana, ' ') = 'bk:service']"/>
        <xsl:variable name="bk:commodity"
            select="$bk:Entry//*[tokenize(@ana, ' ') = 'bk:commodity']"/>

        <!-\- /// -\->
        <!-\- help variable storing data of current year and current bk:EconomicAgent -\->
        <xsl:variable name="allMoneyofEntriesofCurrentYear_bkBetween">
            <!-\- select all bk:Entry where current $Between_Id is the bk:to -\->
            <xsl:for-each select="$bk:Entry">
                <xsl:call-template name="prepareMoney_Currency_Conversion">
                    <xsl:with-param name="bk_when">
                        <xsl:call-template name="getWhen"/>
                    </xsl:with-param>
                    <xsl:with-param name="currentYear" select="$currentYear"/>
                    <xsl:with-param name="mainCurrency" select="$mainCurrency"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:variable>
    </xsl:template>-->
	<!-- //////////////////////////////////// -->
	<!-- this template creates a bk:Dataset. it creats a bk:Dataset for all distinct years in bk:when from all bk:entry. 
         it uses the information in <t:unitDef> to do the conversion of currencies and calucaltes the sum of bk:income and bk:expense -->
	<!-- /////////////////////////////// -->
	<!-- return: <bk:bookedOn> #Debit | #Credit  
         ToDo: check for bk:debit|bk:credit inside bk:entry-->
	<xsl:template name="bookedOn_credit_debit">
		<xsl:choose>
			<!-- bk:debit|bk:credit next to bk:entry|bk:total  -->
			<xsl:when test="tokenize(@ana, ' ') = 'bk:debit' or tokenize(@ana, ' ') = 'bk:credit'">
				<xsl:if test="tokenize(@ana, ' ') = 'bk:debit'">
					<bk:debit rdf:resource="https://gams.uni-graz.at/o:depcha.bookkeeping#Booking"/>
				</xsl:if>
				<xsl:if test="tokenize(@ana, ' ') = 'bk:credit'">
					<bk:credit rdf:resource="https://gams.uni-graz.at/o:depcha.bookkeeping#Booking"
					/>
				</xsl:if>
			</xsl:when>
			<!-- bk:debit|bk:credit inside bk:entry|bk:total  -->
			<xsl:when
				test=".//*[tokenize(@ana, ' ') = 'bk:debit'] | .//*[tokenize(@ana, ' ') = 'bk:credit']">
				<xsl:if test=".//*[tokenize(@ana, ' ') = 'bk:debit']">
					<bk:debit rdf:resource="https://gams.uni-graz.at/o:depcha.bookkeeping#Booking"/>
				</xsl:if>
				<xsl:if test=".//*[tokenize(@ana, ' ') = 'bk:credit']">
					<bk:credit rdf:resource="https://gams.uni-graz.at/o:depcha.bookkeeping#Booking"
					/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise> </xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- /////////////////////////////// -->
	<!-- adds gams:memberOfColletion, gams:isPartofTEI, bk:entry and bk:when to bk:Transaction or bk:Sum  -->
	<xsl:template name="getBasicProperties">
		<xsl:param name="URI"/>
		<gams:isMemberOfCollection rdf:resource="{concat($BASE-URL, $CONTEXT)}"/>
		<gams:isPartOf rdf:resource="{concat($BASE-URL, $TEI-PID)}"/>
		<!-- bk:entry -->
		<bk:entry>
			<!-- remove " because its not valid JSON -->
			<xsl:for-each select=".//text()">
				<xsl:if test="not(../local-name() = 'abbr')">
					<xsl:value-of select="gams:json-escape(normalize-space(replace(., $quot, '')))"/>
					<xsl:if test="not(position() = last())">
						<xsl:text> </xsl:text>
					</xsl:if>
				</xsl:if>
			</xsl:for-each>
		</bk:entry>
		<!-- bk:when -->
		<xsl:call-template name="getWhen">
			<xsl:with-param name="URI" select="$URI"/>
		</xsl:call-template>
	</xsl:template>
	
	<!-- this template creates a bk:Transfer with bk:to, bk:from and bk:transfers -->
	<xsl:template name="create_bk_Transfer">
		<xsl:param name="Transfer-ID"/>
		<xsl:param name="bk_EconomicAsset"/>
		<xsl:param name="number_of_economic_units"/>
		<xsl:variable name="EconomicAsset-ID" select="concat($Transfer-ID, 'EA')"/>
		<!--  bk:to @ref -->
		<xsl:variable name="bk_To_ref">
			<xsl:call-template name="getFromTO_ref">
				<xsl:with-param name="Direction" select="'bk:to'"/>
			</xsl:call-template>
		</xsl:variable>
		<!--  bk:from @ref -->
		<xsl:variable name="bk_From_ref">
			<xsl:call-template name="getFromTO_ref">
				<xsl:with-param name="Direction" select="'bk:from'"/>
			</xsl:call-template>
		</xsl:variable>
		<bk:Transfer rdf:about="{$Transfer-ID}">
			<xsl:choose>
				<!-- case 1: accounts with nested measure in bk:money  -->
				<xsl:when
					test=".[contains(@ana, 'bk:money')]//t:measure[(@unit or @unitRef) and @quantity]">
					<xsl:for-each select=".//t:measure">
						<bk:transfers>
							<xsl:call-template
								name="create_element_unit_commodity_for_economicAsset">
								<xsl:with-param name="EconomicAsset-ID" select="$EconomicAsset-ID"/>
								<xsl:with-param name="EconomicAsset_new_created_element"
									select="'bk:Money'"/>
							</xsl:call-template>
						</bk:transfers>
					</xsl:for-each>
				</xsl:when>
				<!-- case 2 -->
				<xsl:when test="$number_of_economic_units > 1">
					<xsl:for-each select="current-group()">
						<bk:transfers>
							<xsl:call-template name="create_bk_economicAsset">
								<xsl:with-param name="EconomicAsset-ID" select="$EconomicAsset-ID"/>
							</xsl:call-template>
						</bk:transfers>
					</xsl:for-each>
				</xsl:when>
				<!-- case 3 -->
				<xsl:otherwise>
					<bk:transfers>
						<xsl:call-template name="create_bk_economicAsset">
							<xsl:with-param name="EconomicAsset-ID" select="$EconomicAsset-ID"/>
						</xsl:call-template>
					</bk:transfers>
				</xsl:otherwise>
			</xsl:choose>
			<!--  -->
			<xsl:variable name="rubric" select="../ancestor::*[tokenize(@ana, ' ') = 'bk:account'][1] | ../ancestor::*[tokenize(@ana, ' ') = 'bk:rubric'][1]"/>
			<xsl:choose>
				<xsl:when test="$rubric/@corresp">
					<!-- the TOTEI.xsl creates lower-case @xml:id -->
					<xsl:variable name="rubric-id">
						<xsl:choose>
							<xsl:when test="contains($rubric/@corresp, '#')">
								<xsl:value-of select="lower-case(substring-after($rubric/@corresp, '#'))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="lower-case($rubric/@corresp)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="rubric-in-taxonomy" select="//t:taxonomy[@ana = 'bk:rubrics']//t:category[@xml:id = $rubric-id][1]"/>
					<xsl:variable name="income-or-expense" select="$rubric-in-taxonomy/ancestor-or-self::t:category[not(parent::t:category)][1]/@ana"/>	

					<xsl:choose>
						<xsl:when test="contains($income-or-expense, 'bk:to')">
							<bk:to rdf:resource="{concat($BASE-URL, $CONTEXT, $bk_To_ref)}"/>
							<bk:from rdf:resource="{$ACCOUNHOLDER-URI}"/>
						</xsl:when>
						<xsl:when test="contains($income-or-expense, 'bk:from')">
							<bk:from rdf:resource="{concat($BASE-URL, $CONTEXT, $bk_To_ref)}"/>
							<bk:to rdf:resource="{$ACCOUNHOLDER-URI}"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:comment>Error in rubric-in-taxonomy</xsl:comment>
						</xsl:otherwise>
					</xsl:choose>
					
				</xsl:when>
				
				<!-- bk:money -->
				<xsl:when test="contains(@ana, 'bk:money')">
					<xsl:if test="$bk_From_ref">
						<bk:from rdf:resource="{concat($BASE-URL, $CONTEXT, $bk_From_ref)}"/>
					</xsl:if>
					<xsl:if test="$bk_To_ref">
						<bk:to rdf:resource="{concat($BASE-URL, $CONTEXT, $bk_To_ref)}"/>
					</xsl:if>
				</xsl:when>
				<!-- not bk:money -->
				<xsl:when test="not(contains(@ana, 'bk:money'))">
					<xsl:if test="$bk_From_ref">
						<bk:from rdf:resource="{concat($BASE-URL, $CONTEXT, $bk_To_ref)}"/>
					</xsl:if>
					<xsl:if test="$bk_To_ref">
						<bk:to rdf:resource="{concat($BASE-URL, $CONTEXT, $bk_From_ref)}"/>
					</xsl:if>
				</xsl:when>
				<xsl:when test="$bk_From_ref or $bk_To_ref">
					<xsl:comment>aaa</xsl:comment>
					<bk:from rdf:resource="{concat($BASE-URL, $CONTEXT,  $bk_From_ref)}"/>
					<bk:to rdf:resource="{concat($BASE-URL, $CONTEXT,  $bk_To_ref)}"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message>Error: problem identifying bk:to; bk:from; bk:Agent. The @ana need
						further bk:to bk:from like measure ana="bk:money bk:to"</xsl:message>
					<xsl:value-of select="normalize-space(.)"/>
				</xsl:otherwise>
			</xsl:choose>
		</bk:Transfer>
	</xsl:template>
	<!--  -->
	<xsl:template name="create_bk_economicAsset">
		<xsl:param name="EconomicAsset-ID"/>
		<xsl:choose>
			<!-- if there is a bk:each the context changes. so we have to check this case first -->
			<xsl:when
				test="ancestor::*[contains(@ana, 'bk:entry')][1]//*[contains(@ana, 'bk:each')]">
				<xsl:for-each
					select="ancestor::*[contains(@ana, 'bk:entry')][1]//*[contains(@ana, 'bk:each')]">
					<xsl:variable name="EconomicAsset_new_created_element">
						<xsl:call-template name="choose_ana_economicAsset"/>
					</xsl:variable>
					<xsl:call-template name="create_element_unit_commodity_for_economicAsset">
						<xsl:with-param name="EconomicAsset_new_created_element"
							select="$EconomicAsset_new_created_element"/>
						<xsl:with-param name="EconomicAsset-ID" select="$EconomicAsset-ID"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:when
				test="contains(@ana, 'bk:money') or contains(@ana, 'bk:service') or contains(@ana, 'bk:commodity') or contains(@ana, 'bk:tax')">
				<xsl:variable name="EconomicAsset_new_created_element">
					<xsl:call-template name="choose_ana_economicAsset"/>
				</xsl:variable>
				<!-- ///////////////////////////////////////// -->
				<!-- create bk:Money, bk:Commodity, bk:Service -->
				<xsl:choose>
					<!-- more than 1 measure, like 1 dollar 50 cents -->
					<xsl:when test="count(current-group()) > 1">
						<!-- HUHUHUH::..> i cahnged this ? why ?! :P -->
						<!--<xsl:for-each select="current-group()">-->
						<xsl:call-template name="create_element_unit_commodity_for_economicAsset">
							<xsl:with-param name="EconomicAsset_new_created_element"
								select="$EconomicAsset_new_created_element"/>
							<xsl:with-param name="EconomicAsset-ID"
								select="concat($EconomicAsset-ID, position())"/>
						</xsl:call-template>
						<!--</xsl:for-each>-->
					</xsl:when>
					<!-- 1 bk:EconomicAsset -->
					<xsl:otherwise>
						<xsl:call-template name="create_element_unit_commodity_for_economicAsset">
							<xsl:with-param name="EconomicAsset_new_created_element"
								select="$EconomicAsset_new_created_element"/>
							<xsl:with-param name="EconomicAsset-ID" select="$EconomicAsset-ID"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>Log: Failed to create bk:EconomicAsset missing @ana</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- this template creates an element for e bk:EconomicAsset amds atts bk:unit, bk:quantity and bk:classified -->
	<xsl:template name="create_element_unit_commodity_for_economicAsset">
		<xsl:param name="EconomicAsset-ID"/>
		<xsl:param name="EconomicAsset_new_created_element"/>
		<xsl:element name="{$EconomicAsset_new_created_element}">
			<xsl:attribute name="rdf:about" select="$EconomicAsset-ID"/>
			<!-- get bk:unit -->
			<xsl:call-template name="create_bk_unit"/>
			<!-- get bk:quantity -->
			<xsl:call-template name="create_bk_quantity"/>
			<!-- get bk:classified -->
			<xsl:call-template name="create_bk_classified"/>
		</xsl:element>
	</xsl:template>
	<!-- this template checks if a @ana of a current element contains bk:EconomicAsset and returns the string (for building the e.g. <bk:Money> -->
	<xsl:template name="choose_ana_economicAsset">
		<xsl:choose>
			<xsl:when test="contains(@ana, 'bk:money')">
				<xsl:text>bk:Money</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@ana, 'bk:service')">
				<xsl:text>bk:Service</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@ana, 'bk:commodity')">
				<xsl:text>bk:Commodity</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@ana, 'bk:tax')">
				<xsl:text>bk:Tax</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>bk:EconomicAsset</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- choses if it is bk:Group|bk:Individual|bk:Organisation|bk:EconomicAgent; it a parameter for a xsl:element -->
	<xsl:template name="BK_ECONOMIC_AGENT_SUBCLASS_CHOOSE">
		<xsl:choose>
			<xsl:when test="contains(@ana, 'bk:group')">
				<xsl:text>bk:Group</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@ana, 'bk:individual')">
				<xsl:text>bk:Individual</xsl:text>
			</xsl:when>
			<xsl:when test="contains(@ana, 'bk:organisation')">
				<xsl:text>bk:Organisation</xsl:text>
			</xsl:when>
			<xsl:when test="local-name() = 'persName'">
				<xsl:text>bk:Individual</xsl:text>
			</xsl:when>
			<!-- if it is a  <orgName ana="bk:from">-->
			<xsl:when test="local-name() = 'orgName'">
				<xsl:text>bk:Organisation</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>bk:EconomicAgent</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- names -->
	<xsl:template name="handle_names">
		<xsl:choose>
			<!--  -->
			<xsl:when test="t:forename and t:surname">
				<rdfs:label>
					<xsl:value-of select="normalize-space(t:surname[1])"/>
					<xsl:text>, </xsl:text>
					<xsl:value-of select="normalize-space(t:forename[1])"/>
				</rdfs:label>
				<xsl:if test="t:forename[1]">
					<xsl:apply-templates select="t:forename"/>
				</xsl:if>
				<xsl:if test="t:surname">
					<xsl:apply-templates select="t:surname"/>
				</xsl:if>
			</xsl:when>
			<!-- only surname -->
			<xsl:when test="t:surname">
				<rdfs:label>
					<xsl:value-of select="normalize-space(t:surname[1])"/>
				</rdfs:label>
				<xsl:apply-templates select="t:surname"/>
			</xsl:when>
			<!-- only surname -->
			<xsl:when test="t:forename">
				<rdfs:label>
					<xsl:value-of select="normalize-space(t:forename[1])"/>
				</rdfs:label>
				<xsl:apply-templates select="t:forename"/>
			</xsl:when>
			<xsl:otherwise>
				<rdfs:label>
					<xsl:value-of select="normalize-space(.)"/>
				</rdfs:label>
				<schema:name>
					<xsl:value-of select="normalize-space(.)"/>
				</schema:name>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- to transform string to JSON valid string (SPARQL JSON result) -->
	<xsl:function as="xs:string" name="gams:json-escape">
		<xsl:param as="xs:string" name="string"/>
		<xsl:variable name="regexp">\\|\n|\r|\t|&quot;|/|"</xsl:variable>
		<xsl:variable name="json-escapes">
			<esc j="\\" x="\"/>
			<esc j="\n" x=" "/>
			<esc j="\&quot;" x="&quot;"/>
			<esc j="\t" x=" "/>
			<esc j="\r" x=" "/>
			<esc j="\/" x="/"/>
		</xsl:variable>
		<xsl:variable name="substrings">
			<xsl:analyze-string regex="{$regexp}" select="$string">
				<xsl:matching-substring>
					<xsl:value-of select="$json-escapes/esc[@x = current()]/@j"/>
				</xsl:matching-substring>
				<xsl:non-matching-substring>
					<xsl:value-of select="."/>
				</xsl:non-matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<xsl:value-of select="$substrings"/>
	</xsl:function>
</xsl:stylesheet>

