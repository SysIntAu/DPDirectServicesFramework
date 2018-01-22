<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="dp date" version="1.0"
	exclude-result-prefixes="dp date">
	<!--========================================================================
		Purpose:
		Performs dynamic configuration of a policy flow by routing the next rule destination based on
		the current service configuration state
				
		History:
		2016-10-26	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="OperationConfig">
		<xsl:variable name="NEXT_RULE_SHORT_NAME" select="local-name(*[2])"/>
		<xsl:variable name="NEXT_RULE_NAME">
			<xsl:choose>
				<xsl:when test="normalize-space($NEXT_RULE_SHORT_NAME)">
					<xsl:value-of select="concat($RULE_NAME_PREFIX,normalize-space($NEXT_RULE_SHORT_NAME),'_rule')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="''"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="$NEXT_RULE_NAME_VAR_NAME" value="string($NEXT_RULE_NAME)"/>
		<!-- Copy modified config doc to result set -->
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="*[position() &gt; 1]"/>
		</xsl:copy>
	</xsl:template>
	<!-- Standard identity template -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
