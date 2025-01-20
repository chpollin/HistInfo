<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="xs" version="2.0">
    <xsl:strip-space elements="*"/>
    <xsl:template match="/">
        <xsl:variable name="server" select="'http://gams.uni-graz.at/'"/>
        <xsl:variable name="idno" select="normalize-space(//t:idno[@type = 'PID'])"/>
        <mets:mets xmlns:mets="http://www.loc.gov/METS/" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:vi="http://gams.uni-graz.at/viewer" xmlns:xlink="http://www.w3.org/1999/xlink">
            <mets:dmdSec ID="DMD.1">
                <mets:mdWrap MDTYPE="MODS" MIMETYPE="text/xml">
                    <mets:xmlData>
                        <mods:mods xmlns:mods="http://www.loc.gov/mods/v3">
                            <mods:identifier type="urn">
                                <xsl:value-of select="$idno"/>
                            </mods:identifier>
                            <mods:titleInfo>
                                <mods:title>
                                    <xsl:value-of select="normalize-space(//t:titleStmt/t:title)"/>
                                </mods:title>
                            </mods:titleInfo>
                            <mods:name type="personal">
                                <mods:displayForm>
                                    <xsl:value-of select="normalize-space(//t:titleStmt/t:author)"/>
                                </mods:displayForm>
                                <mods:role>
                                    <mods:roleTerm type="text">author</mods:roleTerm>
                                </mods:role>
                            </mods:name>
                            <mods:originInfo>
                                <mods:dateIssued/>
                            </mods:originInfo>
                        </mods:mods>
                    </mets:xmlData>
                </mets:mdWrap>
            </mets:dmdSec>
            <mets:amdSec ID="AMD.1">
                <mets:rightsMD ID="RMD.1">
                    <mets:mdWrap MDTYPE="OTHER" MIMETYPE="text/xml" OTHERMDTYPE="DVRIGHTS">
                        <mets:xmlData>
                            <dv:rights xmlns:dv="http://dfg-viewer.de/">
                                <dv:owner/>
                                <dv:ownerContact/>
                                <dv:ownerLogo/>
                                <dv:ownerSiteURL/>
                            </dv:rights>
                        </mets:xmlData>
                    </mets:mdWrap>
                </mets:rightsMD>
                <mets:digiprovMD ID="PMD.1">
                    <mets:mdWrap MDTYPE="OTHER" MIMETYPE="text/xml" OTHERMDTYPE="DVLINKS">
                        <mets:xmlData>
                            <dv:links xmlns:dv="http://dfg-viewer.de/">
                                <dv:reference/>
                                <dv:presentation/>
                            </dv:links>
                        </mets:xmlData>
                    </mets:mdWrap>
                </mets:digiprovMD>
            </mets:amdSec>
            <mets:fileSec>
                <mets:fileGrp USE="DEFAULT">
                    <xsl:for-each select="//t:facsimile/t:surface">
                        <mets:file MIMETYPE="image/jpeg">
                            <xsl:attribute name="ID">
                                <xsl:value-of select="t:graphic/@xml:id"/>
                            </xsl:attribute>
                            <mets:FLocat LOCTYPE="URL">
                                <xsl:attribute name="xlink:href">
                                    <xsl:value-of select="concat($server, $idno, '/', t:graphic/@xml:id)"/>
                                </xsl:attribute>
                            </mets:FLocat>
                        </mets:file>
                    </xsl:for-each>
                </mets:fileGrp>
            </mets:fileSec>
            <mets:structMap TYPE="PHYSICAL">
                <mets:div ID="PHY.0" TYPE="physSequence">
                    <xsl:for-each select="//t:facsimile/t:surface">
                        <mets:div TYPE="page">
                            <xsl:attribute name="ID">
                                <xsl:value-of select="substring-after(@start, '#')"/>
                            </xsl:attribute>
                            <xsl:attribute name="ORDER">
                                <xsl:value-of select="position()"/>
                            </xsl:attribute>
                            <mets:fptr>
                                <xsl:attribute name="FILEID">
                                    <xsl:value-of select="t:graphic/@xml:id"/>
                                </xsl:attribute>
                            </mets:fptr>
                        </mets:div>
                    </xsl:for-each>
                </mets:div>
            </mets:structMap>
            <mets:structMap TYPE="LOGICAL">
                <mets:div ADMID="AMD.1" DMDID="DMD.1" ID="LOG.0" TYPE="monograph"/>
            </mets:structMap>
            <mets:structLink>
                <mets:smLink xlink:from="LOG.0" xlink:to="PHYS.0"/>
                <mets:smLink xlink:from="LOG.d1e56" xlink:to=""/>
            </mets:structLink>
        </mets:mets>
    </xsl:template>
</xsl:stylesheet>