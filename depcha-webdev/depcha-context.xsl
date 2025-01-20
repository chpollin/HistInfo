<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    Project: depcha
    Company: ZIM-ACDH (Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities)
    Author: Christopher Pollin, Jakob Sonnberger
    Last update: 2024
 -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
	xmlns:s="http://www.w3.org/2001/sw/DataAccess/rf1/result" xmlns="http://www.w3.org/1999/xhtml"
	xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:dc="http://purl.org/dc/elements/1.1/" exclude-result-prefixes="#all">

	<xsl:include href="depcha-static.xsl"/>


	<!-- ///////////////////// -->
	<!-- CONTENT -->
	<xsl:template name="content">
		<xsl:choose>
			<xsl:when test="$mode = 'project'">
				<xsl:apply-templates
					select="document('/archive/objects/context:depcha/datastreams/PROJECT/content')//t:body"
					mode="cd"/>
			</xsl:when>
			<xsl:when test="$mode = 'db'">
				<xsl:call-template name="db"/>
			</xsl:when>
			<xsl:when test="$mode = 'collections'">
				<xsl:call-template name="collections"/>
			</xsl:when>
			<xsl:when test="$mode = 'imprint'">
				<xsl:apply-templates
					select="document('/archive/objects/context:depcha/datastreams/IMPRINT/content')//t:body"
					mode="cd"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="home"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ///////////////////// -->
	<!-- project -->
	<xsl:template name="project">
		<div class="py-3 bg-light">
			<div class="container">
				<div class="row">
					<div class="col-12">
						<h3>Project</h3>
						<h4>Digital Edition Publishing Cooperative for Historical Accounts</h4>
						<p>...</p>
					</div>
				</div>
				<hr/>
			</div>
			<div class="container">
				<div class="row row-cols-1 row-cols-sm-1 row-cols-md-1">
					<p>Lorem Ipsum</p>
				</div>
			</div>
		</div>
	</xsl:template>

	<!-- ///////////////////// -->
	<!-- databasket -->
	<xsl:template name="db">
		<div class="container">
			<div class="card my-4">
				<div class="card-body">
					<div class="row">
						<div class="col-12">
							<h3>Databasket</h3>
						</div>
					</div>
					<!--					<div class="row my-2">
						<div class="col-12">
							<button type="button" class="btn btn-dark float-end" onclick="clear_DB()">Clear Basket  <i class="bi bi-trash"><xsl:text>  </xsl:text></i></button>
						</div>
					</div>-->
					<table id="db_table" class="table small dataTable no-footer">
						<thead>
							<tr>
								<th>Transaction</th>
								<th>Date</th>
								<th>Entry</th>
								<th>From</th>
								<th>To</th>
								<th>Measure</th>
								<th>Good</th>
								<th><!-- delete icon --></th>
							</tr>
						</thead>
						<tbody>
							<xsl:text>  </xsl:text>
						</tbody>
					</table>
				</div>
			</div>
		</div>
		<script type="text/javascript">
            show_DB();
            $("#db_table").DataTable({
                'aaSorting':[],
                columnDefs:[ {
                    'orderable': false, targets: 7
                }, {
                    type: 'natural-nohtml', targets: 0
                }],
                dom: 'Bftip',
                buttons:[ {
                    extend: 'csv',
                    text: 'CSV Export',
                    filename: 'depcha_databasket',
                    exportOptions: {
                        columns:[0, 1, 2, 3, 4, 5, 6]
                    }
                }, {
                    text: 'Clear Basket',
                    action: function () {
                        clear_DB();
                    }
                }]
            });</script>
	</xsl:template>

	<!-- ///////////////////// -->
	<!-- COLLECTIONS -->
	<xsl:template name="collections">

		<!-- date -->
		<xsl:variable name="DATES">
			<xsl:for-each-group select="//s:result" group-by="s:pid/@uri">
				<xsl:choose>
					<xsl:when test="contains(s:date, '-')">
						<xsl:element name="date">
							<xsl:value-of select="substring-before(s:date, '-')"/>
						</xsl:element>
						<xsl:element name="date">
							<xsl:value-of select="substring-after(s:date, '-')"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="s:date"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each-group>
		</xsl:variable>
		<xsl:variable name="MAX_DATE" select="max($DATES/*:date)"/>
		<xsl:variable name="MIN_DATE" select="min($DATES/*:date)"/>

		<!-- collections -->
		<div class="py-3 bg-light">
			<div class="container">
				<div class="row row-cols-md-2 row-cols-sm-1">
					<div class="col-md-4">
						<h3>Collections</h3>
						<p>The following <span class="fw-bold" id="total-projects"><xsl:value-of
									select="count(distinct-values(//s:result/s:pid/@uri))"/>
								projects</span> are published in DEPCHA.</p>
					</div>
					<!-- filter -->
					<div class="col-md-8">
						<div class="card">
							<div class="card-body">
								<div class="input-filter input-group">
									<input type="text" class="filter form-control"
										name="collections-filter" id="collections-filter"
										placeholder="Filter Collections"
										onkeyup="searchCollection()">
										<xsl:text> </xsl:text>
									</input>
								</div>
								<div class="input-group d-flex justify-content-center mt-1">
									<xsl:for-each select="distinct-values(//s:subject[text()])">
										<div class="form-check form-check-inline">
											<input class="form-check-input subjectCheckbox"
												type="checkbox" name="inlineRadioOptions" id="{.}"
												value="{.}" checked="checked"
												onchange="searchCollection()"/>
											<label class="form-check-label" for="{.}">
												<xsl:value-of select="."/>
											</label>
										</div>
									</xsl:for-each>
								</div>
								<div id="timeSlider" class="m-3">
									<xsl:text> </xsl:text>
								</div>
								<div class="text-center">
									<button type="button" class="btn btn-outline-dark"
										onclick="resetFilters()">Reset</button>
								</div>
							</div>
						</div>
					</div>
				</div>
				<hr/>
			</div>
			<!-- collections cards -->
			<div class="container">
				<div class="row row-cols-sm-1 row-cols-md-3 g-3" id="card-list">
					<xsl:for-each-group select="//s:result" group-by="s:pid/@uri">
						<xsl:sort select="s:title" data-type="text"/>

						<!-- ///////////////////////// -->
						<!-- VARIABLES -->
						<xsl:variable name="PID"
							select="substring-after(current-grouping-key(), 'info:fedora/')"/>

						<xsl:variable name="QUERY_PARAM"
							select="encode-for-uri(concat('$1%7C&lt;', $BASE_URL, $PID, '&gt;'))"/>

						<!-- card created from /context:depcha/METADATA  -->
						<div class="col collectionCard">
							<!-- data-date="{s:date}"-->
							<xsl:attribute name="data-from">
								<xsl:choose>
									<xsl:when test="contains(s:date, '-')">
										<xsl:value-of select="substring-before(s:date, '-')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="s:date"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:attribute name="data-to">
								<xsl:choose>
									<xsl:when test="contains(s:date, '-')">
										<xsl:value-of select="substring-after(s:date, '-')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="s:date"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:attribute name="data-subject">
								<xsl:for-each
									select="distinct-values(current-group()/s:subject[text()])">
									<xsl:value-of select="."/>
									<xsl:if test="position() != last()">
										<xsl:text>, </xsl:text>
									</xsl:if>
								</xsl:for-each>
							</xsl:attribute>
							<div class="card h-100">
								<div class="card-body d-grid">
									<xsl:attribute name="id">
										<xsl:value-of select="s:identifier"/>
									</xsl:attribute>

									<!-- Title -->
									<div>
										<xsl:if test="s:title">
											<h5 class="fw-bold">
												<xsl:value-of select="s:title"/>
											</h5>
										</xsl:if>
										<hr/>

										<dl class="row">
											<!-- Scope information -->
											<xsl:if
												test="s:date[not(@bound = 'false')] or s:coverage[not(@bound = 'false')] or s:language[not(@bound = 'false')]">
												<dt class="col-sm-3 text-muted">Scope</dt>
												<dd class="col-sm-9">
												<xsl:if test="s:date/text()">
												<xsl:value-of select="s:date"/>
												<br/>
												</xsl:if>
												<xsl:if test="s:coverage/text()">
												<xsl:value-of select="s:coverage"/>
												<br/>
												</xsl:if>
												<xsl:choose>
												<xsl:when test="s:language/text()">
												<xsl:call-template name="langeCodeToText">
												<xsl:with-param name="code" select="s:language"/>
												</xsl:call-template>
												</xsl:when>
												<xsl:otherwise>
												<xsl:text> </xsl:text>
												</xsl:otherwise>

												</xsl:choose>
												</dd>
											</xsl:if>

											<!-- Source information -->
											<xsl:if test="s:source[not(@bound = 'false')]">
												<dt class="col-sm-3 text-muted">Source</dt>
												<dd class="col-sm-9">
												<xsl:choose>
												<xsl:when
												test="starts-with(s:source, 'http') or starts-with(s:source, 'www')">
												<a target="_blank">
												<xsl:attribute name="href">
												<xsl:value-of select="s:source"/>
												</xsl:attribute>
												<xsl:value-of select="s:source"/>
												</a>
												</xsl:when>
												<xsl:otherwise>
												<xsl:value-of select="s:source"/>
												</xsl:otherwise>
												</xsl:choose>
												</dd>
											</xsl:if>

											<!-- Information about editors and contributors -->
											<xsl:if test="s:contributor[not(@bound = 'false')]">
												<dt class="col-sm-3 text-muted">Editor</dt>
												<dd class="col-sm-9">
												<xsl:for-each-group
												select="current-group()/s:contributor"
												group-by=".">
												<xsl:value-of select="."/>
												<xsl:value-of select="
																if (not(position() = last())) then
																	' / '
																else
																	''"/>
												</xsl:for-each-group>
												</dd>
											</xsl:if>

											<!-- dc:subject-->
											<xsl:if test="current-group()/s:subject[text() != '']">
												<dt class="col-sm-3 text-muted">Subject</dt>
												<dd class="col-sm-9">
												<xsl:for-each
												select="distinct-values(current-group()/s:subject[text()])">
												<xsl:value-of select="."/>
												<xsl:if test="position() != last()">
												<xsl:text> / </xsl:text>
												</xsl:if>
												</xsl:for-each>
												</dd>
											</xsl:if>

											<!-- dc:description-->
											<xsl:if
												test="current-group()/s:description[text() != '']">
												<dt class="col-sm-3 text-muted">Description</dt>
												<dd class="col-sm-9">

												<div class="accordion accordion-flush"
												id="{concat('a', s:description/generate-id())}">
												<div class="accordion-item">
												<button
												class="accordion-button short-desc collapsed"
												type="button" data-bs-toggle="collapse"
												data-bs-target="{concat('#c', s:description/generate-id())}"
												aria-expanded="false"
												aria-controls="{concat('c', s:description/generate-id())}"
												onclick="toggle_teaser({concat('t', s:description/generate-id())})">
												<div
												id="{concat('t', s:description/generate-id())}"
												style="display:block;">
												<span class="text-ellipsis">
												<xsl:value-of select="s:description"/>
												</span>
												</div>
												</button>


												<div
												id="{concat('c', s:description/generate-id())}"
												class="accordion-collapse collapse"
												aria-labelledby="{concat('h', s:description/generate-id())}"
												data-bs-parent="{concat('#a', s:description/generate-id())}">
												<div class="accordion-body full-desc">
												<p>
												<xsl:value-of select="s:description"/>
												</p>
												<img src="{concat('/', $PID, '/IMG.1')}"
												class="img-fluid my-3" alt="Thumbnail"/>
												</div>
												</div>
												</div>
												</div>
												</dd>
											</xsl:if>

										</dl>
									</div>
									<!-- called in depcha-static.xsl -->
									<xsl:call-template name="create_pid_date_in_collection_card"/>
								</div>
								<!-- card footer -->
								<div class="card-footer">
									<div class="btn-group d-flex justify-content-center">
										<!-- /archive/objects/query:depcha.dashboard/methods/sdef:Query/get?params=$1|<https://gams.uni-graz.at/context:depcha.burgos> -->
										<a
											href="{concat('/archive/objects/query:depcha.dashboard/methods/sdef:Query/get?params=', $QUERY_PARAM)}"
											class="btn btn-outline-dark"
											title="Display of all transactions in a dashboard">
											<xsl:text>Dashboard</xsl:text>

										</a>
										<a
											href="{substring-after(current-grouping-key(), 'info:fedora')}"
											class="btn btn-outline-dark"
											title="Display of all documents of a collection">
											<xsl:text>Collection</xsl:text>
										</a>
									</div>
								</div>
							</div>
						</div>
					</xsl:for-each-group>
				</div>
			</div>
			<script type="text/javascript" src="{concat($projectRootPath, 'js/depcha-collections.js')}"><xsl:text>//  </xsl:text>
			</script>
		</div>

		<!--<script type="text/javascript">get_totals()</script>-->



	</xsl:template>

	<!-- HOMEPAGE -->
	<xsl:template name="home">

		<xsl:variable name="HOME" select="document('/context:depcha/HOME')"/>
		<xsl:variable name="COLLECTIONS" select="document('/context:depcha/METADATA')"/>
		<div class="bg-light">
			<div class="container">
				<div class="position-relative overflow-hidden text-center">
					<div class="col-md-5 p-lg-5 mx-auto my-3">
						<h1 class="display-4 fw-normal">
							<xsl:text>DEPCHA</xsl:text>
						</h1>
						<p class="lead">Digital Edition Publishing Cooperative for Historical
							Accounts</p>
					</div>
				</div>
			</div>
		</div>
		<div class="container">
			<div class="row my-3">
				<div class="col-md-6 col-sm-12 px-5">
					<h2 class="text-center">
						<a class="link-dark"
							href="/archive/objects/context:depcha/methods/sdef:Context/get?mode=collections"
							>Collections</a>
					</h2>
					<div class="text-center">
						<!-- Gallery -->
						<div class="gallery-block compact-gallery row" id="collections-gallery">
							<!-- CP: 02.01.2024 -->
							<!--<xsl:for-each-group select="$COLLECTIONS//s:result"
								group-by="s:pid/@uri">
								<xsl:variable name="CONTEXT"
									select="substring-after(current-grouping-key(), 'info:fedora')"/>
								<div class="col-4 wrapper">
									<div class="item zoom-on-hover projects">
										<img
											class="img-fluid image w-75 shadow rounded mb-2 w-sm-25"
											alt="{s:title}">
											<xsl:attribute name="src"
												select="concat($CONTEXT, '/IMG.1')"/>
											<xsl:if test="not(position() &lt; 7)">
												<xsl:attribute name="class"
												select="'img-fluid image w-75 shadow rounded mb-2 collapse multi-collapse'"/>
												<xsl:attribute name="id"
												select="concat('multiCollapseExample', position())"
												/>
											</xsl:if>
										</img>
										<div class="description">
											<span class="description-heading" title="{s:title}">
												<a class="btn btn-outline-dark" href="{$CONTEXT}"
												target="_blank">
												<xsl:value-of select="s:title"/>
												</a>
											</span>
										</div>

									</div>
								</div>
							</xsl:for-each-group>-->
							<button class="btn btn-outline-dark" type="button"
								data-bs-toggle="collapse" data-bs-target=".multi-collapse"
								aria-expanded="false">Show More</button>
						</div>

					</div>
				</div>
				<div class="col-md-6 col-sm-12 px-5">
					<h2 class="text-center">
						<a class="link-dark"
							href="/archive/objects/context:depcha/methods/sdef:Context/get?mode=project"
							>Project</a>
					</h2>
					<xsl:apply-templates select="$HOME//t:body/t:div[@xml:id = 'project']/t:p"/>
				</div>
			</div>
			<div class="row">
				<div class="col-md-4 px-5">
					<h2>
						<a class="link-secondary disabled">Discovery</a>
					</h2>
					<p class="lead">
						<xsl:value-of select="$HOME//t:body/t:div[@xml:id = 'discovery']/t:head"/>
					</p>
					<xsl:apply-templates select="$HOME//t:body/t:div[@xml:id = 'discovery']/t:p"/>
				</div>
				<div class="col-md-4 px-5">
					<h2>
						<a class="link-dark" href="/o:depcha.bookkeeping">Bookkeeping-Ontology</a>
					</h2>
					<p class="lead">
						<xsl:value-of select="$HOME//t:body/t:div[@xml:id = 'ontology']/t:head"/>
					</p>
					<xsl:apply-templates select="$HOME//t:body/t:div[@xml:id = 'ontology']/t:p"/>
				</div>
				<div class="col-md-4 px-5">
					<h2>
						<a class="link-dark" href="/o:depcha.tutorial">Tutorial</a>
					</h2>
					<p class="lead">
						<xsl:value-of select="$HOME//t:body/t:div[@xml:id = 'tutorial']/t:head"/>
					</p>
					<xsl:apply-templates select="$HOME//t:body/t:div[@xml:id = 'tutorial']/t:p"/>
				</div>
			</div>
		</div>
	</xsl:template>

	<!-- templates for context datastreams (PROJECT, ABOUT, IMPRINT, ...) -->
	<xsl:template match="t:body" mode="cd">
		<div class="py-3 bg-light">
			<div class="container">
				<div class="card">
					<div class="card-body">
						<xsl:apply-templates mode="cd"/>
					</div>
				</div>
			</div>
		</div>
	</xsl:template>

	<xsl:template match="t:p" mode="cd">
		<p>
			<xsl:apply-templates mode="cd"/>
		</p>
	</xsl:template>

	<xsl:template match="t:head" mode="cd">
		<xsl:choose>
			<xsl:when test="@type = 'main'">
				<h3>
					<xsl:apply-templates mode="cd"/>
				</h3>
			</xsl:when>
			<xsl:otherwise>
				<h5>
					<xsl:apply-templates mode="cd"/>
				</h5>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="t:list" mode="cd">
		<ul>
			<xsl:for-each select="t:item">
				<li>
					<xsl:apply-templates mode="cd"/>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:template>

	<xsl:template match="t:lb" mode="cd">
		<br/>
	</xsl:template>

	<xsl:template match="t:ref" mode="cd">
		<a target="_blank" href="{@target}">
			<xsl:apply-templates mode="cd"/>
		</a>
	</xsl:template>

</xsl:stylesheet>
