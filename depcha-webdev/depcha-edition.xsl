<?xml version="1.0" encoding="UTF-8"?>

<!-- 
    Project: GAMS Projekttemplate
    Company: ZIM-ACDH (Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities)
    Author: Christopher Pollin 
 -->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:s="http://www.w3.org/2001/sw/DataAccess/rf1/result" xmlns="http://www.w3.org/1999/xhtml"
	xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:bk="https://gams.uni-graz.at/o:depcha.bookkeeping#"
	xmlns:lido="http://www.lido-schema.org" xmlns:void="http://rdfs.org/ns/void#"
	xmlns:depcha="https://gams.uni-graz.at/o:depcha.ontology#"
	xmlns:gams="https://gams.uni-graz.at/o:gams-ontology#"
	xmlns:oai="http://www.openarchives.org/OAI/2.0/" exclude-result-prefixes="#all">

	<xsl:include href="depcha-static.xsl"/>

	<!-- VARIABLES -->
	<xsl:variable name="teiHeader" select="/t:TEI/t:teiHeader"/>

	<xsl:variable name="DATASET" select="//depcha:Dataset"/>

	<xsl:variable name="PID">
		<xsl:choose>
			<xsl:when test="/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type = 'PID']">
				<xsl:value-of
					select="/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type = 'PID']"/>
			</xsl:when>
			<!--  <depcha:Dataset rdf:about="https://gams.uni-graz.at/o:depcha.gwfp.4#Dataset"> -->
			<xsl:when test="$DATASET/@rdf:about">
				<xsl:value-of
					select="substring-before(substring-after($DATASET/@rdf:about, 'https://gams.uni-graz.at/'), '#')"
				/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="CONTEXT">
		<xsl:choose>
			<xsl:when test="$DATASET/@rdf:about">
				<xsl:value-of
					select="substring-after($DATASET/gams:isMemberOfCollection/@rdf:resource, 'uni-graz.at/')"
				/>
			</xsl:when>
			<xsl:when
				test="contains(/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:ref[1]/@target, 'info:fedora/')">
				<xsl:value-of
					select="substring-after(/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:ref[1]/@target, 'info:fedora/')"
				/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of
					select="/t:TEI/t:teiHeader/t:fileDesc/t:publicationStmt/t:ref[1]/@target"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<xsl:variable name="TAXONOMY"
		select="$teiHeader/t:encodingDesc/t:classDecl/t:taxonomy[@ana = 'depcha:index'][1]"/>
	<xsl:variable name="LIST_ACCOUNTS"
		select="$teiHeader/t:encodingDesc/t:classDecl/t:taxonomy[@ana = 'bk:account'][1]"/>
	<xsl:variable name="LIST_PERSON" select="//t:listPerson[@ana = 'depcha:index'][1]"/>
	<xsl:variable name="LIST_ORG" select="//t:listOrg[@ana = 'depcha:index'][1]"/>
	<xsl:variable name="LIST_PLACE" select="//t:listPlace[@ana = 'depcha:index'][1]"/>
	<xsl:variable name="UNIT_DECL" select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef"/>
	<xsl:variable name="FACSIMILE" select="/t:TEI/t:facsimile"/>
	<xsl:variable name="ACCOUNTHOLDER" select="//*[tokenize(@ana, ' ') = 'bk:accountHolder']"/>


	<!-- TEMPLATES -->
	<xsl:template name="content">
		<!-- EDITION VIEW HEADER -->
		<div class="py-3 bg-light">
			<div class="container">
				<div class="row">

					<div class="col-md-8">
						<h3>Edition</h3>
						<h4>
							<xsl:value-of
								select="/t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc/t:msContents/t:msItem/t:title[1] | $DATASET/dc:title"
							/>
						</h4>
					</div>


					<!-- INFOBOX TRANSACTIONS -->
					<div class="col-md-4">
						<div class="card">
							<div class="card-body">
								<dl class="row small">
									<dt class="col-sm-6">Number of Transactions</dt>
									<dd class="col-sm-6">
										<xsl:value-of
											select="count(//*[contains(@ana, 'bk:entry')])"/>
									</dd>

									<xsl:choose>
										<xsl:when test="$ACCOUNTHOLDER">

											<dt class="col-sm-6">Accountholder</dt>
											<dd class="col-sm-6">
												<xsl:choose>
												<xsl:when test="//t:persName">
												<xsl:value-of
												select="concat($ACCOUNTHOLDER//t:forename[1], ' ', $ACCOUNTHOLDER//t:persName/t:surname[1])"
												/>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of select="$ACCOUNTHOLDER"/>
												</xsl:otherwise>
												</xsl:choose>
											</dd>
										</xsl:when>
									</xsl:choose>
								</dl>
							</div>
						</div>
					</div>
				</div>
				<hr/>

				<!-- ///////////////////////////////////////////////////// -->
				<!-- EDITION VIEW BODY -->
				<div class="py-3 bg-light">

					<!-- Variables -->
					<xsl:variable name="msDESC" select="$teiHeader/t:fileDesc/t:sourceDesc/t:msDesc"/>
					<xsl:variable name="CURRENCIES">
						<xsl:text>[</xsl:text>
						<xsl:for-each
							select="$DATASET/depcha:unit/@rdf:resource | $teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@type = 'currency']/t:label[1]">
							<xsl:text>'</xsl:text>
							<xsl:value-of select="
									if (contains(., '#')) then
										substring-after(., '#')
									else
										."/>
							<xsl:text>'</xsl:text>
							<xsl:if test="not(position() = last())">
								<xsl:text>,</xsl:text>
							</xsl:if>
						</xsl:for-each>
						<xsl:text>]</xsl:text>
					</xsl:variable>


					<!-- ///////////////////////////////////////////////////// -->
					<!-- EDITION VIEW NAVIGATION BAR - between dashboard head and body -->
					<div class="card sticky-top" id="edition-nav">
						<div class="card-body d-flex justify-content-evenly">

							<!-- Return button to get back to collection view -->
							<div class="my-3">

								<a class="btn btn-outline-dark bg-light" style="box-shadow: none;"
									href="/{$CONTEXT}"><svg xmlns="http://www.w3.org/2000/svg"
										width="16" height="16" fill="currentColor"
										class="bi bi-skip-backward" viewBox="0 0 16 16">
										<path
											d="M.5 3.5A.5.5 0 0 1 1 4v3.248l6.267-3.636c.52-.302 1.233.043 1.233.696v2.94l6.267-3.636c.52-.302 1.233.043 1.233.696v7.384c0 .653-.713.998-1.233.696L8.5 8.752v2.94c0 .653-.713.998-1.233.696L1 8.752V12a.5.5 0 0 1-1 0V4a.5.5 0 0 1 .5-.5zm7 1.133L1.696 8 7.5 11.367V4.633zm7.5 0L9.196 8 15 11.367V4.633z"
										/>
									</svg> Collection</a>
							</div>

							<!-- Navigation bar - adapting to different edition contents -->
							<!-- Edition button -->
							<div class="my-3">
								<ul class="nav justify-content-md-center">
									<li class="nav-item">
										<xsl:if test="//t:body">
											<a class="btn btn-outline-dark active" role="tab"
												id="edition-tab" data-bs-toggle="tab"
												data-bs-target="#edition" aria-controls="edition"
												aria-selected="true">
												<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="bottom"
												title="Transcription and Facsimiles"><!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>Edition</span>
											</a>
										</xsl:if>
										<!-- About button -->
										<a class="btn btn-outline-dark" role="tab" id="about-tab"
											data-bs-toggle="tab" data-bs-target="#about"
											aria-controls="about" aria-selected="true">
											<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="bottom"
												title="Metadata about the current edition">
												<!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>About
											</span>
										</a>
										<!-- Transaction button -->
										<a class="btn btn-outline-dark" role="tab"
											id="transaction-tab" data-bs-toggle="tab"
											data-bs-target="#transaction"
											aria-controls="transaction" aria-selected="true">
											<xsl:choose>
												<xsl:when test="not(//t:body)">
												<xsl:attribute name="class">
												<xsl:text>btn btn-outline-dark active</xsl:text>
												</xsl:attribute>
												</xsl:when>
												<xsl:otherwise>
												<xsl:attribute name="onclick">
												<xsl:value-of
												select="concat('get_datatable(&quot;query:depcha.transactions&quot;,', '&quot;', $PID, '&quot;);')"
												/>
												</xsl:attribute>
												</xsl:otherwise>
											</xsl:choose>
											<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="bottom"
												title="Overview of annotated transactions"><!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>Transactions</span>
										</a>
										<!-- Economic Goods button-->
										<xsl:if test="$TAXONOMY">
											<a class="btn btn-outline-dark" role="tab"
												id="assets-tab" data-bs-toggle="tab"
												data-bs-target="#assets" aria-controls="assets"
												aria-selected="true" data-bs-placement="bottom"
												title="Tooltip on bottom">
												<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="bottom"
												title="Overview of traded goods"><!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>Economic
												Goods</span>
											</a>
										</xsl:if>
										<!-- Economic Agents button -->
										<xsl:if test="$LIST_PERSON">
											<a class="btn btn-outline-dark" role="tab"
												id="agents-tab" data-bs-toggle="tab"
												data-bs-target="#agents" aria-controls="agents"
												aria-selected="true">
												<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="bottom"
												title="Overview of persons, groups and organizations involved in the transactions"><!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>Economic
												Agents</span>
											</a>
										</xsl:if>
										<!-- Accounts button -->
										<xsl:if test="$LIST_ACCOUNTS">
											<a class="btn btn-outline-dark" role="tab"
												id="accounts-tab" data-bs-toggle="tab"
												data-bs-target="#accounts" aria-controls="accounts"
												aria-selected="true">
												<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="bottom"
												title="Overview of annotated booking accounts"><!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>Accounts</span>
											</a>
										</xsl:if>
										<!-- Currencies and Units button -->
										<xsl:if test="$UNIT_DECL">
											<a class="btn btn-outline-dark" role="tab"
												id="currencies_units-tab" data-bs-toggle="tab"
												data-bs-target="#currencies_units"
												aria-controls="currencies_units"
												aria-selected="true">
												<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="bottom"
												title="Currencies and other units of measurements used in the current edition"><!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>Currencies
												and Units</span>
											</a>
										</xsl:if>
										<!-- Places button -->
										<xsl:if test="$LIST_PLACE">
											<a class="btn btn-outline-dark" role="tab"
												id="places-tab" data-bs-toggle="tab"
												data-bs-target="#places" aria-controls="places"
												aria-selected="true">
												<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="bottom"
												title="Overview of mentioned places"><!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>Places</span>
											</a>
										</xsl:if>
									</li>
									<li class="nav-item">
										<div class="dropdown">
											<button class="btn btn-outline-dark dropdown-toggle"
												id="dropdownMenuButton1" data-bs-toggle="dropdown"
												aria-expanded="false">
												<span class="py-2" data-bs-toggle="tooltip"
												data-bs-placement="top"
												title="Download your selection of data"><!-- only generate a visible entity view switch if there is a TEI file, 
													for collections with RDF only do not offer an entity view -->
												<xsl:if test="t:TEI"><xsl:attribute name="onclick"
												>entityView()</xsl:attribute></xsl:if>Export</span>
											</button>
											<ul class="dropdown-menu"
												aria-labelledby="dropdownMenuButton1">
												<xsl:if test="//t:body">
												<li>
												<a class="dropdown-item"
												download="{concat(substring-after($PID, 'o:'), '_TEI.xml')}"
												href="{concat('/', $PID, '/TEI_SOURCE')}"
												>XML/TEI</a>
												</li>
												</xsl:if>
												<!--												<li>
													<a class="dropdown-item" href="#">CSV</a>
												</li>-->
												<li>
												<a class="dropdown-item"
												download="{concat(substring-after($PID, 'o:'), '_RDF.xml')}">
												<xsl:attribute name="href">
												<xsl:choose>
												<xsl:when test="//t:body">
												<xsl:value-of select="concat('/', $PID, '/RDF')"/>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of
												select="concat('/', $PID, '/ONTOLOGY')"/>
												</xsl:otherwise>
												</xsl:choose>
												</xsl:attribute>
												<xsl:text>XML/RDF</xsl:text>
												</a>
												</li>
											</ul>
										</div>

									</li>
								</ul>
							</div>

							<div class="my-3" id="entity-view-switch">
								<div class="text-end">
									<div class="d-flex flex-row-reverse">
										<p class="p-1 mb-0" id="colourise">Entity view off</p>
										<p class="p-1 mb-0" id="decolourise">Entity view on</p>
										<div class="d-flex text-end">
											<div class="d-flex center">
												<label class="switch">
												<input type="checkbox" id="switch"
												onclick="mySwitch()"/>
												<span class="slider round p-1"/>
												</label>
											</div>
										</div>
									</div>
								</div>
							</div>
							<!-- For a better layout - sorry! -->
							<div class="my-3" id="placeholder">The invisible tab :)</div>
						</div>
					</div>



					<!-- ///////////////////////////////////////////////////// -->
					<!-- TAB VIEWS -->

					<!-- Edition tab - choosing between views for editions with or without facsimiles -->
					<div class="tab-content">
						<xsl:if test="//t:body">
							<div role="tabpanel" id="edition" aria-labelledby="edition-tab">
								<xsl:attribute name="class" select="
										if (//t:body) then
											'tab-pane fade show active'
										else
											'tab-pane fade'"/>
								<xsl:choose>
									<xsl:when test="$FACSIMILE">
										<div class="col-12">
											<div class="card bg-white" id="text-image-content">
												<xsl:call-template name="get-text-image"/>
											</div>
										</div>
									</xsl:when>
									<xsl:otherwise>
										<div class="col-12">
											<div class="card bg-white" id="only-text-content">
												<xsl:call-template name="get-only-text"/>
											</div>
										</div>
									</xsl:otherwise>
								</xsl:choose>
							</div>
						</xsl:if>

						<!-- About tab -->
						<div role="tabpanel" id="about" class="tab-pane fade"
							aria-labelledby="about-tab">
							<div class="row">
								<div class="col-12">
									<div class="card" id="assets-index-content">
										<xsl:call-template name="get_about_from_teiHeader"/>
									</div>
								</div>
							</div>
						</div>

						<!-- Transaction tab -->
						<div role="tabpanel" id="transaction" class="tab-pane fade"
							aria-labelledby="transactions-tab">
							<xsl:attribute name="class" select="
									if (//t:body) then
										'tab-pane fade'
									else
										'tab-pane fade show active'"/>
							<div class="card" id="transactions-content">
								<div class="card-header">
									<h5 class="card-title"> Transactions <span
											class="badge rounded-pill bg-dark">
											<xsl:value-of
												select="count(//*[contains(@ana, 'bk:entry')])"/>
										</span>
									</h5>
								</div>
								<div class="card-body">
									<div class="table-responsive">
										<div class="d-flex align-items-center" id="loading_spinner">
											<strong>Loading...</strong>
											<div class="spinner-border ms-auto" role="status"
												aria-hidden="true"
												style="width: 5rem; height: 5rem;">
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
									</div>
								</div>
							</div>
							<!-- as for rdf objects we can get the json instantly -->
							<xsl:if test="not(//t:body)">
								<script>
										get_datatable(<xsl:value-of select="'&quot;query:depcha.transactions&quot;'"/>, <xsl:value-of select="concat('&quot;', $PID, '&quot;')"/>);
                                    </script>
							</xsl:if>

						</div>

						<!-- Economic Goods Tab -->
						<xsl:if test="$TAXONOMY">
							<div role="tabpanel" id="assets" class="tab-pane fade"
								aria-labelledby="assets-tab">
								<div class="row">
									<div class="col-12">
										<div class="card" id="assets-index-content">
											<xsl:call-template name="get_taxonomy"/>
										</div>
									</div>
								</div>
							</div>
						</xsl:if>

						<!-- Economic Agents Tab -->
						<xsl:if test="$LIST_PERSON">
							<div role="tabpanel" id="agents" class="tab-pane fade"
								aria-labelledby="agents-tab">
								<div class="row">
									<div class="col-12">
										<div class="card" id="agents-content">
											<xsl:call-template name="get_economic_agent_list_tab"/>
										</div>
									</div>
								</div>
							</div>
						</xsl:if>

						<!-- Currencies and Units Tab -->
						<xsl:if test="$teiHeader/t:encodingDesc/t:unitDecl">
							<div role="tabpanel" id="currencies_units" class="tab-pane fade"
								aria-labelledby="currencies_units-tab">
								<div class="row">
									<div class="col-12">
										<div class="card" id="currencies_units-content">
											<xsl:call-template name="get_unitDecl_list"/>
										</div>
									</div>
								</div>
							</div>
						</xsl:if>

						<!-- Accounts Tab -->
						<xsl:if test="$LIST_ACCOUNTS">
							<div role="tabpanel" id="accounts" class="tab-pane fade"
								aria-labelledby="accounts-tab">
								<div class="row">
									<div class="col-12">
										<div class="card" id="account-content">
											<xsl:call-template name="get_account_list"/>
										</div>
									</div>
								</div>
							</div>
						</xsl:if>

						<!-- Places Tab -->
						<xsl:if test="$LIST_PLACE">
							<div role="tabpanel" id="places" class="tab-pane fade"
								aria-labelledby="places-tab">
								<div class="row">
									<div class="col-12">
										<div class="card" id="currencies_units-content">
											<xsl:call-template name="get_place_list"/>
										</div>
									</div>
								</div>
							</div>
						</xsl:if>
					</div>
				</div>
			</div>


			<xsl:if test="/t:TEI">
				<script>
					$(document).ready(function(){
					entityView();
					})
				</script>
			</xsl:if>
		</div>
	</xsl:template>


	<!-- ////////////////////////////////////////////////////////////////////////////////////////////////////////// -->
	<!-- EDITION TAB CONTENT -->
	<!-- TEXT-IMAGE VIEW - generates the view for editions with facsimiles -->
	<xsl:template name="get-text-image">

		<!-- Toggleable style key that shows how entities are styled when entity view is switched on -->
		<div class="card sticky-top" id="stylekey">
			<div class="card-body d-flex justify-content-end">
				<div class="item">
					<p class="mb-0">Style Key</p>
				</div>
				<div class="item">
					<p class="mb-0 bg-ea" title="without further categorisation">Econ. Agent
						<!--<svg
												xmlns="http://www.w3.org/2000/svg" width="14"
												height="14" fill="currentColor"
												class="bi bi-info-circle" viewBox="0 0 16 16">
												<path
												d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"/>
												<path
												d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533L8.93 6.588zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0z"
												/>
											</svg>-->
					</p>
				</div>
				<div class="item">
					<p class="mb-0 bg-ea-individual">Individual</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-ea-group">Group</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-ea-organisation">Organisation</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-eg-commodity">Commodity</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-eg-service">Service</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-eg-right">Right</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-place">Place</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-date">Date</p>
				</div>
				<div class="item">
					<p class="mb-0 item entry">Transaction</p>
				</div>
				<div class="item account-style">
					<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"
						fill="currentColor" class="bi bi-book" viewBox="0 0 16 16">
						<path
							d="M1 2.828c.885-.37 2.154-.769 3.388-.893 1.33-.134 2.458.063 3.112.752v9.746c-.935-.53-2.12-.603-3.213-.493-1.18.12-2.37.461-3.287.811V2.828zm7.5-.141c.654-.689 1.782-.886 3.112-.752 1.234.124 2.503.523 3.388.893v9.923c-.918-.35-2.107-.692-3.287-.81-1.094-.111-2.278-.039-3.213.492V2.687zM8 1.783C7.015.936 5.587.81 4.287.94c-1.514.153-3.042.672-3.994 1.105A.5.5 0 0 0 0 2.5v11a.5.5 0 0 0 .707.455c.882-.4 2.303-.881 3.68-1.02 1.409-.142 2.59.087 3.223.877a.5.5 0 0 0 .78 0c.633-.79 1.814-1.019 3.222-.877 1.378.139 2.8.62 3.681 1.02A.5.5 0 0 0 16 13.5v-11a.5.5 0 0 0-.293-.455c-.952-.433-2.48-.952-3.994-1.105C10.413.809 8.985.936 8 1.783z"
						/>
					</svg> Account </div>> <div class="item">
					<p class="mb-0 item subtotal">Subtotal</p>
				</div>
				<div class="item">
					<p class="mb-0 item total">Total</p>
				</div>
			</div>
		</div>

		<div class="container py-4">

			<div class="row">
				<div class="col-md-6">
					<h2>Transcription</h2>
				</div>
			</div>
		</div>

		<section class="row">
			<article class="col-md-6">
				<div class="card">
					<div class="card-body">
						<xsl:apply-templates select="//t:body"/>
					</div>
				</div>
			</article>
			<article class="col-md-6">
				<div class="sticky-top" style="top:235px; z-index:100;" id="image-viewer">
					<div id="vwr-content" class="toc"
						style="background-color: #F0F0F0; height:700px;">
						<xsl:text> </xsl:text>
					</div>
					<xsl:variable name="Desc"
						select="t:TEI/t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc"/>
					<div class="MsInfo">
						<xsl:apply-templates select="$Desc/t:msIdentifier/t:settlement"/>
						<xsl:text>, </xsl:text>
						<xsl:value-of select="$Desc/t:msIdentifier/t:institution"/>
					</div>
				</div>
				<script type="text/javascript" src="/editionviewer/openseadragon.js"><xsl:text> </xsl:text>
				</script>
				<script type="text/javascript" src="/editionviewer/bs-scroll-the-edition.js"><xsl:text> </xsl:text>
				</script>
				<script type="text/javascript" src="/editionviewer/gamsEdition.js"><xsl:text> </xsl:text>
				</script>
				<script type="text/javascript">
                    gamsOsd({
                        id: "vwr-content",
                        prefixUrl: "/osdviewer/images/",
                        showNavigator: false,
                        sequenceMode: true,
                        intialPage: 0,
                        defaultZoomLevel: 0,
                        showSequenceControl: true,
                        showReferenceStrip: false,
                        showRotationControl: false,
                        referenceStripScroll: "horizontal",
                        pid:<xsl:value-of select="concat('&quot;', '/', $teipid, '&quot;')"/>

                });</script>
				<!--<script type="text/javascript" src="{$projectRootPath}/js/depcha.js"><xsl:text> </xsl:text></script>-->
			</article>
		</section>
	</xsl:template>

	<!-- //////////////////// -->
	<!-- TEXT-ONLY VIEW - generates the view for editions without facsimiles -->
	<xsl:template name="get-only-text">

		<!-- Toggleable style key that shows how entities are styled when entity view is switched on -->
		<div class="card sticky-top" id="stylekey">
			<div class="card-body d-flex justify-content-end">
				<div class="item">
					<p class="mb-0">Style Key</p>
				</div>
				<div class="item">
					<p class="mb-0 bg-ea" title="without further categorisation">Econ. Agent
						<!--<svg
												xmlns="http://www.w3.org/2000/svg" width="14"
												height="14" fill="currentColor"
												class="bi bi-info-circle" viewBox="0 0 16 16">
												<path
												d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"/>
												<path
												d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533L8.93 6.588zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0z"
												/>
											</svg>-->
					</p>
				</div>
				<div class="item">
					<p class="mb-0 bg-ea-individual">Individual</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-ea-group">Group</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-ea-organisation">Organisation</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-eg-commodity">Commodity</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-eg-service">Service</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-eg-right">Right</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-place">Place</p>
				</div>
				<div class="item">
					<p class="mb-0 item bg-date">Date</p>
				</div>
				<div class="item">
					<p class="mb-0 item entry">Transaction</p>
				</div>
				<div class="item account-style">
					<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"
						fill="currentColor" class="bi bi-book" viewBox="0 0 16 16">
						<path
							d="M1 2.828c.885-.37 2.154-.769 3.388-.893 1.33-.134 2.458.063 3.112.752v9.746c-.935-.53-2.12-.603-3.213-.493-1.18.12-2.37.461-3.287.811V2.828zm7.5-.141c.654-.689 1.782-.886 3.112-.752 1.234.124 2.503.523 3.388.893v9.923c-.918-.35-2.107-.692-3.287-.81-1.094-.111-2.278-.039-3.213.492V2.687zM8 1.783C7.015.936 5.587.81 4.287.94c-1.514.153-3.042.672-3.994 1.105A.5.5 0 0 0 0 2.5v11a.5.5 0 0 0 .707.455c.882-.4 2.303-.881 3.68-1.02 1.409-.142 2.59.087 3.223.877a.5.5 0 0 0 .78 0c.633-.79 1.814-1.019 3.222-.877 1.378.139 2.8.62 3.681 1.02A.5.5 0 0 0 16 13.5v-11a.5.5 0 0 0-.293-.455c-.952-.433-2.48-.952-3.994-1.105C10.413.809 8.985.936 8 1.783z"
						/>
					</svg> Account </div>
				<div class="item">
					<p class="mb-0 item subtotal">Subtotal</p>
				</div>
				<div class="item">
					<p class="mb-0 item total">Total</p>
				</div>
			</div>
		</div>


		<div class="container my-4">
			<div class="row">
				<div class="col-md-6">
					<h2>Transcription</h2>
				</div>
			</div>
		</div>

		<section>
			<div class="card">
				<div class="card-body">
					<xsl:apply-templates select="//t:body"/>
				</div>
			</div>
		</section>
	</xsl:template>

	<!-- ABOUT TAB CONTENT - creates the about tab from the tei-header -->
	<xsl:template name="get_about_from_teiHeader">
		<div class="container my-4">
			<h2>About</h2>
			<div class="table-responsive">
				<table class="table table-borderless">
					<tbody>
						<xsl:for-each select="$teiHeader//t:titleStmt/t:*">
							<tr>
								<th class="col-md-2">

									<xsl:choose>
										<xsl:when test="local-name() = 'respStmt'">
											<xsl:text>Responsibility Statement:</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of
												select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ''[not(last())], ': ')"
											/>
										</xsl:otherwise>
									</xsl:choose>
								</th>
								<td class="col-md-8">
									<xsl:value-of select="."/>
								</td>
							</tr>
						</xsl:for-each>
					</tbody>
				</table>
			</div>
			<div id="publication">
				<h3 class="mt-3">Publication</h3>
				<div class="table-responsive">
					<table class="table table-borderless">
						<tbody>
							<xsl:for-each select="$teiHeader//t:publicationStmt/t:*">
								<tr>
									<th class="col-md-2">
										<xsl:choose>
											<xsl:when test="local-name() = 'ref'">
												<xsl:text>Reference:</xsl:text>
											</xsl:when>
											<xsl:when test="local-name() = 'idno'">
												<xsl:text>Persistent Identifier:</xsl:text>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of
												select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ''[not(last())], ': ')"
												/>
											</xsl:otherwise>
										</xsl:choose>

									</th>
									<td class="col-md-8">
										<xsl:value-of select="."/>
									</td>
								</tr>
							</xsl:for-each>
						</tbody>
					</table>
				</div>
			</div>
			<!-- Project -->
			<xsl:if test="$teiHeader//t:projectDesc">
				<div id="project">
					<h3 class="mt-3">Project</h3>
					<table class="table table-borderless">
						<tbody>
							<tr>
								<th class="col-md-2">
									<xsl:text>Project Information</xsl:text>
								</th>
								<td class="col-md-8">
									<xsl:apply-templates select="$teiHeader//t:projectDesc"/>
								</td>
							</tr>
						</tbody>
					</table>
				</div>
			</xsl:if>
			<!-- Source -->
			<xsl:if test="$teiHeader//t:sourceDesc">
				<div id="source">
					<h3 class="mt-3">Source</h3>
					<div class="table-responsive">
						<table class="table table-borderless">
							<tbody>
								<xsl:for-each select="$teiHeader//t:sourceDesc/t:msDesc/t:*">
									<tr>
										<th class="col-md-2">
											<xsl:if test="local-name() = 'msIdentifier'">
												<xsl:text>Manuscript Information:</xsl:text>
											</xsl:if>
											<xsl:if test="local-name() = 'msContents'">
												<xsl:text>Manuscript Content:</xsl:text>
											</xsl:if>
										</th>
										<td class="col-md-8">
											<xsl:for-each select="t:*">
												<xsl:value-of select="."/>
												<xsl:if test="not(position() = last())">
												<br/>
												</xsl:if>
											</xsl:for-each>
										</td>
									</tr>
								</xsl:for-each>
							</tbody>
						</table>
					</div>
				</div>
			</xsl:if>
			<!-- Revision -->
			<xsl:if test="$teiHeader/t:revisionDesc">
				<div id="revision">
					<h3 class="mt-3">Revision</h3>
					<ul>
						<xsl:for-each select="$teiHeader/t:revisionDesc/t:*">
							<li>
								<xsl:value-of
									select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ''[not(last())], ': ')"/>
								<xsl:apply-templates/>
							</li>
						</xsl:for-each>
					</ul>
				</div>
			</xsl:if>
		</div>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- ECONOMIC GOODS TAB CONTENT - processes a taxonomy from the edition -->
	<xsl:template name="get_taxonomy">
		<div class="container">
			<div class="accordion accordion-flush my-4" id="accordion_taxonomy">
				<div class="my-4">
					<h2>Economic Goods</h2>
					<xsl:for-each select="$TAXONOMY/t:category">
						<xsl:sort select="t:catDesc/t:term[1] | t:catDesc/t:gloss[1]"/>
						<div class="accordion-item" id="{@xml:id}" title="Top concept">
							<h2 class="accordion-header fw-bold">
								<span class="accordion-button collapsed row"
									data-bs-toggle="collapse"
									data-bs-target="{concat('#', generate-id())}"
									aria-expanded="true" aria-controls="{generate-id()}">
									<span class="col-8">
										<xsl:value-of
											select="t:catDesc/t:term[1] | t:catDesc/t:gloss[1]"/>
									</span>
									<a
										href="{concat('/archive/objects/query:depcha.search.economicgoods/methods/sdef:Query/get?params=', encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '#', @xml:id, '&gt;')))}"
										target="_blank" class="col-4" title="Search for all trans">
										<i class="bi bi-search link-dark">
											<xsl:text> </xsl:text>
										</i>
									</a>
								</span>
							</h2>
							<div id="{generate-id()}" class="accordion-collapse collapse"
								aria-labelledby="headingOne" data-bs-parent="#accordion_taxonomy">
								<div class="accordion-body">
									<dl class="row text-start">
										<xsl:for-each select="*[not(local-name() = 'category')]">
											<dt class="col-sm-3">
												<xsl:choose>
												<xsl:when test="local-name() = 'todo'">
												<xsl:text>todo</xsl:text>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of
												select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ' '[not(last())])"
												/>
												</xsl:otherwise>
												</xsl:choose>
											</dt>
											<dd class="col-sm-9">
												<xsl:choose>
												<xsl:when test="local-name() = 'todo'">
												<xsl:value-of select="@value"/>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of select="normalize-space(.)"/>
												</xsl:otherwise>
												</xsl:choose>
											</dd>
										</xsl:for-each>
									</dl>
								</div>
							</div>
							<xsl:apply-templates select="t:category"/>
						</div>
					</xsl:for-each>
				</div>
			</div>
		</div>
	</xsl:template>

	<!-- template for all sub categories -->
	<xsl:template match="t:category/t:category">
		<xsl:variable name="DEPTH" select="count(ancestor::t:category)"/>
			
			<div class="accordion-item" id="{@xml:id}">
				<xsl:element name="{concat('h', $DEPTH + 2)}">
					<xsl:attribute name="class" select="'accordion-header'"/>
					<span class="accordion-button collapsed row" data-bs-toggle="collapse"
						data-bs-target="{concat('#', generate-id())}" aria-expanded="true"
						aria-controls="{generate-id()}">
						<span>
							<xsl:attribute name="class" select="concat('col-6 ps-', $DEPTH + 1)"/>
							<xsl:value-of select="
									if (t:catDesc/t:term[1]) then
										(t:catDesc/t:term[1])
									else
										(t:catDesc)"/>
						</span>
						<span class="col-2">
							<xsl:if test="t:catDesc/t:term[1]/@ref">
								<a target="_blank">
									<xsl:attribute name="href">
										<xsl:choose>
											<xsl:when
												test="contains(t:catDesc/t:term[1]/@ref, 'wd:')">
												<xsl:value-of
												select="concat('http://www.wikidata.org/wiki/', substring-after(t:catDesc/t:term[1]/@ref, 'wd:'))"
												/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="t:catDesc/t:term[1]/@ref"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:attribute>
									<img src="{concat($projectRootPath, 'img/wikidata.png')}"
										title="Wikidata" idth="20px" height="20px"/>
									<xsl:text> </xsl:text>
								</a>
							</xsl:if>
							<xsl:text> </xsl:text>
						</span>
						<a
							href="{concat('/archive/objects/query:depcha.search.economicgoods/methods/sdef:Query/get?params=', encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '#', @xml:id, '&gt;')))}"
							target="_blank" class="col-4" title="Search for all trans">
							<i class="bi bi-search link-dark">
								<xsl:text> </xsl:text>
							</i>
							<xsl:text> </xsl:text>
						</a>
					</span>
				</xsl:element>
				<div id="{generate-id()}" class="accordion-collapse collapse"
					aria-labelledby="headingOne" data-bs-parent="#accordion_taxonomy">
					<div class="accordion-body">
						<dl class="row text-start">
							<xsl:for-each select="*[not(local-name() = 'category')]">
								<dt class="col-sm-3">
									<xsl:choose>
										<xsl:when test="local-name() = 'todo'">
											<xsl:text>todo</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of
												select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ' '[not(last())])"
											/>
										</xsl:otherwise>
									</xsl:choose>
								</dt>
								<dd class="col-sm-9">
									<xsl:choose>
										<xsl:when test="local-name() = 'todo'">
											<xsl:value-of select="@value"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(.)"/>
										</xsl:otherwise>
									</xsl:choose>
								</dd>
							</xsl:for-each>
						</dl>
					</div>
				</div>
				<xsl:apply-templates select="t:category"/>
			</div>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- ECONOMIC AGENTS TAB - check listPerson and listOrg for economic agents -->
	<xsl:template name="get_economic_agent_list_tab">
		<xsl:choose>
			<xsl:when test="$LIST_PERSON and $LIST_ORG">
				<div>
					<div class="row">
						<div class="col-6">
							<div class="tab-content">
								<div role="tabpanel" id="list-person"
									aria-labelledby="list-person-tab">
									<xsl:attribute name="class" select="
											if (//t:body) then
												'tab-pane fade show active'
											else
												'tab-pane fade'"/>
									<div id="persons">
										<xsl:call-template name="get-list-person"/>
									</div>
								</div>

							</div>
						</div>

						<div class="col-6">
							<div role="tabpanel" id="list-organisation" class="tab-pane fade"
								aria-labelledby="list-organisation-tab">
								<xsl:attribute name="class" select="
										if (//t:body) then
											'tab-pane fade show active'
										else
											'tab-pane fade'"/>
								<div id="organisations">
									<xsl:call-template name="get-list-organisation"/>
								</div>
							</div>
						</div>
					</div>
				</div>

			</xsl:when>
			<xsl:when test="$LIST_PERSON">
				<xsl:call-template name="get-list-person"/>
			</xsl:when>
			<xsl:when test="$LIST_ORG">
				<xsl:call-template name="get-list-organisation"/>
			</xsl:when>
		</xsl:choose>

	</xsl:template>

	<xsl:template name="get-list-person">
		<div class="container">
			<!-- process data from listPerson -->
			<xsl:if test="$LIST_PERSON">
				<div class="accordion accordion-flush my-4" id="accordion_list_person">
					<h3 class="my-4">
						<xsl:value-of select="
								if ($LIST_PERSON/t:head[1]) then
									$LIST_PERSON/t:head[1]
								else
									'Persons'"/>
					</h3>
					<xsl:if test="$LIST_PERSON/t:desc">
						<p>
							<xsl:value-of select="$LIST_PERSON/t:desc"/>
						</p>
					</xsl:if>

					<xsl:for-each select="$LIST_PERSON/t:person">
						<xsl:sort select="t:name[1]" data-type="text"/>
						<xsl:sort select="t:persName[1]" data-type="text"/>
						<xsl:sort select="t:occupation[1]" data-type="text"/>
						<xsl:variable name="current_xml_id" select="@xml:id"/>

						<div class="accordion-item p-3" id="{$current_xml_id}">
							<h2 class="accordion-header">
								<span class="accordion-button collapsed row"
									data-bs-toggle="collapse"
									data-bs-target="{concat('#', generate-id())}"
									aria-expanded="true" aria-controls="{generate-id()}">
									<span class="col-8">
										<xsl:choose>
											<xsl:when test="t:name | t:persName">
												<xsl:value-of select="t:name | t:persName"/>
												<!--<xsl:text> </xsl:text>
												<span class="badge rounded-pill bg-dark">
												<xsl:value-of select="0"/>
												</span>-->
											</xsl:when>
											<xsl:when test="t:occupation">
												<xsl:value-of
												select="concat('[', t:occupation, ']')"/>
											</xsl:when>
											<xsl:otherwise/>
										</xsl:choose>
									</span>
									<a
										href="{concat('/archive/objects/query:depcha.search.economicagents/methods/sdef:Query/get?params=', encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '#', @xml:id, '&gt;')))}"
										target="_blank" class="col-3"
										title="Search for all transactions connected to this economic uni">
										<i class="bi bi-search link-dark">
											<xsl:text> </xsl:text>
										</i>
										<xsl:text> </xsl:text>
									</a>
								</span>
							</h2>
							<div id="{generate-id()}" class="accordion-collapse collapse"
								aria-labelledby="headingOne" data-bs-parent="#accordion_list_person">
								<div class="accordion-body">
									<dl class="row text-start">
										<xsl:for-each select="*">
											<dt class="col-sm-3">
												<xsl:choose>
												<xsl:when test="local-name() = 'persName'">
												<xsl:text>Name</xsl:text>
												</xsl:when>
												<xsl:when test="local-name() = 'AddName'">
												<xsl:text>Add Name</xsl:text>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of
												select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ' '[not(last())])"
												/>
												</xsl:otherwise>
												</xsl:choose>
											</dt>
											<dd class="col-sm-9">
												<xsl:choose>
												<xsl:when test="local-name() = 'sex'">
												<xsl:value-of select="."/>
												</xsl:when>
												<xsl:when test="local-name() = 'state'">
												<xsl:value-of select="@type"/>
												<xsl:text>: </xsl:text>
												<span title="Not before">
												<xsl:value-of select="@notBefore"/>
												</span>
												<xsl:if test="@notAfter">
												<xsl:text>-</xsl:text>
												<span title="Not after">
												<xsl:value-of select="@notAfter"/>
												</span>
												</xsl:if>
												</xsl:when>
												<xsl:when
												test="local-name() = 'birth' or local-name() = 'death'">
												<xsl:choose>
												<xsl:when test="@from or @to">
												<xsl:value-of select="@from"/>
												<xsl:if test="@to">
												<xsl:text>-</xsl:text>
												<xsl:value-of select="@to"/>
												</xsl:if>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of select="@when"/>
												</xsl:otherwise>
												</xsl:choose>
												<xsl:if test="t:placeName">
												<xsl:text>, </xsl:text>
												<xsl:value-of select="t:placeName"/>
												</xsl:if>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of select="normalize-space(.)"/>
												</xsl:otherwise>
												</xsl:choose>
											</dd>
										</xsl:for-each>
									</dl>
								</div>
							</div>
						</div>
					</xsl:for-each>
				</div>
			</xsl:if>
		</div>
	</xsl:template>

	<xsl:template name="get-list-organisation">
		<div class="container">
			<!-- process data from listOrganisation -->
			<xsl:if test="$LIST_ORG">
				<div class="accordion accordion-flush my-4" id="accordion_org_list">
					<h3 class="my-4">
						<xsl:value-of select="
								if ($LIST_ORG/t:head[1]) then
									$LIST_ORG/t:head[1]
								else
									'Organisations'"/>
					</h3>
					<xsl:if test="$LIST_ORG/t:desc">
						<p>
							<xsl:value-of select="$LIST_ORG/t:desc"/>
						</p>
					</xsl:if>
					<xsl:for-each select="$LIST_ORG/t:org">
						<div class="accordion-item p-3" id="{@xml:id}">
							<h2 class="accordion-header">
								<span class="accordion-button collapsed row"
									data-bs-toggle="collapse"
									data-bs-target="{concat('#', generate-id())}"
									aria-expanded="true" aria-controls="{generate-id()}">
									<span class="col-8">
										<xsl:value-of select="t:name | t:orgName"/>
									</span>
									<a
										href="{concat('/archive/objects/query:depcha.search.economicagents/methods/sdef:Query/get?params=', encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '#', @xml:id, '&gt;')))}"
										target="_blank" class="col-3" title="Search for all trans">
										<i class="bi bi-search link-dark">
											<xsl:text> </xsl:text>
										</i>
										<xsl:text> </xsl:text>
									</a>
								</span>
							</h2>
							<div id="{generate-id()}" class="accordion-collapse collapse"
								aria-labelledby="headingOne" data-bs-parent="#accordion_org_list">
								<div class="accordion-body">
									<dl class="row text-start">
										<xsl:for-each select="*">
											<dt class="col-sm-3">
												<xsl:choose>
												<xsl:when test="local-name() = 'orgName'">
												<xsl:text>Name</xsl:text>
												</xsl:when>
												<xsl:when test="local-name() = 'AddName'">
												<xsl:text>Add Name</xsl:text>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of
												select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ' '[not(last())])"
												/>
												</xsl:otherwise>
												</xsl:choose>
											</dt>
											<dd class="col-sm-9">
												<xsl:choose>
												<xsl:when test="local-name() = 'sex'">
												<xsl:value-of select="@value"/>
												</xsl:when>
												<xsl:otherwise>
												<xsl:choose>
												<xsl:when test="local-name() = 'settlement'">
												<xsl:value-of select="@value"/>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of select="normalize-space(.)"/>
												</xsl:otherwise>
												</xsl:choose>
												</xsl:otherwise>
												</xsl:choose>
											</dd>
										</xsl:for-each>
									</dl>
								</div>
							</div>
						</div>
					</xsl:for-each>
				</div>
			</xsl:if>
		</div>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<!-- CURRENCIES AND UNITS TAB -->
	<xsl:template name="get_unitDecl_list">
		<div class="container">
			<div class="accordion accordion-flush my-4" id="accordion_unitDecl_list">
				<h2>Currencies and Units</h2>
				<xsl:for-each-group select="$UNIT_DECL" group-by="@type">
					<xsl:sort select="@type" data-type="text" lang="en"/>
					<div class="my-4">
						<h3>
							<xsl:value-of
								select="concat(upper-case(substring(current-grouping-key(), 1, 1)), substring(current-grouping-key(), 2), ' '[not(last())])"
							/>
						</h3>
						<xsl:for-each select="current-group()">
							<div class="accordion-item p-3" id="{@xml:id}">
								<h2 class="accordion-header">
									<span class="accordion-button collapsed row"
										data-bs-toggle="collapse"
										data-bs-target="{concat('#', generate-id())}"
										aria-expanded="true" aria-controls="{generate-id()}">
										<span class="col-8">
											<xsl:value-of select="
													if (t:label[@xml:lang = 'en'][1]) then
														t:label[@xml:lang = 'en'][1]
													else
														t:label[1]"/>
											<xsl:if
												test="t:label[@type = 'abbreviation'] | t:label[@type = 'abbr'][1]">
												<span title="Abbreviation">
												<xsl:value-of
												select="concat(' (', t:label[@type = 'abbreviation'][1] | t:label[@type = 'abbr'][1], ')')"
												/>
												</span>
											</xsl:if>
											<xsl:if test="@ana = 'bk:mainCurrency'">
												<xsl:text> [bk:mainCurrency]</xsl:text>
											</xsl:if>
										</span>
										<a
											href="{concat('/archive/objects/query:depcha.search.units/methods/sdef:Query/get?params=', encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '#', @xml:id, '&gt;')))}"
											target="_blank" class="col-4"
											title="Search for all trans">
											<i class="bi bi-search link-dark">
												<xsl:text> </xsl:text>
											</i>
											<xsl:text> </xsl:text>
										</a>
									</span>
								</h2>
								<div id="{generate-id()}" class="accordion-collapse collapse"
									aria-labelledby="headingOne"
									data-bs-parent="#accordion_unitDecl_list">
									<div class="accordion-body">
										<dl class="row text-start">
											<xsl:for-each select="*">
												<dt class="col-sm-3">
												<xsl:value-of
												select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ' '[not(last())])"
												/>
												</dt>
												<dd class="col-sm-9">
												<xsl:choose>
												<xsl:when test="local-name() = 'conversion'">
												<xsl:variable name="FROM_UNIT" select="
																	if (contains(@fromUnit, '#')) then
																		(substring-after(@fromUnit, '#'))
																	else
																		(@fromUnit)"/>
												<xsl:variable name="TO_UNIT" select="
																	if (contains(@toUnit, '#')) then
																		(substring-after(@toUnit, '#'))
																	else
																		(@toUnit)"/>
												<xsl:value-of
												select="$UNIT_DECL[@xml:id = $FROM_UNIT]/t:label[1]"/>
												<xsl:text> </xsl:text>
												<svg xmlns="http://www.w3.org/2000/svg" width="16"
												height="16" fill="currentColor"
												class="bi bi-arrow-right" viewBox="0 0 16 16">
												<path fill-rule="evenodd"
												d="M1 8a.5.5 0 0 1 .5-.5h11.793l-3.147-3.146a.5.5 0 0 1 .708-.708l4 4a.5.5 0 0 1 0 .708l-4 4a.5.5 0 0 1-.708-.708L13.293 8.5H1.5A.5.5 0 0 1 1 8z"
												/>
												</svg>
												<xsl:text> </xsl:text>
												<xsl:value-of
												select="$UNIT_DECL[@xml:id = $TO_UNIT]/t:label[1]"/>
												<xsl:text>: </xsl:text>
												<xsl:value-of select="@formula"/>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of select="normalize-space(.)"/>
												</xsl:otherwise>
												</xsl:choose>

												</dd>
											</xsl:for-each>
										</dl>
									</div>
								</div>
							</div>
						</xsl:for-each>
					</div>
				</xsl:for-each-group>
			</div>

		</div>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- ACCOUNTS TAB -->
	<xsl:template name="get_account_list">
		<div class="container">
			<div class="accordion accordion-flush my-4" id="accordion_account">
				<h2>Accounts</h2>
				<xsl:for-each select="$LIST_ACCOUNTS//t:category">
					<xsl:sort select="
							lower-case(
							if (t:catDesc/t:term[1]) then
								(t:catDesc/t:term[1])
							else
								if (t:catDesc/t:gloss[1]) then
									(t:catDesc/t:gloss[1])
								else
									if (t:term[1]) then
										(t:term[1])
									else
										if (t:gloss[1]) then
											(t:gloss[1])
										else
											(t:catDesc))"/>
					<div class="accordion-item p-3" id="{@xml:id}">
						<span class="accordion-button collapsed row" data-bs-toggle="collapse"
							data-bs-target="{concat('#', generate-id())}" aria-expanded="true"
							aria-controls="{generate-id()}">
							<span class="col-8">
								<xsl:value-of select="
										if (t:catDesc/t:term[1]) then
											(t:catDesc/t:term[1])
										else
											if (t:catDesc/t:gloss[1]) then
												(t:catDesc/t:gloss[1])
											else
												if (t:term[1]) then
													(t:term[1])
												else
													if (t:gloss[1]) then
														(t:gloss[1])
													else
														(t:catDesc)"/>
							</span>
							<a
								href="{concat('/archive/objects/query:depcha.search.economicagents/methods/sdef:Query/get?params=', encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '#', @xml:id, '&gt;')))}"
								target="_blank" class="col-4"
								title="Search for all transactions connected to this account">
								<i class="bi bi-search link-dark">
									<xsl:text> </xsl:text>
								</i>
								<xsl:text> </xsl:text>
							</a>
						</span>
						<div id="{generate-id()}" class="accordion-collapse collapse"
							aria-labelledby="headingOne" data-bs-parent="#accordion_account">
							<div class="accordion-body">
								<dl class="row text-start">
									<xsl:for-each select="*[not(local-name() = 'category')]">
										<dt class="col-sm-3">
											<xsl:value-of
												select="concat(upper-case(substring(local-name(), 1, 1)), substring(local-name(), 2), ' '[not(last())])"
											/>
										</dt>
										<dd class="col-sm-9">
											<xsl:value-of select="normalize-space(.)"/>
										</dd>
									</xsl:for-each>
								</dl>
							</div>
						</div>
					</div>
				</xsl:for-each>
			</div>
		</div>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- PLACES TAB -->
	<xsl:template name="get_place_list">
		<div class="container">
			<div class="accordion accordion-flush my-4" id="accordion_place_list">
				<h2>Places</h2>
				<xsl:for-each select="$LIST_PLACE/t:place">
					<xsl:sort select="(t:geogName | t:placeName)[1]" data-type="text" lang="en"/>
					<div class="accordion-item p-3" id="{@xml:id}">
						<h2 class="accordion-header">
							<span class="accordion-button collapsed row" data-bs-toggle="collapse"
								data-bs-target="{concat('#', generate-id())}" aria-expanded="true"
								aria-controls="{generate-id()}">
								<span class="col-8">
									<xsl:value-of select="(t:geogName | t:placeName)[1]"/>
								</span>
								<a
									href="{concat('/archive/objects/query:depcha.search.places/methods/sdef:Query/get?params=', encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $CONTEXT, '#', @xml:id, '&gt;')))}"
									target="_blank" class="col-4" title="Search for all trans">
									<i class="bi bi-search link-dark">
										<xsl:text> </xsl:text>
									</i>
									<xsl:text> </xsl:text>
								</a>
							</span>
						</h2>
						<div id="{generate-id()}" class="accordion-collapse collapse"
							aria-labelledby="headingOne" data-bs-parent="#accordion_place_list">
							<div class="accordion-body">
								<dl class="row text-start">
									<xsl:for-each
										select=".//*[not(local-name() = 'placeName' or descendant::*)]">
										<dt class="col-sm-3">
											<xsl:value-of select="local-name()"/>
										</dt>
										<dd class="col-sm-9">
											<xsl:value-of select="normalize-space(.)"/>
										</dd>
									</xsl:for-each>
								</dl>
							</div>
						</div>
					</div>
				</xsl:for-each>
			</div>
		</div>
	</xsl:template>


	<!-- ////////////////////////////////////////////////////////////////////////////////////////////////////////// -->
	<!-- EDITION BODY TEXT TEMPLATES -->

	<!--//////////////////////////////////////////////////////////////////////////////// -->
	<!-- TEI ELEMENTS -->

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:body">
		<div class="container bg-white">
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:text">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:fw">
		<div class="row pt-2">
			<p>
				<xsl:if test="@type">
					<xsl:attribute name="data-bs-toggle">
						<xsl:text>tooltip</xsl:text>
					</xsl:attribute>
					<xsl:attribute name="data-bs-placement">
						<xsl:text>left</xsl:text>
					</xsl:attribute>
					<xsl:attribute name="title">
						<xsl:value-of select="@type"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</p>
		</div>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:front">
		<div id="front" class="lead">
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:head">
		<h5>
			<xsl:apply-templates/>
		</h5>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:table">
		<table class="table table-borderless">
			<xsl:apply-templates/>
		</table>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:row" priority="9">
		<tr>
			<xsl:apply-templates/>
		</tr>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:list">
		<ul class="simple">
			<xsl:apply-templates/>
		</ul>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:item" priority="9">
		<li class="m-2">
			<xsl:apply-templates/>
		</li>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:foreign">
		<span>
			<xsl:if test="text()">
				<xsl:attribute name="title" select="text()"/>
			</xsl:if>
			<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
				class="bi bi-info-circle" viewBox="0 0 16 16">
				<path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14zm0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16z"/>
				<path
					d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 1.178-.252 1.465-.598l.088-.416c-.2.176-.492.246-.686.246-.275 0-.375-.193-.304-.533L8.93 6.588zM9 4.5a1 1 0 1 1-2 0 1 1 0 0 1 2 0z"
				/>
			</svg>
		</span>
		<xsl:text> </xsl:text>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:date" priority="8">
		<xsl:apply-templates/>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:cell" priority="9">
		<td>
			<xsl:if test="../@cols">
				<xsl:attribute name="colspan">
					<xsl:value-of select="../@cols"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="text()">
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:div" priority="8">

		<xsl:choose>
			<xsl:when test="descendant-or-self::*[tokenize(@ana, ' ') = 'bk:account']">
				<xsl:call-template name="get-account"/>
			</xsl:when>
			<xsl:otherwise>
				<div>
					<xsl:apply-templates/>
				</div>
			</xsl:otherwise>
		</xsl:choose>


	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:p" priority="9">
		<p>
			<xsl:apply-templates/>
		</p>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:pb">
		<div class="page text-center text-muted mt-5 mb-3" level="{@xml:id}" id="{@xml:id}">
			<span class="pageNumber">
				<xsl:call-template name="pageNumber">
					<xsl:with-param name="number" select="@n"/>
				</xsl:call-template>
			</span>
		</div>
	</xsl:template>

	<xsl:template name="pageNumber">
		<xsl:param name="number"/>
		<xsl:choose>
			<xsl:when test="starts-with($number, '0')">
				<xsl:variable name="saveNumber" select="substring-after($number, '0')"/>
				<xsl:call-template name="pageNumber">
					<xsl:with-param name="number" select="$saveNumber"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<b>
					<xsl:text>[</xsl:text>
					<xsl:value-of select="$number"/>
					<xsl:text>]</xsl:text>
				</b>
			</xsl:otherwise>
		</xsl:choose>
		<hr/>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:lb[@n]">
		<!-- Zeilennummern schreiben  -->
		<xsl:if test="not(@n = 'N001')">
			<br/>
		</xsl:if>
		<span class="bold">
			<xsl:value-of select="substring-after(@n, 'N0')"/>
			<xsl:text>: </xsl:text>
		</span>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="t:lb[not(@n)]">
		<br/>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:del">
		<del class="bg-warning" data-toggle="tooltip" title="deletion">
			<xsl:apply-templates/>
		</del>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:damage">
		<xsl:if test="text()">
			<span title="damage">
				<xsl:apply-templates/>
			</span>
		</xsl:if>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:supplied">
		<span>
			<xsl:attribute name="title">
				<xsl:choose>
					<xsl:when test="@reason">
						<xsl:value-of select="concat('supplied: ', @reason)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>supplied</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:text>[</xsl:text>
			<xsl:choose>
				<xsl:when test="text()">
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>]</xsl:text>
		</span>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:add">
		<span class="bg-success" data-toggle="tooltip" title="add">
			<xsl:apply-templates/>
		</span>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:subst">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:note">
		<xsl:apply-templates/>
		<!--<xsl:text> </xsl:text>
        <mark class="glyphicon glyphicon-star" data-toggle="tooltip" title="{normalize-space(.)}"><xsl:text> </xsl:text>
            <i class="fa fa-info" aria-hidden="true"><xsl:text> </xsl:text></i>
        </mark>-->
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:ex">
		<xsl:text>[</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>]</xsl:text>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<xsl:template match="t:choice">
		<abbr title="{t:expan}">
			<xsl:choose>
				<xsl:when test="t:abbr">
					<xsl:value-of select="t:abbr"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:comment>t:abbr missing in choice</xsl:comment>
				</xsl:otherwise>
			</xsl:choose>
		</abbr>
		<xsl:text> </xsl:text>
	</xsl:template>



	<!-- /////////////////////////////////////////////////////////////////////////////////////////////////// -->
	<!-- ELEMENTS WITH BOOKKEEPING ANNOTATIONS -->
	<!-- Mainly generation of tooltips for entity view with information on bookkeeping class and normalized data -->



	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Transactions - Processing bk:entries -->


	<xsl:template match="*[tokenize(@ana, ' ') = 'bk:entry']" priority="10">
		<xsl:choose>

			<xsl:when test="local-name() = 'row'">
				<tr vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Transaction">
					<xsl:attribute name="id">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
					<xsl:call-template name="get-booking"/>

					<xsl:apply-templates/>
				</tr>
			</xsl:when>

			<xsl:when test="local-name() = 'cell'">
				<td vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Transaction"
					data-title="bk:Transaction">
					<xsl:attribute name="id">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
					<xsl:call-template name="get-booking"/>
					<xsl:apply-templates/>
				</td>
			</xsl:when>

			<xsl:when test="local-name() = 'div' or local-name() = 'ab'">
				<p vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Transaction"
					data-title="bk:Transaction">
					<xsl:attribute name="id">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
					<xsl:call-template name="get-booking"/>
					<xsl:apply-templates/>
				</p>
			</xsl:when>


			<xsl:when test="local-name() = 'seg'">
				<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Transaction"
					data-title="bk:Transaction">
					<xsl:attribute name="id">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
					<xsl:call-template name="get-booking"/>
					<xsl:apply-templates/>
				</span>
			</xsl:when>

			<xsl:when test="local-name() = 'p'">
				<p vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Transaction"
					data-title="bk:Transaction">
					<xsl:attribute name="id">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
					<xsl:call-template name="get-booking"/>
					<xsl:apply-templates/>
				</p>
			</xsl:when>

			<xsl:when test="local-name() = 'item'">
				<li vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Transaction"
					data-title="bk:Transaction">
					<xsl:attribute name="id">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
					<xsl:call-template name="get-booking"/>
					<xsl:apply-templates/>
				</li>
			</xsl:when>
			
			<xsl:when test="local-name() = 'ab'">
				<p vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Transaction"
					data-title="bk:Transaction">
					<xsl:attribute name="id">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
					<xsl:call-template name="get-booking"/>
					<xsl:apply-templates/>
				</p>
			</xsl:when>

			<xsl:otherwise>
				<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Transaction"
					data-title="bk:Transaction">
					<xsl:attribute name="id">
						<xsl:value-of select="@xml:id"/>
					</xsl:attribute>
					<xsl:call-template name="get-booking"/>
					<xsl:apply-templates/>
				</span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--Specific Categorisation of Booking Details - processing Debit and Credit-->
	<xsl:template name="get-booking">
		<xsl:choose>
			<xsl:when test="descendant-or-self::*[tokenize(@ana, ' ') = 'bk:credit']">
				<xsl:attribute name="data-title" select="'bk:Transaction (Credit)'"/>
			</xsl:when>
			<xsl:when test="descendant-or-self::*[tokenize(@ana, ' ') = 'bk:debit']">
				<xsl:attribute name="data-title" select="'bk:Transaction (Debit)'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="data-title" select="'bk:Transaction'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Economic Goods - processing Commodities / Services / Rights -->
	<xsl:template
		match="*[tokenize(@ana, ' ') = 'bk:commodity'] | *[tokenize(@ana, ' ') = 'bk:service'] | *[tokenize(@ana, ' ') = 'bk:right']"
		priority="1">
		<xsl:variable name="UNIT_REF">
			<xsl:choose>
				<xsl:when test="@unitRef">
					<xsl:value-of select="
							if (contains(@unitRef, '#')) then
								(substring-after(@unitRef, '#'))
							else
								(@unitRef)"/>
				</xsl:when>
				<xsl:when test="@unit">
					<xsl:value-of select="
							if (contains(@unit, '#')) then
								(substring-after(@unit, '#'))
							else
								(@unit)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="UNIT_NAME"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:label[1]"> </xsl:variable>
		<xsl:variable name="UNIT" select="
				if (contains(@unit, '#')) then
					(substring-after(@unit, '#'))
				else
					(@unit)"/>
		<xsl:variable name="COMMODITY" select="
				if (contains(@commodity, '#')) then
					(substring-after(@commodity, '#'))
				else
					(@commodity)"/>
		<xsl:variable name="COMMODITY_TERM"
			select="$TAXONOMY//t:category[@xml:id = $COMMODITY]/*[self::t:catDesc/t:term or self::t:catDesc/t:gloss or self::t:catDesc]"/>
		<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#">
			<xsl:attribute name="typeof">
				<xsl:choose>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:commodity'">
						<xsl:text>Commodity</xsl:text>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:service'">
						<xsl:text>Service</xsl:text>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:right'">
						<xsl:text>Right</xsl:text>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="data-title">
				<xsl:choose>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:commodity'">
						<xsl:choose>
							<xsl:when test="@quantity or $UNIT_NAME or $UNIT or $COMMODITY">
								<xsl:text>bk:Commodity (</xsl:text>
								<xsl:choose>
									<xsl:when test="@quantity and $UNIT_NAME">
										<xsl:value-of select="@quantity, $UNIT_NAME"/>
									</xsl:when>
									<xsl:when test="@quantity and $UNIT_NAME and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of
												select="@quantity, $UNIT_NAME, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of
												select="@quantity, $UNIT_NAME, $COMMODITY"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="@quantity and $UNIT and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of
												select="@quantity, $UNIT, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="@quantity, $UNIT, $COMMODITY"
												/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="@quantity and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of select="@quantity, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="@quantity, $COMMODITY"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="$UNIT">
										<xsl:value-of select="$UNIT"/>
									</xsl:when>
								</xsl:choose>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>bk:Commodity</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>

					<xsl:when test="tokenize(@ana, ' ') = 'bk:service'">
						<xsl:choose>
							<xsl:when test="@quantity or $UNIT_NAME or $UNIT or $COMMODITY">
								<xsl:text>bk:Service (</xsl:text>
								<xsl:choose>
									<xsl:when test="@quantity and $UNIT_NAME">
										<xsl:value-of select="@quantity, $UNIT_NAME"/>
									</xsl:when>
									<xsl:when test="@quantity and $UNIT_NAME and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of
												select="@quantity, $UNIT_NAME, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of
												select="@quantity, $UNIT_NAME, $COMMODITY"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="@quantity and $UNIT and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of
												select="@quantity, $UNIT, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="@quantity, $UNIT, $COMMODITY"
												/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="@quantity and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of select="@quantity, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="@quantity, $COMMODITY"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="$UNIT">
										<xsl:value-of select="$UNIT"/>
									</xsl:when>
								</xsl:choose>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>bk:Service</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>

					<xsl:when test="tokenize(@ana, ' ') = 'bk:right'">
						<xsl:choose>
							<xsl:when test="@quantity or $UNIT_NAME or $UNIT or $COMMODITY">
								<xsl:text>bk:Right (</xsl:text>
								<xsl:choose>
									<xsl:when test="@quantity and $UNIT_NAME">
										<xsl:value-of select="@quantity, $UNIT_NAME"/>
									</xsl:when>
									<xsl:when test="@quantity and $UNIT_NAME and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of
												select="@quantity, $UNIT_NAME, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of
												select="@quantity, $UNIT_NAME, $COMMODITY"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="@quantity and $UNIT and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of
												select="@quantity, $UNIT, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="@quantity, $UNIT, $COMMODITY"
												/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="@quantity and $COMMODITY">
										<xsl:choose>
											<xsl:when test="$COMMODITY_TERM">
												<xsl:value-of select="@quantity, $COMMODITY_TERM"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="@quantity, $COMMODITY"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="$UNIT">
										<xsl:value-of select="$UNIT"/>
									</xsl:when>
								</xsl:choose>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>bk:Right</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
		</span>
	</xsl:template>

	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Specific Categorisation of Economic Goods - processing Individuals / Groups / Organisations -->
	<xsl:template
		match="*[tokenize(@ana, ' ') = 'bk:individual'] | *[tokenize(@ana, ' ') = 'bk:group'] | *[tokenize(@ana, ' ') = 'bk:organisation'] | *[tokenize(@ana, ' ') = 'bk:to'] | *[tokenize(@ana, ' ') = 'bk:from']"
		priority="1">
		<xsl:variable name="PERS_REF" select="
				if (contains(@ref, '#')) then
					(substring-after(@ref, '#'))
				else
					(@ref)"/>
		<xsl:variable name="PERSON"
			select="$LIST_PERSON/t:person[@xml:id = $PERS_REF]/*[self::t:persName or self::t:name][1]"/>
		<xsl:variable name="FORENAME" select="$PERSON/t:forename"/>
		<xsl:variable name="SURNAME" select="$PERSON/t:surname"/>

		<xsl:variable name="ORG_REF" select="
				if (contains(@ref, '#')) then
					(substring-after(@ref, '#'))
				else
					(@ref)"/>
		<xsl:variable name="ORGANISATION" select="$LIST_ORG/t:org[@xml:id = $ORG_REF]/t:orgName"/>

		<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#">
			<xsl:attribute name="typeof">
				<xsl:choose>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:individual'">
						<xsl:text>Individual</xsl:text>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:group'">
						<xsl:text>Group</xsl:text>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:organisation'">
						<xsl:text>Organisation</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>EconomicAgent</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="data-title">
				<xsl:choose>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:individual'">
						<xsl:text>bk:Individual</xsl:text>
						<xsl:if test="$PERSON">
							<xsl:text> (</xsl:text>
							<xsl:value-of select="$FORENAME, $SURNAME"/>
							<xsl:text>)</xsl:text>
						</xsl:if>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:group'">
						<xsl:text>bk:Group</xsl:text>
						<xsl:choose>
							<xsl:when test="$ORGANISATION">
								<xsl:text> (</xsl:text>
								<xsl:value-of select="$ORGANISATION"/>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:when test="$PERSON">
								<xsl:text> (</xsl:text>
								<xsl:value-of select="$FORENAME, $SURNAME"/>
								<xsl:text>)</xsl:text>
							</xsl:when>

						</xsl:choose>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:organisation'">
						<xsl:text>bk:Organisation</xsl:text>
						<xsl:if test="$ORGANISATION">
							<xsl:text> (</xsl:text>
							<xsl:value-of select="$ORGANISATION"/>
							<xsl:text>)</xsl:text>
						</xsl:if>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:to'">
						<xsl:text>bk:EconomicAgent - To</xsl:text>
						<xsl:choose>
							<xsl:when test="$PERSON">
								<xsl:text> (</xsl:text>
								<xsl:value-of select="$FORENAME, $SURNAME"/>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:when test="$ORGANISATION">
								<xsl:text> (</xsl:text>
								<xsl:value-of select="$ORGANISATION"/>
								<xsl:text>)</xsl:text>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:from'">
						<xsl:text>bk:EconomicAgent - From</xsl:text>
						<xsl:choose>
							<xsl:when test="$PERSON">
								<xsl:text> (</xsl:text>
								<xsl:value-of select="$FORENAME, $SURNAME"/>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:when test="$ORGANISATION">
								<xsl:text> (</xsl:text>
								<xsl:value-of select="$ORGANISATION"/>
								<xsl:text>)</xsl:text>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
		</span>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Currencies - processing Monetary Values -->
	<xsl:template match="*[tokenize(@ana, ' ') = 'bk:money'] | *[tokenize(@ana, ' ') = 'bk:tax']"
		priority="2">
		<xsl:variable name="UNIT_REF" select="
				if (contains(@unitRef, '#')) then
					(substring-after(@unitRef, '#'))
				else
					(@unitRef)"/>
		<xsl:variable name="UNIT_NAME"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:label[not(@type = 'abbr')]"/>
		<xsl:variable name="UNIT_LABEL"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:label[1][not(@type = 'abbr')]"/>
		<xsl:variable name="UNIT_IN_UNITDECL"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:unit"/>
		<xsl:variable name="UNIT_ABBR"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:label[(@type = 'abbr')]"/>
		<xsl:variable name="UNIT" select="
				if (contains(@unit, '#')) then
					(substring-after(@unit, '#'))
				else
					(@unit)"/>
		<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#">
			<xsl:attribute name="typeof">
				<xsl:choose>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:money'">
						<xsl:text>Monetary Value</xsl:text>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:tax'">
						<xsl:text>Tax</xsl:text>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="data-title">
				<xsl:choose>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:money'">
						<xsl:choose>
							<xsl:when test="@quantity | $UNIT_NAME | $UNIT">
								<xsl:text>bk:Monetary Value (</xsl:text>
								<xsl:choose>
									<xsl:when test="@quantity and $UNIT_NAME">
										<xsl:value-of select="@quantity, $UNIT_NAME"/>
									</xsl:when>
									<xsl:when test="$UNIT_NAME">
										<xsl:value-of select="$UNIT_NAME"/>
									</xsl:when>
									<xsl:when test="@quantity and $UNIT">
										<xsl:value-of select="@quantity, $UNIT"/>
									</xsl:when>
									<xsl:when test="$UNIT">
										<xsl:value-of select="$UNIT"/>
									</xsl:when>
								</xsl:choose>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>bk:Monetary Value</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="tokenize(@ana, ' ') = 'bk:tax'">
						<xsl:choose>
							<xsl:when test="@quantity | $UNIT_NAME | $UNIT">
								<xsl:text>bk:Tax (</xsl:text>
								<xsl:choose>
									<xsl:when test="@quantity and $UNIT_NAME">
										<xsl:value-of select="@quantity, $UNIT_NAME"/>
									</xsl:when>
									<xsl:when test="$UNIT_NAME">
										<xsl:value-of select="$UNIT_NAME"/>
									</xsl:when>
									<xsl:when test="@quantity and $UNIT">
										<xsl:value-of select="@quantity, $UNIT"/>
									</xsl:when>
									<xsl:when test="$UNIT">
										<xsl:value-of select="$UNIT"/>
									</xsl:when>
								</xsl:choose>
								<xsl:text>)</xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>bk:Tax</xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
			<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Monetary Unit"
				id="currency">
				<xsl:choose>
					<xsl:when test="$UNIT_REF">
						<xsl:choose>
							<xsl:when test="$UNIT_IN_UNITDECL">
								<xsl:value-of select="$UNIT_IN_UNITDECL"/>
							</xsl:when>
							<xsl:when test="$UNIT_ABBR">
								<xsl:value-of select="$UNIT_ABBR"/>
							</xsl:when>
							<xsl:when test="$UNIT_LABEL">
								<xsl:value-of select="substring($UNIT_LABEL, 1, 1)"/>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$UNIT">
						<xsl:value-of select="substring($UNIT, 1, 1)"/>
					</xsl:when>
				</xsl:choose>
			</span>
		</span>

	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Totals and Subtotals - processing bk:total and bk:subtotal -->
	<xsl:template match="*[tokenize(@ana, ' ') = 'bk:subtotal']">
		<xsl:choose>
			<xsl:when test="local-name() = 'row'">
				<tr vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Subtotal Transaction" data-title="bk:Subtotal">
					<xsl:apply-templates/>
				</tr>
			</xsl:when>
			<xsl:when test="local-name() = 'div' or local-name() = 'seg' or local-name() = 'ab'">
				<div vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Subtotal Transaction" data-title="bk:Subtotal">
					<xsl:apply-templates/>
				</div>
			</xsl:when>
			<xsl:when test="local-name() = 'p'">
				<p vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Subtotal Transaction" data-title="bk:Subtotal">
					<xsl:apply-templates/>
				</p>
			</xsl:when>
			<xsl:when test="local-name() = 'item'">
				<li vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Subtotal Transaction" data-title="bk:Subtotal">
					<xsl:apply-templates/>
				</li>
			</xsl:when>
			<xsl:when test="local-name() = 'cell'">
				<td vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Subtotal Transaction" data-title="bk:Subtotal">
					<xsl:apply-templates/>
				</td>
			</xsl:when>
			<xsl:otherwise>
				<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Subtotal Transaction" data-title="bk:Subtotal">
					<xsl:apply-templates/>
				</span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*[tokenize(@ana, ' ') = 'bk:total']">
		<xsl:choose>
			<xsl:when test="local-name() = 'row'">
				<tr vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Total Transaction" data-title="bk:Total">
					<xsl:apply-templates/>
				</tr>
			</xsl:when>
			<xsl:when test="local-name() = 'div' or local-name() = 'seg' or local-name() = 'ab'">
				<div vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Total Transaction" data-title="bk:Total">
					<xsl:apply-templates/>
				</div>
			</xsl:when>
			<xsl:when test="local-name() = 'p'">
				<p vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Total Transaction"
					data-title="bk:Total">
					<xsl:apply-templates/>
				</p>
			</xsl:when>
			<xsl:when test="local-name() = 'item'">
				<li vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Total Transaction" data-title="bk:Total">
					<xsl:apply-templates/>
				</li>
			</xsl:when>
			<xsl:when test="local-name() = 'cell'">
				<td vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Total Transaction" data-title="bk:Total">
					<xsl:apply-templates/>
				</td>
			</xsl:when>
			<xsl:when test="local-name() = 'ab'">
				<div vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Total Transaction" data-title="bk:Total">
					<xsl:apply-templates/>
				</div>
			</xsl:when>
			<xsl:otherwise>
				<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#"
					typeof="Total Transaction" data-title="bk:Total">
					<xsl:apply-templates/>
				</span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Prices of economic assets - processing bk:price -->
	<xsl:template match="*[tokenize(@ana, ' ') = 'bk:price']">
		<xsl:variable name="UNIT_REF" select="
				if (contains(@unitRef, '#')) then
					(substring-after(@unitRef, '#'))
				else
					(@unitRef)"/>
		<xsl:variable name="UNIT_NAME"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:label[not(@type = 'abbr')]"/>
		<xsl:variable name="UNIT_LABEL"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:label[1][not(@type = 'abbr')]"/>
		<xsl:variable name="UNIT_IN_UNITDECL"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:unit"/>
		<xsl:variable name="UNIT_ABBR"
			select="$teiHeader/t:encodingDesc/t:unitDecl/t:unitDef[@xml:id = $UNIT_REF]/t:label[(@type = 'abbr')]"/>
		<xsl:variable name="UNIT" select="
				if (contains(@unit, '#')) then
					(substring-after(@unit, '#'))
				else
					(@unit)"/>

		<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Price">
			<xsl:attribute name="data-title">
				<xsl:choose>
					<xsl:when test="@quantity | $UNIT_NAME | $UNIT">
						<xsl:text>bk:Price (</xsl:text>
						<xsl:choose>
							<xsl:when test="@quantity and $UNIT_NAME">
								<xsl:value-of select="@quantity, $UNIT_NAME"/>
							</xsl:when>
							<xsl:when test="$UNIT_NAME">
								<xsl:value-of select="$UNIT_NAME"/>
							</xsl:when>
							<xsl:when test="@quantity and $UNIT">
								<xsl:value-of select="@quantity, $UNIT"/>
							</xsl:when>
							<xsl:when test="$UNIT">
								<xsl:value-of select="$UNIT"/>
							</xsl:when>
						</xsl:choose>
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>bk:Price</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
			<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Monetary Unit"
				id="currency">
				<xsl:choose>
					<xsl:when test="$UNIT_REF">
						<xsl:choose>
							<xsl:when test="$UNIT_IN_UNITDECL">
								<xsl:value-of select="$UNIT_IN_UNITDECL"/>
							</xsl:when>
							<xsl:when test="$UNIT_ABBR">
								<xsl:value-of select="$UNIT_ABBR"/>
							</xsl:when>
							<xsl:when test="$UNIT_LABEL">
								<xsl:value-of select="substring($UNIT_LABEL, 1, 1)"/>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$UNIT">
						<xsl:value-of select="substring($UNIT, 1, 1)"/>
					</xsl:when>
				</xsl:choose>
			</span>
		</span>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Status of Transaction - processing bk:status -->
	<xsl:template match="*[@ana = 'bk:status']">
		<xsl:choose>
			<xsl:when test="local-name() = 'cell'">
				<td title="bk:Status (of the transaction)">
					<xsl:apply-templates/>
				</td>
			</xsl:when>
			<xsl:otherwise>
				<span title="bk:Status (of the transaction)">
					<xsl:apply-templates/>
				</span>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Date of Transaction - processing bk:when -->
	<xsl:template match="*[tokenize(@ana, ' ') = 'bk:when']" priority="9">
		<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Date">
			<xsl:attribute name="data-title">
				<xsl:choose>
					<xsl:when test="@when">
						<xsl:text>bk:Date (</xsl:text>
						<xsl:value-of select="@when"/>
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:when test="@from and @to">
						<xsl:text>bk:Date (</xsl:text>
						<xsl:value-of select="@from"/>
						<xsl:text> – </xsl:text>
						<xsl:value-of select="@to"/>
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>bk:Date</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
		</span>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Place of Transaction - processing bk:where -->
	<xsl:template match="*[tokenize(@ana, ' ') = 'bk:where']">
		<xsl:variable name="PLACE_REF" select="
				if (contains(@ref, '#')) then
					(substring-after(@ref, '#'))
				else
					(@ref)"/>
		<xsl:variable name="PLACE" select="$LIST_PLACE/t:place[@xml:id = $PLACE_REF]/t:placeName"/>
		<span vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Place">
			<xsl:attribute name="data-title">
				<xsl:choose>
					<xsl:when test="$PLACE_REF">
						<xsl:text>bk:Place (</xsl:text>
						<xsl:choose>
							<xsl:when test="$PLACE">
								<xsl:value-of select="$PLACE"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="
										if (contains(@ref, '#')) then
											(substring-after(@ref, '#'))
										else
											(@ref)"/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>bk:Place</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates/>
		</span>
	</xsl:template>


	<!-- //////////////////////////////////////////////////////////// -->
	<!-- Accounts - processing bk:account -->
	<xsl:template name="get-account">
		<xsl:variable name="ACCOUNT_REF" select="
				if (contains(@corresp, '#')) then
					(substring-after(@corresp, '#'))
				else
					(@corresp)"/>
		<xsl:variable name="ACCOUNT"
			select="$LIST_ACCOUNTS/t:category[@xml:id = $ACCOUNT_REF]/*[self::t:catDesc/t:term or self::t:catDesc/t:gloss or self::t:catDesc or self::t:gloss]"/>
		<xsl:variable name="SUB_ACCOUNT"
			select="$LIST_ACCOUNTS//t:category[@xml:id = $ACCOUNT_REF]/*[self::t:catDesc/t:term or self::t:catDesc/t:gloss or self::t:catDesc or self::t:gloss]"/>

		<div vocab="https://gams.uni-graz.at/o:depcha.bookkeeping#" typeof="Account">
			<xsl:attribute name="data-title">
				<xsl:text>bk:Account</xsl:text>
				<xsl:choose>
					<xsl:when test="$ACCOUNT">
						<xsl:text>(</xsl:text>
						<xsl:value-of select="$ACCOUNT"/>
						<xsl:text>)</xsl:text>
					</xsl:when>
					<xsl:when test="$SUB_ACCOUNT">
						<xsl:text>(</xsl:text>
						<xsl:value-of select="$SUB_ACCOUNT"/>
						<xsl:text>)</xsl:text>

					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="data-subtitle">
				<xsl:choose>
					<xsl:when test="$ACCOUNT">
						<xsl:value-of select="$ACCOUNT"/>
					</xsl:when>
					<xsl:when test="$SUB_ACCOUNT">
						<xsl:value-of select="$SUB_ACCOUNT"/>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
				class="bi bi-book account-book mb-2" viewBox="0 0 16 16">
				<path
					d="M1 2.828c.885-.37 2.154-.769 3.388-.893 1.33-.134 2.458.063 3.112.752v9.746c-.935-.53-2.12-.603-3.213-.493-1.18.12-2.37.461-3.287.811V2.828zm7.5-.141c.654-.689 1.782-.886 3.112-.752 1.234.124 2.503.523 3.388.893v9.923c-.918-.35-2.107-.692-3.287-.81-1.094-.111-2.278-.039-3.213.492V2.687zM8 1.783C7.015.936 5.587.81 4.287.94c-1.514.153-3.042.672-3.994 1.105A.5.5 0 0 0 0 2.5v11a.5.5 0 0 0 .707.455c.882-.4 2.303-.881 3.68-1.02 1.409-.142 2.59.087 3.223.877a.5.5 0 0 0 .78 0c.633-.79 1.814-1.019 3.222-.877 1.378.139 2.8.62 3.681 1.02A.5.5 0 0 0 16 13.5v-11a.5.5 0 0 0-.293-.455c-.952-.433-2.48-.952-3.994-1.105C10.413.809 8.985.936 8 1.783z"
				/>
			</svg>
			<xsl:apply-templates/>
		</div>

	</xsl:template>



	<!-- /////////////////////////////////////// -->
	<!-- From multiple variants choose English or first elements -->
	<xsl:template name="printENorFirst">
		<xsl:param name="path"/>
		<xsl:choose>
			<xsl:when test="$path[@xml:lang = 'en']">
				<xsl:value-of select="$path[@xml:lang = 'en']"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$path[1]"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>



</xsl:stylesheet>
