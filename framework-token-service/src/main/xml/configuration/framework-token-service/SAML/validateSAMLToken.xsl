<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512/"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:date="http://exslt.org/dates-and-times" version="1.0" 
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:exslt="http://exslt.org/common" 
	extension-element-prefixes="dp exslt" 
	exclude-result-prefixes="dp exslt date wst saml wsa">
	<!--========================================================================
		Purpose:
		Verifies the Group Memberships within an Assertion
		
		History:
		2016-03-25  v1.0    Chris Sherlock  Initial Version.
		========================================================================-->
	<xsl:import href="local:///SecureTokenService/common/Utils.xsl"/>
	<!-- prior to this style sheet, the token has been decoded.  Here we test the signature -->
	<!-- Some Useful Information when Creating a SAML Token :-) -->
	<!-- The attribute statement is generated in the Authorise Step of the AAA Action -->
	<xsl:variable name="AUTHENTICATED_USER" select="dp:variable('var://context/WSM/identity/authenticated-user')"/>
	<xsl:variable name="GROUP_ATTRIBUTE">
		<xsl:call-template name="GetDPDirectProperty">
			<xsl:with-param name="KEY" select="$DPDIRECT.PROPKEY_AUTH_LDAP_GROUP_ATTRIBUTE_NAME"/>
		</xsl:call-template>
	</xsl:variable>
	
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="/">
		<!-- make sure the claims match what's in LDAP. I know, this sounds ridiculous, we're not trusting our own claims, but we don't have an invalidate binding.
            		LDAP results are being cached and will only go off box after TTL has passed -->
		<xsl:variable name="RESULTS">
			<xsl:call-template name="getMsgGroupsForUser">
				<xsl:with-param name="USERID" select="$AUTHENTICATED_USER"/>
				<xsl:with-param name="USECACHE" select="'true'"></xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<!-- get all group memberships which start with the Mobile Group Prefix-->
		<xsl:variable name="EXT_GRPS"
			select="exslt:node-set($RESULTS)/LDAP-search-results/result/attribute-value[@name=$GROUP_ATTRIBUTE]"/>
		<xsl:variable name="EXT_GRP_RESULT">
			<result>
				<xsl:copy-of select="exslt:node-set($EXT_GRPS)"/>
			</result>
		</xsl:variable>
		<xsl:variable name="EVALUATED_ATTRIBUTE">
			<saml:Attribute>
				<xsl:apply-templates mode="validateAssertions" select="/*[local-name()='Envelope']/*[local-name()='Header']/*[local-name()='Security'
					]/saml:Assertion/saml:AttributeStatement/saml:Attribute[@name='group']/saml:AttributeValue">
					<xsl:with-param name="EXT_GRP_RESULT" select="$EXT_GRP_RESULT"/>
				</xsl:apply-templates>
			</saml:Attribute>
		</xsl:variable>
		<xsl:variable name="VALIDATION_CODE">
			<!-- TODO... SAML Attribute (LDAP groups) validation -->
			<xsl:choose>
				<xsl:when test="($EVALUATED_ATTRIBUTE//saml:AttributeValue/@statusCode) 
					and not(contains(normalize-space($EVALUATED_ATTRIBUTE//saml:AttributeValue/@statusCode), 'invalid'))">
					<xsl:value-of select="'http://docs.oasis-open.org/ws-sx/ws-trust/200512/status/valid'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'http://docs.oasis-open.org/ws-sx/ws-trust/200512/status/invalid'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="'var://context/ESB_Services/debug/EXT_GRP_RESULT'" value="$EXT_GRP_RESULT"/>
		<dp:set-variable name="'var://context/ESB_Services/debug/EVALUATED_ATTRIBUTE'" value="$EVALUATED_ATTRIBUTE"/>
		<dp:set-variable name="'var://context/ESB_Services/debug/VALIDATION_CODE'" value="string($VALIDATION_CODE)"/>
		
		<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
			<soap:Header>
				<xsl:copy-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[namespace-uri() =
					'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd']"/>
				<xsl:copy-of select="/*[local-name()='Envelope']/*[local-name()='Header']/*[namespace-uri() =
					'http://www.w3.org/2005/08/addressing'][not(self::wsa:MessageID)]"/>
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
	<xsl:template match="saml:AttributeValue" mode="validateAssertions">
		<xsl:param name="EXT_GRP_RESULT"/>
		<xsl:copy>
			<xsl:attribute name="statusCode">
				<xsl:variable name="ASSERTED_GROUP" select="normalize-space(.)"/>
				<xsl:choose>
					<xsl:when test="$EXT_GRP_RESULT/result[normalize-space(attribute-value) = $ASSERTED_GROUP]">
						<xsl:value-of select="'valid'"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'invalid'"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
