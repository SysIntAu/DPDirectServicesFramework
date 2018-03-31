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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions" xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:err="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0" extension-element-prefixes="dp regexp" version="1.0"
	exclude-result-prefixes="dp regexp err scm wsa saml wsse">
	<!--========================================================================
		Purpose:
		Performs initialisation of the generic policy flow. The request or response policy configuration
		node is output to the SERVICE_METADATA context and the first rule in the policy is set on the associated
		context variable. The INPUT context is copied to the RESULT_DOC context.
		
		History:
		2016-12-12	v1.0	N.A. , Tim Goodwil	Initial Version.
		
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="PROXY_NAME" select="normalize-space(dp:variable($DP_SERVICE_PROCESSOR_NAME))"/>
	<xsl:variable name="CONFIG_DOC" select="document(concat($JSON_RESTAPI_ROOT_FOLDER,'config/',$PROXY_NAME,'_ServiceConfig.xml'))"/>
	<xsl:variable name="INPUT_URI" select="string(dp:variable('var://service/URI'))"/>
	<xsl:variable name="INPUT_PORT" select="normalize-space(substring-after(dp:variable($DP_SERVICE_LOCAL_SERVICE_ADDRESS),':'))"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- The DP transaction rule type ('request'|'response'|'error') -->
		<xsl:variable name="TX_RULE_TYPE" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
		<xsl:if test="$TX_RULE_TYPE != 'error'">
			<dp:set-variable name="$FLOW_DIRECTION_VAR_NAME" value="string($TX_RULE_TYPE)"/>
		</xsl:if>
		<!-- Retrieve the policy configuration for the matching service and store 
			for later use in the request/response flow -->
		<xsl:variable name="OPERATION_CONFIG_NODE">
			<xsl:element name="OperationConfig">
				<xsl:attribute name="txRuleType">
					<xsl:value-of select="$TX_RULE_TYPE"/>
				</xsl:attribute>
				<!-- In request flow -->
				<xsl:choose>
					<xsl:when test="$TX_RULE_TYPE = 'request'">
						<!-- Match based on input criteria -->
						<xsl:variable name="OPERATION_CONFIG_NODE_ID">
							<xsl:choose>
								<!-- InboundURI match at the OperationConfig level. HTTPS port only.  -->
								<xsl:when test="$CONFIG_DOC/ServiceConfig/OperationConfig[InputMatchCriteria[
									regexp:match($INPUT_URI, regexp:replace(InboundURI/text(), '\*', 'g', '.*'))  != ''][(normalize-space(HTTPSPort) =
									$INPUT_PORT) or not(/HTTPSPort)]]">
									<xsl:value-of select="$CONFIG_DOC/ServiceConfig/OperationConfig[InputMatchCriteria[
										regexp:match($INPUT_URI, regexp:replace(InboundURI/text(), '\*', 'g', '.*'))  != ''][
										(normalize-space(HTTPSPort) = $INPUT_PORT) or not(/HTTPSPort)]]/@id"/>
								</xsl:when>
								<!-- Config with no InboundURI specified HTTPS port only. -->
								<xsl:otherwise>
									<xsl:value-of select="$CONFIG_DOC/ServiceConfig/OperationConfig[InputMatchCriteria[not(/InboundURI)][
										(HTTPSPort/text() = $INPUT_PORT) or not(/HTTPSPort)]]/@id"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- Copy OperationConfig Attributes -->
						<xsl:for-each select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
							$OPERATION_CONFIG_NODE_ID]/RequestPolicyConfig/@*">
							<xsl:attribute name="{name()}">
								<xsl:value-of select="."/>
							</xsl:attribute>
						</xsl:for-each>
						<xsl:choose>
							<!-- Reject unmatched services -->
							<xsl:when test="normalize-space($OPERATION_CONFIG_NODE_ID) = ''">
								<!-- Reject to error flow -->
								<xsl:call-template name="RejectToErrorFlow">
									<xsl:with-param name="MSG">
										<xsl:text>No matching service configuration for input message. URI='</xsl:text>
										<xsl:value-of select="$INPUT_URI"/>
										<xsl:text>' on input port '</xsl:text>
										<xsl:value-of select="$INPUT_PORT"/>
										<xsl:text>'</xsl:text>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:when>
							<!-- Configure the flow -->
							<xsl:otherwise>
								<xsl:variable name="REQUEST_POLICY_CONFIG">
									<RequestPolicyConfig>
										<xsl:copy-of select="$CONFIG_DOC/ServiceConfig/PreProcessConfig/*"/>
										<xsl:copy-of select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
											$OPERATION_CONFIG_NODE_ID]/RequestPolicyConfig/*"/>
									</RequestPolicyConfig>
								</xsl:variable>
								<!-- Set the policy config node id for use in the response flow -->
								<dp:set-variable name="$OPERATION_CONFIG_NODE_ID_VAR_NAME" value="string($OPERATION_CONFIG_NODE_ID)"/>
								<!-- Set the backend provider name for the service for use in the error flow -->
								<dp:set-variable name="$OPERATION_CONFIG_PROVIDER_VAR_NAME"
									value="string($REQUEST_POLICY_CONFIG/BackendRouting/@provider)"/>
								<!-- Copy the request config child elements -->
								<xsl:apply-templates select="$REQUEST_POLICY_CONFIG/RequestPolicyConfig" mode="processPolicyMetadata"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<!-- In response flow -->
					<xsl:when test="$TX_RULE_TYPE = 'response'">
						<xsl:variable name="INPUT_MSG" select="dp:variable(concat($INPUT_CONTEXT_NAME, '_roottree'))"/>
						<xsl:variable name="SOAP_FAULT">
							<xsl:if test="($INPUT_MSG/*) 
								and (($INPUT_MSG/*[local-name() = 'Envelope']/*[local-name() = 'Body']/*[local-name() =   'Fault'])
								or ($INPUT_MSG/*[local-name() = 'Fault']))">
								<xsl:copy-of select="$INPUT_MSG/*[local-name() = 'Envelope']/*[local-name() = 'Body']/*[local-name() =   'Fault'] | /*[local-name() = 'Fault']"/>
							</xsl:if>
						</xsl:variable>
						<!-- Retrieve the policy config node id -->
						<xsl:variable name="OPERATION_CONFIG_NODE_ID"
							select="string(dp:variable($OPERATION_CONFIG_NODE_ID_VAR_NAME))"/>
						<!-- Copy OperationConfig Attributes -->
						<xsl:for-each select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
							$OPERATION_CONFIG_NODE_ID]/ResponsePolicyConfig/@*">
							<xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
						</xsl:for-each>
						<xsl:variable name="DP_RESPONSE_CODE" select="dp:response-header('x-dp-response-code')"/>
						<xsl:variable name="BACKSIDE_PROTOCOL" select="substring-before(dp:variable($DP_SERVICE_URL_OUT),':')"/>
						<xsl:variable name="PROVIDER_NAME" select="dp:variable($OPERATION_CONFIG_PROVIDER_VAR_NAME)"/>
						<xsl:variable name="INPUT_MSG_EMPTY" select="boolean(not(/*))"/>
						<!-- Copy the response config child elements -->
						<xsl:apply-templates select="$CONFIG_DOC/ServiceConfig/OperationConfig[@id =
							$OPERATION_CONFIG_NODE_ID]/ResponsePolicyConfig/*" mode="processPolicyMetadata"/>
						<xsl:choose>
							<xsl:when test="($BACKSIDE_PROTOCOL = 'dpmq')
								and (normalize-space($SOAP_FAULT) != '')">
								<!-- Reject to error flow -->
								<xsl:call-template name="RejectToErrorFlow">
									<xsl:with-param name="MSG">
										<xsl:text>MQ PUT Failure - Failed to put current message to URL '</xsl:text>
										<xsl:value-of select="dp:variable($DP_SERVICE_URL_OUT)"/>
										<xsl:text>'. Backside url-open error: [errorcode=</xsl:text>
										<xsl:value-of select="$DP_RESPONSE_CODE"/>
										<xsl:text>]</xsl:text>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:when>
							<xsl:when test="normalize-space($SOAP_FAULT) != ''">
								<xsl:variable name="ERROR_TEXT">
									<xsl:choose>
										<!-- EnterpriseError -->
										<xsl:when test="$SOAP_FAULT//*[local-name() = 'Description']">
											<xsl:value-of select="normalize-space($SOAP_FAULT//*[local-name() = 'Description'])"/>
										</xsl:when>
										<!-- SOAP 1.1 -->
										<xsl:when test="$SOAP_FAULT//faultstring">
											<xsl:value-of select="normalize-space($SOAP_FAULT)//faultstring"/>
										</xsl:when>
										<!-- SOAP 1.2 -->
										<xsl:when test="$SOAP_FAULT//*[local-name() = 'Reason']">
											<xsl:value-of select="normalize-space($SOAP_FAULT)//*[local-name() = 'Reason']"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="dp:serialize($SOAP_FAULT)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- Reject to error flow -->
								<xsl:call-template name="RejectToErrorFlow">
									<xsl:with-param name="MSG">
										<xsl:text>Service error: </xsl:text>
										<xsl:value-of select="$ERROR_TEXT"/>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:when>
							<!-- MQ timeout -->
							<xsl:when test="($BACKSIDE_PROTOCOL = 'dpmq')
								and (number($DP_RESPONSE_CODE) = 2033)">
								<!-- Reject to error flow -->
								<xsl:call-template name="RejectToErrorFlow">
									<xsl:with-param name="MSG">
										<xsl:text>Backend service timed out.</xsl:text>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:when>
							<!-- Reject backend for MQ put errors -->
							<xsl:when test="$INPUT_MSG_EMPTY 
								and ($BACKSIDE_PROTOCOL = 'dpmq')
								and (number($DP_RESPONSE_CODE) = number($DP_RESPONSE_CODE) )
								and (number($DP_RESPONSE_CODE) &gt;= 2000)">
								<!-- Reject to error flow -->
								<xsl:call-template name="RejectToErrorFlow">
									<xsl:with-param name="MSG">
										<xsl:text>MQ PUT Failure - Failed to put current message to URL '</xsl:text>
										<xsl:value-of select="dp:variable($DP_SERVICE_URL_OUT)"/>
										<xsl:text>'. Backside url-open error: [errorcode=</xsl:text>
										<xsl:value-of select="$DP_RESPONSE_CODE"/>
										<xsl:text>]</xsl:text>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:when>
							<!-- Empty response : assume timeout -->
							<xsl:when test="$INPUT_MSG_EMPTY">
								<!-- Store the Message Format -->
								<dp:set-variable name="$RES_IN_MSG_FORMAT_VAR_NAME" value="'zero-bytes'"/>
								<!-- Reject to error flow -->
								<xsl:call-template name="RejectToErrorFlow">
									<xsl:with-param name="MSG" select="'A valid response was not returned by the backend.'"/>
								</xsl:call-template>
							</xsl:when>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:element>
		</xsl:variable>
		<!-- Set the next rule name variable for dynamic policy flow execution -->
		<xsl:variable name="NEXT_RULE_NAME"
			select="concat($RULE_NAME_PREFIX,normalize-space(local-name($OPERATION_CONFIG_NODE//OperationConfig/*[1])),'_rule')"/>
		<dp:set-variable name="$NEXT_RULE_NAME_VAR_NAME" value="string($NEXT_RULE_NAME)"/>
<!--		<dp:set-variable name="$SERVICE_METADATA_CONTEXT_NAME" value="$OPERATION_CONFIG_NODE"/>-->
		<!-- Copy Operation Config node to output context -->
		<xsl:copy-of select="$OPERATION_CONFIG_NODE"/>
	</xsl:template>
	<!--=============================================================-->
	<!-- MODAL TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to add timing metadata to policy config metadata -->
	<xsl:template match="RequestPolicyConfig" mode="processPolicyMetadata">
		<!-- Copy service chain children -->
		<xsl:apply-templates select="@*|node()" mode="processPolicyMetadata"/>
	</xsl:template>
	<!-- Standard identity template (mode="processPolicyMetadata") -->
	<xsl:template match="node()|@*" mode="processPolicyMetadata">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="processPolicyMetadata"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
