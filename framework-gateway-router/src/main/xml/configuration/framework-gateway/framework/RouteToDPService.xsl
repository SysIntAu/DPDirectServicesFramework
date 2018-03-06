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
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	extension-element-prefixes="dp regexp" exclude-result-prefixes="dp regexp wsa" version="1.0">
	<!--========================================================================
		History:
		2016-12-12	v0.1		Tim Goodwill	Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->

	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="DP_SERVICE_URL_IN" select="'var://service/URL-in'"/>
	<xsl:variable name="DP_SERVICE_LOCAL_SERVICE_ADDRESS" select="'var://service/local-service-address'"/>
	<xsl:variable name="DP_SERVICE_ROUTING_URL" select="'var://service/routing-url'"/>
	<xsl:variable name="DP_PROTOCOL_METHOD" select="'var://service/protocol-method'"/>
	<xsl:variable name="GATEWAY_ROUTER_ROOT_FOLDER" select="'local:///framework-gateway-router/'"/>
	<xsl:variable name="ROUTING_DOC"
		select="document(concat($GATEWAY_ROUTER_ROOT_FOLDER,'config/Gateway_Router_V1_ServiceRoute.xml'))"/>
	<xsl:variable name="WSA_ACTION" select="normalize-space(/*[local-name() = 'Envelope'][1]/*[local-name() =
		'Header'][1]/wsa:Action[1])"/>
	<xsl:variable name="INPUT_URI" select="concat('/', substring-after(substring-after(dp:variable($DP_SERVICE_URL_IN), '//'), '/'))"/>
	<xsl:variable name="INPUT_PORT"
		select="normalize-space(substring-after(dp:variable($DP_SERVICE_LOCAL_SERVICE_ADDRESS),':'))"/>
	<!--========================================================================
		MATCH TEMPLATES
	========================================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Debug vars -->
<!--		<dp:set-variable name="'var://context/framework-gateway-router/debug/action'" value="string($WSA_ACTION)"/>
		<dp:set-variable name="'var://context/framework-gateway-router/debug/uri'" value="string($INPUT_URI)"/>-->
		<xsl:choose>
			<xsl:when test="$WSA_ACTION != ''">
				<xsl:variable name="ROUTING_IDENTIFIER">
					<xsl:choose>
						<xsl:when test="$ROUTING_DOC//InputMatchCriteria[Action = $WSA_ACTION]">
							<xsl:copy-of select="$ROUTING_DOC//InputMatchCriteria[Action = $WSA_ACTION]"/>
						</xsl:when>
					</xsl:choose>	
				</xsl:variable>
				<xsl:if test="not($ROUTING_IDENTIFIER/InputMatchCriteria)">
					<dp:set-http-response-header name="'x-dp-response-code'" value="'404 Not Found'" />
					<dp:set-variable name="'var://service/error-protocol-response'" value="404"/>
					<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Not Found'"/>
					<dp:reject>Not Found</dp:reject>
				</xsl:if>
				<xsl:variable name="ROUTING_ADDRESS">
					<xsl:choose>
						<xsl:when test="$ROUTING_IDENTIFIER//HTTPSPort">
							<xsl:value-of select="'https://'"/>
							<xsl:value-of select="($ROUTING_IDENTIFIER/InputMatchCriteria[//HTTPSPort])[1]/LocalHostAlias"/>
							<xsl:value-of select="':'"/>
							<xsl:value-of select="($ROUTING_IDENTIFIER//HTTPSPort)[1]"/>
							<xsl:value-of select="($ROUTING_IDENTIFIER/InputMatchCriteria[//HTTPSPort])[1]//InboundURI[1]"/>
						</xsl:when>
						<xsl:when test="$ROUTING_IDENTIFIER//HTTPPort">
							<xsl:value-of select="'http://'"/>
							<xsl:value-of select="($ROUTING_IDENTIFIER/InputMatchCriteria[//HTTPPort])[1]/LocalHostAlias"/>
							<xsl:value-of select="':'"/>
							<xsl:value-of select="($ROUTING_IDENTIFIER//HTTPPort)[1]"/>
							<xsl:value-of select="($ROUTING_IDENTIFIER/InputMatchCriteria[//HTTPPort])[1]//InboundURI[1]"/>
						</xsl:when>
					</xsl:choose>
				</xsl:variable>
				<!-- Debug vars -->
