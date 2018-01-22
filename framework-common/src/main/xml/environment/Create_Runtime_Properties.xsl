<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="" version="1.0">
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="yes" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="/">
		<!-- Create the root output element -->
		<PropertiesList xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:noNamespaceSchemaLocation="PropertiesList.xsd">
			<xsl:apply-templates select="//dpdirects/parameter"/>
		</PropertiesList>
	</xsl:template>
	<!-- Template to create "Property" output elements -->
	<xsl:template match="parameter">
		<xsl:if test="starts-with(normalize-space(@name),'dpdirect://')">
			<Property key="{normalize-space(@name)}" value="{normalize-space(@value)}"/>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>