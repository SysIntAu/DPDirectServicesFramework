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
	extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
	<!--========================================================================
		History:
		2016-12-12	v0.1			Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:import href="Constants.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output method="text"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="UNAUTHORISED">
		<unauthorised/>
	</xsl:variable>
	<xsl:variable name="PROCESS_HRESPONSE_HEADERS">
		<xsl:apply-templates select="$UNAUTHORISED"/>
	</xsl:variable>
	<!--========================================================================
		MATCH TEMPLATES
	========================================================================-->
	<!-- Root Template -->
	<xsl:template match="/"> 
		<xsl:variable name="RESPONSE_CODE" select="dp:variable('var://service/error-protocol-response')"/>
		<dp:set-variable name="'var://context/Json_RestAPI/debug/responseCode'" value="string($RESPONSE_CODE)"/>
		<xsl:choose>
			<xsl:when test="contains(normalize-space(dp:variable('var://context/WSM/identity/authenticated-user')), 'token has expired') or
				contains(normalize-space(dp:variable('var://context/WSM/identity/credentials')), 'token has expired')">
				<xsl:variable name="VALIDATION_ERROR_TEXT" select="normalize-space(dp:variable($JWT_VALIDATION_ERROR_CODE_VAR_NAME))"/>
				<xsl:text>{ "error": "</xsl:text>
				<xsl:value-of select="$VALIDATION_ERROR_TEXT"/>
				<xsl:text>" }</xsl:text>
				<dp:set-http-response-header name="'x-dp-response-code'" value="'-1 exampleReasonPhrase'"/>
				<dp:append-response-header name="'x-dp-response-code'" value="'401 Token Expired'"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="'401'"/>
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Token Expired'"/>
			</xsl:when>
			<xsl:when test="contains(normalize-space(dp:variable('var://context/WSM/identity/authenticated-user')), 'not valid') or
				contains(normalize-space(dp:variable('var://context/WSM/identity/credentials')), 'not valid')">
<!--				<xsl:if test="normalize-space(dp:variable($JWT_VALIDATION_ERROR_CODE_VAR_NAME)) != ''">
					<xsl:text>{ "error": "</xsl:text>
					<xsl:value-of select="normalize-space(dp:variable($JWT_VALIDATION_ERROR_CODE_VAR_NAME))"/>
					<xsl:text>" }</xsl:text>
				</xsl:if>-->
				<dp:set-http-response-header name="'x-dp-response-code'" value="'-1 exampleReasonPhrase'"/>
				<dp:append-response-header name="'x-dp-response-code'" value="'401 Unauthorized'"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="'401'"/>
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Unauthorized'"/>
			</xsl:when>
			<!-- No token provided, or no user identified -->
			<xsl:when test="(normalize-space(dp:variable('var://context/WSM/resource/extracted-resource')) != '')
				and (normalize-space(dp:variable('var://context/WSM/identity/authenticated-user')) = '')">
				<dp:set-http-response-header name="'x-dp-response-code'" value="'-1 exampleReasonPhrase'"/>
				<dp:append-response-header name="'x-dp-response-code'" value="'401 Unauthorized'"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="'401'"/>
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Unauthorized'"/>
<!--				<dp:append-response-header name="'x-dp-response-code'" value="'500 Error'"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="'500'"/>
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Error'"/>-->
			</xsl:when>
			<xsl:when test="$RESPONSE_CODE = ''">
				<dp:set-http-response-header name="'x-dp-response-code'" value="'-1 exampleReasonPhrase'"/>
				<dp:append-response-header name="'x-dp-response-code'" value="'500 Error'"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="'500'"/>
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Error'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="X_RESP_CODE" select="normalize-space(concat('500', ' ', dp:variable('var://service/error-message')))"/>
				<dp:set-http-response-header name="'x-dp-response-code'" value="'-1 exampleReasonPhrase'"/>
				<dp:append-response-header name="'x-dp-response-code'" value="$X_RESP_CODE"/>
				<dp:set-variable name="'var://service/error-protocol-response'" value="'500'"/>
				<!-- TODO This reason phrase detsil is providecd for POC testing only, must be removed for production services -->
				<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="dp:variable('var://service/error-message')"/>
				<!--<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Internal Error'"/>-->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
