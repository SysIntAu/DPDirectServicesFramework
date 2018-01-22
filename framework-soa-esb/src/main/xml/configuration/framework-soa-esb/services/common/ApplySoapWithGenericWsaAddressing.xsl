<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:ctx="http://www.dpdirect.org/Namespace/ApplicationContext/Core/V1.0"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" version="1.0" exclude-result-prefixes="dp soapenv scm ctx">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>Tim Goodwill</dc:creator>
			<dc:date>2016-01-28</dc:date>
			<dc:title>Template to strip internal headers, but retain inbound generic ws addressing elements</dc:title>
			<dc:subject>Template to strip internal headers, but retain inbound generic (anonymous) ws addressing elements</dc:subject>
			<dc:contributor>Tim Goodwill</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///ESB_Services/framework/Constants.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:param name="ACTION_HEADER" select="''"/>
	<xsl:variable name="REQ_SOAP_ENV" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
	<xsl:variable name="MSG_PAYLOAD">
		<xsl:choose>
			<xsl:when test="/soapenv:Envelope/soapenv:Body/*[1]">
				<xsl:copy-of  select="/soapenv:Envelope/soapenv:Body/*[1]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of  select="/*[1]"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- Request Identifiers -->
	<xsl:variable name="REQ_REPLYTOQMGR" select="dp:variable($REQ_REPLYTOQMGR_VAR_NAME)"/>
	<xsl:variable name="REQ_REPLYTOQ" select="dp:variable($REQ_REPLYTOQ_VAR_NAME)"/>
	<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
	<xsl:variable name="BACKEND_ROUTING">
		<xsl:copy-of select="$SERVICE_METADATA/PolicyConfig/BackendRouting[1]"/>
	</xsl:variable>
	<xsl:variable name="ASYNC">
		<xsl:if test="$BACKEND_ROUTING/BackendRouting[@async='true']">
			<xsl:value-of select="'true'"/>
		</xsl:if>
	</xsl:variable>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="soapenv:Envelope/soapenv:Header">
				<xsl:apply-templates select="soapenv:Envelope"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$REQ_SOAP_ENV/soapenv:Envelope"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template to apply the payload to the SOAP env -->
	<xsl:template match="soapenv:Body">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:copy-of select="$MSG_PAYLOAD"/>
		</xsl:copy>
	</xsl:template>
	<!-- Template to process SOAP Header -->
	<xsl:template match="soapenv:Header">
		<soapenv:Header xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsa="http://www.w3.org/2005/08/addressing">
			<xsl:apply-templates select="wsse:Security"/>
			<xsl:apply-templates select="$REQ_SOAP_ENV/soapenv:Envelope/soapenv:Header/*[namespace-uri() = 'http://www.w3.org/2005/08/addressing']"/>
			<xsl:apply-templates select="ctx:ApplicationContext"/>
		</soapenv:Header>
	</xsl:template>
	<!-- Template to copy through limited set of "wsse:Security" header content  (Strips SAML Assertion and related dig sig content) -->
	<xsl:template match="wsse:Security">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="wsse:UsernameToken"/> 
		</xsl:copy>
	</xsl:template>
	<!-- Template to genericise ws addressing headers -->
	<xsl:template match="wsa:MessageID">
		<xsl:copy-of select="."/>
	</xsl:template>
	<xsl:template match="wsa:RelatesTo">
		<xsl:copy-of select="."/>
	</xsl:template>
	<xsl:template match="wsa:To[1]">
		<xsl:copy>
			<xsl:value-of select="'http://www.w3.org/2005/08/addressing/anonymous'"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="wsa:To">
		<!-- Do nothing -->
	</xsl:template>
	<xsl:template match="wsa:ReplyTo">
		<!-- Do nothing -->
	</xsl:template>
	<!-- Template to genericise wsa:Action header -->
	<xsl:template match="wsa:Action">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="normalize-space($ACTION_HEADER) != ''">
					<xsl:value-of select="$ACTION_HEADER"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'http://www.w3.org/2005/08/addressing/anonymous'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<!-- Standard identity template -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
