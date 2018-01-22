<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:date="http://exslt.org/dates-and-times" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" extension-element-prefixes="dp">
	<xsl:import href="local:///SecureTokenService/common/Utils.xsl"/>
	<!-- Default timestamp duration (8hours) -->
	<xsl:variable name="TOKEN_LIFE" select="8*3600"/>
	<xsl:variable name="IAT_TIME" select="date:seconds()"/>
	<xsl:variable name="EXP_TIME" select="$IAT_TIME + $TOKEN_LIFE"/>
	<xsl:variable name="JWT_TOKEN_ID" select="concat('JWT-',dp:generate-uuid())"/>
	<xsl:variable name="AUTHENTICATED_USER" select="dp:variable('var://context/WSM/identity/authenticated-user')"/>
	<!-- The attribute statement is generated in the Authorise Step of the AAA Action.
    It is actually a SAML Attribute at this point. Must be converted to a JSON Structure-->
	<xsl:variable name="SAML_ATTRIBUTE_STATEMENT" select="dp:variable('var://context/service/groupattributes')"/>
<!--	<xsl:variable name="GROUPS">
		<xsl:call-template name="buildArray">
			<xsl:with-param name="ARRAYLIST" select="$SAML_ATTRIBUTE_STATEMENT"/>
		</xsl:call-template>
	</xsl:variable>-->
	<xsl:variable name="TOKEN_TYPE" select="'JWT'"/>
	<xsl:variable name="TOKEN_ISSUER" select="'api.dpdirect.org'"/>
	<xsl:variable name="IP_ADDRESS" select="dp:variable('var://service/transaction-client')"/>
	<xsl:variable name="STS_HOST_ALIAS" select="dp:variable($DP_SERVICE_DOMAIN_NAME)"/>
	<xsl:variable name="STS_BASE_ADDR" select="concat('https://', $STS_HOST_ALIAS)"/>
	<xsl:variable name="TOKEN_ALG" select="'HS256'"/>
	<xsl:output omit-xml-declaration="yes"/>
	<xsl:template match="/">
		<!-- Generate the header and claims as text -->
		<xsl:variable name="JWT_HEADER">
			<xsl:call-template name="buildHeader"/>
		</xsl:variable>
		<xsl:variable name="JWT_CLAIMS">
			<xsl:call-template name="buildClaims"/>
		</xsl:variable>
		<!-- the JWS Payload is what we need to sign -->
		<xsl:variable name="JWT_PAYLOAD" select="concat($JWT_HEADER, '.', $JWT_CLAIMS)"/>
		<!-- Sign the Payload -->
		<xsl:variable name="SIGNATURE">
			<xsl:call-template name="signJwtToken">
				<xsl:with-param name="PAYLOAD" select="$JWT_PAYLOAD"/>
			</xsl:call-template>
		</xsl:variable>
		<!-- output the payload -->
		<xsl:variable name="CREATED_TOKEN">
			<xsl:call-template name="JsonxToJson">
				<xsl:with-param name="JSONX_NODE_SET">
					<json:object xsi:schemaLocation="http://www.datapower.com/schemas/json jsonx.xsd"
						xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
						<json:string name="status">OK</json:string>
						<json:string name="{$JWT_TOKEN_LABLE}">
							<xsl:value-of select="concat($JWT_PAYLOAD, '.', $SIGNATURE)"/>
						</json:string>
					</json:object>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<dp:set-variable name="'var://context/service/createdtoken'" value="string($CREATED_TOKEN)"/>
	</xsl:template>
	<xsl:template name="buildHeader">
		<xsl:call-template name="base64UrlEncode">
			<xsl:with-param name="PAYLOAD">
				<xsl:call-template name="JsonxToJson">
					<xsl:with-param name="JSONX_NODE_SET">
						<json:object xsi:schemaLocation="http://www.datapower.com/schemas/json jsonx.xsd"
							xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
							<json:string name="type">
								<xsl:value-of select="$TOKEN_TYPE"/>
							</json:string>
							<json:string name="alg">
								<xsl:value-of select="$TOKEN_ALG"/>
							</json:string>
						</json:object>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="buildClaims">
		<xsl:call-template name="base64UrlEncode">
			<xsl:with-param name="PAYLOAD">
				<xsl:call-template name="JsonxToJson">
					<xsl:with-param name="JSONX_NODE_SET">
						<json:object xsi:schemaLocation="http://www.datapower.com/schemas/json jsonx.xsd"
							xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
							<json:string name="iss">
								<xsl:value-of select="$TOKEN_ISSUER"/>
							</json:string>
							<json:string name="sub">
								<xsl:value-of select="$AUTHENTICATED_USER"/>
							</json:string>
							<json:number name="iat">
								<xsl:value-of select="$IAT_TIME"/>
							</json:number>
							<json:number name="nbf">
								<xsl:value-of select="$IAT_TIME"/>
							</json:number>
							<json:number name="exp">
								<xsl:value-of select="$EXP_TIME"/>
							</json:number>
							<json:array name="aud">
								<json:string><xsl:value-of select="$GATEWAY_BASE_ADDR"/></json:string>
								<json:string><xsl:value-of select="$STS_BASE_ADDR"/></json:string>
							</json:array>
							<json:string name="{concat($JWT_TOKEN_NS, '-tokenid')}">
								<xsl:value-of select="$JWT_TOKEN_ID"/>
							</json:string>
							<json:string name="{concat($JWT_TOKEN_NS, '-ip')}">
								<xsl:value-of select="$IP_ADDRESS"/>
							</json:string>
							<json:array name="{concat($JWT_TOKEN_NS, '-groups')}">
								<xsl:for-each select="$SAML_ATTRIBUTE_STATEMENT/saml:Attribute[@name='group']/*">
									<json:string>
										<xsl:value-of select="."/>
									</json:string>
								</xsl:for-each>
							</json:array>
						</json:object>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
</xsl:stylesheet>
