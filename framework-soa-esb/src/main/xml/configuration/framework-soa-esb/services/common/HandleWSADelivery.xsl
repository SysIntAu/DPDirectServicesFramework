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
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:wsa="http://www.w3.org/2005/08/addressing"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	extension-element-prefixes="dp regexp" version="1.0" exclude-result-prefixes="dp regexp scm wsse wsa">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>Tim Goodwill</dc:creator>
			<dc:date>2016-12-12</dc:date>
			<dc:title>Copy SOAP Fault to a WS FaultTo or ReplyTo endpoint</dc:title>
			<dc:subject>Copy SOAP Fault to a WS FaultTo or ReplyTo endpoint</dc:subject>
			<dc:contributor>Tim Goodwill</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--========================================================================
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///ESB_Services/framework/FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!-- Service Metadata document -->
	<xsl:variable name="TX_RULE_TYPE" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
	<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
	<xsl:variable name="USER_NAME" select="normalize-space(dp:variable($REQ_USER_NAME_VAR_NAME))"/>
	<xsl:variable name="REQ_MQMD" select="dp:variable($REQ_MQMD_VAR_NAME)"/>
	<xsl:variable name="CURRENT_MQMD">
		<xsl:choose>
			<xsl:when test="$REQ_MQMD/*">
				<xsl:copy-of select="$REQ_MQMD"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="GetCurrentReqMQMD"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- WSA RelatesTo ID -->
	<xsl:variable name="REQ_WSA_RELATES_TO_ID" select="dp:variable($REQ_WSA_RELATES_TO_VAR_NAME)"/>
	<xsl:variable name="RES_WSA_RELATES_TO_ID" select="dp:variable($RES_WSA_RELATES_TO_VAR_NAME)"/>
	<!-- WSA MessageID -->
	<xsl:variable name="REQ_WSA_MESSAGE_ID" select="dp:variable($REQ_WSA_MSG_ID_VAR_NAME)"/>
	<xsl:variable name="RES_WSA_MESSAGE_ID" select="dp:variable($RES_WSA_MSG_ID_VAR_NAME)"/>
	<!-- WSA Endpoints -->
	<xsl:variable name="REQ_WSA_TO" select="normalize-space(dp:variable($REQ_WSA_TO_VAR_NAME))"/>
	<xsl:variable name="REQ_WSA_REPLY_TO" select="normalize-space(dp:variable($REQ_WSA_REPLY_TO_VAR_NAME))"/>
	<xsl:variable name="REQ_WSA_FAULT_TO" select="normalize-space(dp:variable($REQ_WSA_FAULT_TO_VAR_NAME))"/>
	<xsl:variable name="RES_WSA_TO" select="normalize-space(dp:variable($RES_WSA_TO_VAR_NAME))"/>
	<xsl:variable name="RES_WSA_FAULT_TO" select="normalize-space(dp:variable($RES_WSA_FAULT_TO_VAR_NAME))"/>
	<!-- WSA Endpoint -->
	<xsl:variable name="SOAP_FAULT_MSG_TYPE" select="count(/soapenv:Envelope/soapenv:Body/soapenv:Fault) > 0"/>
	<xsl:variable name="WSA_DELIVERY_ENDPOINT">
		<xsl:choose>
			<xsl:when test="$TX_RULE_TYPE = 'request'">
				<xsl:choose>
					<xsl:when test="$SOAP_FAULT_MSG_TYPE and ($REQ_WSA_FAULT_TO != '')">
						<xsl:value-of select="$REQ_WSA_FAULT_TO"/>
					</xsl:when>
					<xsl:when test="$REQ_WSA_TO != ''">
						<xsl:value-of select="$REQ_WSA_TO"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<!-- Request-Error flow : Did not make it to the backend -->
			<xsl:when test="not(dp:responding()) and ($TX_RULE_TYPE = 'error')">
				<xsl:choose>
					<xsl:when test="$SOAP_FAULT_MSG_TYPE and ($REQ_WSA_FAULT_TO != '')">
						<xsl:value-of select="$REQ_WSA_FAULT_TO"/>
					</xsl:when>
					<xsl:when test="$REQ_WSA_REPLY_TO != ''">
						<xsl:value-of select="$REQ_WSA_REPLY_TO"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<!-- Response and Response-Error flows -->
			<xsl:when test="dp:responding()">
				<xsl:choose>
					<!-- deliver properly addressed responses -->
					<xsl:when test="$RES_WSA_TO != ''">
						<xsl:value-of select="$RES_WSA_TO"/>
					</xsl:when>
					<xsl:when test="$SOAP_FAULT_MSG_TYPE and ($REQ_WSA_FAULT_TO != '')">
						<xsl:value-of select="$REQ_WSA_FAULT_TO"/>
					</xsl:when>
					<xsl:when test="$REQ_WSA_REPLY_TO != ''">
						<xsl:value-of select="$REQ_WSA_REPLY_TO"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>			
		</xsl:choose>
	</xsl:variable>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:if test="$WSA_DELIVERY_ENDPOINT != ''">
			<xsl:variable name="REQ_SOAP_ENV" select="dp:variable($REQ_SOAP_ENV_VAR_NAME)"/>
			<xsl:variable name="RES_MSG">
				<xsl:apply-templates select="." mode="outboundWSAHeaders"/>
			</xsl:variable>
			<xsl:variable name="UC" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
			<xsl:variable name="LC" select="'abcdefghijklmnopqrstuvwxyz'" />
			<xsl:variable name="WSA_TO_UC" select="translate(normalize-space($WSA_DELIVERY_ENDPOINT), $LC, $UC)"/>
			<xsl:choose>
				<xsl:when test="(substring($WSA_TO_UC, 1, 2) = 'MQ')
					or (substring($WSA_TO_UC, 1, 2) = 'DPMQ')">
					<!--  eg. mq://host:port?QueueManager=QM1;RequestQueue=Q123;ReplyQueue=Q456 -->
					<xsl:variable name="WSA_ADJUSTED" select="concat($WSA_TO_UC, ';')"/>
					<xsl:variable name="REPLYTO_QMNAME" select="substring-before(substring-after($WSA_ADJUSTED, 'QUEUEMANAGER='), ';')"/>
					<xsl:variable name="QMGR_NAME" select="$SOA_QMGR_GROUP_NAME"/>
					<xsl:variable name="REQ_QUEUE_NAME" select="substring-before(substring-after($WSA_ADJUSTED, 'REQUESTQUEUE='), ';')"/>
					<!-- Construct the MQ URL -->
					<xsl:variable name="TARGET_MQ_URL">
						<xsl:call-template name="ConstructDpmqUrl">
							<xsl:with-param name="QMGR_NAME" select="$QMGR_NAME"/>
							<xsl:with-param name="REQ_QUEUE_NAME" select="$REQ_QUEUE_NAME"/>
							<xsl:with-param name="ASYNC" select="'true'"/>
						</xsl:call-template>
					</xsl:variable>
					<!-- Generate the output MQMD -->
					<xsl:variable name="OUTPUT_MQMD">
						<xsl:call-template name="CreateMQMD"/>
					</xsl:variable>
					<xsl:call-template name="PutMsgToMQUrl">
						<xsl:with-param name="QUEUE_URL" select="$TARGET_MQ_URL"/>
						<xsl:with-param name="REMOTE_QMGR" select="$REPLYTO_QMNAME"/>
						<xsl:with-param name="QUEUE_NAME" select="$REQ_QUEUE_NAME"/>
						<xsl:with-param name="MSG" select="$RES_MSG"/>
						<xsl:with-param name="MQMD_NODESET" select="$OUTPUT_MQMD"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="(substring($WSA_TO_UC, 1, 3) = 'WMQ') 
					or (substring($WSA_TO_UC, 1, 3) = 'JMS')">
					<!-- wmq starndard URI eg. IMTEL SV370 
		eg. wmq://example.com:1415/msg/queue/INS.QUOTE.REQUEST@MOTOR.INS ?ReplyTo=msg/queue/INS.QUOTE.REPLY@BRANCH452&persistence=MQPER_NOT_PERSISTENT -->
					<!-- jms queue standard URI 
		eg. jms:/queue?destination=myQ@myRQM&initialContextFactory=com.ibm.mq.jms.Nojndi -->
					<xsl:variable name="WSA_ADJUSTED">
						<xsl:choose>
							<xsl:when test="contains($WSA_TO_UC, 'QUEUE?DESTINATION=')">
								<!-- Roll the JMS URI into a common WMQ URI format for processing -->
								<xsl:value-of select="concat('WMQ://QUEUE/' , substring-after($WSA_TO_UC, 'QUEUE?DESTINATION='), '&#38;')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat(translate($WSA_TO_UC,'?','&#38;'), '&#38;')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="REPLYTO_QMNAME" select="substring-before(substring-after($WSA_ADJUSTED, '@'), '&#38;')"/>
					<xsl:variable name="QMGR_NAME" select="$SOA_QMGR_GROUP_NAME"/>
					<xsl:variable name="REQ_QUEUE_NAME">
						<xsl:choose>
							<xsl:when test="contains(substring-before($WSA_ADJUSTED, '&#38;'), '@')">
								<xsl:value-of select="substring-before(substring-after($WSA_ADJUSTED, '/QUEUE/'), '@')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="substring-after(substring-before($WSA_ADJUSTED, '&#38;'), '/QUEUE/')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- Construct the MQ URL -->
					<xsl:variable name="TARGET_MQ_URL">
						<xsl:call-template name="ConstructDpmqUrl">
							<xsl:with-param name="QMGR_NAME" select="$QMGR_NAME"/>
							<xsl:with-param name="REQ_QUEUE_NAME" select="$REQ_QUEUE_NAME"/>
							<xsl:with-param name="ASYNC" select="'true'"/>
						</xsl:call-template>
					</xsl:variable>
					<!-- Generate the output MQMD -->
					<xsl:variable name="OUTPUT_MQMD">
						<xsl:call-template name="CreateMQMD"/>
					</xsl:variable>
					<xsl:call-template name="PutMsgToMQUrl">
						<xsl:with-param name="QUEUE_URL" select="$TARGET_MQ_URL"/>
						<xsl:with-param name="REMOTE_QMGR" select="$REPLYTO_QMNAME"/>
						<xsl:with-param name="QUEUE_NAME" select="$REQ_QUEUE_NAME"/>
						<xsl:with-param name="MSG" select="$RES_MSG"/>
						<xsl:with-param name="MQMD_NODESET" select="$OUTPUT_MQMD"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="substring($WSA_TO_UC, 1, 4) = 'HTTP'">
					<xsl:call-template name="PutMsgToHTTPUrl">
						<xsl:with-param name="ENDPOINT_URL" select="$WSA_DELIVERY_ENDPOINT"/>
						<xsl:with-param name="MSG" select="$RES_MSG"/>
					</xsl:call-template>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:if test="dp:variable($ERROR_TO_WSA_ENDPOINT_RESULT_VAR_NAME) != ''">
			<xsl:call-template name="WriteSysLogNoticeMsg">
				<xsl:with-param name="LOG_EVENT_KEY">
					<xsl:choose>
						<xsl:when test="($WSA_DELIVERY_ENDPOINT = $REQ_WSA_FAULT_TO) 
							and $SOAP_FAULT_MSG_TYPE or ($TX_RULE_TYPE = 'error')">
							<xsl:text>WSAFaultToDelivery</xsl:text>
						</xsl:when>
						<xsl:when test="$WSA_DELIVERY_ENDPOINT = $REQ_WSA_REPLY_TO">
							<xsl:text>WSAReplyToDelivery</xsl:text>
						</xsl:when>
						<xsl:when test="$WSA_DELIVERY_ENDPOINT = $REQ_WSA_TO">
							<xsl:text>WSAToDelivery</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>WSAMsgDelivery</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
				<xsl:with-param name="KEY_VALUES">
					<xsl:text>,DeliveryResult=</xsl:text>
					<xsl:value-of select="$ERROR_TO_WSA_ENDPOINT_RESULT_VAR_NAME"/>
					<xsl:text>,ResponseCode=</xsl:text>
					<xsl:value-of select="$ERROR_TO_WSA_ENDPOINT_RETURN_CODE_VAR_NAME"/>
					<xsl:if test="$REQ_WSA_MESSAGE_ID">
						<xsl:text>,MessageID=</xsl:text>
						<xsl:value-of select="$REQ_WSA_MESSAGE_ID"/>
					</xsl:if>
					<xsl:if test="$REQ_WSA_RELATES_TO_ID">
						<xsl:text>,RelatesTo=</xsl:text>
						<xsl:value-of select="$REQ_WSA_RELATES_TO_ID"/>
					</xsl:if>
					<xsl:text>,WSAEndpointURL='</xsl:text>
					<xsl:value-of select="$WSA_DELIVERY_ENDPOINT"/>
					<xsl:text>'</xsl:text>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<!-- Copy input to output -->
		<xsl:copy-of select="."/>
	</xsl:template>
	<!--=============================================================-->
	<!-- MODAL TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to create appropriate WS Addressing for Fault response -->
	<xsl:template match="wsa:MessageID" mode="outboundWSAHeaders">
		<xsl:choose>
			<xsl:when test="$TX_RULE_TYPE = 'request'">
				<xsl:copy-of select="."/>
			</xsl:when>
			<xsl:otherwise>
				<!-- New WSA MessageID -->
				<xsl:variable name="NEW_MSG_ID" select="dp:generate-uuid()"/>
				<xsl:copy>
					<xsl:value-of select="$NEW_MSG_ID"/>
				</xsl:copy>
				<xsl:if test="not(preceding-sibling::wsa:RelatesTo) and not(following-sibling::wsa:RelatesTo)">
					<wsa:RelatesTo>
						<xsl:choose>
							<xsl:when test="$RES_WSA_RELATES_TO_ID != ''">
								<xsl:value-of select="$RES_WSA_RELATES_TO_ID"/>
							</xsl:when>
							<xsl:when test="$REQ_WSA_RELATES_TO_ID != ''">
								<xsl:value-of select="$REQ_WSA_RELATES_TO_ID"/>
							</xsl:when>
							<xsl:when test="$REQ_WSA_MESSAGE_ID != ''">
								<xsl:value-of select="$REQ_WSA_MESSAGE_ID"/>
							</xsl:when>
						</xsl:choose>
					</wsa:RelatesTo>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template to create appropriate WS Addressing for Fault response -->
	<xsl:template match="wsa:RelatesTo" mode="outboundWSAHeaders">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="$RES_WSA_RELATES_TO_ID != ''">
					<xsl:value-of select="$RES_WSA_RELATES_TO_ID"/>
				</xsl:when>
				<xsl:when test="$REQ_WSA_RELATES_TO_ID != ''">
					<xsl:value-of select="$REQ_WSA_RELATES_TO_ID"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$REQ_WSA_MESSAGE_ID"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<!-- Template to create appropriate WS Addressing for Fault response -->
	<xsl:template match="wsa:To" mode="outboundWSAHeaders">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="$WSA_DELIVERY_ENDPOINT != ''">
					<xsl:value-of select="$WSA_DELIVERY_ENDPOINT"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'http://www.w3.org/2005/08/addressing/anonymous'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<!-- Template to create appropriate WS Addressing for Fault response -->
	<xsl:template match="wsa:ReplyTo" mode="outboundWSAHeaders">
		<xsl:if test="$TX_RULE_TYPE = 'request'">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
	<!-- Template to create appropriate WS Addressing for Fault response -->
	<xsl:template match="wsa:FaultTo" mode="outboundWSAHeaders">
		<xsl:if test="$TX_RULE_TYPE = 'request'">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
	<!-- Template to create appropriate WS Addressing for Fault response -->
	<xsl:template match="wsa:Action" mode="outboundWSAHeaders">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="$TX_RULE_TYPE = 'error' or $SOAP_FAULT_MSG_TYPE">
					<xsl:value-of select="concat(normalize-space(.),'/Fault')"/>
				</xsl:when>
				<xsl:when test="($TX_RULE_TYPE = 'response') and contains(normalize-space(.), 'Response')">
					<xsl:value-of select="concat(normalize-space(.),'/Response')"/>
				</xsl:when>
				<xsl:when test="$TX_RULE_TYPE = 'response'">
					<xsl:value-of select="concat(normalize-space(.),'Response')"/>
				</xsl:when>
				<xsl:when test="$TX_RULE_TYPE = 'request'">
					<xsl:value-of select="normalize-space(.)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<!-- Template to copy through limited set of "wsse:Security" header content  (Strips SAML Assertion and related dig sig content) -->
	<xsl:template match="wsse:Security" mode="outboundWSAHeaders">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="wsse:UsernameToken" mode="outboundWSAHeaders"/> 
		</xsl:copy>
	</xsl:template>
	<!-- Template to strip "scm:ServiceChainMetadata" headers -->
	<xsl:template match="scm:ServiceChainMetadata" mode="outboundWSAHeaders">
		<!-- Strip elements -->
	</xsl:template>
	<!-- Standard identity template -->
	<xsl:template match="node()|@*" mode="outboundWSAHeaders">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="outboundWSAHeaders"/>
		</xsl:copy>
	</xsl:template>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to put a message on an MQ queue -->
	<xsl:template name="PutMsgToMQUrl">
		<xsl:param name="QUEUE_URL"/>
		<xsl:param name="REMOTE_QMGR"/>
		<xsl:param name="QUEUE_NAME"/>
		<xsl:param name="MSG"/>
		<xsl:param name="MQMD_NODESET">
			<!-- Initialise the param with an empty 'MQMD' node. This prevents a DataPower compilation 
				warning about an illegal cast from string to nodeset when calling dp:serialize() below. -->
			<MQMD/>
		</xsl:param>
		<xsl:variable name="SERIALIZED_MQMD">
			<dp:serialize select="$MQMD_NODESET" omit-xml-decl="yes"/>
		</xsl:variable>
		<!-- Optional MQOD Header for the request -->
		<xsl:variable name="MQOD_NODESET">
			<xsl:if test="normalize-space($REMOTE_QMGR) != ''">
				<MQOD>
					<Version>2</Version>
					<ObjectName>
						<xsl:value-of select="normalize-space($QUEUE_NAME)"/>
					</ObjectName>
					<ObjectQMgrName>
						<xsl:value-of select="normalize-space($REMOTE_QMGR)"/>
					</ObjectQMgrName>
				</MQOD>
			</xsl:if>
		</xsl:variable>	
		<!-- Serialize the MQOD nodeset -->
		<xsl:variable name="SERIALIZED_MQOD">
			<xsl:if test="$MQOD_NODESET/*">
				<dp:serialize select="$MQOD_NODESET" omit-xml-decl="yes"/>
			</xsl:if>
		</xsl:variable>
		<!-- Header for the request -->
		<xsl:variable name="HEADERS">
			<header name="{$MQMD_ELEMENT_NAME}">
				<xsl:value-of select="$SERIALIZED_MQMD"/>
			</header>
			<!-- Set the MQMD header -->
			<dp:set-request-header name="$MQMD_ELEMENT_NAME" value="$SERIALIZED_MQMD"/>
			<xsl:if test="$SERIALIZED_MQOD != ''">
				<header name="{$MQOD_ELEMENT_NAME}">
					<xsl:value-of select="$SERIALIZED_MQOD"/>
				</header>
				<!-- Set the MQOD header -->
				<dp:set-request-header name="$MQOD_ELEMENT_NAME" value="$SERIALIZED_MQOD"/>
			</xsl:if>
		</xsl:variable>
		<!-- Timestamp for the request -->
		<xsl:variable name="REQUEST_TIMEVALUE">
			<xsl:value-of select="string(dp:time-value())"/>
		</xsl:variable>
		<!-- Create the url-open call -->
		<xsl:variable name="RESPONSE">
			<dp:url-open target="{$QUEUE_URL}" http-headers="$HEADERS" response="responsecode-ignore">
				<xsl:copy-of select="$MSG"/>
			</dp:url-open>
		</xsl:variable>
		<dp:set-variable name="$ERROR_TO_WSA_ENDPOINT_RETURN_CODE_VAR_NAME" value="string($RESPONSE/url-open/responsecode)"/>
		<xsl:choose>
			<xsl:when test="$RESPONSE/url-open/responsecode > '0'">
				<dp:set-variable name="$WSA_ENDPOINT_RESULT_VAR_NAME" value="string('FAILURE')"/>
				<xsl:if test="$SOAP_FAULT_MSG_TYPE or ($TX_RULE_TYPE = 'error')">
					<dp:set-variable name="$ERROR_TO_WSA_ENDPOINT_RESULT_VAR_NAME" value="string('FAILURE')"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<dp:set-variable name="$WSA_ENDPOINT_RESULT_VAR_NAME" value="string('SUCCESS')"/>
				<xsl:if test="$SOAP_FAULT_MSG_TYPE or ($TX_RULE_TYPE = 'error')">
					<dp:set-variable name="$ERROR_TO_WSA_ENDPOINT_RESULT_VAR_NAME" value="string('SUCCESS')"/>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="PutMsgToHTTPUrl">
		<xsl:param name="ENDPOINT_URL"/>
		<xsl:param name="MSG"/>
		<!-- Delete all existing HTTP request headers -->
		<xsl:call-template name="DeleteHttpRequestHeaders"/>
		<!-- Set HTTP Headers provided in the policy config -->
		<xsl:variable name="CONTENT_TYPE">
			<xsl:value-of select="'text/xml'"/>
		</xsl:variable>
		<xsl:variable name="HTTP_HEADERS">
			<header name="Connection">
				<xsl:value-of select="'close'"/>
			</header>
			<dp:set-http-request-header name="Connection" value="'close'"/>
			<header name="SOAPAction">
				<xsl:value-of select="''"/>
			</header>
			<dp:set-http-request-header name="SOAPAction" value="''"/>
			<header name="Content-Type">
				<xsl:value-of select="$CONTENT_TYPE"/>
			</header>
			<dp:set-http-request-header name="Content-Type" value="$CONTENT_TYPE"/>
		</xsl:variable>
		<!-- Timestamp for the request -->
		<xsl:variable name="REQUEST_TIMEVALUE">
			<xsl:value-of select="string(dp:time-value())"/>
		</xsl:variable>
		<!-- Open URL and capture the response -->
		<xsl:variable name="RESPONSE">
			<!-- For logging and error generation -->
			<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$ENDPOINT_URL"/>
			<!-- Make the service call -->
			<dp:url-open target="{$ENDPOINT_URL}" http-headers="$HTTP_HEADERS"
				response="responsecode" timeout="{number($TIMEOUT_SECONDS)}"
				content-type="{$CONTENT_TYPE}">
				<xsl:copy-of select="$MSG"/>
			</dp:url-open>
		</xsl:variable>
		<!-- Handle the response -->
		<dp:set-variable name="$ERROR_TO_WSA_ENDPOINT_RETURN_CODE_VAR_NAME" value="string($RESPONSE/url-open/responsecode)"/>
		<xsl:choose>
			<xsl:when test="$RESPONSE/url-open[(string(responsecode) != '200') or (errorcode) or (errorstring)]">
				<dp:set-variable name="$WSA_ENDPOINT_RESULT_VAR_NAME" value="string('FAILURE')"/>
				<xsl:if test="$SOAP_FAULT_MSG_TYPE or ($TX_RULE_TYPE = 'error')">
					<dp:set-variable name="$ERROR_TO_WSA_ENDPOINT_RESULT_VAR_NAME" value="string('FAILURE')"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<dp:set-variable name="$WSA_ENDPOINT_RESULT_VAR_NAME" value="string('SUCCESS')"/>
				<xsl:if test="$SOAP_FAULT_MSG_TYPE or ($TX_RULE_TYPE = 'error')">
					<dp:set-variable name="$ERROR_TO_WSA_ENDPOINT_RESULT_VAR_NAME" value="string('SUCCESS')"/>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- create MQMD -->
	<xsl:template name="CreateMQMD">
		<!-- New MQ Message ID for use in the outbound MQMD -->
		<xsl:variable name="NEW_MSG_ID" select="dp:radix-convert(dp:random-bytes(24),64,16)"/>
		<MQMD>
			<StrucId>
				<xsl:value-of select="$MQMD_STRUC_ID"/>
			</StrucId>
			<Version>
				<xsl:value-of select="$MQMD_VERSION_1"/>
			</Version>
			<Report>
				<xsl:value-of select="$MQRO_NONE"/>
			</Report>
			<MsgType>
				<xsl:value-of select="$MQMT_DATAGRAM"/>
			</MsgType>
			<Expiry>
				<xsl:value-of select="$MQEI_UNLIMITED"/>
			</Expiry>
			<Feedback>
				<xsl:value-of select="$MQFB_NONE"/>
			</Feedback>
			<Encoding>
				<xsl:value-of select="'&#x20;'"/>
			</Encoding>
			<CodedCharSetId>
				<xsl:value-of select="$MQ_CCSID_UTF8"/>
			</CodedCharSetId>
			<Format>
				<xsl:value-of select="$MQFMT_STRING"/>
			</Format>
			<Priority>
				<xsl:value-of select="'0'"/>
			</Priority>
			<Persistence>
				<xsl:value-of select="$MQPER_NOT_PERSISTENT"/>
			</Persistence>
			<MsgId>
				<xsl:choose>
					<!-- MQ Msg Id is 48 char hexdec -->
					<xsl:when test="(string-length($REQ_WSA_MESSAGE_ID) = 48)
						and regexp:match($REQ_WSA_MESSAGE_ID, '^[a-fA-F0-9]*$')">
						<xsl:value-of select="$REQ_WSA_MESSAGE_ID"/>
					</xsl:when>
					<xsl:when test="normalize-space(($CURRENT_MQMD//MsgId)[1]) != ''">
						<xsl:value-of select="normalize-space(($CURRENT_MQMD//MsgId)[1])"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$NEW_MSG_ID"/>
					</xsl:otherwise>
				</xsl:choose>
			</MsgId>
			<CorrelId>
				<xsl:choose>
					<!-- MQ Correl Id is 48 char hexdec -->
					<xsl:when test="(string-length($REQ_WSA_RELATES_TO_ID) = 48)
						and regexp:match($REQ_WSA_RELATES_TO_ID, '^[a-fA-F0-9]*$')">
						<xsl:value-of select="$REQ_WSA_RELATES_TO_ID"/>
					</xsl:when>
					<!-- MQ Msg Id is 48 char hexdec -->
					<xsl:when test="(string-length($REQ_WSA_MESSAGE_ID) = 48)
						and regexp:match($REQ_WSA_MESSAGE_ID, '^[a-fA-F0-9]*$')">
						<xsl:value-of select="$REQ_WSA_MESSAGE_ID"/>
					</xsl:when>
					<xsl:when test="normalize-space(($CURRENT_MQMD//CorrelId)[1]) != ''">
						<xsl:value-of select="normalize-space(($CURRENT_MQMD//CorrelId)[1])"/>
					</xsl:when>
					<xsl:when test="normalize-space(($CURRENT_MQMD//MsgId)[1]) != ''">
						<xsl:value-of select="normalize-space(($CURRENT_MQMD//MsgId)[1])"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$NEW_MSG_ID"/>
					</xsl:otherwise>
				</xsl:choose>
			</CorrelId>
			<BackoutCount>
				<xsl:value-of select="'0'"/>
			</BackoutCount>
			<ReplyToQ>
				<xsl:value-of select="'&#x20;'"/>
			</ReplyToQ>
			<ReplyToQMgr>
				<xsl:value-of select="''"/>
			</ReplyToQMgr>
			<UserIdentifier>
				<xsl:choose>
					<xsl:when test="normalize-space($USER_NAME) != ''">
						<xsl:value-of select="$USER_NAME"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'DPESB'"/>
					</xsl:otherwise>
				</xsl:choose>
			</UserIdentifier>
			<AccountingToken>
				<xsl:value-of select="'0000000000000000000000000000000000000000000000000000000000000000'"/>
			</AccountingToken>
			<ApplIdentityData>
				<xsl:value-of select="'&#x20;'"/>
			</ApplIdentityData>
			<PutApplType>
				<xsl:value-of select="'0'"/>
			</PutApplType>
			<PutApplName>
				<xsl:value-of select="'DPESB'"/>
			</PutApplName>
			<PutDate>
				<xsl:call-template name="GetCurrentUTCDateAsYYYYMMDD"/>
			</PutDate>
			<PutTime>
				<xsl:call-template name="GetCurrentUTCTimeAsHHMMSSTH"/>
			</PutTime>
			<ApplOriginData>
				<xsl:value-of select="'&#x20;'"/>
			</ApplOriginData>
		</MQMD>
	</xsl:template>
</xsl:stylesheet>
