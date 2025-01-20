<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    Project: depcha
    Company: ZIM-ACDH (Zentrum für Informationsmodellierung - Austrian Centre for Digital Humanities)
    Author: Christopher Pollin, Jakob Sonnberger
    Last update: 2022
 -->
<xsl:stylesheet xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="xs" version="2.0">
	<xsl:param name="pid"/>
	<xsl:template match="/">
		<oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
			xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
			xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:t="http://www.tei-c.org/ns/1.0">

			<!--  -->
			<dc:identifier>
				<xsl:value-of
					select="//t:teiHeader/t:fileDesc/t:publicationStmt/t:idno[@type = 'PID']"/>
			</dc:identifier>
			<!-- try t:msItem/t:title else t:titleStmt/t:title -->
			<dc:title>
				<xsl:value-of select="
						if (//t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc[1]/t:msContents/t:msItem/t:title[1]) then
							//t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc[1]/t:msContents/t:msItem/t:title[1]
						else
							//t:teiHeader/t:fileDesc/t:titleStmt/t:title"/>
			</dc:title>
			<!--  -->
			<xsl:for-each
				select="//t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc[1]/t:msContents/t:msItem/t:docAuthor">
				<dc:creator>
					<xsl:value-of select="."/>
				</dc:creator>
			</xsl:for-each>
			<!--  -->
			<dc:publisher>Institute Centre for Information Modelling, University of
				Graz</dc:publisher>
			<!--  -->
			<xsl:for-each
				select="//t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc[1]/t:msContents/t:msItem/t:textLang/t:lang">
				<dc:language>
					<xsl:value-of select="."/>
				</dc:language>
			</xsl:for-each>
			<!--  -->
			<dc:format>tei+xml</dc:format>
			<!--  -->
			<dc:date>
				<xsl:value-of
					select="//t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc[1]/t:msContents/t:msItem/t:docDate"
				/>
			</dc:date>
			<!--  -->
			<dc:description>
				<xsl:value-of select="//t:teiHeader/t:encodingDesc/t:projectDesc/t:ab"/>
			</dc:description>
			<!--  -->
			<dc:coverage>
				<xsl:value-of
					select="//t:teiHeader/t:encodingDesc/t:projectDesc/t:ab/t:placeName[1]"/>
			</dc:coverage>
			<!--  -->
			
			<dc:source>
				<xsl:variable name="msIdentifier" select="//t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc[1]/t:msIdentifier[1]"/>
				<xsl:choose>
					<xsl:when test='contains($msIdentifier, "&apos;")'>
						<xsl:value-of
							select='normalize-space(replace($msIdentifier, "&apos;", "´"))'
						/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of
							select="normalize-space(//t:teiHeader/t:fileDesc/t:sourceDesc/t:msDesc[1]/t:msIdentifier[1])"
						/>
					</xsl:otherwise>
				</xsl:choose>
				
			</dc:source>
			<!--  -->
			<dc:relation>DEPCHA - Digital Edition Publishing Cooperative for Historical
				Accounts</dc:relation>
			<dc:relation>https://gams.uni-graz.at/context:depcha</dc:relation>
			<!--  -->
			<dc:rights>Creative Commons BY 4.0</dc:rights>
			<dc:rights>https://creativecommons.org/licenses/by/4.0/</dc:rights>
		</oai_dc:dc>
	</xsl:template>
</xsl:stylesheet>
