<?xml version="1.0" encoding="UTF-8"?>

<!-- 
    Project: depcha
    Company: ZIM-ACDH (Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities)
    Author: Christopher Pollin
    Last update: 2022
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
	<xsl:variable name="SEARCH_PARAM_URI">
		<xsl:value-of
			select="substring-after($FIRST_RESULT/s:query/@uri, 'https://gams.uni-graz.at/')"/>
	</xsl:variable>
	<xsl:variable name="COUNT_TRANSACTIONS" select="count(distinct-values($RESULTS/s:t/@uri))"/>

	<xsl:template name="content">

		<!-- ///////////////////////////////////////////////////// -->
		<!-- dashboard header -->
		<div class="m-2">
			<div class="py-3 bg-light">
				<div class="container">
					<h2>
						<xsl:text>Search Result</xsl:text>
					</h2>
					<p class="lead">
						<xsl:text>The search</xsl:text>
						<xsl:if test="$FIRST_RESULT/s:query_label">
							<xsl:text> for </xsl:text>
							<span class="fw-bold">
								<xsl:value-of select="$FIRST_RESULT/s:query_label"/>
							</span>
						</xsl:if>
						<xsl:text> returned </xsl:text>
						<span class="fw-bold">
							<xsl:value-of select="concat($COUNT_TRANSACTIONS, ' transaction', if ($COUNT_TRANSACTIONS != 1) then 's.' else '.')"/>
						</span>
					</p>
				</div>
			</div>

			<!-- ///////////////////////////////////////////////////// -->
			<!-- builds the navigation between search head and body -->
			<div class="my-3">
				<ul class="nav justify-content-md-center">
					<!-- Transaction -->
					<li class="nav-item">
						<a class="btn btn-outline-dark active" role="tab" id="transaction-tab"
						data-bs-toggle="tab" data-bs-target="#transaction"
						aria-controls="transaction" aria-selected="true">
						Transactions</a>
					</li>
					<li class="nav-item">
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
					</li>
				</ul>
			</div>

			<!-- ///////////////////////////////////////////////////// -->
			<!-- search body -->
			<div>
				<xsl:choose>
					<!-- RESULTS FOR DASHBOARD -->
					<xsl:when test="$FIRST_RESULT">
						<div class="container">
							<!-- ////////////////////////// -->
							<div class="tab-content">
								<!-- transaction-tab -->
								<div role="tabpanel" id="transaction" class="tab-pane fade show active"
									aria-labelledby="transaction-tab">
									<xsl:attribute name="class" select="
										if (//t:body) then
										'tab-pane fade'
										else
										'tab-pane fade show active'"/>
									<div class="row">
										<div class="col-12">
											<div class="card" id="transaction-content">
												<div class="card-header">
													<h5 class="card-title col-11"> Transactions <span
														class="badge rounded-pill bg-dark">
														<xsl:value-of select="$COUNT_TRANSACTIONS"/>
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
														<table class="table" id="data_table" style="width:100%">
															<!-- is build in depcha-datatable.js -->
															<xsl:text> </xsl:text>
														</table>
													</div>
												</div>
												<script>
													//das ist nicht schön, aber wie bekomme ich den query-pid ins XML/JS?
													let qpid;
													if(window.location.href.indexOf('query:depcha.search.economicgoods') != -1)
													  {qpid = 'query:depcha.search.economicgoods'}
													else if (window.location.href.indexOf('query:depcha.search.economicagents') != -1)
													  {qpid = 'query:depcha.search.economicagents'}
													else if (window.location.href.indexOf('query:depcha.search.units') != -1)
													  {qpid = 'query:depcha.search.units'}
												    else if (window.location.href.indexOf('query:depcha.search.places') != -1)
												    {qpid = 'query:depcha.search.places'};
													//console.log('qpid: ' + qpid);
													get_datatable(qpid, <xsl:value-of select="concat('&quot;', $SEARCH_PARAM_URI, '&quot;')"/>);
												</script>
												
											</div>
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

		</div>
	</xsl:template>

</xsl:stylesheet>
