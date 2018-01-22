<?xml version="1.0" encoding="UTF-8"?>
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
		2016-02-05	v1.0	Tim Goodwill		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Constants.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="AUTHORIZATION_TOKEN" select="dp:http-request-header('Authorization')"/>
	<xsl:variable name="JWT_TOKEN">
		<xsl:choose>
			<xsl:when test="translate(substring($AUTHORIZATION_TOKEN, 1, 7),'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ') = 'BEARER '">
				<xsl:value-of select="substring-after($AUTHORIZATION_TOKEN, ' ')"/>
			</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="dp:http-request-header($JWT_TOKEN_LABLE)"/>
		</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="identity[@au-success = 'false']">
				<!-- No metadata : An empty output of this XSL means “authentication failure” to the DataPower AAA framework. -->
			</xsl:when>
			<xsl:when test="$JWT_TOKEN = ''">
				<!-- No JWT : An empty output of this XSL means “authentication failure” to the DataPower AAA framework. -->
			</xsl:when>
			<xsl:otherwise>
				<!-- debug vars -->
				<dp:set-variable name="'var://context/Json_RestAPI/debug/identity'" value="container/identity"/>
				<xsl:variable name="STS_VALIDATE_HOSTNAME">
					<xsl:value-of select="dp:variable($DP_SERVICE_DOMAIN_NAME)"/>
				</xsl:variable>
				<xsl:variable name="STS_VALIDATE_ENDPOINT">
					<xsl:value-of select="concat('https://', $STS_VALIDATE_HOSTNAME, ':4444', $STS_VALIDATE_URI)"/>
				</xsl:variable>
				<!-- Delete all existing HTTP request headers -->
				<xsl:variable name="HEADER_MANIFEST" select="dp:variable($DP_SERVICE_HEADER_MANIFEST)"/>
				<xsl:variable name="TIMEOUT_SECONDS" select="'30'"/>
				<!-- Open URL and capture the response -->
				<xsl:variable name="RESPONSE">
					<!-- Make the service call -->
					<dp:url-open target="{$STS_VALIDATE_ENDPOINT}" http-headers="$HEADER_MANIFEST/headers"
						response="binaryNode" timeout="{number($TIMEOUT_SECONDS)}" 
						ssl-proxy="SslClientNoCredentials" content-type="application/json">
						<xsl:value-of select="concat('{ &#34;', $JWT_TOKEN_LABLE, '&#34;: &#34;', $JWT_TOKEN, '&#34; }')"/>
					</dp:url-open>
				</xsl:variable>
				<dp:set-variable name="'var://context/Json_RestAPI/debug/validationResponseRaw'" value="$RESPONSE"/>
				<xsl:choose>
					<!-- Membership of any 'denied' group takes precedence -->
					<xsl:when test="not($RESPONSE/result/binary)">
						<!-- An empty output of this XSL means “authentication failure” to the DataPower AAA framework. -->
						<unauthorised>
							<xsl:text>The presented token could not be validated.</xsl:text>
						</unauthorised>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="JSON_RESPONSE" select="dp:decode( dp:binary-encode($RESPONSE/result/binary/node()), 'base-64')"/>
						<!-- validation success returned as "status":"VALID" eg.
						{ "tokenstatus":{ 
							"status":"VALID", "tokenclaims":{ 
								"iss":"api.dpdirect.org", 
								"sub":"existk", 
								"x-gateway-tokenid":"JWT-3b74526f-45b6-4535-9d09-176af6817244", 
								"iat":1435882117, 
								"nbf":1435882117, 
								"exp":1435910917,
								"aud":[ "https://dpdirect.org" ]
								"x-gateway-ip":"10.92.128.35", 
								"x-gateway-groups":[ "data_compliance_high_summary" ] 
								} 
							}
						} -->
						<!-- validation failure returned as "status":"INVALID" eg.
						{ "tokenstatus":{ 
							"status":"INVALID", 
							"code": "token_invalid"
							}
						} -->
						<xsl:variable name="TOKEN_STATUS" select="normalize-space(substring-before(substring-after(substring-after($JSON_RESPONSE, '&#34;status&#34;'), '&#34;'), '&#34;'))"/>
						<xsl:variable name="VALIDATION_ERROR_CODE" select="normalize-space(substring-before(substring-after(substring-after($JSON_RESPONSE, '&#34;code&#34;'), '&#34;'), '&#34;'))"/>
						<xsl:variable name="USER_NAME" select="normalize-space(substring-before(substring-after(substring-after($JSON_RESPONSE, '&#34;sub&#34;'), '&#34;'), '&#34;'))"/>
						<xsl:variable name="DPDIRECT.GROUPS" select="normalize-space(substring-before(substring-after(substring-after($JSON_RESPONSE, concat('&#34;',$JWT_TOKEN_NS,'-groups&#34;')), '['), ']'))"/>
						<!-- regexp:replace(normalize-space(NamespaceURI), '\*', 'g', '.*'), '$')) -->
						<dp:set-variable name="'var://context/Json_RestAPI/debug/validationResponse'" value="$JSON_RESPONSE"/>
						<dp:set-variable name="$JWT_VALIDATION_ERROR_CODE_VAR_NAME" value="$VALIDATION_ERROR_CODE"/>
						<dp:set-variable name="$REQ_USER_NAME_VAR_NAME" value="$USER_NAME"/>
						<xsl:choose>
							<xsl:when test="contains($VALIDATION_ERROR_CODE, $JWT_EXPIRED_CODE)">
								<!-- An empty output of this XSL means “authentication failure” to the DataPower AAA framework. -->
								<!-- Output a single 'approved' element allowing the subject to proceed to the authorization step -->
								<!-- This element is required by DataPower as the output element for successful authorisation -->
								<unauthorised>
									<xsl:text>The presented token has expired.</xsl:text>
								</unauthorised>
							</xsl:when>
							<xsl:when test="not(translate($TOKEN_STATUS,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ') = $JWT_VALID_RESPONSE)">
								<!-- An empty output of this XSL means “authentication failure” to the DataPower AAA framework. -->
								<!-- Output a single 'approved' element allowing the subject to proceed to the authorization step -->
								<!-- This element is required by DataPower as the output element for successful authorisation -->
								<unauthorised>
									<xsl:text>The presented token is not valid.</xsl:text>
								</unauthorised>
							</xsl:when>
							<xsl:otherwise>
								<!-- Output a single 'approved' element allowing the subject to proceed to the authorization step -->
								<!-- This element is required by DataPower as the output element for successful authorisation -->
								<approved>
									<xsl:text>The presented token is valid.</xsl:text>
								</approved>
								<Attribute>
									<xsl:attribute name="name">
										<xsl:value-of select="'group'"/>
									</xsl:attribute>
									<xsl:attribute name="type">
										<xsl:value-of select="'jwt-attr-name'"/>
									</xsl:attribute>
									<xsl:call-template name="createGroupCollection">
										<xsl:with-param name="GROUP_LIST" select="normalize-space(regexp:replace($DPDIRECT.GROUPS, '&#34;', 'g', ''))"/>
									</xsl:call-template>
								</Attribute>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="createGroupCollection">
		<xsl:param name="GROUP_LIST"/>
		<xsl:variable name="GROUP_NAME">
			<xsl:choose>
				<xsl:when test="contains($GROUP_LIST, ',')">
					<xsl:value-of select="normalize-space(substring-before($GROUP_LIST, ','))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$GROUP_LIST"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<AttributeValue>
			<xsl:value-of select="$GROUP_NAME"/>
		</AttributeValue>
		<xsl:variable name="REMAINING_GROUPS" select="normalize-space(substring-after($GROUP_LIST, ','))"/>
		<xsl:if test="$REMAINING_GROUPS != ''">
			<xsl:call-template name="createGroupCollection">
				<xsl:with-param name="GROUP_LIST" select="$REMAINING_GROUPS"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
