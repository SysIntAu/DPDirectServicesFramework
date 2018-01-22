<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
	xmlns:date="http://exslt.org/dates-and-times" xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp"
	version="1.0">
	<!--========================================================================
		History:
		2016-10-03	v0.1			Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///SecureTokenService/common/Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output method="text"/>
	<!--========================================================================
		MATCH TEMPLATES
	========================================================================-->
	<xsl:template match="/">
		<xsl:variable name="AUTHORIZATION_TOKEN">
			<xsl:choose>
				<xsl:when test="dp:http-request-header('Authorization') != ''">
					<xsl:value-of  select="dp:http-request-header('Authorization')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of  select="json:object/json:string[@name='Authorization']"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="JWT_TOKEN">
			<xsl:choose>
				<xsl:when test="translate(substring($AUTHORIZATION_TOKEN, 7),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ') = 'BEARER '">
					<xsl:value-of select="substring-after($AUTHORIZATION_TOKEN, ' ')"/>
				</xsl:when>
				<xsl:when test="dp:http-request-header($JWT_TOKEN_LABLE) != ''">
					<xsl:value-of  select="dp:http-request-header($JWT_TOKEN_LABLE)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="json:object/json:string[@name=$JWT_TOKEN_LABLE]"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="'var://context/service/JWT_TOKEN'" value="string($JWT_TOKEN)"/>
		<!-- Extract Components of Token-->
		<xsl:variable name="JWT_HEADER">
			<xsl:call-template name="getJwtHeader">
				<xsl:with-param name="TOKEN" select="$JWT_TOKEN"/>
			</xsl:call-template>
		</xsl:variable>
		<dp:set-variable name="'var://context/service/JWT_HEADER'" value="string($JWT_HEADER)"/>
		<xsl:variable name="JWT_CLAIMS">
			<xsl:call-template name="getJwtClaims">
				<xsl:with-param name="TOKEN" select="$JWT_TOKEN"/>
			</xsl:call-template>
		</xsl:variable>
		<dp:set-variable name="'var://context/service/JWT_CLAIMS'" value="string($JWT_CLAIMS)"/>
		<xsl:variable name="JWT_SIGNATURE">
			<xsl:call-template name="getJwtSignature">
				<xsl:with-param name="TOKEN" select="$JWT_TOKEN"/>
			</xsl:call-template>
		</xsl:variable>
		<dp:set-variable name="'var://context/service/JWT_SIGNATURE'" value="string($JWT_SIGNATURE)"/>
		<dp:set-variable name="'var://context/service/TOKEN'" value="$JWT_TOKEN"/>
		<!-- Decode the Claims and use them as the INPUT Context to the next step -->
		<xsl:variable name="DECODED_CLAIMS">
			<xsl:call-template name="base64UrlDecode">
				<xsl:with-param name="PAYLOAD" select="$JWT_CLAIMS"/>
			</xsl:call-template>
		</xsl:variable>
		<dp:set-variable name="'var://context/service/DECODED'" value="string($DECODED_CLAIMS)"/>
		<!-- Output the decoded claims (Json) -->
		<xsl:value-of select="string($DECODED_CLAIMS)"/>
	</xsl:template>
</xsl:stylesheet>
