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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions" extension-element-prefixes="dp regexp" exclude-result-prefixes="dp regexp"
	version="1.0">
	<!--========================================================================
		History:
		2016-12-12	v0.1			Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output method="text"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="JSONX_TO_JSON_XSL_LOCATION" select="'store:///jsonx2json.xsl'"/>
	<xsl:variable name="DEFAULT_TIMEOUT_SECONDS" select="30"/>
	<xsl:variable name="PROXY_NAME" select="normalize-space(dp:variable($DP_SERVICE_PROCESSOR_NAME))"/>
	<xsl:variable name="CONFIG_DOC" select="document(concat($JSON_RESTAPI_ROOT_FOLDER,'config/',$PROXY_NAME,'_ServiceConfig.xml'))"/>
	<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
	<!-- SOAP config stylesheet -->
	<xsl:variable name="SOAP_XSLT_LOCATION"
		select="normalize-space($SERVICE_METADATA/OperationConfig[1]/BackendRouting[1]/SOAPConfig[1])"/>
	<!-- Backend STUB stylesheet -->
	<xsl:variable name="BACKEND_STUB_LOCATION"
		select="normalize-space($SERVICE_METADATA/OperationConfig[1]/BackendRouting[1]/BackendStub[1])"/>
	<!--========================================================================
		MATCH TEMPLATES
	========================================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="INPUT_URI" select="string(dp:variable('var://service/URI'))"/>
		<xsl:variable name="INPUT_PORT" select="normalize-space(substring-after(dp:variable($DP_SERVICE_LOCAL_SERVICE_ADDRESS),':'))"/>
		<!-- Save Service Metadata with additional backend routing removed -->
		<dp:set-variable name="$SERVICE_METADATA_CONTEXT_NAME" value="$SERVICE_METADATA"/>
		<!-- Save provider name to the environment -->
		<dp:set-variable name="$OPERATION_CONFIG_PROVIDER_VAR_NAME" value="string(($SERVICE_METADATA/OperationConfig/BackendRouting)[1]/@provider)"/>
		<!-- Determine BackendRouting Configuration-->
		<xsl:variable name="BACKEND_ROUTING">
			<xsl:choose>
				<xsl:when test="$SERVICE_METADATA/OperationConfig[1]/BackendRouting[1]/BackendStub">
					<xsl:variable name="DP_ECHO_ENDPOINT">
						<xsl:call-template name="GetDPDirectProperty">
							<xsl:with-param name="KEY" select="concat($DPDIRECT.PROP_URI_PREFIX,'echoHttpEndpoint')"/>
						</xsl:call-template>
					</xsl:variable>
					<BackendRouting provider="MSG">
						<HTTPEndpoint>
							<Address><xsl:value-of select="$DP_ECHO_ENDPOINT"/></Address>
						</HTTPEndpoint>
					</BackendRouting>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$SERVICE_METADATA/OperationConfig[1]/BackendRouting[1]"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- <dp:set-variable name="'var://context/Json_RestAPI/debug/backendRouting'" value="$BACKEND_ROUTING/BackendRouting[1]"/>-->
		<!-- Timeout for the backend response -->
		<xsl:variable name="TIMEOUT_SECONDS">
			<xsl:choose>
				<!-- Source timeout value from the service policy configuration when provided -->
				<xsl:when test="$BACKEND_ROUTING/BackendRouting[1]/TimeoutSeconds[1]">
					<xsl:value-of select="$BACKEND_ROUTING/BackendRouting[1]/TimeoutSeconds[1]"/>
				</xsl:when>
				<!-- Otherwise use default timeout value -->
				<xsl:otherwise>
					<xsl:value-of select="$DEFAULT_TIMEOUT_SECONDS"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Set the back end URL -->
		<xsl:variable name="BACK_END_URL" select="$BACKEND_ROUTING/BackendRouting[1]/HTTPEndpoint[1]/Address"/>
		<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="concat($BACK_END_URL, $INPUT_URI)"/>
		<!-- Set the backend timeout -->
		<dp:set-variable name="$DP_SERVICE_BACKEND_TIMEOUT" value="$TIMEOUT_SECONDS"/>
		<!-- Delete all existing HTTP request headers -->
		<dp:remove-http-request-header name="{$JWT_TOKEN_LABLE}"/>
		<dp:remove-http-request-header name="Authorization"/>
<!--		<xsl:variable name="HEADER_MANIFEST" select="dp:variable($DP_SERVICE_HEADER_MANIFEST)"/>
		<xsl:for-each select="$HEADER_MANIFEST/headers/header">
			<dp:remove-http-request-header name="{normalize-space(.)}"/>
		</xsl:for-each>-->
		<!-- Set headers -->
		<xsl:choose>
			<xsl:when test="$BACKEND_ROUTING/BackendRouting[1]/HTTPEndpoint[1]/HeaderList">
				<xsl:for-each select="$BACKEND_ROUTING/BackendRouting[1]/HTTPEndpoint[1]/HeaderList/Header">
					<xsl:variable name="NAME" select="normalize-space(@name)"/>
					<xsl:variable name="VALUE" select="normalize-space(@value)"/>
					<xsl:choose>
						<xsl:when test="($NAME = 'callerName') and ($VALUE = '*')">
							<xsl:variable name="USER_NAME" select="dp:variable($REQ_USER_NAME_VAR_NAME)"/>
							<dp:set-http-request-header name="$NAME" value="$USER_NAME"/>
						</xsl:when>
						<xsl:otherwise>
							<dp:set-http-request-header name="$NAME" value="$VALUE"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<dp:set-http-request-header name="Connection" value="'close'"/>
				<dp:set-http-request-header name="Content-type" value="'application/json'"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="$SOAP_XSLT_LOCATION != ''">
				<xsl:variable name="RESULT_NODE" select="dp:transform($SOAP_XSLT_LOCATION,.)"/>
				<xsl:choose>
					<xsl:when test="$BACKEND_STUB_LOCATION != ''">
						<xsl:variable name="STUB_NODE" select="dp:transform($BACKEND_STUB_LOCATION,$RESULT_NODE)"/>
						<dp:set-variable name="$RESULT_DOC_CONTEXT_NAME" value="$STUB_NODE"/>
					</xsl:when>
					<xsl:otherwise>
						<dp:set-variable name="$RESULT_DOC_CONTEXT_NAME" value="$RESULT_NODE"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$BACKEND_STUB_LOCATION != ''">
				<xsl:variable name="STUB_NODE" select="dp:transform($BACKEND_STUB_LOCATION,.)"/>
				<dp:set-variable name="$RESULT_DOC_CONTEXT_NAME" value="$STUB_NODE"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
