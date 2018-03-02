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
	xmlns:os="urn:oasis:names:tc:xacml:2.0:policy:schema:os" 
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:wst="http://docs.oasis-open.org/ws-sx/ws-trust/200512/"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	extension-element-prefixes="dp regexp" exclude-result-prefixes="dp regexp os wsse wst wsa saml"
	version="1.0">
	<!--========================================================================
		Purpose:Performs authorisation against a local XACML policy file
		
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="SAML_VALID_RESPONSE" select="'http://docs.oasis-open.org/ws-sx/ws-trust/200512/status/valid'"/>
	<xsl:variable name="REQ_WSA_MSG_ID" select="normalize-space(dp:variable($REQ_WSA_MSG_ID_VAR_NAME))"/>
	<xsl:variable name="STS_VALIDATE_URI" select="'/STS'"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="identity[@au-success = 'false']">
				<!-- An empty output of this XSL means “authentication failure” to the DataPower AAA framework. -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="WSSE_SECURITY_HEADER"
					select="identity/entry/token/wsse:Security"/>
				<!-- debug vars -->
				<dp:set-variable name="'var://context/ESB_Services/debug/identity'" value="container/identity"/>
				<dp:set-variable name="'var://context/ESB_Services/debug/WSSE_SECURITY_HEADER'" value="$WSSE_SECURITY_HEADER"/>
				<xsl:variable name="STS_VALIDATE_MSG">
					<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
						xmlns:dp="http://www.datapower.com/schemas/management">
						<soap:Header>
							<xsl:copy-of select="$WSSE_SECURITY_HEADER"/>
							<wsa:MessageID>
								<xsl:value-of select="$REQ_WSA_MSG_ID"/>
							</wsa:MessageID>
							<wsa:Action>
								<xsl:value-of select="'http://docs.oasis-open.org/ws-sx/ws-trust/200512/RST/Validate'"/>
							</wsa:Action>
						</soap:Header>
						<soap:Body>
							<ws-t:RequestSecurityToken xmlns:ws-t="http://docs.oasis-open.org/ws-sx/ws-trust/200512/">
								<ws-t:TokenType>http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0</ws-t:TokenType>
								<ws-t:ValidateTarget>
									<wsse:SecurityTokenReference>
										<wsse:Reference>
											<xsl:attribute name="URI">
												<xsl:value-of select="concat('#',$WSSE_SECURITY_HEADER//saml:Assertion/@ID)"/>
											</xsl:attribute>
										</wsse:Reference>
									</wsse:SecurityTokenReference>
								</ws-t:ValidateTarget>
								<ws-t:RequestType>http://docs.oasis-open.org/ws-sx/ws-trust/200512/Validate</ws-t:RequestType>
							</ws-t:RequestSecurityToken>
						</soap:Body>
					</soap:Envelope>
				</xsl:variable>
				<xsl:variable name="STS_VALIDATE_HOSTNAME">
					<xsl:value-of select="dp:variable($DP_SERVICE_DOMAIN_NAME)"/>
				</xsl:variable>
				<xsl:variable name="STS_VALIDATE_ENDPOINT">
					<xsl:value-of select="concat('https://', $STS_VALIDATE_HOSTNAME, ':4443', $STS_VALIDATE_URI)"/>
				</xsl:variable>
				<!-- Delete all existing HTTP request headers -->
				<xsl:call-template name="DeleteHttpRequestHeaders"/>
				<xsl:variable name="HEADER_LIST">
					<HeaderList>
						<Header name="Connection" value="close"/>
						<Header name="SOAPAction" value=""/>
						<Header name="Content-type" value="text/xml"/>
					</HeaderList>
				</xsl:variable>
				<xsl:variable name="HTTP_HEADERS">
					<xsl:for-each
						select="$HEADER_LIST/HeaderList/Header">
						<xsl:variable name="NAME" select="normalize-space(@name)"/>
						<xsl:variable name="VALUE" select="normalize-space(@value)"/>
						<header name="{$NAME}">
							<xsl:value-of select="$VALUE"/>
						</header>
						<dp:set-http-request-header name="$NAME" value="$VALUE"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="TIMEOUT_SECONDS" select="'30'"/>
				<!-- Open URL and capture the response -->
				<xsl:variable name="RESPONSE">
					<!-- Make the service call -->
					<dp:url-open target="{$STS_VALIDATE_ENDPOINT}" http-headers="$HTTP_HEADERS"
						response="responsecode" timeout="{number($TIMEOUT_SECONDS)}" 
						ssl-proxy="SslClientNoCredentials" content-type="text/xml">
						<xsl:copy-of select="$STS_VALIDATE_MSG"/>
					</dp:url-open>
				</xsl:variable>
				<dp:set-variable name="$AUTHZ_RESULT_SET_VAR_NAME" value="$RESPONSE/url-open/response/*"/>
				<xsl:choose>
					<!-- Membership of any 'denied' group takes precedence -->
					<xsl:when test="not($RESPONSE/url-open/response//wst:Status/wst:Code)">
						<!-- An empty output of this XSL means “authentication failure” to the DataPower AAA framework. -->
						<!-- Reject to error flow for error handling/mapping -->
						<xsl:call-template name="RejectToErrorFlow">
							<!-- Do not log in prod -->
							<xsl:with-param name="MSG">
								<xsl:text>The presented SAML assertion could not be validated.</xsl:text>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'ENTR00011'"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="($RESPONSE/url-open/response)//wst:Status/wst:Code[1] != $SAML_VALID_RESPONSE">
						<!-- An empty output of this XSL means “authentication failure” to the DataPower AAA framework. -->
						<!-- Reject to error flow for error handling/mapping -->
						<xsl:call-template name="RejectToErrorFlow">
							<!-- Do not log in prod -->
							<xsl:with-param name="MSG">
								<xsl:text>The presented SAML assertion is not valid.</xsl:text>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'ENTR00011'"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- Output a single 'approved' element allowing the subject to proceed to the authorization step -->
						<!-- This element is required by DataPower as the output element for successful authorisation -->
						<approved>
							<xsl:text>The presented SAML assertion is valid.</xsl:text>
						</approved>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
