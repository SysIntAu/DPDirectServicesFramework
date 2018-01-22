<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xop="http://www.w3.org/2004/08/xop/include"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:dpconfig="http://www.datapower.com/param/config"
	xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="dp date" version="1.0"
	exclude-result-prefixes="dp dpconfig date">
	<!--========================================================================
		Purpose:
		Copy RESULT_DOC to output context, preserving INPUT context attachments
		
		History:
		2016-08-30	v1.0	Tim Goodwill		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Stylesheet Parameters =========================-->
	<xsl:param name="dpconfig:FROM_CONTEXT" select="'RESULT_DOC'"/>
	<xsl:param name="dpconfig:TO_CONTEXT" select="'INPUT'"/>
	<!--============== Global Variable Declarations =================-->
	
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Copy INPUT context to OUTPUT context -->
		<xsl:copy-of select="dp:variable(concat('var://context/',$dpconfig:FROM_CONTEXT))"/>
		<!-- Copy attachments to OUTPUT context -->
		<xsl:variable name="FROM_MANIFEST" select="dp:variable(concat('var://context/',$dpconfig:FROM_CONTEXT,'/attachment-manifest'))"/>
<!--		<dp:set-variable name="'var://context/ESB_Services/MIME/FROM_MANIFEST'" value="$FROM_MANIFEST"/>-->
<!--		<xsl:variable name="TO_MANIFEST" select="dp:variable(concat('var://context/',$dpconfig:TO_CONTEXT,'/attachment-manifest'))"/>-->
<!--		<dp:set-variable name="'var://context/ESB_Services/MIME/TO_MANIFEST'" value="$TO_MANIFEST"/>-->
		<xsl:choose>
<!--			<xsl:when test="($FROM_MANIFEST/manifest != '') and ($TO_MANIFEST/manifest = '') ">-->
			<xsl:when test="$FROM_MANIFEST/manifest != ''">
				<!-- Indicates newly created attachment(s) : copy attachment to the 'TO' context-->
				<xsl:call-template name="CopyAttachments">
					<xsl:with-param name="FROM_CONTEXT" select="$dpconfig:FROM_CONTEXT"/>
					<xsl:with-param name="TO_CONTEXT" select="$dpconfig:TO_CONTEXT"/>
				</xsl:call-template>
				<xsl:variable name="CONTENT_TYPE">
					<xsl:choose>
						<xsl:when test="dp:variable('var://context/ESB_Services/MIME/contentType') != ''">
							<xsl:value-of select="dp:variable('var://context/ESB_Services/MIME/contentType')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="normalize-space($FROM_MANIFEST/manifest/media-type/value/text())"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="$CONTENT_TYPE != ''">
					<dp:set-mime-header name="MIME-Version"
						value="'1.0'"/>
					<dp:set-mime-header name="Content-Type"
						value="$CONTENT_TYPE"/>
				</xsl:if>
			</xsl:when>
<!--			<xsl:when test="($TO_MANIFEST/manifest != '') and ($FROM_MANIFEST/manifest = '')">
				<!-\- Indicates attachment(s) have been removed or decoded : remove attachment from the 'TO' context-\->
				<dp:strip-attachments/>
			</xsl:when>-->
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
