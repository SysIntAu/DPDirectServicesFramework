<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="dp date" version="1.0"
	exclude-result-prefixes="dp date">
	<!--========================================================================
		Purpose:
		Transform the input document with the stylesheet specified in the policy config
				
		History:
		2016-10-26	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
		<!-- Start a timer event for the rule -->
		<xsl:call-template name="StartTimerEvent">
			<xsl:with-param name="EVENT_ID" select="$SERVICE_METADATA/OperationConfig/Transform[1]/@timerId"/>
		</xsl:call-template>
		<xsl:variable name="XSLT_LOCATION" select="$SERVICE_METADATA//OperationConfig/Transform[1]/Stylesheet"/>
		<xsl:copy-of select="dp:transform($XSLT_LOCATION,.)"/>
	</xsl:template>
</xsl:stylesheet>
