<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    Project: depcha
    Company: ZIM-ACDH (Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities)
    Author: Christopher Pollin
    Last update: 2023
 -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:i18n="http://apache.org/cocoon/i18n/2.1"
	xmlns:s="http://www.w3.org/2001/sw/DataAccess/rf1/result" xmlns="http://www.w3.org/1999/xhtml"
	xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:lido="http://www.lido-schema.org"
	xmlns:bibtex="http://bibtexml.sf.net/" exclude-result-prefixes="#all">

	<xsl:param name="mode"/>
	<xsl:param name="search"/>

	<xsl:variable name="model"
		select="substring-after(/s:sparql/s:results/s:result/s:model/@uri, '/')"/>

	<xsl:variable name="cid">
		<!-- das ist der pid des contextes, kommt aus dem sparql (ggfs. query anpassen) - wenn keine objekte zugeordnet sind, gibt es ihn nicht! -->
		<xsl:value-of select="/s:sparql/s:results/s:result[1]/s:cid"/>
	</xsl:variable>

	<xsl:variable name="teipid">
		<xsl:value-of select="//t:idno[@type = 'PID']"/>
	</xsl:variable>

	<!-- GAMS global variables -->
	<xsl:variable name="zim">Zentrum für Informationsmodellierung - Austrian Centre for Digital
		Humanities</xsl:variable>
	<xsl:variable name="zim-acdh">ZIM-ACDH</xsl:variable>
	<xsl:variable name="gams">Geisteswissenschaftliches Asset Management System</xsl:variable>
	<xsl:variable name="uniGraz">Universität Graz</xsl:variable>

	<!-- ************
		project-specific variables
		************ -->

	<xsl:variable name="projectAbbr">depcha</xsl:variable>

	<!-- /gamsdev/pollin/depcha/gams-www/ -->	
	<xsl:variable name="projectRootPath" select="'/depcha/'"/>
	<doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
		<desc>Path to gams/zim-managed dependencies like bootstrap / jquery / fonts / logos
			etc.</desc>
	</doc>
	<xsl:variable name="projectTitle">
		<xsl:text>DEPCHA - Digital Edition Publishing Cooperative for Historical Accounts</xsl:text>
	</xsl:variable>
	<xsl:variable name="subTitle">
		<xsl:text>Alpha-Version 1.3</xsl:text>
	</xsl:variable>


	<!-- gesamtes css ist in dieser Datei zusammengefasst mit Ausnahme der Navigation -->
	<xsl:variable name="projectCss">
		<xsl:value-of select="concat($projectRootPath, 'css/', $projectAbbr, '.css')"/>
	</xsl:variable>
	<!--css für die navigation-->
	<xsl:variable name="projectNav">
		<xsl:value-of select="concat($projectRootPath, 'css/navbar.css')"/>
	</xsl:variable>
	<!--css für die Edition-->
	<xsl:variable name="projectEditionCSS">
		<xsl:value-of select="concat($projectRootPath, 'css/edition.css')"/>
	</xsl:variable>


	<!-- ///////////////////////// -->
	<!-- VARIABLES -->
	<xsl:variable name="BASE_URL" select="'https://gams.uni-graz.at/'"/>

	<doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
		<desc>Main</desc>
	</doc>
	<xsl:template match="/">

		<html lang="de">
			<head>
				<meta charset="utf-8"/>

				<meta name="viewport"
					content="width=device-width, initial-scale=1, shrink-to-fit=no"/>
				<!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
				<meta name="keywords"
					content="DEPCHA, digital editions, historical accounts, Historical Financial Records, GAMS, Digital Edition, Publishing Cooperative, 
					Historical Accounts, Bookkeeping Ontology, Linked Open Data, Web of Data, Digital History"/>
				<meta name="description"
					content="The Project ”Digital Edition Publishing Cooperative for Historical Accounts”, a Andrew W. Mellon funded cooperation of five US partners and the Centre for Information Modelling 
					at Graz University, aims to link the knowledge domain of economic activities to historical accounting records. For this purpose the so-called Bookkeeping Ontology is developed. 
					DEPCHA creates a publication hub for digital editions on the web. It converts multiple formats into RDF and publishes these incombination with the associated transcriptions. 
					DEPCHA also allows the usage of retrieval and visualization functionalities, as well as interoperability and reuse of information in the sense of Linked Open Data."/>
				<!-- Projektbeschreibung eingeben -->
				<!-- evtl. noch mehr Meta Tags aus Dublin Core, schema.org oder Open Graph -->
				<meta name="publisher"
					content="Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities"/>
				<meta name="content-language" content="en"/>
				<meta name="author" content="Christopher Pollin"/>
				<meta name="author" content="Georg Vogeler"/>

				<!--Projekttitel-->
				<title>
					<xsl:value-of select="$projectTitle"/>
				</title>

				<!-- CSS ******************************* -->
				<!-- # CSS Bootstrap core -->
				<link rel="stylesheet" type="text/css" href="{concat($projectRootPath, 'lib/Bootstrap-5-5.1.3/css/bootstrap.min.css')}"/>
				<link rel="stylesheet" type="text/css" href="{concat($projectRootPath, 'lib/DataTables/DataTables-1.13.1/css/dataTables.bootstrap5.min.css')}"/>
				<link rel="stylesheet" type="text/css" href="{concat($projectRootPath, 'lib/DataTables/Buttons-2.3.3/css/buttons.bootstrap5.min.css')}"/>
				<!-- # CSS Bootstrap icons -->
				<link rel="stylesheet" type="text/css" href="{concat($projectRootPath, 'lib/bootstrap-icons-1.10.3/bootstrap-icons.css')}"/>
				<!-- # CSS fontawesome  -->
				<link rel="stylesheet" type="text/css" href="/lib/2.0/fa/css/all.min.css"/>
				<!-- # CSS noUIslider -->
				<link rel="stylesheet" type="text/css" href="{concat($projectRootPath, 'lib/nouislider/nouislider.min.css')}"/>
				<!-- # CSS projectspecific -->
				<link rel="stylesheet" type="text/css" href="{$projectCss}"/>
				<link rel="stylesheet" type="text/css" href="{$projectNav}"/>
				<link rel="stylesheet" type="text/css" href="{$projectEditionCSS}"/>
				<link rel="stylesheet" type="text/css" href="{concat($projectRootPath, 'css/tutorial_highlighting.css')}"/>

				<!-- JS ********************************** -->
				<!-- # JS jQuery core JavaScript ================================================== -->				
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/jQuery-3.6.0/jquery-3.6.0.min.js')}"><xsl:text> </xsl:text></script>
				<!-- # JS Bootstrap core JavaScript ================================================== -->
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/Bootstrap-5-5.1.3/js/bootstrap.bundle.min.js')}"><xsl:text> </xsl:text></script>
				<!-- # JS datatable JavaScript -->
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/DataTables/DataTables-1.13.1/js/jquery.dataTables.min.js')}"><xsl:text> </xsl:text></script>
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/DataTables/DataTables-1.13.1/js/dataTables.bootstrap5.min.js')}"><xsl:text> </xsl:text></script>
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/DataTables/Buttons-2.3.3/js/dataTables.buttons.min.js')}"><xsl:text> </xsl:text></script>
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/DataTables/Buttons-2.3.3/js/buttons.bootstrap5.min.js')}"><xsl:text> </xsl:text></script>
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/DataTables/Buttons-2.3.3/js/buttons.html5.min.js')}"><xsl:text> </xsl:text></script>
				<!-- # JS datatable sort-natural JavaScript -->
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/DataTables/natural.js')}"><xsl:text> </xsl:text></script>
				<!-- # JS GamsJs inclusion-->
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/gamsJS/1.x/gams.js')}"><xsl:text> </xsl:text></script>
				<!-- # JS noUIslider JavaScript (+ wNumb) ====================================== -->
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/nouislider/wNumb.min.js')}"><xsl:text>   </xsl:text></script>
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/nouislider/nouislider.min.js')}"><xsl:text>   </xsl:text></script>
				<!-- # JS D3 JavaScript -->
				<script type="text/javascript" src="{concat($projectRootPath, 'lib/d3-7.8.2/package/dist/d3.min.js')}"><xsl:text> </xsl:text></script>
				<!-- # JS projectspecific JavaScript -->
				<script type="text/javascript" src="{concat($projectRootPath, 'js/depcha.js')}"><xsl:text> </xsl:text></script>
				<script type="text/javascript" src="{concat($projectRootPath, 'js/depcha-dashboard-index.js')}"><xsl:text> </xsl:text></script>
				<script type="text/javascript" src="{concat($projectRootPath, 'js/depcha-datatable.js')}"><xsl:text> </xsl:text></script>
				<script type="text/javascript" src="{concat($projectRootPath, 'js/depcha-databasket.js')}"><xsl:text> </xsl:text></script>

			</head>

			<body>
				<!-- ////// -->
				<!-- HEADER -->
				<header class="sticky-top site-header">
					<nav class="navbar navbar-expand-lg">
						<div class="container d-flex justify-content-center">
							<button class="py-2 navbar-toggler white" type="button"
								data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent"
								aria-controls="navbarSupportedContent" aria-expanded="false"
								aria-label="Toggle navigation">
								<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"
									fill="none" stroke="currentColor" stroke-linecap="round"
									stroke-linejoin="round" stroke-width="2" class="d-block mx-auto"
									role="img" viewBox="0 0 24 24">
									<title>DEPCHA</title>
									<circle cx="12" cy="12" r="10"/>
									<path
										d="M14.31 8l5.74 9.94M9.69 8h11.48M7.38 12l5.74-9.94M9.69 16L3.95 6.06M14.31 16H2.83m13.79-4l-5.74 9.94"
									/>
								</svg>
							</button>
							<div class="collapse navbar-collapse" id="navbarSupportedContent">
								<ul class="navbar-nav ">
									<li class="nav-item mx-5">
										<a class="nav-link active" href="/context:depcha">Home</a>
									</li>
									<li class="nav-item mx-5">
										<a class="nav-link"
											href="/archive/objects/context:depcha/methods/sdef:Context/get?mode=collections"
											>Collections</a>
									</li>
									<li class="nav-item mx-5">
										<a class="nav-link disabled" href="#">Discovery</a>
									</li>
									<li class="nav-item dropdown mx-5">
										<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false">
											Ontologies
										</a>
										<ul class="dropdown-menu dropdown-menu-dark" aria-labelledby="navbarDropdown">
											<li><a class="dropdown-item" href="/o:depcha.bookkeeping">Bookkeeping-Ontology</a></li>
											<!--<li><a class="dropdown-item" href="/o:depcha.huc-ontology">Historical Units of Measurements and Currencies Ontology</a></li>
											<li><a class="dropdown-item" href="/o:depcha.ontology">DEPCHA Domain Ontology</a></li>-->
										</ul>
									</li>
									<li class="nav-item mx-5">
										<a class="nav-link"
											href="/archive/objects/context:depcha/methods/sdef:Context/get?mode=project"
											>Project</a>
									</li>
									<li class="nav-item mx-5">
										<a class="nav-link" href="/o:depcha.tutorial">Tutorial</a>
									</li>
									<li class="nav-item mx-5">
										<a class="nav-link text-nowrap"
											href="/archive/objects/context:depcha/methods/sdef:Context/get?mode=db"
											>Databasket <small>(<span id="dbCount"
											>0</span>)</small></a>
									</li>
								</ul>
							</div>
						</div>
					</nav>
				</header>
				<!-- ////// -->
				<!-- MAIN -->
				<main>
					<xsl:call-template name="content"/>
				</main>
				<!-- ////// -->
				<!-- FOOTER -->
				<footer class="bg-dark text-white">
					<div class="container">
						<div class="row pt-1">
							<div class="col-md-3 col-sm">
								<ul class="list-unstyled text-small">
									<li>
										<a class="link-light" href="/archive/objects/context:depcha/methods/sdef:Context/get?mode=imprint">Imprint</a>
									</li>
									<li>
										<a class="link-light"
											href="https://gams.uni-graz.at/archive/objects/context:gams/methods/sdef:Context/get?mode=dataprotection&amp;locale=en"
											>Data protection</a>
									</li>
									<li>
										<xsl:value-of select="year-from-date(current-date())"/>
									</li>
								</ul>
							</div>
							<div class="col-md-3 col-sm">
								<h5>Contact</h5>
								<p>
									<a class="link-light"
										href="mailto:christopher.pollin@uni-graz.at"
										>christopher.pollin@uni-graz.at</a>
									<br/>
									<a class="link-light" href="mailto:georg.vogeler@uni-graz.at"
										>georg.vogeler@uni-graz.at</a>
								</p>

							</div>
							<div class="col-md-6 col-sm text-sm-begin text-md-end">
								<a href="https://mellon.org/" target="_blank">
									<img src="{concat($projectRootPath, 'img/logo-mellon.svg')}"
										class="img-fluid rounded m-1"
										alt="The Andrew W. Mellon Foundation Logo" width="85px"
										height="85px"/>
								</a>
								<a href="https://centerfordigitalediting.org/" target="_blank">
									<img
										src="{concat($projectRootPath, 'img/logo-digitalediting.png')}"
										class="img-fluid rounded m-1"
										alt="The University of Virginia Logo" width="85px"
										height="85px"/>
								</a>
								<a href="https://www.virginia.edu/" target="_blank">
									<img src="{concat($projectRootPath, 'img/uva_logo.png')}"
										class="img-fluid rounded m-1"
										alt="The University of Virginia Logo" width="85px"
										height="85px"/>
								</a>
								<a href="https://informationsmodellierung.uni-graz.at/en/"
									target="_blank">
									<img
										src=" /templates/img/ZIM_weiss_zugeschnitten.png"
										class="img-fluid rounded m-1" alt="ZIM Logo" width="60px"
										height="60px"/>
								</a>
								<a href="https://www.uni-graz.at/en" target="_blank">
									<img
										src=" /templates/img/logo_uni_graz_4c.jpg"
										class="img-fluid rounded m-1" alt="Universität Graz Logo"
										width="60px" height="60px"/>
								</a>
								<a href="https://gams.uni-graz.at" target="_blank">
									<img
										src=" /templates/img/gamslogo_weiss.gif"
										class="img-fluid rounded m-1" alt="GAMS Logo" width="85px"
										height="85px"/>
								</a>
							</div>
						</div>
					</div>
				</footer>
				<!-- Initializing tooltips-->
				<script>
					var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
					var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
					return new bootstrap.Tooltip(tooltipTriggerEl)
					})
					count_DB();
				</script>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="t:lb">
		<br/>
	</xsl:template>


	<!-- returns langauge from a language code -->
	<xsl:template name="langeCodeToText">
		<xsl:param name="code"/>
		<xsl:choose>
			<xsl:when test="$code = 'en'">
				<xsl:text>English</xsl:text>
			</xsl:when>
			<xsl:when test="$code = 'nl'">
				<xsl:text>Dutch</xsl:text>
			</xsl:when>
			<xsl:when test="$code = 'de'">
				<xsl:text>German</xsl:text>
			</xsl:when>
			<xsl:when test="$code = 'fr'">
				<xsl:text>French</xsl:text>
			</xsl:when>
			<xsl:when test="$code = 'es'">
				<xsl:text>Spanish</xsl:text>
			</xsl:when>
			<xsl:when test="$code = 'it'">
				<xsl:text>Italian</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$code"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- returns icons for pid and date -->
	<xsl:template name="create_pid_date_in_collection_card">
		<div class="small mb-2 align-self-end">

			<div class="row row-cols-auto">

				<div class="col">
					<a href="{concat('https://gams.uni-graz.at/', s:identifier)}"
						class="small link-dark mx-1" title="Permalink of the Collection:">
						<i class="fas fa-link">
							<xsl:text> </xsl:text>
						</i>
						<span class="small ms-3">
							<xsl:value-of select="concat('https://gams.uni-graz.at/', s:identifier)"
							/>
						</span>
					</a>
					<br/>
					<span title="{'Last modified'}" class="mx-1">
						<i class="fas fa-calendar-week">
							<xsl:text> </xsl:text>
						</i>
						<span class="small ms-3">
							<xsl:value-of select="
									if (s:lastModifiedDate) then
										(format-dateTime(s:lastModifiedDate, '[D].[M].[Y]'))
									else
										' '"/>
						</span>
					</span>
				</div>
				<!-- return sums of transactions, economic goods, economic agents and accounts for all datasets in a collection -->
				<div class="col">
					<span title="{'Sum of processed Transactions'}" class="mx-1">
						<i class="fas fa-exchange-alt">
							<xsl:text> </xsl:text>
						</i>
						<span class="small ms-3 nt">
							<xsl:text/>
						</span>
					</span>
					<br/>
					<span title="{'Sum of Economic Goods involved'}" class="mx-1">
						<i class="fas fa-boxes">
							<!--<i class="bi bi-boxes">-->
							<xsl:text> </xsl:text>
							<!--</i>-->
						</i>
						<span class="small ms-3 neg">
							<xsl:text/>
						</span>
					</span>
					<br/>
				</div>

				<div class="col">
					<span title="{'Sum of Economic Agents involved'}" class="mx-1">
						<i class="bi bi-people-fill">
							<xsl:text> </xsl:text>
						</i>
						<span class="small ms-3 nea">
							<xsl:text/>
						</span>
					</span>
					<br/>
					<span title="{'Sum of Accounts'}" class="mx-1">
						<i class="bi bi-book">
							<xsl:text> </xsl:text>
						</i>
						<span class="small ms-3 nacc">
							<xsl:text/>
						</span>
					</span>
					<br/>
				</div>

			</div>
		</div>
	</xsl:template>

</xsl:stylesheet>
