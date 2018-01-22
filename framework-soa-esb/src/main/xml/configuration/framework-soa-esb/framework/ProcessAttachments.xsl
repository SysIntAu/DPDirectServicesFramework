<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xop="http://www.w3.org/2004/08/xop/include"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:dpconfig="http://www.datapower.com/param/config"
	xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="dp date" version="1.0"
	exclude-result-prefixes="dp dpconfig date">
	<!--========================================================================
		Purpose:
		Parameter controlled processing of attachments : 
			'pre' =  wrap data in DP attachment reference.
			'post' = remove DP attachment reference.
				
		History:
		2016-08-30	v1.0	Tim Goodwill		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Stylesheet Parameters =========================-->
	<xsl:param name="dpconfig:PROCESS" select="'pre'"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
	<xsl:variable name="CONFIG_ATTACHMENTS_REFERENCE">
		<xsl:value-of select="($SERVICE_METADATA/OperationConfig/EncodeMTOM/TargetElement
			| $SERVICE_METADATA/OperationConfig/DecodeMTOM/TargetElement)[1]"/>
	</xsl:variable>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="$dpconfig:PROCESS = 'pre'"> 
				<xsl:copy>
					<xsl:apply-templates mode="preProcessDocument"/>
				</xsl:copy>
			</xsl:when>
			<xsl:when test="$dpconfig:PROCESS = 'post'"> 
				<xsl:copy>
					<xsl:apply-templates mode="postProcessDocument"/>
				</xsl:copy>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- 'preProcessDocument' Modal identity templates -->
	<xsl:template match="node()|@*" mode="preProcessDocument">
		<!-- wrap data in DP attachment reference -->
		<xsl:choose>
			<xsl:when test="local-name() = $CONFIG_ATTACHMENTS_REFERENCE">
				<xsl:copy>
					<xsl:element name="DPAttachmentsReference">
						<xsl:apply-templates select="@*|node()"/>
					</xsl:element>
				</xsl:copy>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@*|node()" mode="preProcessDocument"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="xop:include" mode="preProcessDocument">
		<!-- wrap data in DP attachment reference, TargetElement '*' wildcard char means decode all refs -->
		<xsl:choose>
			<xsl:when test="$CONFIG_ATTACHMENTS_REFERENCE = '*'">
				<xsl:element name="DPAttachmentsReference">
					<xsl:copy-of select="."/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- 'postProcessDocument' Modal identity templates -->
	<xsl:template match="node()|@*" mode="postProcessDocument">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="postProcessDocument"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="DPAttachmentsReference" mode="postProcessDocument">
		<!-- remove DP attachment reference -->
		<xsl:apply-templates select="node()" />
	</xsl:template>
	<!-- Standard identity template-->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