<!--				<dp:set-variable name="'var://context/framework-gateway-router/debug/ROUTING_IDENTIFIER'" value="$ROUTING_IDENTIFIER"/>
				<dp:set-variable name="'var://context/framework-gateway-router/debug/ROUTING_ADDRESS'" value="normalize-space($ROUTING_ADDRESS)"/>-->
				<!-- Construct web service request from service metadata configuration -->
				<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="normalize-space($ROUTING_ADDRESS)"/>
				<!-- Set http Connection header to 'close' -->
				<dp:set-http-request-header name="'Connection'" value="'close'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="ROUTING_IDENTIFIER">
					<!--<xsl:copy-of select="$ROUTING_DOC//InputMatchCriteria[not(Action)][regexp:match($INPUT_URI, concat('^', regexp:replace(InputMatchCriteria/InboundURI/text(), '\*', 'g', '.*'), '$'))  != '']"/>-->
					<xsl:copy-of select="$ROUTING_DOC//InputMatchCriteria[regexp:match($INPUT_URI, concat('^', regexp:replace(InboundURI/text(), '\*', 'g', '.*'), '$'))  != '']"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="not($ROUTING_IDENTIFIER/InputMatchCriteria)">
						<dp:set-http-response-header name="'x-dp-response-code'" value="'404 Not Found'" />
						<dp:set-variable name="'var://service/error-protocol-response'" value="404"/>
						<dp:set-variable name="'var://service/error-protocol-reason-phrase'" value="'Not Found'"/>
						<dp:reject>Not Found</dp:reject>
					</xsl:when>
					<xsl:when test="normalize-space(dp:variable($DP_PROTOCOL_METHOD)) = 'OPTIONS'">
						<!-- CORS support -->
						<xsl:variable name="DP_HOST_ALIAS" select="normalize-space(dp:variable('var://service/domain-name'))"/>
						<xsl:variable name="LOOPBACK_PROXY" select="concat('http://', $DP_HOST_ALIAS, ':10000')"/>
						<xsl:variable name="ORIGIN">
							<xsl:value-of select="dp:http-request-header('Origin')"/>
						</xsl:variable>
						<xsl:variable name="AC_REQ_HEADERS">
							<xsl:value-of select="dp:http-request-header('Access-Control-Request-Headers')"/>
						</xsl:variable>
						<dp:set-http-response-header name="'Access-Control-Allow-Origin'" value="'*'"/>
						<dp:set-http-response-header name="'Access-Control-Allow-Methods'" value="'GET, PUT, POST, DELETE, OPTIONS'"/>
						<xsl:if test="normalize-space($AC_REQ_HEADERS) != ''">
							<dp:set-http-response-header name="'Access-Control-Allow-Headers'" value="$AC_REQ_HEADERS"/>
						</xsl:if>
						<dp:set-variable name="$DP_PROTOCOL_METHOD" value="'POST'"/>
						<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$LOOPBACK_PROXY"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="ROUTING_ADDRESS">
							<xsl:choose>
								<xsl:when test="$ROUTING_IDENTIFIER//HTTPSPort">
									<xsl:value-of select="'https://'"/>
									<xsl:value-of select="($ROUTING_IDENTIFIER/InputMatchCriteria[//HTTPSPort])[1]/LocalHostAlias"/>
									<xsl:value-of select="':'"/>
									<xsl:value-of select="($ROUTING_IDENTIFIER//HTTPSPort)[1]"/>
									<xsl:value-of select="$INPUT_URI"/>
								</xsl:when>
								<xsl:when test="$ROUTING_IDENTIFIER//HTTPPort">
									<xsl:value-of select="'http://'"/>
									<xsl:value-of select="($ROUTING_IDENTIFIER/InputMatchCriteria[//HTTPPort])[1]/LocalHostAlias"/>
									<xsl:value-of select="':'"/>
									<xsl:value-of select="($ROUTING_IDENTIFIER//HTTPPort)[1]"/>
									<xsl:value-of select="$INPUT_URI"/>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<!-- Construct web service request from service metadata configuration -->
						<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="normalize-space($ROUTING_ADDRESS)"/>
						<!-- Set http Connection header to 'close' -->
						<dp:set-http-request-header name="'Connection'" value="'close'"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
