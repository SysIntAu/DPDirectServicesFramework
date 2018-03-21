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
	*	distributed under the License is distributeon an "AS IS" BASIS,
	*	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	*	See the License for the specific language governing permissions and
	*	limitations under the License.
	**********************************************************************-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	extension-element-prefixes="dp regexp" version="1.0" exclude-result-prefixes="dp">

	<!--========================================================================
		Purpose: Puts/posts a copy of the current context message to an MQ queue or HTTP Endpoint
		
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		2016-12-12	v1.0	Tim Goodwill		HTTP & Initial Gateway version.
		========================================================================-->

	<!--============== Included Stylesheets =========================-->
	<xsl:include href="FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!-- Transaction rule type -->
	<xsl:variable name="TX_RULE_TYPE" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
	<!-- Service Metadata document -->
	<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
	<!-- Optional UrlOpenOutputVar attributes will save the response message to the environment -->
	<xsl:variable name="URL_OPEN_OUTPUT_VAR_NAME"
		select="normalize-space($SERVICE_METADATA/OperationConfig/Copy[1]/UrlOpenOutputVar[1])"/>
	<xsl:variable name="USER_NAME" select="normalize-space(dp:variable($REQ_USER_NAME_VAR_NAME))"/>
	<xsl:variable name="CURRENT_MQMD">
		<xsl:call-template name="GetReqMQMD"/>
	</xsl:variable>
	<xsl:variable name="PROVIDER_NAME"
		select="string($SERVICE_METADATA/OperationConfig/Copy[1]/@provider)"/>
	<!-- WSA RelatesTo ID -->
	<xsl:variable name="WSA_RELATES_TO_ID" select="dp:variable($REQ_WSA_RELATES_TO_VAR_NAME)"/>
	<!-- WSA MessageID -->
	<xsl:variable name="WSA_MESSAGE_ID" select="dp:variable($REQ_WSA_MSG_ID_VAR_NAME)"/>
	<!-- New MQ Message ID for use in the outbound MQMD -->
	<xsl:variable name="NEW_MSG_ID" select="dp:radix-convert(dp:random-bytes(24),64,16)"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Save provider name to the environment -->
		<dp:set-variable name="$PROVIDER_VAR_NAME" value="string($SERVICE_METADATA/OperationConfig/Copy[1]/@provider)"/>
		<!-- Optional stylesheet to transform the input document to create the request doc for the service call -->
		<xsl:variable name="XSLT_LOCATION"
			select="$SERVICE_METADATA/OperationConfig/Copy[1]/Transform[1]/Stylesheet[1]"/>
		<!-- SOAP config stylesheet -->
		<xsl:variable name="SOAP_XSLT_LOCATION"
			select="$SERVICE_METADATA/OperationConfig/Copy[1]/SOAPConfig[1]"/>
		<xsl:variable name="FAIL_ON_ERROR">
			<xsl:choose>
				<xsl:when
					test="not($SERVICE_METADATA/OperationConfig/Copy[1]/@failOnError)">
					<xsl:value-of select="'true'"/>
				</xsl:when>
				<xsl:when
					test="(normalize-space($SERVICE_METADATA/OperationConfig/Copy[1]/@failOnError)
					= 'true') or
					(normalize-space($SERVICE_METADATA/OperationConfig/Copy[1]/@failOnError)
					= '1')">
					<xsl:value-of select="'true'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'false'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="REQ_MSG">
			<xsl:choose>
				<xsl:when test="normalize-space($XSLT_LOCATION) != ''">
					<xsl:call-template name="ApplyTranformPipeline">
						<xsl:with-param name="INPUT_NODE" select="."/>
						<xsl:with-param name="TRANSFORM_NODE"
							select="$SERVICE_METADATA/OperationConfig/Copy[1]/Transform[1]"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="normalize-space($SOAP_XSLT_LOCATION) != ''">
					<xsl:call-template name="ApplySOAPTransform">
						<xsl:with-param name="INPUT_NODE" select="."/>
						<xsl:with-param name="XSLT_LOCATION" select="$SOAP_XSLT_LOCATION"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="dp:variable($CONTENT_BINARY_VAR_NAME) = 'true'">
					<!-- Copy handling of Binary or MTOM messages -->
					<dp:serialize select="." omit-xml-decl="yes"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$SERVICE_METADATA/OperationConfig/Copy[1]/MQRouting">
				<xsl:variable name="QMGR_NAME" select="$SERVICE_METADATA/OperationConfig/Copy[1]/MQRouting[1]/QueueMgr[1]"/>
				<xsl:variable name="REMOTE_QMGR_NAME" select="$SERVICE_METADATA/OperationConfig/Copy[1]/MQRouting[1]/RemoteQueueMgr[1]"/>
				<xsl:variable name="REQ_QUEUE_NAME"
					select="$SERVICE_METADATA/OperationConfig/Copy[1]/MQRouting[1]/RequestQueue[1]"/>
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
					<xsl:with-param name="REMOTE_QMGR" select="$REMOTE_QMGR_NAME"/>
					<xsl:with-param name="QUEUE_NAME" select="$REQ_QUEUE_NAME"/>
					<xsl:with-param name="MSG" select="$REQ_MSG"/>
					<xsl:with-param name="MQMD_NODESET" select="$OUTPUT_MQMD"/>
					<xsl:with-param name="FAIL_ON_ERROR" select="$FAIL_ON_ERROR"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$SERVICE_METADATA/OperationConfig/Copy[1]/HTTPEndpoint">
				<xsl:variable name="ENDPOINT_URL"
					select="$SERVICE_METADATA/OperationConfig/Copy[1]/HTTPEndpoint[1]/Address"/>
				<xsl:call-template name="PutMsgToHTTPUrl">
					<xsl:with-param name="ENDPOINT_URL" select="$ENDPOINT_URL"/>
					<xsl:with-param name="MSG" select="$REQ_MSG"/>
					<xsl:with-param name="FAIL_ON_ERROR" select="$FAIL_ON_ERROR"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$SERVICE_METADATA/OperationConfig/Copy[1]/SFTPEndpoint">
				<xsl:variable name="SFTP_FILENAME" select="dp:variable($SFTP_OUTPUT_FILE_NAME)"/>
				<xsl:variable name="ENDPOINT_URL"
					select="concat($SERVICE_METADATA/OperationConfig/Copy[1]/SFTPEndpoint[1]/Address,$SFTP_FILENAME)"/>
				<xsl:call-template name="PutMsgToSFTPUrl">
					<xsl:with-param name="ENDPOINT_URL" select="$ENDPOINT_URL"/>
					<xsl:with-param name="MSG" select="$REQ_MSG"/>
					<xsl:with-param name="FAIL_ON_ERROR" select="$FAIL_ON_ERROR"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
		<!-- Copy input to output -->
		<xsl:copy-of select="."/>
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
		<xsl:param name="FAIL_ON_ERROR"/>
		<!-- Timestamp for the request -->
		<xsl:variable name="REQUEST_TIMEVALUE">
			<xsl:value-of select="string(dp:time-value())"/>
		</xsl:variable>
		<xsl:variable name="SERIALIZED_MQMD">
			<dp:serialize select="$MQMD_NODESET" omit-xml-decl="yes"/>
		</xsl:variable>
		<!-- Optional MQOD retainEV005AndSV539Steps for the request -->
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
			<header name="MQMD">
				<xsl:value-of select="$SERIALIZED_MQMD"/>
			</header>
			<!-- Set the MQMD header -->
			<dp:set-request-header name="$MQMD_ELEMENT_NAME" value="$SERIALIZED_MQMD"/>
			<xsl:if test="$SERIALIZED_MQOD != ''">
				<header name="MQOD">
					<xsl:value-of select="$SERIALIZED_MQOD"/>
				</header>
				<!-- Set the MQOD header -->
				<dp:set-request-header name="$MQOD_ELEMENT_NAME" value="$SERIALIZED_MQOD"/>
			</xsl:if>
		</xsl:variable>
		<!-- Create the url-open call -->
		<xsl:variable name="RESPONSE">
			<dp:url-open target="{$QUEUE_URL}" http-headers="$HEADERS" response="responsecode-ignore">
				<xsl:copy-of select="$MSG"/>
			</dp:url-open>
		</xsl:variable>
		<xsl:if test="$URL_OPEN_OUTPUT_VAR_NAME != ''">
			<dp:set-variable name="$URL_OPEN_OUTPUT_VAR_NAME" value="$RESPONSE"/>
		</xsl:if>
		<xsl:if test="($FAIL_ON_ERROR = 'true') and ($RESPONSE/url-open/responsecode > '0')">
			<xsl:call-template name="RejectToErrorFlow">
				<xsl:with-param name="MSG">
					<xsl:text>MQ PUT Failure - Failed to copy current message to URL '</xsl:text>
					<xsl:value-of select="$QUEUE_URL"/>
					<xsl:text>'. Copy url-open error: [errorcode=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/errorcode"/>
					<xsl:text>] [errorstring=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/errorstring"/>
					<xsl:text>] [responsecode=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/responsecode"/>
					<xsl:text>]</xsl:text>
				</xsl:with-param>
				<xsl:with-param name="ERROR_CODE" select="'ERROR0014'"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template name="PutMsgToHTTPUrl">
		<xsl:param name="ENDPOINT_URL"/>
		<xsl:param name="MSG"/>
		<xsl:param name="FAIL_ON_ERROR"/>
		<!-- Set the back end URL for logging and skipBackend scenario -->
		<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$ENDPOINT_URL"/>
		<!-- Delete all existing HTTP request headers -->
		<xsl:call-template name="DeleteHttpRequestHeaders"/>
		<!-- Set HTTP Headers provided in the policy config -->
		<xsl:variable name="ATTACHMENT_MANIFEST"
			select="dp:variable($DP_LOCAL_ATTACHMENT_MANIFEST)"/>
		<xsl:variable name="HEADER_LIST">
			<xsl:choose>
				<xsl:when test="$SERVICE_METADATA/OperationConfig/Copy[1]/HTTPEndpoint[1]/HeaderList">
					<xsl:copy-of select="$SERVICE_METADATA/OperationConfig/Copy[1]/HTTPEndpoint[1]/HeaderList[1]"/>
				</xsl:when>
				<xsl:otherwise>
					<HeaderList>
						<Header name="Connection" value="close"/>
						<Header name="SOAPAction" value=""/>
						<Header name="Content-type" value="application/soap+xml"/>
					</HeaderList>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="HTTP_HEADERS">
			<xsl:for-each
				select="$HEADER_LIST/HeaderList/Header">
				<xsl:variable name="NAME" select="normalize-space(@name)"/>
				<xsl:variable name="VALUE">
					<xsl:choose>
						<!-- Over-ride content-type when manifest media type is present -->
						<xsl:when test="($NAME = 'Content-Type') and
							(normalize-space(@value) = '*')">
							<xsl:choose>
								<xsl:when test="$ATTACHMENT_MANIFEST/manifest != ''">
									<xsl:value-of
										select="$ATTACHMENT_MANIFEST/manifest/media-type/value"
									/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="'text/xml'"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<!-- Resolve context variable if a variable name has been provided -->
						<xsl:when test="starts-with(normalize-space(@value),
							'var://context/')">
							<xsl:value-of select="dp:variable(normalize-space(@value))"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="normalize-space(@value)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<header name="{$NAME}">
					<xsl:value-of select="$VALUE"/>
				</header>
				<dp:set-http-request-header name="$NAME" value="$VALUE"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="CONTENT_TYPE">
			<xsl:choose>
				<xsl:when test="$HTTP_HEADERS[@name='Content-Type']">
					<xsl:value-of select="$HTTP_HEADERS[@name='Content-Type']"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'text/xml'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Timestamp for the request -->
		<xsl:variable name="REQUEST_TIMEVALUE">
			<xsl:value-of select="string(dp:time-value())"/>
		</xsl:variable>
		<!-- For logging and error generation -->
		<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$ENDPOINT_URL"/>
		<!-- Open URL and capture the response -->
		<xsl:variable name="RESPONSE">
			<!-- Make the service call -->
			<dp:url-open target="{$ENDPOINT_URL}" http-headers="$HTTP_HEADERS"
				response="responsecode" timeout="{number($TIMEOUT_SECONDS)}"
				content-type="{$CONTENT_TYPE}">
				<xsl:copy-of select="$MSG"/>
			</dp:url-open>
		</xsl:variable>
		<xsl:if test="($FAIL_ON_ERROR = 'true') and $RESPONSE/url-open[(string(responsecode)
			!= '200') or (errorcode) or (errorstring)]">
			<xsl:call-template name="RejectToErrorFlow">
				<xsl:with-param name="MSG">
					<xsl:text>Copy http error: [provider=</xsl:text>
					<xsl:value-of select="$PROVIDER_NAME"/>
					<xsl:text>] [errorcode=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/errorcode"/>
					<xsl:text>] [errorstring=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/errorstring"/>
					<xsl:text>] [responsecode=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/responsecode"/>
					<xsl:text>]</xsl:text>
				</xsl:with-param>
				<xsl:with-param name="ERROR_CODE" select="'ERROR0014'"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<xsl:template name="PutMsgToSFTPUrl">
		<xsl:param name="ENDPOINT_URL"/>
		<xsl:param name="MSG"/>
		<xsl:param name="FAIL_ON_ERROR"/>
		<!-- Set the back end URL for logging and skipBackend scenario -->
		<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$ENDPOINT_URL"/>
		<!-- Timestamp for the request -->
		<xsl:variable name="REQUEST_TIMEVALUE">
			<xsl:value-of select="string(dp:time-value())"/>
		</xsl:variable>
		<!-- Open URL and capture the response -->
		<xsl:variable name="RESPONSE">
			<!-- For logging and error generation -->
			<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$ENDPOINT_URL"/>
			<!-- Make the service call -->
			<dp:url-open target="{$ENDPOINT_URL}" response="responsecode" 
				timeout="{number($TIMEOUT_SECONDS)}" content-type="{$CONTENT_TYPE}">
				<xsl:copy-of select="$MSG"/>
			</dp:url-open>
		</xsl:variable>
		<xsl:if test="($FAIL_ON_ERROR = 'true') and ($RESPONSE/url-open/responsecode != '0')">
			<xsl:call-template name="RejectToErrorFlow">
				<xsl:with-param name="MSG">
					<xsl:text>Copy sftp error: [provider=</xsl:text>
					<xsl:value-of select="$PROVIDER_NAME"/>
					<xsl:text>] [errorcode=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/errorcode"/>
					<xsl:text>] [errorstring=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/errorstring"/>
					<xsl:text>] [responsecode=</xsl:text>
					<xsl:value-of select="$RESPONSE/url-open/responsecode"/>
					<xsl:text>]</xsl:text>
				</xsl:with-param>
				<xsl:with-param name="ERROR_CODE" select="'ERROR0014'"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<!-- create MQMD -->
	<xsl:template name="CreateMQMD">
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
					<xsl:when test="(string-length($WSA_MESSAGE_ID) = 48)
						and regexp:match($WSA_MESSAGE_ID, '^[a-fA-F0-9]*$')">
						<xsl:value-of select="$WSA_MESSAGE_ID"/>
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
					<xsl:when test="(string-length($WSA_RELATES_TO_ID) = 48)
						and regexp:match($WSA_RELATES_TO_ID, '^[a-fA-F0-9]*$')">
						<xsl:value-of select="$WSA_RELATES_TO_ID"/>
					</xsl:when>
					<!-- MQ Msg Id is 48 char hexdec -->
					<xsl:when test="(string-length($WSA_MESSAGE_ID) = 48)
						and regexp:match($WSA_MESSAGE_ID, '^[a-fA-F0-9]*$')">
						<xsl:value-of select="$WSA_MESSAGE_ID"/>
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
	<!-- Template to apply pre Copy XSLT Transform pipeline to the current context node -->
	<xsl:template name="ApplyTranformPipeline">
		<xsl:param name="INPUT_NODE"/>
		<xsl:param name="TRANSFORM_NODE"/>
		<xsl:variable name="XSLT_LOCATION" select="normalize-space($TRANSFORM_NODE//Stylesheet[1])"/>
		<xsl:choose>
			<xsl:when test="normalize-space($XSLT_LOCATION) != ''">
				<xsl:choose>
					<xsl:when test="$TRANSFORM_NODE/following-sibling::Transform[1]">
						<xsl:call-template name="ApplyTranformPipeline">
							<xsl:with-param name="INPUT_NODE"
								select="dp:transform($XSLT_LOCATION,$INPUT_NODE)"/>
							<xsl:with-param name="TRANSFORM_NODE"
								select="$TRANSFORM_NODE/following-sibling::Transform[1]"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="$TRANSFORM_NODE/following-sibling::SOAPConfig[1]">
						<xsl:call-template name="ApplySOAPTransform">
							<xsl:with-param name="INPUT_NODE"
								select="dp:transform($XSLT_LOCATION,$INPUT_NODE)"/>
							<xsl:with-param name="XSLT_LOCATION" select="normalize-space($TRANSFORM_NODE/following-sibling::SOAPConfig[1])"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="dp:transform($XSLT_LOCATION,$INPUT_NODE)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$INPUT_NODE"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Named Template to apply pre Service-Call SOAPConfig XSLT Transform to the current context node -->
	<xsl:template name="ApplySOAPTransform">
		<xsl:param name="INPUT_NODE"/>
		<xsl:param name="XSLT_LOCATION" select="''"/>
		<xsl:choose>
			<xsl:when test="normalize-space($XSLT_LOCATION) != ''">
				<xsl:copy-of select="dp:transform($XSLT_LOCATION,$INPUT_NODE)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$INPUT_NODE"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
