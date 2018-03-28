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
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	extension-element-prefixes="dp regexp" exclude-result-prefixes="dp regexp" version="1.0">
	<!--========================================================================
		History:
		2016-12-12	v0.1		Tim Goodwill	Initial Version.
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
		<dp:set-variable name="'var://context/framework-gateway-router/RESPONSE_CODE'" value="string($RESPONSE_CODE)"/>
		<dp:set-variable name="'var://context/framework-gateway-router/X_RESPONSE_CODE'" value="string($X_RESPONSE_CODE)"/>
		<!-- CORS support -->
		<dp:set-http-response-header name="'Access-Control-Allow-Origin'" value="'*'"/>
	</xsl:template>
</xsl:stylesheet>
