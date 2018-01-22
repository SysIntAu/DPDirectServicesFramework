<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>Tim Goodwill</dc:creator>
			<dc:date>2016-01-09</dc:date>
			<dc:title>DataPower exported configuration file (xcfg)  configuration file injection
				transform.</dc:title>
			<dc:subject>Adds environment specific objects from the  configuration file.</dc:subject>
			<dc:contributor>Tim Goodwill</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--========================================================================
		History:
		2016-01-09	v0.1	Tim Goodwill		Initial Version.
		========================================================================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="yes" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:param name="XCONFIG_PATH" select="''"/>
	<xsl:variable name="XCONFIG_DOC" select="document($XCONFIG_PATH)"/>
	<!--============== Stylesheet Parameter Declarations ============-->
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to perform a Standard Identity Transform -->
	<xsl:template match="*[parent::configuration]" priority="10">
		<xsl:variable name="CURRENT_NODE_NAME" select="local-name()"/>
		<xsl:variable name="CURRENT_NODE_NAME_ATTR" select="normalize-space(@name)"/>
		<xsl:variable name="LAST_BOOL" select="boolean(count(following-sibling::node()[local-name() = $CURRENT_NODE_NAME]) = 0)"/>
		<xsl:variable name="REPLACEMENT_NODE" select="$XCONFIG_DOC/datapower-configuration/configuration/*[local-name() = $CURRENT_NODE_NAME][normalize-space(@name) = $CURRENT_NODE_NAME_ATTR]"/>
		<xsl:choose>
			<!-- Remove placeholders -->
			<xsl:when test="count(node()) = 0">
				<!--  Remove -->
			</xsl:when>
			<!-- overwrite existing config with replacement config (same type, same name)-->
			<xsl:when test="$REPLACEMENT_NODE != ''">
				<xsl:apply-templates select="$REPLACEMENT_NODE" mode="newConfig"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="node()|@*"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
		<!-- follow existing config with new config (same type)-->
		<xsl:if test="$LAST_BOOL">
			<xsl:apply-templates select="$XCONFIG_DOC/datapower-configuration/configuration/*[local-name() = $CURRENT_NODE_NAME][normalize-space(@name) != $CURRENT_NODE_NAME_ATTR]"  mode="newConfig"/>
		</xsl:if>
	</xsl:template>
	<!-- Template to perform a Standard Identity Transform -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to perform a Standard Identity Transform, 'newConfig' node -->
	<xsl:template match="node()|@*" mode="newConfig">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
