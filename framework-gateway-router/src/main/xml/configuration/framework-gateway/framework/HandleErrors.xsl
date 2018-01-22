<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	extension-element-prefixes="dp regexp" exclude-result-prefixes="dp regexp" version="1.0">
	<!--========================================================================
		History:
		2016-10-03	v0.1			Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->

	<!--============== Output Configuration =========================-->
	<xsl:output method="text"/>
	<!--============== Global Variable Declarations =================-->
	<!--========================================================================
		MATCH TEMPLATES
	========================================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="RESPONSE_CODE" select="dp:variable('var://service/error-protocol-response')"/>
		<xsl:variable name="X_RESPONSE_CODE" select="dp:http-response-header('x-dp-response-code')"/>
		<xsl:variable name="X_BACKSIDE_TRANSPORT" select="dp:http-response-header('X-Backside-Transport')"/>
		<xsl:choose>
			<xsl:when test="$X_RESPONSE_CODE != ''">
				<dp:set-http-response-header name="'x-dp-response-code'" value="'-1 exampleReasonPhrase'"/>
				<dp:append-response-header name="'x-dp-response-code'" value="normalize-space($X_RESPONSE_CODE)"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="substring-before(normalize-space($X_RESPONSE_CODE), ' ')"/>
				<!-- TODO This reason phrase detsil is providecd for POC testing only, must be removed for production services -->
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="substring-after(normalize-space($X_RESPONSE_CODE), ' ')"/>
				<!--<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Internal Error'"/>-->
			</xsl:when>
			<xsl:when test="($RESPONSE_CODE) != '' and ($RESPONSE_CODE) != '0' and ($RESPONSE_CODE) != '200'">
				<dp:set-http-response-header name="'x-dp-response-code'" value="'-1 exampleReasonPhrase'"/>
				<dp:append-response-header name="'x-dp-response-code'" value="normalize-space(concat($RESPONSE_CODE, ' ', dp:variable('var://service/error-message')))"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="normalize-space($RESPONSE_CODE)"/>
				<!-- TODO This reason phrase detsil is providecd for POC testing only, must be removed for production services -->
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="dp:variable('var://service/error-message')"/>
				<!--<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Internal Error'"/>-->
			</xsl:when>
			<xsl:when test="($RESPONSE_CODE = '') or contains($X_BACKSIDE_TRANSPORT, 'FAIL')">
				<dp:set-http-response-header name="'x-dp-response-code'" value="'-1 exampleReasonPhrase'"/>
				<dp:append-response-header name="'x-dp-response-code'" value="'500 Error'"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="'500'"/>
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Error'"/>
			</xsl:when>
		</xsl:choose>
		<dp:set-variable name="'var://context/Gateway_Router/RESPONSE_CODE'" value="string($RESPONSE_CODE)"/>
		<dp:set-variable name="'var://context/Gateway_Router/X_RESPONSE_CODE'" value="string($X_RESPONSE_CODE)"/>
		<!-- CORS support -->
		<dp:set-http-response-header name="'Access-Control-Allow-Origin'" value="'*'"/>
	</xsl:template>
</xsl:stylesheet>
