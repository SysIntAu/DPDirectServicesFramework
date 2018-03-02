<?xml version="1.0" encoding="UTF-8"?>
	<!-- *****************************************************************
	*	Copyright 2016 SysInt Pty Ltd (Australia)
	*	
	*	Licensed under the Apache License, Version 2.0 (the "License");
	*	you may not use this file except in compliance with the License.
	*	You may obtain a copy of the License at
	*	
	*	    http://www.apache.org/licenses/LICENSE-2.0
	*	
	*	Unless required by applicable law or agreed to in writing, software
	*	distributed under the License is distributed on an "AS IS" BASIS,
	*	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	*	See the License for the specific language governing permissions and
	*	limitations under the License.
	**********************************************************************-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:ctx="http://www.dpdirect.org/Namespace/ApplicationContext/Core/V1.0"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:date="http://exslt.org/dates-and-times"
	extension-element-prefixes="dp date" version="1.0" exclude-result-prefixes="dp date soapenv ctx scm">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>Tim Goodwill</dc:creator>
			<dc:date>2016-12-12</dc:date>
			<dc:title>Template to re-apply original inbound SOAP</dc:title>
			<dc:subject>Template to re-apply original inbound SOAP with internal headers and wsa:Action required for internal service invocation</dc:subject>
			<dc:contributor>Tim Goodwill</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--========================================================================
		Purpose:
		Template to re-apply original inbound SOAP with internal headers and wsa:Action required for internal service invocation
		
		History:
		2016-12-12	v1.0	Tim Goodwill		Initial Version.
		========================================================================-->
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
	<xsl:variable name="REQUEST_NAMESPACE_URI">
		<xsl:choose>
			<xsl:when test="/soapenv:Envelope">
				<xsl:value-of select="namespace-uri(/soapenv:Envelope/soapenv:Body/*[1])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="namespace-uri(*[1])"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="REQUEST_LOCAL_NAME">
		<xsl:choose>
			<xsl:when test="/soapenv:Envelope">
				<xsl:copy-of select="local-name(/soapenv:Envelope/soapenv:Body/*[1])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="local-name(/*[1])"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="REQUEST_ACTION_ENDPOINT">
		<xsl:choose>
			<xsl:when test="substring($REQUEST_LOCAL_NAME,string-length($REQUEST_LOCAL_NAME)-6,7) = 'Request'">
				<xsl:value-of select="substring($REQUEST_LOCAL_NAME,1,string-length($REQUEST_LOCAL_NAME)-7)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$REQUEST_LOCAL_NAME"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="DPDIRECT.SERVICE_STREAM" select="substring-before(substring-after($REQUEST_NAMESPACE_URI, 'http://www.dpdirect.org/Namespace/'), '/Service/')"/>
	<xsl:variable name="ESB_PROXY_ID">
		<xsl:choose>
			<xsl:when test="$DPDIRECT.SERVICE_STREAM = 'PersonIdentity'">
				<xsl:value-of select="'Identity'"/>
			</xsl:when>
			<xsl:when test="$DPDIRECT.SERVICE_STREAM = 'Aggregation'">
				<!-- Target proxy unknown -->
			</xsl:when>
			<xsl:when test="not(contains($DPDIRECT.SERVICE_STREAM, '/'))">
				<xsl:value-of select="$DPDIRECT.SERVICE_STREAM"/>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="ESB_SERVICE_REQUEST_ACTION">
		<xsl:variable name="ESB_INTERFACE_NS_PREFIX" select="'http://www.dpdirect.org/Namespace/'"/>
		<xsl:variable name="ESB_INTERFACE_NS_SUFFIX" select="'/Services/Interface/V1/'"/>
		<xsl:variable name="ESB_INTERFACE_PORT_SUFFIX" select="'_PortType_V1/'"/>
		<xsl:if test="normalize-space($ESB_PROXY_ID) != ''">
			<xsl:value-of select="concat($ESB_INTERFACE_NS_PREFIX, $ESB_PROXY_ID, $ESB_INTERFACE_NS_SUFFIX,  $ESB_PROXY_ID, $ESB_INTERFACE_PORT_SUFFIX, $REQUEST_ACTION_ENDPOINT)"/>
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
	<!-- Template to re-apply inbound security and service meta-data headers for internal proxy calls -->
	<xsl:template match="soapenv:Header">
		<soapenv:Header xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsa="http://www.w3.org/2005/08/addressing">
			<xsl:copy-of select="$REQ_SOAP_ENV/soapenv:Envelope/soapenv:Header/wsse:Security"/>
			<xsl:apply-templates select="*[not(self::wsse:Security)]"/>
			<xsl:if test="not(ctx:ApplicationContext)">
				<!-- Generate an ApplicationContext header otherwise the DHUB SV288 service will not respond -->
				<xsl:variable name="USER_NAME" select="normalize-space(dp:variable($REQ_USER_NAME_VAR_NAME))"/>
				<xsl:variable name="WSA_MSGID" select="normalize-space(dp:variable($REQ_WSA_MSG_ID_VAR_NAME))"/>
				<xsl:variable name="POLICY_LOCATION" select="normalize-space(dp:variable($OPERATION_CONFIG_NODE_ID_VAR_NAME))"/>
				<ctx:ApplicationContext
					xmlns:ctx="http://www.dpdirect.org/Namespace/ApplicationContext/Core/V1.0">
					<ctx:SessionContext>
						<ctx:UserName><xsl:value-of select="$USER_NAME"/></ctx:UserName>
						<ctx:SessionId><xsl:value-of select="$WSA_MSGID"/></ctx:SessionId>
						<ctx:CreationTime><xsl:value-of select="date:date-time()"/></ctx:CreationTime>
					</ctx:SessionContext>
					<ctx:InvocationContext>
						<ctx:Call>
							<ctx:BranchIndex>1</ctx:BranchIndex>
							<ctx:CallerName>DESB</ctx:CallerName>
							<ctx:CallerLocation><xsl:value-of select="$POLICY_LOCATION"/></ctx:CallerLocation>
						</ctx:Call>
					</ctx:InvocationContext>
				</ctx:ApplicationContext>
			</xsl:if>
			<xsl:if test="not(scm:ServiceChainMetadata)">
				<xsl:apply-templates select="$REQ_SOAP_ENV/soapenv:Envelope/soapenv:Header/scm:ServiceChainMetadata"/>
			</xsl:if>
		</soapenv:Header>
	</xsl:template>
	<!-- Template to optionally apply wsa:Action param -->
	<xsl:template match="wsa:Action">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="normalize-space($ACTION_HEADER) != ''">
					<xsl:value-of select="$ACTION_HEADER"/>
				</xsl:when>
				<xsl:when test="normalize-space($ESB_SERVICE_REQUEST_ACTION) != ''">
					<xsl:value-of select="$ESB_SERVICE_REQUEST_ACTION"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="dp:variable($REQ_WSA_ACTION_VAR_NAME)"/>
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
