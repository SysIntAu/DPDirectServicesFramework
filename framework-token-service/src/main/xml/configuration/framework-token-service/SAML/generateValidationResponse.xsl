<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:date="http://exslt.org/dates-and-times" version="1.0" 
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:exslt="http://exslt.org/common" exclude-result-prefixes="dp date wst saml wsa">
	<!--========================================================================
		Purpose:
		Verifies A SAML Assertion
		
		History:
		2016-03-25  v1.0    Chris Sherlock  Initial Version.
		========================================================================-->
	<xsl:import href="local:///SecureTokenService/common/Utils.xsl"/>
	<!-- prior to this style sheet, the token has been decoded.  Here we test the signature -->
	<!-- Some Useful Information when Creating a SAML Token :-) -->
	<xsl:variable name="AUTHENTICATED_USER" select="dp:variable('var://context/WSM/identity/authenticated-user')"/>
	<!-- The attribute statement is generated in the Authorise Step of the AAA Action -->
	<xsl:variable name="SAML_ATTRIBUTE_STATEMENT" select="dp:variable('var://context/service/groupattributes')"/>
	<xsl:variable name="CURRENT_TIMESTAMP" select="date:seconds()"/>
	<xsl:variable name="GROUP_ATTRIBUTE">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_GROUP_ATTRIBUTE_NAME"/>
		</xsl:call-template>
	</xsl:variable>
	<!-- time bounds -->
	<xsl:variable name="TOKEN_START_TIMESTAMP" select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security'
		]/saml:Assertion/saml:Conditions/@NotBefore"/>
	<xsl:variable name="TOKEN_EXPIRY_TIMESTAMP" select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security'
		]/saml:Assertion/saml:Conditions/@NotOnOrAfter"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="/">
		<xsl:variable name="VALIDATION_CODE">
			<xsl:value-of select="'http://docs.oasis-open.org/ws-sx/ws-trust/200512/status/invalid'"/>
		</xsl:variable>
		<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
			xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" 
			xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
			xmlns:dp="http://www.datapower.com/schemas/management">
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
						<wst:Code><xsl:value-of select="$VALIDATION_CODE"/></wst:Code>
					</wst:Status>
				</wst:RequestSecurityTokenResponse>
			</soap:Body>
		</soap:Envelope>
	</xsl:template>
</xsl:stylesheet>
