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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:date="http://exslt.org/dates-and-times" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	extension-element-prefixes="dp date" exclude-result-prefixes="dp  date saml wsa wsse ds wsu" version="1.0">
	<!--========================================================================
		Purpose:
		Adds SAML2 Assertion to messages being routed to framework-soa-esb endpoints
		
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:param name="ACTION_HEADER" select="''"/>
	<!-- Adding zero duration results in UTC (re:timezone) which is consitent for the wsu:Timestamp values -->
	<xsl:variable name="CURRENT_TIME" select="date:add(date:date-time(), 'PT0S')"/>
	<xsl:variable name="TIMESTAMP_ID" select="concat('Timestamp-',dp:generate-uuid())"/>
	<xsl:variable name="SEC_TOKEN_ID" select="concat('SecToken-',dp:generate-uuid())"/>
	<xsl:variable name="SAML_ASSERTION_ID" select="concat('SamlAssertion-',dp:generate-uuid())"/>
	<xsl:variable name="SIGN_METHOD_ALGO" select="'http://www.w3.org/2000/09/xmldsig#rsa-sha1'"/>
	<xsl:variable name="SIGN_KEY_ID" select="'name:apiGatewayServices'"/>
	<xsl:variable name="SIGN_CERT_ID" select="'name:apiGatewayServices'"/>
	<xsl:variable name="C14N_ALGO" select="'http://www.w3.org/2001/10/xml-exc-c14n#'"/>
	<xsl:variable name="DIGEST_ALGO" select="'http://www.w3.org/2000/09/xmldsig#sha1'"/>
	<!-- Default timestamp duration (5 minutes) -->
	<xsl:variable name="TS_DURATION" select="'PT5M'"/>
	<xsl:variable name="SIGN_CERT_TEXT" select="dp:base64-cert($SIGN_CERT_ID)"/>
	<xsl:variable name="SIGN_CERT_DN" select="dp:get-cert-subject(concat('cert:',$SIGN_CERT_TEXT))"/>
	<!-- Action header vars -->
	<xsl:variable name="MSG_PAYLOAD">
		<xsl:choose>
			<xsl:when test="/soap:Envelope/soap:Body/*[1]">
				<xsl:copy-of  select="/soap:Envelope/soap:Body/*[1]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of  select="/*[1]"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="REQUEST_NAMESPACE_URI">
		<xsl:choose>
			<xsl:when test="/soap:Envelope">
				<xsl:value-of select="namespace-uri(/soap:Envelope/soap:Body/*[1])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="namespace-uri(*[1])"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="REQUEST_LOCAL_NAME">
		<xsl:choose>
			<xsl:when test="/soap:Envelope">
				<xsl:copy-of select="local-name(/soap:Envelope/soap:Body/*[1])"/>
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
	<xsl:variable name="WSA_MSGID">
		<xsl:choose>
			<xsl:when test="/soap:Envelope/soap:Header/wsa:MessageID">
				<xsl:value-of select="/soap:Envelope/soap:Header/wsa:MessageID"/>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="normalize-space(dp:generate-uuid())"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Strip existing WS-Security header and add a new one with a SAML2 Assertion and signed parts -->
	<xsl:template match="soap:Header">
		<xsl:copy>
			<wsse:Security soap:mustUnderstand="0">
				<xsl:variable name="TIMESTAMP_NODE">
					<xsl:call-template name="NewTimestamp">
						<xsl:with-param name="ID" select="$TIMESTAMP_ID"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:copy-of select="$TIMESTAMP_NODE"/>
				<xsl:variable name="SAML_ASSERTION_NODE">
					<xsl:call-template name="NewSaml2Assertion">
						<xsl:with-param name="ID" select="$SAML_ASSERTION_ID"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:copy-of select="$SAML_ASSERTION_NODE"/>
				<wsse:BinarySecurityToken wsu:Id="{$SEC_TOKEN_ID}"
					EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
					ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3">
					<xsl:value-of select="$SIGN_CERT_TEXT"/>
				</wsse:BinarySecurityToken>
				<ds:Signature>
					<xsl:variable name="SIGNED_INFO_NODE">
						<ds:SignedInfo>
							<ds:CanonicalizationMethod Algorithm="{$C14N_ALGO}"/>
							<ds:SignatureMethod Algorithm="{$SIGN_METHOD_ALGO}"/>
							<xsl:call-template name="NewReference">
								<xsl:with-param name="ID" select="concat('#',$TIMESTAMP_ID)"/>
								<xsl:with-param name="NODE" select="$TIMESTAMP_NODE"/>
							</xsl:call-template>
							<xsl:call-template name="NewReference">
								<xsl:with-param name="ID" select="concat('#',$SAML_ASSERTION_ID)"/>
								<xsl:with-param name="NODE" select="$SAML_ASSERTION_NODE"/>
							</xsl:call-template>
						</ds:SignedInfo>
					</xsl:variable>
					<xsl:copy-of select="$SIGNED_INFO_NODE"/>
					<ds:SignatureValue>
						<xsl:variable name="SIGNED_INFO_HASH" select="dp:exc-c14n-hash('', $SIGNED_INFO_NODE,
							false(), $DIGEST_ALGO)"/>
						<xsl:value-of select="dp:sign($SIGN_METHOD_ALGO, $SIGNED_INFO_HASH, $SIGN_KEY_ID)"/>
					</ds:SignatureValue>
					<ds:KeyInfo>
						<wsse:SecurityTokenReference>
							<wsse:Reference URI="{concat('#',$SEC_TOKEN_ID)}"
								ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"
							/>
						</wsse:SecurityTokenReference>
					</ds:KeyInfo>
				</ds:Signature>
				<xsl:copy-of select="wsse:security/*[
					not(self::wsu:Timestamp) and
					not(self::saml:Assertion) and
					not(self::wsse:BinarySecurityToken) and
					not(self::ds:Signature)]"/>
			</wsse:Security>
			<xsl:if test="not(wsa:To)">
				<wsa:To>http://www.w3.org/2005/08/addressing/anonymous</wsa:To>
			</xsl:if>
			<xsl:if test="not(wsa:MessageID)">
				<wsa:Action><xsl:value-of select="$WSA_MSGID"/></wsa:Action>
			</xsl:if>
			<xsl:if test="not(wsa:Action)">
				<wsa:Action><xsl:value-of select="$ESB_SERVICE_REQUEST_ACTION"/></wsa:Action>
			</xsl:if>
			<xsl:apply-templates select="*[not(self::wsse:Security)]"/>
		</xsl:copy>
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
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<!-- Template to perform a Standard Identity Transform -->
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<!-- Named template to generate a new SignedInfo Reference element -->
	<xsl:template name="NewReference">
		<xsl:param name="NODE">
			<!-- Initialise the param with an empty node. This prevents a DataPower compilation 
				warning about an illegal cast from string to nodeset when calling dp:exc-c14n-hash() below. -->
			<Empty/>
		</xsl:param>
		<xsl:param name="ID"/>
		<ds:Reference URI="{$ID}">
			<ds:Transforms>
				<ds:Transform Algorithm="{$C14N_ALGO}"/>
			</ds:Transforms>
			<ds:DigestMethod Algorithm="{$DIGEST_ALGO}"/>
			<ds:DigestValue>
				<xsl:value-of select="dp:exc-c14n-hash('', $NODE, false(), $DIGEST_ALGO)"/>
			</ds:DigestValue>
		</ds:Reference>
	</xsl:template>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Named template to generate a new SAML2 Assertion -->
	<xsl:template name="NewSaml2Assertion">
		<xsl:param name="ID"/>
		<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="{$ID}" IssueInstant="{$CURRENT_TIME}"
			Version="2.0">
			<saml:Issuer>urn:www.api.dpdirect.org:Json_RestAPI</saml:Issuer>
			<saml:Subject>
				<saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName">
					<xsl:value-of select="$SIGN_CERT_DN"/>
				</saml:NameID>
				<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"/>
			</saml:Subject>
			<saml:AuthnStatement AuthnInstant="{$CURRENT_TIME}">
				<saml:AuthnContext>
					<saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:X509</saml:AuthnContextClassRef>
				</saml:AuthnContext>
			</saml:AuthnStatement>
		</saml:Assertion>
	</xsl:template>
	<!-- Named template to generate a new Timestamp using the current time -->
	<xsl:template name="NewTimestamp">
		<xsl:param name="ID"/>
		<wsu:Timestamp wsu:Id="{$ID}">
			<wsu:Created>
				<xsl:value-of select="$CURRENT_TIME"/>
			</wsu:Created>
			<wsu:Expires>
				<xsl:value-of select="date:add($CURRENT_TIME, $TS_DURATION)"/>
			</wsu:Expires>
		</wsu:Timestamp>
	</xsl:template>
</xsl:stylesheet>
