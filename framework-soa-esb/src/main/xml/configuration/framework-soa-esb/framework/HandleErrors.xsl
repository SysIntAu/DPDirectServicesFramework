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
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:xop="http://www.w3.org/2004/08/xop/include"
	xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:ctx="http://www.dpdirect.org/Namespace/ApplicationContext/Core/V1.0"
	xmlns:err="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0"
	xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="dp date regexp" version="1.0"
	exclude-result-prefixes="dp date regexp scm ctx err wsse wsa xop wsnt">
	<!--========================================================================
		Purpose:
		Error Handler Stylesheet for the Gateway  Gateway component
		
		History:
		2016-12-12	v0.1	N.A.		Initial Version. 
		2016-12-12	v2.0	Tim Goodwill		Init Gateway  instance
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="CodeMapping.xsl"/>
	<xsl:include href="EventCodeUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0" cdata-section-elements="err:Description"/>
	<!--============== Global Variable Declarations =================-->
	<!-- The literal value for a replacement token that may occur in the 'MessageDescription' element of a code mapping entry. -->
	<xsl:variable name="UC" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
	<xsl:variable name="LC" select="'abcdefghijklmnopqrstuvwxyz'" />
	<xsl:variable name="MANUAL_REJECTION" select="normalize-space(dp:variable($ERROR_CODE_VAR_NAME))   != ''"/>
	<xsl:variable name="ERROR_MSG" select="dp:variable($ERROR_MSG_VAR_NAME)"/>
	<xsl:variable name="ERROR_ORIG_NAME" select="dp:variable($ERROR_ORIG_NAME_VAR_NAME)"/>
	<xsl:variable name="ERROR_ORIG_LOC" select="dp:variable($ERROR_ORIG_LOC_VAR_NAME)"/>
	<xsl:variable name="ERROR_ADD_DETAILS" select="dp:variable($ERROR_ADD_DETAILS_VAR_NAME)"/>
	<xsl:variable name="ERROR_PROVIDER_NAME" select="dp:variable($ERROR_PROVIDER_NAME_VAR_NAME)"/>
	<xsl:variable name="DP_EVENT_CODE">
		<xsl:choose>
			<xsl:when test="normalize-space(dp:variable($EVENT_CODE_VAR_NAME)) != ''">
				<xsl:value-of select="normalize-space(dp:variable($EVENT_CODE_VAR_NAME))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space(dp:variable($DP_SERVICE_ERROR_CODE))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="DP_EVENT_SUBCODE">
		<xsl:choose>
			<xsl:when test="normalize-space(dp:variable($EVENT_SUBCODE_VAR_NAME)) != ''">
				<xsl:value-of select="normalize-space(dp:variable($EVENT_SUBCODE_VAR_NAME))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space(dp:variable($DP_SERVICE_ERROR_SUBCODE))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="DP_EVENT_DESC">
		<xsl:call-template name="GetEventDescription">
			<xsl:with-param name="CODE" select="$DP_EVENT_CODE"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="DP_EVENT_ERROR_MSG">
		<xsl:choose>
			<xsl:when test="normalize-space(dp:variable($EVENT_MESSAGE_VAR_NAME)) != ''">
				<xsl:value-of select="normalize-space(dp:variable($EVENT_MESSAGE_VAR_NAME))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space(dp:variable($DP_SERVICE_ERROR_MSG))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="DP_EVENT_ERROR_TEXT">
		<xsl:choose>
			<!-- SOAP 1.1 -->
			<xsl:when test="contains($DP_EVENT_ERROR_MSG, '&lt;faultstring>')">
				<xsl:value-of select="normalize-space(dp:parse($DP_EVENT_ERROR_MSG)//faultstring)"/>
			</xsl:when>
			<!-- SOAP 1.2 -->
			<xsl:when test="contains($DP_EVENT_ERROR_MSG, ':Reason>')">
				<xsl:value-of select="normalize-space(dp:parse($DP_EVENT_ERROR_MSG)//*[local-name() = 'Reason'])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space($DP_EVENT_ERROR_MSG)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="ERROR_CODE">
		<xsl:choose>
			<!-- Security Error Handling (i.e. AAA failure) -->
			<xsl:when test="$DP_EVENT_CODE = '0x01d30002'
				or $DP_EVENT_SUBCODE = '0x01d30002'">
				<xsl:value-of select="'ERROR0011'"/>
			</xsl:when>
			<!-- Invalid Character Encoding Handling -->
			<xsl:when test="$DP_EVENT_CODE = '0x00030001'
				or $DP_EVENT_SUBCODE = '0x00030001'">
				<xsl:value-of select="'ERROR0001'"/>
			</xsl:when>
			<!-- Invalid Soap Envelope -->
			<xsl:when test="$DP_EVENT_CODE = '0x00d30002'
				or $DP_EVENT_SUBCODE = '0x00d30002'">
				<xsl:value-of select="'ERROR0001'"/>
			</xsl:when>
			<!-- WSDL policy violation : eg. header not found -->
			<xsl:when test="($DP_EVENT_CODE= '0x00d30003')
				and contains(dp:variable($DP_SERVICE_ERROR_MSG), 'Required elements filter')">
				<xsl:value-of select="'ERROR0001'"/>
			</xsl:when>
			<!-- Manual Rejection -->
			<xsl:when test="dp:variable($ERROR_CODE_VAR_NAME) != ''">
				<xsl:value-of select="dp:variable($ERROR_CODE_VAR_NAME)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$DP_EVENT_CODE"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- The current flow direction: either 'request' or 'response' or '' (An empty string
		is the result of an error occuring prior to the request flow initialisation stylesheet invocation) -->
	<xsl:variable name="FLOW_DIRECTION">
		<xsl:choose>
			<xsl:when test="normalize-space(dp:variable($FLOW_DIRECTION_VAR_NAME)) != ''">
				<xsl:value-of select="normalize-space(dp:variable($FLOW_DIRECTION_VAR_NAME))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'request'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- Flag to indicate if the error has occured in the request flow. 
		A value of false indicates the error has occured in the response flow -->
	<xsl:variable name="IN_REQUEST_FLOW" select="boolean($FLOW_DIRECTION = 'request')"/>
	<xsl:variable name="WSA_FAULT_ENDPOINT">
		<xsl:choose>
			<xsl:when test="normalize-space(dp:variable($REQ_WSA_FAULT_TO_VAR_NAME)) != ''">
				<xsl:value-of select="normalize-space(dp:variable($REQ_WSA_FAULT_TO_VAR_NAME))"/>
			</xsl:when>
			<xsl:when test="normalize-space(dp:variable($REQ_WSA_REPLY_TO_VAR_NAME)) != ''">
				<xsl:value-of select="normalize-space(dp:variable($REQ_WSA_REPLY_TO_VAR_NAME))"/>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<!-- Inbound Frontside Protocol -->
	<xsl:variable name="FRONTSIDE_PROTOCOL" select="normalize-space(substring-before(dp:variable($DP_SERVICE_URL_IN),':'))"/>
	<!-- Inbound message SOAP envelope -->
	<xsl:variable name="REQ_SOAP_ENV" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
	<!-- The current MQMD, either the original request MQMD if the error occured in the request 
	flow or the MQMD from the backend response if the error occured in the response flow -->
	<xsl:variable name="CURRENT_MQMD">
		<xsl:call-template name="GetReqMQMD"/>
	</xsl:variable>
	<!-- Locate the input message -->
	<xsl:variable name="INPUT_MSG">
		<xsl:choose>
			<xsl:when test="$IN_REQUEST_FLOW">
				<xsl:copy-of select="dp:variable(concat($INPUT_CONTEXT_NAME, '_roottree'))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="dp:variable(concat($RESULT_DOC_CONTEXT_NAME, '_roottree'))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- Determine the ws Username -->
	<xsl:variable name="USERNAME">
		<xsl:choose>
			<xsl:when test="$REQ_SOAP_ENV != ''">
				<xsl:value-of select="normalize-space(($REQ_SOAP_ENV/*[local-name() = 'Envelope']/*[local-name() = 'Header']/wsse:security/wsse:UsernameToken/wsse:Username)[1])"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="FORWARDED_FOR" select="dp:request-header('X-Forwarded-For')"/>
				<xsl:choose>
					<xsl:when test="normalize-space($FORWARDED_FOR) != ''">
						<xsl:value-of select="concat('FwdFor:', $FORWARDED_FOR)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat('Username:', normalize-space((/*[local-name() = 'Envelope']/*[local-name() = 'Header']/wsse:security/wsse:UsernameToken/wsse:Username)[1]))"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- Determine the 'TransactionId' (eg TRN/PRN) -->
	<xsl:variable name="TRANSACTION_ID" select="dp:variable($TRANSACTION_ID_VAR_NAME)"/>
	<!-- Code map entry -->
	<xsl:variable name="CODE_MAP_ENTRY">
		<xsl:call-template name="GetEnterpriseCodeMapEntry">
			<xsl:with-param name="ERROR_CODE" select="$ERROR_CODE"/>
			<xsl:with-param name="SERVICE_NAME" select="'*'"/>
			<xsl:with-param name="PROVIDER_NAME" select="$ERROR_PROVIDER_NAME"/>
		</xsl:call-template>
	</xsl:variable>
	<!-- Enterprise Error Code -->
	<xsl:variable name="ENTERPRISE_ERROR_CODE" select="$CODE_MAP_ENTRY/Row/EnterpriseCode"/>
	<!-- Enterprise Error Description. Standardise description insert token -->
	<xsl:variable name="ENTERPRISE_DESCRIPTION" select="$CODE_MAP_ENTRY/Row/MessageDescription"/>
	<!-- Detailed Descriprion Text -->
	<xsl:variable name="DETAILED_DESCRIPTION_TEXT">
		<xsl:variable name="PROVIDER_TEXT">
			<xsl:choose>
				<xsl:when test="normalize-space($ERROR_MSG) != ''">
					<xsl:value-of select="regexp:replace($ERROR_MSG, '^http://\d+[^\s]+\s+', 'i', '')"/>
				</xsl:when>
				<xsl:when test="$DP_EVENT_DESC != ''">
					<xsl:value-of select="$DP_EVENT_DESC"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="normalize-space($ERROR_MSG) != ''">
				<xsl:value-of select="$ERROR_MSG"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$ENTERPRISE_DESCRIPTION"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- Additional Error Detail -->
	<xsl:variable name="DETAILED_ADDITIONAL_TEXT">
		<xsl:choose>
			<xsl:when test="$ERROR_ADD_DETAILS != ''">
				<xsl:value-of select="$ERROR_ADD_DETAILS"/>
			</xsl:when>
			<xsl:when test="($DP_EVENT_CODE = '0x00230001')
				and contains($ERROR_MSG, 'cvc-particle')">
				<!-- schema validation error detail has been appended to the error message -->
				<xsl:value-of select="''"/>
			</xsl:when>
			<!-- WSDL policy violation : eg. header not found -->
			<xsl:when test="($DP_EVENT_CODE= '0x00d30003')
				and contains(dp:variable($DP_SERVICE_ERROR_MSG), 'Required elements filter')">
				<xsl:value-of select="$DP_EVENT_ERROR_TEXT"/>
			</xsl:when>
			<xsl:when test="($ENTERPRISE_ERROR_CODE = $DP_FALLBACK_ERROR_CODE)
				and ($DP_EVENT_DESC != '')">
				<xsl:value-of select="normalize-space(concat($DP_EVENT_DESC,
					'. ', $DP_EVENT_ERROR_TEXT))"/>
			</xsl:when>
			<xsl:when test="($DP_EVENT_CODE != $DP_MANUAL_REJECT_EVENT_CODE)
				and ($DP_EVENT_ERROR_TEXT != '')
				and ($DP_EVENT_ERROR_TEXT != $DETAILED_DESCRIPTION_TEXT)">
				<xsl:value-of select="$DP_EVENT_ERROR_TEXT"/>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Override HTTP response code  -->
		<dp:set-http-response-header name="'x-dp-response-code'" value="'200'"/>
		<dp:set-variable name="'var://service/error-protocol-response'" value="'200'"/>
		<!-- Create stats in the event of parsing error (InitRequestFlow by-passed) -->
		<xsl:if test="$DP_EVENT_CODE = '0x00030001'">
			<!-- Set input message format-->
			<dp:set-variable name="$REQ_IN_MSG_FORMAT_VAR_NAME" value="'non-XML'"/>
		</xsl:if>
		<!-- Write error log msg -->
		<xsl:call-template name="WriteSysLogErrorMsg">
			<xsl:with-param name="MSG">
				<xsl:text>ServiceError </xsl:text>
			</xsl:with-param>
			<xsl:with-param name="KEY_VALUES">
				<xsl:text>EventCode=</xsl:text>
				<xsl:value-of select="string($DP_EVENT_CODE)"/>
				<xsl:if test="string($DP_EVENT_SUBCODE) != string($DP_EVENT_CODE)">
					<xsl:text>,Event SubCode=</xsl:text>
					<xsl:value-of select="string($DP_EVENT_SUBCODE)"/>
				</xsl:if>
				<xsl:text>,ErrorCode=</xsl:text>
				<xsl:value-of select="string($ERROR_CODE)"/>
				<xsl:text>,FlowDirection=</xsl:text>
				<xsl:value-of select="string($FLOW_DIRECTION)"/>
				<xsl:text>,ServiceOperation=</xsl:text>
				<xsl:value-of select="dp:variable($REQ_WSA_ACTION_VAR_NAME)"/>
			</xsl:with-param>
		</xsl:call-template>
		<!-- Generate SOAP fault -->
		<xsl:variable name="SOAP_FAULT">
			<xsl:choose>
				<!-- Expected input is a SOAP message -->
				<xsl:when test="/*[local-name() = 'Envelope']">
					<!-- Apply templates to the input SOAP message -->
					<xsl:apply-templates select="*"/>
				</xsl:when>
				<!-- If SOAP envelope is missing generate an envelope and soap fault -->
				<xsl:when test="dp:variable($REQ_SOAP_NAMESPACE_VAR_NAME) = $SOAP12_NAMESPACE_URI">
					<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope">
						<soapenv:Header/>
						<soapenv:Body>
							<xsl:call-template name="CreateSOAPFault"/>
						</soapenv:Body>
					</soapenv:Envelope>
				</xsl:when>
				<xsl:otherwise>
					<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
						<soapenv:Header/>
						<soapenv:Body>
							<xsl:call-template name="CreateSOAPFault"/>
						</soapenv:Body>
					</soapenv:Envelope>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Strip any attachments that might be associated with the RESULT_DOC context from the request flow -->
		<dp:strip-attachments/>
		<xsl:copy-of select="$SOAP_FAULT"/>
	</xsl:template>
	<!-- Template to replace soap payload with SOAP Fault -->
	<xsl:template match="*[parent::*[local-name() = 'Body']]">
		<!-- Create the ouput SOAP Fault -->
		<xsl:call-template name="CreateSOAPFault"/>
	</xsl:template>
	<!-- Standard identity template -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<!-- Template to map the provided 'err:SubCode' element -->
	<xsl:template match="err:SubCode" mode="mapError">
		<err:SubCode>
			<xsl:choose>
				<xsl:when test="normalize-space($ERROR_ORIG_NAME) != ''">
					<xsl:value-of select="$ERROR_ORIG_NAME"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$THIS_PROVIDER_NAME"/>
				</xsl:otherwise>
			</xsl:choose>
		</err:SubCode>
	</xsl:template>
	<!-- Template to map the provided 'err:MessageOrigin' element -->
	<xsl:template match="err:MessageOrigin" mode="mapError">
		<err:MessageOrigin>
			<xsl:choose>
				<xsl:when test="normalize-space($ERROR_ORIG_LOC) != ''">
					<xsl:value-of select="$ERROR_ORIG_LOC"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'ESB_Services'"/>
				</xsl:otherwise>
			</xsl:choose>
		</err:MessageOrigin>
	</xsl:template>
	<!-- Template to map the provided 'err:Code' element -->
	<xsl:template match="err:Code" mode="mapError">
		<err:Code>
			<xsl:value-of select="$ENTERPRISE_ERROR_CODE"/>
		</err:Code>
	</xsl:template>
	<!-- Template to map the provided 'err:Description' element -->
	<xsl:template match="err:Description" mode="mapError">
		<err:Description>
			<xsl:value-of select="$DETAILED_DESCRIPTION_TEXT"/>
		</err:Description>
	</xsl:template>
	<!-- Template to map the provided 'err:SubCode' element -->
	<xsl:template match="err:SubCode" mode="mapError">
		<xsl:if test="$CODE_MAP_ENTRY/Row/Subtype = 'Logic' or $CODE_MAP_ENTRY/Row/Subtype =    'Validation'">
			<err:SubCode>
				<xsl:value-of select="."/>
			</err:SubCode>
		</xsl:if>
	</xsl:template>
	<!-- Template to map the provided 'err:SubDescription' element -->
	<xsl:template match="err:SubDescription" mode="mapError">
		<xsl:if test="normalize-space($DETAILED_ADDITIONAL_TEXT) != ''">
			<err:SubDescription>
				<xsl:value-of select="$DETAILED_ADDITIONAL_TEXT"/>
			</err:SubDescription>
		</xsl:if>
	</xsl:template>
	<!-- Templates to strip Gateway  Internal Headers-->
	<xsl:template match="node()|@*" mode="stripInternalHeaders">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="stripInternalHeaders"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="wsse:Password" mode="stripInternalHeaders"/>
	<xsl:template match="wsa:To" mode="stripInternalHeaders"/>
	<xsl:template match="wsa:Address" mode="stripInternalHeaders"/>
	<xsl:template match="wsa:Action" mode="stripInternalHeaders">
		<xsl:if test="string(dp:variable($SERVICE_IDENTIFIER_VAR_NAME)) =
			'{http://www.ibm.com/AC/commonbaseevent1_0_1}CommonBaseEvents'">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="wsa:MessageID" mode="stripInternalHeaders"/>
	<xsl:template match="wsse:Security" mode="stripInternalHeaders">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="wsse:UsernameToken" mode="stripInternalHeaders"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="*[local-name() = 'Body']" mode="stripInternalHeaders">
		<xsl:copy-of select="."/>
	</xsl:template>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to create a SOAP Fault -->
	<xsl:template name="CreateSOAPFault">
		<xsl:choose>
			<xsl:when test="dp:variable($REQ_SOAP_NAMESPACE_VAR_NAME) = $SOAP12_NAMESPACE_URI">
				<soapenv:Fault xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope">
					<soapenv:Code>
						<soapenv:Value>DPDIRECT.SERVICE_ERROR</soapenv:Value>
					</soapenv:Code>
					<soapenv:Reason>
						<soapenv:Text xml:lang="en-US">Please see details.</soapenv:Text>
					</soapenv:Reason>
					<soapenv:Role>www.dpdirect.org</soapenv:Role>
					<soapenv:Detail>
						<xsl:choose>
							<xsl:when test="$CODE_MAP_ENTRY/Row">
								<err:EnterpriseErrors>
									<xsl:call-template name="CreateEnterpriseError"/>
								</err:EnterpriseErrors>
							</xsl:when>
							<xsl:otherwise>
								<!-- This is the result of an error code mapping configuration error.
							Log the error to the system log and return the SOAP fault as-is -->
								<xsl:call-template name="WriteSysLogInfoMsg">
									<xsl:with-param name="MSG">
										<xsl:text>Failed to locate a code map entry. Ensure that a catch-all configuration is present in the enterprise message codes mapping file.</xsl:text>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</soapenv:Detail>
				</soapenv:Fault>
			</xsl:when>
			<xsl:otherwise>
				<soapenv:Fault xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
					<faultcode>DPDIRECT.SERVICE_ERROR</faultcode>
					<faultstring>Please see details.</faultstring>
					<faultactor>www.dpdirect.org</faultactor>
					<detail>
						<xsl:choose>
							<xsl:when test="$CODE_MAP_ENTRY/Row">
								<err:EnterpriseErrors>
									<xsl:call-template name="CreateEnterpriseError"/>
								</err:EnterpriseErrors>
							</xsl:when>
							<xsl:otherwise>
								<!-- This is the result of an error code mapping configuration error.
							Log the error to the system log and return the SOAP fault as-is -->
								<xsl:call-template name="WriteSysLogInfoMsg">
									<xsl:with-param name="MSG">
										<xsl:text>Failed to locate a code map entry. Ensure that a catch-all configuration is present in the enterprise message codes mapping file.</xsl:text>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</detail>
				</soapenv:Fault>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Named template to create a new enterprise error from a code map entry -->
	<xsl:template name="CreateEnterpriseError">
		<xsl:variable name="ERROR_TEMPLATE">
			<err:SubCode/>
			<err:MessageOrigin/>
			<err:Code/>
			<err:Description/>
			<err:SubDescription/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$CODE_MAP_ENTRY/Row/Subtype = 'Logic'">
				<err:BusinessErrors>
					<err:BusinessError>
						<xsl:apply-templates select="$ERROR_TEMPLATE" mode="mapError"/>
					</err:BusinessError>
				</err:BusinessErrors>
			</xsl:when>
			<xsl:when test="$CODE_MAP_ENTRY/Row/Subtype = 'Validation'">
				<err:ValidationErrors>
					<err:ValidationError>
						<xsl:apply-templates select="$ERROR_TEMPLATE" mode="mapError"/>
					</err:ValidationError>
				</err:ValidationErrors>
			</xsl:when>
			<xsl:when test="$CODE_MAP_ENTRY/Row/Subtype = 'Security'">
				<err:SecurityErrors>
					<err:SecurityError>
						<xsl:apply-templates select="$ERROR_TEMPLATE" mode="mapError"/>
					</err:SecurityError>
				</err:SecurityErrors>
			</xsl:when>
			<xsl:otherwise>
				<err:SystemErrors>
					<err:SystemError>
						<xsl:apply-templates select="$ERROR_TEMPLATE" mode="mapError"/>
					</err:SystemError>
				</err:SystemErrors>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Named template to generate a Syslog error message -->
	<xsl:template name="GenerateSysLogErrorMsg">
		<xsl:variable name="TRANSACTION_EVENT_TYPE">
			<xsl:choose>
				<xsl:when test="($FRONTSIDE_PROTOCOL = 'dpmq') and (dp:variable($DP_SERVICE_ERROR_IGNORE) != '1')">
					<xsl:text>Backout</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>Error</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:text>,EventCode=</xsl:text>
		<xsl:value-of select="string($DP_EVENT_CODE)"/>
		<xsl:if test="string($DP_EVENT_SUBCODE) != string($DP_EVENT_CODE)">
			<xsl:text>,EventSubCode=</xsl:text>
			<xsl:value-of select="string($DP_EVENT_SUBCODE)"/>
		</xsl:if>
		<xsl:if test="$ENTERPRISE_ERROR_CODE != ''">
			<xsl:text>,ErrorCode=</xsl:text>
			<xsl:value-of select="$ENTERPRISE_ERROR_CODE"/>
		</xsl:if>
		<xsl:if test="$DETAILED_DESCRIPTION_TEXT != ''">
			<xsl:text>,ErrorMsg='</xsl:text>
			<xsl:value-of select="$DETAILED_DESCRIPTION_TEXT"/>
			<xsl:text>'</xsl:text>
		</xsl:if>
		<xsl:if test="$DETAILED_ADDITIONAL_TEXT != ''">
			<xsl:text>,AddDetail='</xsl:text>
			<xsl:value-of select="substring(normalize-space($DETAILED_ADDITIONAL_TEXT), 1, 256)"/>
			<xsl:text>'</xsl:text>
		</xsl:if>
		<xsl:text>,ErrorFlowDirection=</xsl:text>
		<xsl:value-of select="string($FLOW_DIRECTION)"/>
	</xsl:template>
</xsl:stylesheet>
