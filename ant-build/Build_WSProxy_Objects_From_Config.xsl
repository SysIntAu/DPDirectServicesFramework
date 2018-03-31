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
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:wsoap11="http://schemas.xmlsoap.org/wsdl/soap/"
	xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12/"
	xmlns:exslt="http://exslt.org/common"
	extension-element-prefixes="exslt wsoap11 wsoap12 xsi" version="1.0">
	<!--========================================================================
		History:
		2016-12-12	v0.1	Tim Goodwill	Initial Version.
		========================================================================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="yes" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:param name="SERVICE_CONFIG_FILE_PATH" select="''"/>
	<!--<xsl:variable name="SERVICE_CONFIG_FILE_DOC" select="document('C:/Projects/DPDirectServicesFramework/target/release/local/framework-soa-esb/config/PoliceCheckResultRetrievalService_ServicesProxy_V1_ServiceConfig.xml')"/>-->
	<xsl:variable name="SERVICE_CONFIG_FILE_DOC" select="document($SERVICE_CONFIG_FILE_PATH)"/>
	<!-- WSDL must path must contain the path elements .../WSDL/Vx.0/WsdlName.wsdl -->
	<xsl:variable name="WSDL_DP_PATH" select="string($SERVICE_CONFIG_FILE_DOC/ServiceConfig/@wsdlLocation[1])"/>
	<xsl:variable name="WSDL_NAME">
		<xsl:call-template name="SubstringAfterLast">
			<xsl:with-param name="STRING" select="$WSDL_DP_PATH"/>
			<xsl:with-param name="DELIMITER" select="'/'"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="SERVICES_STREAM">
		<xsl:choose>
			<xsl:when test="contains($WSDL_NAME,'_ServicesProxy')">
				<xsl:value-of select="substring-before($WSDL_NAME, '_ServicesProxy')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring-before($WSDL_NAME, '.wsdl')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="WSDL_BUILD_PATH" select="concat('../local/', substring-after($WSDL_DP_PATH, 'local:///'))"/>
	<xsl:variable name="WSDL_DOC" select="document($WSDL_BUILD_PATH)"/>
	<xsl:variable name="WSDL_NAMESPACE" select="string($WSDL_DOC//*[local-name() = 'definitions'][1]/@targetNamespace)"/>
	<xsl:variable name="WSDL_SOAP_VERSION">
		<xsl:choose>
			<xsl:when test="$WSDL_DOC//*[local-name() = 'definitions']/*[local-name() = 'binding']/wsoap11:binding">
				<xsl:value-of select="'soap-11'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'soap-12'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="WSDL_SERVICE_NAME" select="string($WSDL_DOC//*[local-name() = 'definitions']/*[local-name() = 'service']/@name)"/>
	<xsl:variable name="WSDL_SERVICE_PORT_NAME" select="string($WSDL_DOC//*[local-name() = 'definitions']/*[local-name() = 'service']/*[local-name() = 'port'][1]/@name)"/>
	<xsl:variable name="DP_CONFIG" select="//configuration[1]"/>
	<xsl:variable name="HTTPS_FRONT_SIDE_HANDLERS">
		<FSH>
		<!-- Unique list of HTTPS Port numbers -->
		<xsl:for-each select="$SERVICE_CONFIG_FILE_DOC//HTTPSPort[not(.=preceding::*)]">
			<HTTPSSourceProtocolHandler>
				<xsl:attribute name="name">
					<xsl:value-of select="substring-before($WSDL_NAME, '.')"/>
					<xsl:value-of select="substring-after(string($DP_CONFIG/HTTPSSourceProtocolHandler[1]/@name),'ServicesProxy_Template_Vx')"/>
					<xsl:if test="string(position()) &gt; '1'">
						<xsl:value-of select="concat('_', position())"/>
					</xsl:if>
				</xsl:attribute>
				<mAdminState>enabled</mAdminState>
				<LocalAddress>localhost</LocalAddress>
				<LocalPort><xsl:value-of select="."/></LocalPort>
				<xsl:copy-of select="$DP_CONFIG/HTTPSSourceProtocolHandler[1]/*[not(self::mAdminState | self::LocalAddress | self::LocalPort)]"/>
			</HTTPSSourceProtocolHandler>
		</xsl:for-each>
		</FSH>
	</xsl:variable>
	<xsl:variable name="HTTPS_FSH" select="exslt:node-set($HTTPS_FRONT_SIDE_HANDLERS)"/>
	<xsl:variable name="HTTP_FRONT_SIDE_HANDLERS">
		<FSH>
		<!-- Unique list of HTTP Port numbers -->
		<xsl:for-each select="$SERVICE_CONFIG_FILE_DOC//HTTPPort[not(.=preceding::*)]">
			<HTTPSourceProtocolHandler>
				<xsl:attribute name="name">
					<xsl:value-of select="substring-before($WSDL_NAME, '.')"/>
					<xsl:value-of select="substring-after(string($DP_CONFIG/HTTPSourceProtocolHandler[1]/@name),'ServicesProxy_Template_Vx')"/>
					<xsl:if test="string(position()) &gt; '1'">
						<xsl:value-of select="concat('_', position())"/>
					</xsl:if>
				</xsl:attribute>
				<mAdminState>enabled</mAdminState>
				<LocalAddress>localhost</LocalAddress>
				<LocalPort><xsl:value-of select="."/></LocalPort>
				<xsl:copy-of select="$DP_CONFIG/HTTPSourceProtocolHandler[1]/*[not(self::mAdminState | self::LocalAddress | self::LocalPort)]"/>
			</HTTPSourceProtocolHandler>
		</xsl:for-each>
		</FSH>
	</xsl:variable>
	<xsl:variable name="HTTP_FSH" select="exslt:node-set($HTTP_FRONT_SIDE_HANDLERS)"/>
	<!--=============================================================-->
	<!-- BUILD WSPROXY SERVICE CONFIG FROM TEMPLATE                                -->
	<!--=============================================================-->
	<!-- Template to override the identity template for attributes -->
	<xsl:template match="@*" priority="10">
		<xsl:attribute name="{local-name()}" namespace="{namespace-uri()}">
			<xsl:call-template name="TemplateNameSubstitution">
				<xsl:with-param name="STRING" select="string(.)"/>
			</xsl:call-template>
		</xsl:attribute>
	</xsl:template>
	<!-- Template to override the build-in template for text() nodes -->
	<xsl:template match="text()" priority="10">
		<xsl:call-template name="TemplateNameSubstitution">
			<xsl:with-param name="STRING" select="string(.)"/>
		</xsl:call-template>
	</xsl:template>
	<!-- Template to substitute services template placeholder values -->
	<xsl:template name="TemplateNameSubstitution">
		<xsl:param name="STRING"/>
		<xsl:choose>
			<xsl:when test="contains($STRING,'WSPStreamId')">
				<xsl:call-template name="TemplateNameSubstitution">
					<xsl:with-param name="STRING" select="substring-before($STRING,'WSPStreamId')"/>
				</xsl:call-template>
				<xsl:value-of select="$SERVICES_STREAM"/>
				<xsl:call-template name="TemplateNameSubstitution">
					<xsl:with-param name="STRING" select="substring-after($STRING,'WSPStreamId')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($STRING,'ServicesProxy_Template_Vx_WSDL_Path')">
				<xsl:value-of select="$WSDL_DP_PATH"/>
			</xsl:when>
			<xsl:when test="contains($STRING,'ServicesProxy_Template_Vx')">
				<xsl:call-template name="TemplateNameSubstitution">
					<xsl:with-param name="STRING" select="substring-before($STRING,'ServicesProxy_Template_Vx')"/>
				</xsl:call-template>
				<xsl:value-of select="substring-before($WSDL_NAME, '.')"/>
				<xsl:call-template name="TemplateNameSubstitution">
					<xsl:with-param name="STRING" select="substring-after($STRING,'ServicesProxy_Template_Vx')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($STRING,'ServicesProxy_Template')">
				<xsl:call-template name="TemplateNameSubstitution">
					<xsl:with-param name="STRING" select="substring-before($STRING,'ServicesProxy_Template')"/>
				</xsl:call-template>
				<xsl:call-template name="SubstringBeforeLast">
					<xsl:with-param name="STRING1" select="$WSDL_NAME" />
					<xsl:with-param name="STRING2" select="'_V'" />
				</xsl:call-template>
				<xsl:call-template name="TemplateNameSubstitution">
					<xsl:with-param name="STRING" select="substring-after($STRING,'ServicesProxy_Template')"/>
				</xsl:call-template>
			</xsl:when>                       
			<xsl:when test="contains($STRING,'http://www.namespace/Vx')">
				<xsl:call-template name="TemplateNameSubstitution">
					<xsl:with-param name="STRING" select="substring-before($STRING,'http://www.namespace/Vx')"/>
				</xsl:call-template>
				<xsl:value-of select="$WSDL_NAMESPACE"/>
				<xsl:call-template name="TemplateNameSubstitution">
					<xsl:with-param name="STRING" select="substring-after($STRING,'http://www.namespace/Vx')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$STRING"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template to locate substring before the last occurance of a delimiter -->
	<xsl:template name="SubstringBeforeLast">
		<xsl:param name="STRING1" select="''" />
		<xsl:param name="STRING2" select="''" />
		<xsl:if test="$STRING1 != '' and $STRING2 != ''">
			<xsl:variable name="HEAD" select="substring-before($STRING1, $STRING2)" />
			<xsl:variable name="TAIL" select="substring-after($STRING1, $STRING2)" />
			<xsl:value-of select="$HEAD" />
			<xsl:if test="contains($TAIL, $STRING2)">
				<xsl:value-of select="$STRING2" />
				<xsl:call-template name="SubstringBeforeLast">
					<xsl:with-param name="STRING1" select="$TAIL" />
					<xsl:with-param name="STRING2" select="$STRING2" />
				</xsl:call-template>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<!-- Template to locate substring after the last occurance of a delimiter -->
	<xsl:template name="SubstringAfterLast">
		<xsl:param name="STRING" />
		<xsl:param name="DELIMITER" />
		<xsl:choose>
			<xsl:when test="contains($STRING, $DELIMITER)">
				<xsl:call-template name="SubstringAfterLast">
					<xsl:with-param name="STRING" select="substring-after($STRING, $DELIMITER)" />
					<xsl:with-param name="DELIMITER" select="$DELIMITER" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="$STRING"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!--=============================================================-->
	<!--  build as many  HTTPSourceProtocolHandler and WSEndpointLocalRewriteRule 
		objects as required . Port list includes ALL ports identified in the service config file.
		for install errors, check all service port numbers. -->
	<!--=============================================================-->
	<xsl:template match="HTTPSourceProtocolHandler">
		<xsl:copy-of select="$HTTP_FSH//HTTPSourceProtocolHandler"/>
	</xsl:template>
	<xsl:template match="HTTPSSourceProtocolHandler">
		<xsl:copy-of select="$HTTPS_FSH//HTTPSSourceProtocolHandler"/>
	</xsl:template>
	<xsl:template match="@name" mode="buildFSHObjects">
		<xsl:param name="POSITION"/>
		<xsl:param name="PORT"/>
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="normalize-space($POSITION) = '1'">
					<xsl:value-of select="substring-before($WSDL_NAME, '.')"/>
					<xsl:value-of select="substring-after(.,'ServicesProxy_Template_Vx')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-before($WSDL_NAME, '.')"/>
					<xsl:value-of select="substring-after(.,'ServicesProxy_Template_Vx')"/>
					<xsl:value-of select="concat('_', $POSITION)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="LocalPort" mode="buildFSHObjects">
		<xsl:param name="POSITION"/>
		<xsl:param name="PORT"/>
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="contains(.,'WSPHttpPort')">
					<xsl:value-of select="$PORT"/>
				</xsl:when>
				<xsl:when test="contains(.,'WSPHttpsPort')">
					<xsl:value-of select="$PORT"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<!-- Template to perform a Standard Identity Transform, 'buildFSHObjects' mode -->
	<xsl:template match="node()|@*" mode="buildFSHObjects">
		<xsl:param name="POSITION"/>
		<xsl:param name="PORT"/>
		<xsl:apply-templates select="."/>
	</xsl:template>
	
	<!-- Template to create multiple WSEndpointLocalRewriteRule corresponding to configured FSH -->
	<xsl:template match="WSEndpointLocalRewriteRule">
		<xsl:variable name="REWRITE_RULE" select="."/>
		<xsl:apply-templates select="@*"/>
		<xsl:for-each select="$SERVICE_CONFIG_FILE_DOC//InboundURI">
			<xsl:variable name="INBOUND_URI">
				<xsl:choose>
					<xsl:when test="contains(., '*')">
						<xsl:value-of select="substring-after(., '*')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="normalize-space(.)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:for-each select="$SERVICE_CONFIG_FILE_DOC//HTTPSPort">
				<xsl:apply-templates select="$REWRITE_RULE" mode="buildRewriteRule">
					<xsl:with-param name="ENDPOINT_PROTOCOL" select="'https'"/>
					<xsl:with-param name="INBOUND_PORT" select="normalize-space(.)"/>
					<xsl:with-param name="INBOUND_URI" select="$INBOUND_URI"/>
				</xsl:apply-templates>
			</xsl:for-each>
			<xsl:for-each select="$SERVICE_CONFIG_FILE_DOC//HTTPPort">
				<xsl:apply-templates select="$REWRITE_RULE" mode="buildRewriteRule">
					<xsl:with-param name="ENDPOINT_PROTOCOL" select="'http'"/>
					<xsl:with-param name="INBOUND_PORT" select="normalize-space(.)"/>
					<xsl:with-param name="INBOUND_URI" select="$INBOUND_URI"/>
				</xsl:apply-templates>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="WSEndpointRemoteRewriteRule">
		<xsl:variable name="REWRITE_RULE" select="."/>
		<xsl:apply-templates select="@*"/>
		<xsl:for-each select="$SERVICE_CONFIG_FILE_DOC//InboundURI">
			<xsl:variable name="INBOUND_URI">
				<xsl:choose>
					<xsl:when test="contains(., '*')">
						<xsl:value-of select="substring-after(., '*')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="normalize-space(.)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:apply-templates select="$REWRITE_RULE" mode="buildRewriteRule">
				<xsl:with-param name="INBOUND_URI" select="$INBOUND_URI"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>
	<!-- Template to perform Identity Transforms for 'buildRewriteRule' mode -->
	<xsl:template match="WSEndpointLocalRewriteRule | WSEndpointRemoteRewriteRule" mode="buildRewriteRule">
		<xsl:param name="ENDPOINT_PROTOCOL"/>
		<xsl:param name="INBOUND_PORT"/>
		<xsl:param name="INBOUND_URI"/>
		<xsl:copy>
			<xsl:apply-templates select="*" mode="buildRewriteRule">
				<xsl:with-param name="ENDPOINT_PROTOCOL" select="$ENDPOINT_PROTOCOL"/>
				<xsl:with-param name="INBOUND_PORT" select="$INBOUND_PORT"/>
				<xsl:with-param name="INBOUND_URI" select="$INBOUND_URI"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="LocalEndpointProtocol" mode="buildRewriteRule">
		<xsl:param name="ENDPOINT_PROTOCOL"/>
		<xsl:param name="INBOUND_PORT"/>
		<xsl:param name="INBOUND_URI"/>
		<xsl:copy><xsl:value-of select="$ENDPOINT_PROTOCOL"/></xsl:copy>
	</xsl:template>
	<xsl:template match="LocalEndpointPort" mode="buildRewriteRule">
		<xsl:param name="ENDPOINT_PROTOCOL"/>
		<xsl:param name="INBOUND_PORT"/>
		<xsl:param name="INBOUND_URI"/>
		<xsl:copy><xsl:value-of select="$INBOUND_PORT"/></xsl:copy>
	</xsl:template>
	<xsl:template match="LocalEndpointURI | RemoteEndpointURI" mode="buildRewriteRule">
		<xsl:param name="ENDPOINT_PROTOCOL"/>
		<xsl:param name="INBOUND_PORT"/>
		<xsl:param name="INBOUND_URI"/>
		<xsl:copy><xsl:value-of select="$INBOUND_URI"/></xsl:copy>
	</xsl:template>
	<xsl:template match="WSDLBindingProtocol" mode="buildRewriteRule">
		<xsl:param name="ENDPOINT_PROTOCOL"/>
		<xsl:param name="INBOUND_PORT"/>
		<xsl:param name="INBOUND_URI"/>
		<xsl:copy><xsl:value-of select="$WSDL_SOAP_VERSION"/></xsl:copy>
	</xsl:template>
	<xsl:template match="WSDLBindingProtocol" mode="buildRewriteRule">
		<xsl:param name="ENDPOINT_PROTOCOL"/>
		<xsl:param name="INBOUND_PORT"/>
		<xsl:param name="INBOUND_URI"/>
		<xsl:copy><xsl:value-of select="$WSDL_SOAP_VERSION"/></xsl:copy>
	</xsl:template>
	<!-- Template to perform a Standard Identity Transform, 'buildRewriteRule' mode -->
	<xsl:template match="node()|@*" mode="buildRewriteRule">
		<xsl:param name="ENDPOINT_PROTOCOL"/>
		<xsl:param name="INBOUND_PORT"/>
		<xsl:param name="INBOUND_URI"/>
		<xsl:copy>
			<xsl:call-template name="TemplateNameSubstitution">
				<xsl:with-param name="STRING" select="normalize-space(.)"/>
			</xsl:call-template>
		</xsl:copy>
	</xsl:template>
	

	<!--=============================================================-->
	<!--  WSPROXY USERTOGGLES                                     -->
	<!--=============================================================-->
	<!-- Validation UserToggles to toggle WSProxy Validation from config                                             -->
	<xsl:template match="UserToggles[parent::WSGateway]">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
		<xsl:if test="not(preceding-sibling::UserToggles)">
			<xsl:variable name="WSDL_NAME" select="../BaseWSDL/WSDLName"/>
			<xsl:apply-templates select="$SERVICE_CONFIG_FILE_DOC/ServiceConfig/OperationConfig[*[@schemaValidate = 'false']]" mode="userToggles"/>
		</xsl:if>
	</xsl:template>
	<!-- Modal template to add UserToggles to WSGateway to alter validation bahaviour -->
	<xsl:template match="OperationConfig" mode="userToggles">
		<!-- when req validation  'off', header validation off also  -->
		<xsl:call-template name="CreateUserToggles">
			<xsl:with-param name="ACTION" select="normalize-space(InputMatchCriteria/Action)"/>
			<xsl:with-param name="REQUEST_VALIDATION" select="normalize-space(RequestPolicyConfig/@schemaValidate)"/>
			<xsl:with-param name="RESPONSE_VALIDATION" select="normalize-space(ResponsePolicyConfig/@schemaValidate)"/>
			<xsl:with-param name="FAULT_VALIDATION" select="normalize-space(ErrorPolicyConfig/@schemaValidate)"/>
			<xsl:with-param name="HEADER_VALIDATION" select="normalize-space(RequestPolicyConfig/@schemaValidate)"/>
		</xsl:call-template>
	</xsl:template>
	<!-- named template to create UserToggles to alter validation bahaviour -->
	<xsl:template name="CreateUserToggles">
		<xsl:param name="ACTION"/>
		<xsl:param name="REQUEST_VALIDATION" select="'true'"/>
		<xsl:param name="RESPONSE_VALIDATION" select="'true'"/>
		<xsl:param name="FAULT_VALIDATION" select="'true'"/>
		<xsl:param name="HEADER_VALIDATION" select="'true'"/>
		<!-- Vars -->
		<xsl:variable name="FRONTSIDE_PORT_SUFFIX">
			<xsl:if test="contains(@id, '_VERIFY_Policy')">
				<xsl:value-of select="'.1'"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="OPERATION_NAME" select="normalize-space($WSDL_DOC//*[local-name() = 'definitions'][1]/*[local-name() = 'binding'][1]/*[local-name() = 'operation'][*[@soapAction=$ACTION]]/@name)"/>
		<UserToggles>
			<Toggles>
				<Enable>on</Enable>
				<Publish>off</Publish>
				<VerifyFaults>
					<xsl:choose>
						<xsl:when test="$FAULT_VALIDATION = 'false'">
							<xsl:value-of select="'off'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'on'"/>
						</xsl:otherwise>
					</xsl:choose>
				</VerifyFaults>
				<VerifyHeaders>
					<xsl:choose>
						<xsl:when test="$HEADER_VALIDATION = 'false'">
							<xsl:value-of select="'off'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'on'"/>
						</xsl:otherwise>
					</xsl:choose>
				</VerifyHeaders>
				<NoRequestValidation>
					<xsl:choose>
						<!-- when validation = off, suppress = on -->
						<xsl:when test="$REQUEST_VALIDATION = 'false'">
							<xsl:value-of select="'on'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'off'"/>
						</xsl:otherwise>
					</xsl:choose>
				</NoRequestValidation>
				<NoResponseValidation>
					<xsl:choose>
						<!-- when validation = off, suppress = on -->
						<xsl:when test="$RESPONSE_VALIDATION = 'false'">
							<xsl:value-of select="'on'"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'off'"/>
						</xsl:otherwise>
					</xsl:choose>
				</NoResponseValidation>
				<SuppressFaultsElementsForRPCWrappers>off</SuppressFaultsElementsForRPCWrappers>
				<NoWSA>off</NoWSA>
				<NoWSRM>off</NoWSRM>
				<AllowXOPInclude>on</AllowXOPInclude>
			</Toggles>
			<UseFragmentID>on</UseFragmentID>
			<FragmentID>
				<xsl:value-of select="concat($WSDL_NAMESPACE, '#dp.portOperation(', $WSDL_SERVICE_NAME, '/', $WSDL_SERVICE_PORT_NAME, '/', $OPERATION_NAME, ')')"/>
			</FragmentID>
		</UserToggles>
	</xsl:template>
	<!-- Standard Identity template -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
