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
	extension-element-prefixes="dp " version="1.0"
	exclude-result-prefixes="dp">
	<!--========================================================================
		Purpose:
		Performs backend routing based on policy configuration
		
		History:
		2016-03-06	v1.0	N.A.		Initial Version.
		2016-08-06	v1.0	Tim Goodwill		MQ Async put (Notification).
		2016-09-09	v1.0	Tim Goodwill		Added consumer provided timeout value (msg expiry).
		2016-02-05  v1.1    Vikram Geevanathan	Added Support for SFTP Backends
		2016-03-20	v2.0	Tim Goodwill		Init Gateway  instance
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!-- Default backend timout, only used if the configuration does not specify a timeout value -->
	<xsl:variable name="DEFAULT_TIMEOUT_SECONDS" select="30"/>
	<xsl:variable name="MAX_TIMEOUT_SECONDS" select="120"/>
	<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
	<!-- Service Metadata document -->
	<xsl:variable name="UC" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
	<xsl:variable name="LC" select="'abcdefghijklmnopqrstuvwxyz'" />
	<!-- SOAP config stylesheet -->
	<xsl:variable name="SOAP_XSLT_LOCATION"
		select="$SERVICE_METADATA/OperationConfig/BackendRouting[1]/SOAPConfig[1]"/>
	<!-- Backend STUB stylesheet -->
	<xsl:variable name="BACKEND_STUB_LOCATION"
		select="$SERVICE_METADATA/OperationConfig/BackendRouting[1]/BackendStub[1]"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Save Service Metadata with additional backend routing removed -->
		<dp:set-variable name="$SERVICE_METADATA_CONTEXT_NAME" value="$SERVICE_METADATA"/>
		<!-- Save provider name to the environment -->
		<dp:set-variable name="$PROVIDER_VAR_NAME" value="string(($SERVICE_METADATA/OperationConfig/BackendRouting)[1]/@provider)"/>
		<!-- Start a timer event for the rule -->
		<xsl:call-template name="StartTimerEvent">
			<xsl:with-param name="EVENT_ID"
				select="$SERVICE_METADATA/OperationConfig/BackendRouting[1]/@timerId"/>
		</xsl:call-template>
		<!-- Timeout for the backend response -->
		<xsl:variable name="TIMEOUT_SECONDS">
			<xsl:choose>
				<!-- Source timeout value from the service policy configuration when provided -->
				<xsl:when test="$SERVICE_METADATA/OperationConfig/BackendRouting[1]/TimeoutSeconds[1]">
					<xsl:value-of
						select="$SERVICE_METADATA/OperationConfig/BackendRouting[1]/TimeoutSeconds[1]"
					/>
				</xsl:when>
				<!-- Otherwise use default timeout value -->
				<xsl:otherwise>
					<xsl:value-of select="$DEFAULT_TIMEOUT_SECONDS"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="$PROVIDER_TIMEOUT_MILLIS_VAR_NAME" value="number($TIMEOUT_SECONDS *
			1000)"/>
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
				<xsl:when test="$SERVICE_METADATA/OperationConfig[1]/BackendRouting[1][@useWSAddressing = 'true']">
					<!-- Recreate WSAddressingEndpoint as MQHTTP/FTP Routing Config -->
					<xsl:variable name="OPERATION_CONFIG_NODE">
						<xsl:apply-templates select="$SERVICE_METADATA" mode="resolveWSAddressingEndpoint"/>
					</xsl:variable>
					<!-- Update the service metadata context value -->
					<dp:set-variable name="$SERVICE_METADATA_CONTEXT_NAME" value="$OPERATION_CONFIG_NODE"/>
					<xsl:copy-of select="$OPERATION_CONFIG_NODE/OperationConfig[1]/BackendRouting[1]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$SERVICE_METADATA/OperationConfig[1]/BackendRouting[1]"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<!-- HTTP Backend -->
			<xsl:when test="$BACKEND_ROUTING/BackendRouting[1]/HTTPEndpoint">
				<xsl:variable name="BACK_END_URL"
					select="$BACKEND_ROUTING/BackendRouting[1]/HTTPEndpoint[1]/Address"/>
				<xsl:variable name="BACKEND_PROTOCOL" select="translate(substring-before($BACK_END_URL, ':'), $LC, $UC)"/>
				<dp:set-variable name="$BACKEND_PROTOCOL_VAR_NAME" value="$BACKEND_PROTOCOL"/>
				<!-- Set the back end URL -->
				<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$BACK_END_URL"/>
				<!-- Set the backend timeout -->
				<dp:set-variable name="$DP_SERVICE_BACKEND_TIMEOUT" value="$TIMEOUT_SECONDS"/>
				<!-- Delete all existing HTTP request headers -->
				<xsl:call-template name="DeleteHttpRequestHeaders"/>
				<!-- Set HTTP Headers provided in the policy config -->
				<xsl:variable name="ATTACHMENT_MANIFEST"
					select="dp:variable($DP_LOCAL_ATTACHMENT_MANIFEST)"/>
				<xsl:variable name="HEADER_LIST">
					<xsl:choose>
						<xsl:when test="$BACKEND_ROUTING/BackendRouting[1]/HTTPEndpoint[1]/HeaderList">
							<xsl:copy-of select="$BACKEND_ROUTING/BackendRouting[1]/HTTPEndpoint[1]/HeaderList[1]"/>
						</xsl:when>
						<xsl:otherwise>
							<HeaderList>
								<Header name="Connection" value="close"/>
								<Header name="SOAPAction" value=""/>
							</HeaderList>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:for-each
					select="$HEADER_LIST/HeaderList/Header">
					<xsl:variable name="NAME" select="normalize-space(@name)"/>
					<xsl:variable name="VALUE">
						<xsl:choose>
							<!-- Over-ride content-type when manifest media type is present -->
							<xsl:when test="($NAME = 'Content-Type') and (normalize-space(@value) =
								'*')">
								<xsl:choose>
									<xsl:when test="$ATTACHMENT_MANIFEST/manifest != ''">
										<xsl:value-of select="concat('&#34;', $ATTACHMENT_MANIFEST/manifest/media-type/value, '&#34;')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="'text/xml'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>							
							<!-- create SOAPAction header (MBCU req) -->
							<xsl:when test="($NAME = 'SOAPAction') and (normalize-space(@value) = '*')">
								<xsl:value-of select="dp:variable($REQ_WSA_ACTION_VAR_NAME)"/>
							</xsl:when>
							<!-- Resolve context variable if a variable name has been provided -->
							<xsl:when test="starts-with(normalize-space(@value), 'var://context/')">
								<xsl:value-of select="dp:variable(normalize-space(@value))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="normalize-space(@value)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<dp:set-http-request-header name="$NAME" value="$VALUE"/>
					<!-- Header debug variables -->
					<!--<dp:set-variable name="concat('var://context/ESB_Services/debug/header/',$NAME)" value="string($VALUE)"/>-->
				</xsl:for-each>
				<!-- Store the HTTP request headers -->
				<xsl:call-template name="StoreHTTPHeadersForLog">
					<xsl:with-param name="LOGPOINT" select="'REQ'"/>
					<xsl:with-param name="TARGET_URL" select="$BACK_END_URL"/>
				</xsl:call-template>
			</xsl:when>
			<!-- MQ Backend -->
			<xsl:when test="$BACKEND_ROUTING/BackendRouting[1]/MQRouting">
				<dp:set-variable name="$BACKEND_PROTOCOL_VAR_NAME" value="'DPMQ'"/>
				<!-- Perform transform on the input document to create the request doc for the service call -->
				<xsl:variable name="QMGR_NAME"
					select="$BACKEND_ROUTING/BackendRouting[1]/MQRouting[1]/QueueMgr[1]"/>
				<xsl:variable name="REMOTE_QMGR_NAME"
					select="$BACKEND_ROUTING/BackendRouting[1]/MQRouting[1]/RemoteQueueMgr[1]"/>
				<xsl:variable name="REQ_QUEUE_NAME" 
					select="$BACKEND_ROUTING/BackendRouting[1]/MQRouting[1]/RequestQueue[1]"/>
				<xsl:variable name="RES_QUEUE_NAME"
					select="$BACKEND_ROUTING/BackendRouting[1]/MQRouting[1]/ReplyQueue[1]"/>
				<xsl:variable name="PUBLISH_TOPIC_NAME"
					select="$BACKEND_ROUTING/BackendRouting[1]/MQRouting[1]/PublishTopicString[1]"/>
				<xsl:variable name="ASYNC">
					<xsl:if test="$BACKEND_ROUTING/BackendRouting[1][@async='true']">
						<xsl:value-of select="'true'"/>
					</xsl:if>
				</xsl:variable>
				<dp:set-variable name="$REQ_OUT_MSG_ASYNC_VAR_NAME" value="$ASYNC"/>
				<xsl:variable name="MQMD_CONFIG_XSLT"
					select="$BACKEND_ROUTING/BackendRouting[1]/MQRouting[1]/MQMDConfig[1]"/>
				<xsl:if test="$REMOTE_QMGR_NAME != ''">
					<xsl:variable name="REQ_MQOD_NODESET">
						<MQOD>
							<Version>2</Version>
							<ObjectName>
								<xsl:value-of select="$REQ_QUEUE_NAME"/>
							</ObjectName>
							<ObjectQMgrName>
								<xsl:value-of select="$REMOTE_QMGR_NAME"/>
							</ObjectQMgrName>
						</MQOD>
					</xsl:variable>
					<!-- Serialize the MQOD nodeset -->
					<xsl:variable name="REQ_SERIALIZED_MQOD">
						<dp:serialize select="$REQ_MQOD_NODESET" omit-xml-decl="yes"/>
					</xsl:variable>
					<!-- Set the MQOD header -->
					<dp:set-request-header name="'MQOD'" value="$REQ_SERIALIZED_MQOD"/>
				</xsl:if>
				<xsl:variable name="BACK_END_URL">
					<xsl:call-template name="ConstructDpmqUrl">
						<xsl:with-param name="QMGR_NAME" select="$QMGR_NAME"/>
						<xsl:with-param name="REQ_QUEUE_NAME" select="$REQ_QUEUE_NAME"/>
						<xsl:with-param name="RES_QUEUE_NAME" select="$RES_QUEUE_NAME"/>
						<xsl:with-param name="PUBLISH_TOPIC_NAME" select="$PUBLISH_TOPIC_NAME"/>
						<xsl:with-param name="SET_REPLY_TO" select="'false'"/>
						<xsl:with-param name="PMO" select="$MQPMO_SET_ALL_CONTEXT"/>
						<xsl:with-param name="GMO" select="$MQGMO_CONVERT"/>
						<xsl:with-param name="TIMEOUT_SECONDS" select="$TIMEOUT_SECONDS"/>
						<xsl:with-param name="ASYNC" select="$ASYNC"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:variable name="REQ_MQMD">
					<xsl:call-template name="GetReqMQMD"/>
				</xsl:variable>
				<!-- Set the back end URL -->
				<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$BACK_END_URL"/>
				<!-- Generate the output MQMD -->
				<xsl:variable name="OUTPUT_MQMD" select="dp:transform($MQMD_CONFIG_XSLT,$REQ_MQMD)"/>
				<!-- Set the backend request MQMD -->
				<xsl:call-template name="SetRequestMQMD">
					<xsl:with-param name="MQMD_NODESET" select="$OUTPUT_MQMD"/>
				</xsl:call-template>
				<!-- Save the backend request MQMD for logging-->
				<dp:set-variable name="$BACKEND_MQMD_VAR_NAME" value="$OUTPUT_MQMD"/>
			</xsl:when>
			<!-- SFTP Backend -->
			<xsl:when test="$BACKEND_ROUTING/BackendRouting[1]/SFTPEndpoint">
				<dp:set-variable name="$BACKEND_PROTOCOL_VAR_NAME" value="'SFTP'"/>
				<xsl:variable name="SFTP_FILENAME">
					<xsl:copy-of select="dp:variable('var://context/ESB_Services/sftpFileName')"/>
				</xsl:variable>
				<xsl:variable name="BACK_END_URL"
					select="concat($BACKEND_ROUTING/BackendRouting[1]/SFTPEndpoint[1]/Address,$SFTP_FILENAME)"/>
				<!-- Set the back end URL -->
				<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$BACK_END_URL"/>
			</xsl:when>
		</xsl:choose>
		<!-- Copy Input to Output -->
		<xsl:choose>
			<xsl:when test="normalize-space($SOAP_XSLT_LOCATION) != ''">
				<xsl:call-template name="ApplySOAPTransform">
					<xsl:with-param name="INPUT_NODE" select="."/>
					<xsl:with-param name="XSLT_LOCATION" select="$SOAP_XSLT_LOCATION"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="normalize-space($BACKEND_STUB_LOCATION) != ''">
				<xsl:call-template name="ApplySTUBTransform">
					<xsl:with-param name="INPUT_NODE" select="."/>
					<xsl:with-param name="XSLT_LOCATION" select="$BACKEND_STUB_LOCATION"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template to handle the 'ptycore:Identifier' element -->
	<xsl:template match="BackendRouting[@useWSAddressing = 'true']" mode="resolveWSAddressingEndpoint">
		<!-- Supports HTTP, SFTP and 'MQ', 'WMQ' and 'JMS' queue URIs 
		MQ V8 URIs: http://www-01.ibm.com/support/knowledgecenter/SSFKSJ_8.0.0/com.ibm.mq.dev.doc/q029930_.htm 
		DP V5 URIs: http://www-01.ibm.com/support/knowledgecenter/SS9H2Y_5.0.0/com.ibm.dp.xa.doc/extensionfunctions39.htm%23urlopenmq 
		NOTE: the '/servername:port' component of an MQ uri is IGNORED. The Gateway  will only route to QMgrs known to the SOA QMgr. -->
		<xsl:copy>
			<xsl:variable name="WSA_TO" select="dp:variable($REQ_WSA_TO_VAR_NAME)"/>
			<xsl:variable name="WSA_TO_UC" select="translate(normalize-space($WSA_TO), $LC, $UC)"/>
			<dp:set-variable name="'var://context/ESB_Services/debug/WSA_TO'" value="string($WSA_TO)"/>
			<dp:set-variable name="'var://context/ESB_Services/debug/WSA_TO_Trns'" value="string($WSA_TO_UC)"/>
			<dp:set-variable name="'var://context/ESB_Services/debug/WSA_TO_Sub'" value="substring($WSA_TO_UC, 1, 3)"/>
			<xsl:choose>
				<xsl:when test="substring($WSA_TO_UC, 1, 4) = 'HTTP'">
					<HTTPEndpoint>
						<Address><xsl:value-of select="$WSA_TO"/></Address>
						<xsl:choose>
							<xsl:when test="HTTPEndpoint/HeaderList">
								<xsl:copy-of select="HTTPEndpoint/HeaderList"/>
							</xsl:when>
							<xsl:otherwise>
								<HeaderList>
									<Header name="Connection" value=""/>
									<Header name="SOAPAction" value=""/>
								</HeaderList>
							</xsl:otherwise>
						</xsl:choose>
					</HTTPEndpoint>
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
					<xsl:variable name="QMNAME" select="substring-before(substring-after($WSA_ADJUSTED, '@'), '&#38;')"/>
					<xsl:variable name="REQUEST_QNAME">
						<xsl:choose>
							<xsl:when test="contains(substring-before($WSA_ADJUSTED, '&#38;'), '@')">
								<xsl:value-of select="substring-before(substring-after($WSA_ADJUSTED, '/QUEUE/'), '@')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="substring-after(substring-before($WSA_ADJUSTED, '&#38;'), '/QUEUE/')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="REPLY_QNAME" select="substring-before(substring-after($WSA_ADJUSTED, 'REPLYTO=MSG/QUEUE/'), '&#38;')"/>
					<MQRouting>
						<QueueMgr><xsl:value-of select="$BACKEND_QMGR_GROUP_NAME"/></QueueMgr>
						<xsl:if test="normalize-space($QMNAME) != ''">	
							<RemoteQueueMgr><xsl:value-of select="normalize-space($QMNAME)"/></RemoteQueueMgr>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="(normalize-space($REPLY_QNAME) != '') and (normalize-space($REQUEST_QNAME) = '')">
								<RequestQueue><xsl:value-of select="normalize-space($REPLY_QNAME)"/></RequestQueue>
							</xsl:when>
							<xsl:otherwise>
								<RequestQueue><xsl:value-of select="normalize-space($REQUEST_QNAME)"/></RequestQueue>
								<xsl:if test="normalize-space($REPLY_QNAME) != ''">
									<ReplyQueue><xsl:value-of select="normalize-space($REPLY_QNAME)"/></ReplyQueue>
								</xsl:if>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:choose>
							<xsl:when test="MQRouting/MQMDConfig">
								<xsl:copy-of select="MQRouting/MQMDConfig"/>
							</xsl:when>
							<xsl:otherwise>
								<MQMDConfig><xsl:value-of select="$GENERIC_MQMD_XSLT_PATH"/></MQMDConfig>
							</xsl:otherwise>
						</xsl:choose>
					</MQRouting>
				</xsl:when>
				<xsl:when test="(substring($WSA_TO_UC, 1, 2) = 'MQ')
					or (substring($WSA_TO_UC, 1, 2) = 'DPMQ')">
					<!--  eg. mq://host:port?QueueManager=QM1;RequestQueue=Q123;ReplyQueue=Q456 -->
					<xsl:variable name="WSA_ADJUSTED" select="concat($WSA_TO_UC, ';')"/>
					<xsl:variable name="QMNAME" select="substring-before(substring-after($WSA_ADJUSTED, 'QUEUEMANAGER='), ';')"/>
					<xsl:variable name="REQUEST_QNAME" select="substring-before(substring-after($WSA_ADJUSTED, 'REQUESTQUEUE='), ';')"/>
					<xsl:variable name="REPLY_QNAME" select="substring-before(substring-after($WSA_ADJUSTED, 'REPLYQUEUE='), ';')"/>
					<MQRouting>
						<QueueMgr><xsl:value-of select="$BACKEND_QMGR_GROUP_NAME"/></QueueMgr>
						<xsl:if test="normalize-space($QMNAME) != ''">
							<RemoteQueueMgr><xsl:value-of select="normalize-space($QMNAME)"/></RemoteQueueMgr>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="(normalize-space($REPLY_QNAME) != '') and (normalize-space($REQUEST_QNAME) = '')">
								<RequestQueue><xsl:value-of select="normalize-space($REPLY_QNAME)"/></RequestQueue>
							</xsl:when>
							<xsl:otherwise>
								<RequestQueue><xsl:value-of select="normalize-space($REQUEST_QNAME)"/></RequestQueue>
								<xsl:if test="normalize-space($REPLY_QNAME) != ''">
									<ReplyQueue><xsl:value-of select="normalize-space($REPLY_QNAME)"/></ReplyQueue>
								</xsl:if>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:choose>
							<xsl:when test="MQRouting/MQMDConfig">
								<xsl:copy-of select="MQRouting/MQMDConfig"/>
							</xsl:when>
							<xsl:otherwise>
								<MQMDConfig><xsl:value-of select="$GENERIC_MQMD_XSLT_PATH"/></MQMDConfig>
							</xsl:otherwise>
						</xsl:choose>
					</MQRouting>
				</xsl:when>
				<xsl:when test="substring($WSA_TO_UC, 1, 4) = 'SFTP'">
					<SFTPEndpoint>
						<Address><xsl:value-of select="$WSA_TO"/></Address>
					</SFTPEndpoint>
				</xsl:when>
				<!-- default routing -->
				<xsl:when test="HTTPEndpoint/Address">
					<xsl:copy-of select="HTTPEndpoint"/>
				</xsl:when>
				<xsl:when test="MQRouting/QueueMgr and MQRouting/RequestQueue">
					<xsl:copy-of select="MQRouting"/>
				</xsl:when>
				<xsl:when test="SFTPEndpoint/Address">
					<xsl:copy-of select="SFTPEndpoint"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="RejectToErrorFlow">
						<xsl:with-param name="MSG">
							<xsl:text>AsyncReply url-open error: Missing or badly formed 'wsa:To' SOAP header.</xsl:text>
							<xsl:if test="dp:variable($REQ_WSA_TO_VAR_NAME)">
								<xsl:value-of select="concat(' wsa:To ', dp:variable($REQ_WSA_TO_VAR_NAME), '.')"/>
							</xsl:if>
							<xsl:if test="dp:variable($REQ_WSA_RELATES_TO_VAR_NAME)">
								<xsl:value-of select="concat(' wsa:RelatesTo ', dp:variable($REQ_WSA_RELATES_TO_VAR_NAME), '.')"/>
							</xsl:if>
						</xsl:with-param>
						<xsl:with-param name="ERROR_CODE" select="'ENTR00014'"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<!-- Standard identity template (modal version for mode='stripSV288IsReqSteps' )-->
	<xsl:template match="node()|@*" mode="resolveWSAddressingEndpoint">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="resolveWSAddressingEndpoint"/>
		</xsl:copy>
	</xsl:template>
	<!-- Template to preserve first instance of BackendRouting only-->
	<xsl:template match="BackendRouting[1]" mode="removeAdditionalBackendRouting">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="removeAdditionalBackendRouting"/>
		</xsl:copy>
	</xsl:template>
	<!-- Template to preserve first instance of BackendRouting only-->
	<xsl:template match="BackendRouting" mode="removeAdditionalBackendRouting">
		<!-- remove -->
	</xsl:template>
	<!-- Standard identity template (modal version for mode='removeAdditionalBackendRouting' )-->
	<xsl:template match="node()|@*" mode="removeAdditionalBackendRouting">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="removeAdditionalBackendRouting"/>
		</xsl:copy>
	</xsl:template>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Named Template to apply pre Service-Call SOAPConfig XSLT Transform to the current context node -->
	<xsl:template name="ApplySOAPTransform">
		<xsl:param name="INPUT_NODE"/>
		<xsl:param name="XSLT_LOCATION" select="''"/>
		<xsl:choose>
			<xsl:when test="normalize-space($XSLT_LOCATION) != ''">
				<xsl:variable name="RESULT_NODE" select="dp:transform($XSLT_LOCATION,$INPUT_NODE)"/>
				<xsl:choose>
					<xsl:when test="normalize-space($BACKEND_STUB_LOCATION) != ''">
						<xsl:call-template name="ApplySTUBTransform">
							<xsl:with-param name="INPUT_NODE" select="$RESULT_NODE"/>
							<xsl:with-param name="XSLT_LOCATION" select="$BACKEND_STUB_LOCATION"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$RESULT_NODE"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$INPUT_NODE"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Named Template to apply Backend STUB XSLT Transform to the current context node -->
	<xsl:template name="ApplySTUBTransform">
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
