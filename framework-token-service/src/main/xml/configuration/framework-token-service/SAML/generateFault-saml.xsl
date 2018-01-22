<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512/"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:dp="http://www.datapower.com/extensions"
	version="1.0" 
	extension-element-prefixes="dp" 
	exclude-result-prefixes="dp date wst saml wsa">
	<!--========================================================================
		Purpose:
		Generate a STS SOAP Fault
		
		History:
		2016-03-25  v1.0    Chris Sherlock  Initial Version.
		========================================================================-->
	<xsl:import href="utils-saml.xsl"/>
	<xsl:variable name="FAILUREMODE" select="normalize-space(dp:variable('var://context/service/failuremode'))"/>
	<xsl:variable name="WSA_ACTION" select="dp:variable($REQ_WSA_ACTION_VAR_NAME)"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="/">
		<dp:set-variable name="'var://service/error-protocol-response'" value="'200'"/>
		<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'OK'"/>
		<xsl:choose>
			<xsl:when test="contains($WSA_ACTION, '/Validate')">
				<xsl:call-template name="generateValidationFault"/>
			</xsl:when>
			<xsl:when test="$FAILUREMODE = 'schema'">
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'wst:invalidRequest'"/>
					<xsl:with-param name="FAULTSTRING" select="'The request was invalid or malformed'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$FAILUREMODE = 'authenticate'">
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'wst:failedAuthentication'"/>
					<xsl:with-param name="FAULTSTRING" select="'Authentication failed'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$FAILUREMODE = 'authenticate nomsg_grps'">
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'wst:failedAuthentication'"/>
					<xsl:with-param name="FAULTSTRING" select="'Authentication failed'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$FAILUREMODE = 'authenticate error'">
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'soap:Client'"/>
					<xsl:with-param name="FAULTSTRING" select="'Authentication error'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="generateFault">
					<xsl:with-param name="FAULTCODE" select="'soap:Client'"/>
					<xsl:with-param name="FAULTSTRING" select="'Unknown Error'"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="generateValidationFault">
		<xsl:variable name="VALIDATION_CODE">
			<xsl:value-of select="'http://docs.oasis-open.org/ws-sx/ws-trust/200512/status/invalid'"/>
		</xsl:variable>
		<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
			<soap:Header>
				<xsl:copy-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[namespace-uri() =
					'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd']"/>
				<xsl:copy-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[namespace-uri() =
					'http://www.w3.org/2005/08/addressing'][not(wsa:MessageID)]"/>
				<wsa:MessageID>
					<xsl:value-of select="dp:generate-uuid()"/>
				</wsa:MessageID>
				<wsa:RelatesTo>
					<xsl:value-of select="/*[local-name()='Envelope']/*[local-name()='Header']/wsa:MessageID"/>
				</wsa:RelatesTo>
			</soap:Header>
			<soap:Body>
				<wst:RequestSecurityTokenResponse>
					<wst:TokenType>http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0</wst:TokenType>
					<wst:Status>
						<wst:Code>
							<xsl:value-of select="$VALIDATION_CODE"/>
						</wst:Code>
					</wst:Status>
				</wst:RequestSecurityTokenResponse>
			</soap:Body>
		</soap:Envelope>
	</xsl:template>
</xsl:transform>
