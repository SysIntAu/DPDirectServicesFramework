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
	xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
	xmlns:scm="http://www.dpdirect.org/Namespace/ServiceChainMetadata/V1.0"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:dp="http://www.datapower.com/extensions" 
	xmlns:exslt="http://exslt.org/common" 
	extension-element-prefixes="dp exslt" version="1.0"
	exclude-result-prefixes="dp exslt scm wsu wsa wsse">
	<!--========================================================================
		Purpose:
		A collection of framework logging and utility templates.
		
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		2016-12-12	v2.0	Tim Goodwill		Init Gateway  instance
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to determine if point log capturing is enabled in the current environment configuration -->
	<xsl:template name="GetCapturePointLogsProperty">
		<!-- One of ('all'|'none'|'error') -->
		<xsl:variable name="CAPTURE_POINT_LOGS">
			<xsl:call-template name="GetDPDirectProperty">
				<xsl:with-param name="KEY" select="concat($DPDIRECT.PROP_URI_PREFIX,'logging/capturePointLogs')"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$CAPTURE_POINT_LOGS = 'error'">
				<xsl:value-of select="$CAPTURE_POINT_LOGS"/>
			</xsl:when>
			<xsl:when test="$CAPTURE_POINT_LOGS = 'all'">
				<xsl:value-of select="$CAPTURE_POINT_LOGS"/>
			</xsl:when>
			<xsl:when test="$CAPTURE_POINT_LOGS = 'none'">
				<xsl:value-of select="$CAPTURE_POINT_LOGS"/>
			</xsl:when>
			<!-- Default to 'error' (in case of misconfiguration) -->
			<xsl:otherwise>
				<xsl:value-of select="'error'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Starts a new timer event -->
	<xsl:template name="StartTimerEvent">
		<xsl:param name="EVENT_ID" select="''"/>
		<xsl:if test="normalize-space($EVENT_ID) != ''">
			<xsl:variable name="VAR_NAME" select="concat($TIMER_START_BASEVAR_NAME,$EVENT_ID)"/>
			<dp:set-variable name="$VAR_NAME" value="string(dp:time-value())"/>
			<xsl:choose>
				<xsl:when test="normalize-space($EVENT_ID) = 'RequestFlow'">
					<!-- Store start times in ISO8601 format -->
					<xsl:variable name="CURRENT_DATETIME">
						<xsl:call-template name="GetCurrentDateTimeWithMillis"/>
					</xsl:variable>
					<xsl:variable name="TS_VAR_NAME" select="concat($VAR_NAME,'/Timestamp')"/>
					<dp:set-variable name="$TS_VAR_NAME" value="string($CURRENT_DATETIME)"/>
				</xsl:when>
				<xsl:when test="contains($EVENT_ID,'BackendRouting')">
					<xsl:variable name="TV_VAR_NAME" select="concat($TIMER_START_BASEVAR_NAME,'BackendRouting')"/>
					<dp:set-variable name="$TV_VAR_NAME" value="string(dp:time-value())"/>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	<!-- Stops a timer event. Returns the elapsed time of the event (in milliseconds) or 'NaN' if there is no call was made to "StartTimerEvent" for the "EVENT_ID" -->
	<xsl:template name="StopTimerEvent">
		<xsl:param name="EVENT_ID" select="''"/>
		<xsl:variable name="START_TIME"
			select="normalize-space(dp:variable(concat($TIMER_START_BASEVAR_NAME,$EVENT_ID)))"/>
		<xsl:choose>
			<xsl:when test="$START_TIME = ''">
				<xsl:text>NaN</xsl:text>
			</xsl:when>
			<xsl:when test="normalize-space($EVENT_ID) = 'CallService'">
				<xsl:variable name="FLOW_DIRECTION" select="dp:variable($FLOW_DIRECTION_VAR_NAME) "/>
				<xsl:variable name="VAR_NAME" select="concat($TIMER_ELAPSED_BASEVAR_NAME,$FLOW_DIRECTION,$EVENT_ID)"/>
				<xsl:variable name="ELAPSED_MILLIS" select="string(dp:time-value() - number($START_TIME))"/>
				<xsl:variable name="ACCUMULATED_CALLSERVICE_MILLIS" select="dp:varaible($VAR_NAME)"/>
				<xsl:variable name="CALLSERVICE_MILLIS">
					<xsl:choose>
						<xsl:when test="number($ACCUMULATED_CALLSERVICE_MILLIS) = number($ACCUMULATED_CALLSERVICE_MILLIS)">
							<xsl:value-of select="number($ACCUMULATED_CALLSERVICE_MILLIS) + number($ELAPSED_MILLIS)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$ELAPSED_MILLIS"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>	
				<dp:set-variable name="$VAR_NAME" value="$CALLSERVICE_MILLIS"/>
				<xsl:value-of select="$CALLSERVICE_MILLIS"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="VAR_NAME" select="concat($TIMER_ELAPSED_BASEVAR_NAME,$EVENT_ID)"/>
				<xsl:variable name="ELAPSED_MILLIS" select="string(dp:time-value() - number($START_TIME))"/>
				<dp:set-variable name="$VAR_NAME" value="string($ELAPSED_MILLIS)"/>
				<xsl:value-of select="$ELAPSED_MILLIS"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template to construct 'dpmq' URLs -->
	<xsl:template name="ConstructDpmqUrl">
		<xsl:param name="QMGR_NAME" select="''"/>
		<xsl:param name="REMOTE_QMGR_NAME" select="''"/>
		<xsl:param name="REQ_QUEUE_NAME" select="''"/>
		<xsl:param name="RES_QUEUE_NAME" select="''"/>
		<xsl:param name="PUBLISH_TOPIC_NAME" select="''"/>
		<xsl:param name="SET_REPLY_TO" select="''"/>
		<xsl:param name="PMO" select="$MQPMO_SET_ALL_CONTEXT"/>
		<xsl:param name="GMO" select="''"/>
		<xsl:param name="TIMEOUT_SECONDS" select="''"/>
		<xsl:param name="ASYNC" select="''"/>
		<xsl:text>dpmq://</xsl:text>
		<xsl:value-of select="$QMGR_NAME"/>
		<xsl:text>/?</xsl:text>
		<xsl:if test="normalize-space($REQ_QUEUE_NAME) != ''">
			<xsl:text>RequestQueue=</xsl:text>
			<xsl:value-of select="$REQ_QUEUE_NAME"/>
			<xsl:text>;</xsl:text>
		</xsl:if>
		<xsl:if test="normalize-space($PUBLISH_TOPIC_NAME) != ''">
			<xsl:text>PublishTopicString=</xsl:text>
			<xsl:value-of select="$PUBLISH_TOPIC_NAME"/>
			<xsl:text>;</xsl:text>
		</xsl:if>
		<xsl:if test="(normalize-space($RES_QUEUE_NAME) != '')
			and (normalize-space($ASYNC) != 'true')">
			<xsl:text>ReplyQueue=</xsl:text>
			<xsl:value-of select="$RES_QUEUE_NAME"/>
			<xsl:text>;</xsl:text>
		</xsl:if>
		<xsl:if test="normalize-space($SET_REPLY_TO) != ''">
			<xsl:text>SetReplyTo=</xsl:text>
			<xsl:value-of select="$SET_REPLY_TO"/>
			<xsl:text>;</xsl:text>
		</xsl:if>
		<xsl:text>PMO=</xsl:text>
		<xsl:value-of select="$PMO"/>
		<xsl:if test="normalize-space($GMO) != ''">
			<xsl:text>;GMO=</xsl:text>
			<xsl:value-of select="$GMO"/>
		</xsl:if>
		<xsl:if test="(normalize-space($ASYNC) != 'true')
			and (normalize-space($TIMEOUT_SECONDS) != '')">
			<xsl:text>;Timeout=</xsl:text>
			<xsl:value-of select="string($TIMEOUT_SECONDS * 1000)"/>
		</xsl:if>
		<xsl:if test="normalize-space($ASYNC) != ''">
			<xsl:text>;AsyncPut=</xsl:text>
			<xsl:value-of select="$ASYNC"/>
		</xsl:if>
	</xsl:template>
	<!-- Template to update (i.e. override) the current request MQMD with a new MQMD nodeset -->
	<xsl:template name="SetRequestMQMD">
		<xsl:param name="MQMD_NODESET">
			<!-- Initialise the param with an empty 'MQMD' node. This prevents a DataPower compilation 
				warning about an illegal cast from string to nodeset when calling dp:serialize() below. -->
			<MQMD/>
		</xsl:param>
		<!-- Serialize the MQMD nodeset -->
		<xsl:variable name="SERIALIZED_MQMD">
			<dp:serialize select="$MQMD_NODESET" omit-xml-decl="yes"/>
		</xsl:variable>
		<!-- Override the existing MQMD header -->
		<dp:set-request-header name="'MQMD'" value="$SERIALIZED_MQMD"/>
	</xsl:template>
	<!-- Template to update (i.e. override) the current response MQMD with a new MQMD nodeset -->
	<xsl:template name="SetResponseMQMD">
		<xsl:param name="MQMD_NODESET">
			<!-- Initialise the param with an empty 'MQMD' node. This prevents a DataPower compilation 
				warning about an illegal cast from string to nodeset when calling dp:serialize() below. -->
			<MQMD/>
		</xsl:param>
		<!-- Serialize the MQMD nodeset -->
		<xsl:variable name="SERIALIZED_MQMD">
			<dp:serialize select="$MQMD_NODESET" omit-xml-decl="yes"/>
		</xsl:variable>
		<!-- Override the existing MQMD header -->
		<dp:set-response-header name="'MQMD'" value="$SERIALIZED_MQMD"/>
	</xsl:template>
	<!-- Template to update a given MQMD nodeset element with a new MQMD nodeset. Elements in the new MQMD nodeset override elements of the same name in the old nodeset -->
	<xsl:template name="MergeMQMDNodesets">
		<xsl:param name="OLD_MQMD_NODESET"/>
		<xsl:param name="NEW_MQMD_NODESET"/>
		<xsl:variable name="MQMD_NODESET_NAMES">
			<xsl:for-each select="$NEW_MQMD_NODESET/MQMD/*">
				<xsl:copy-of select="concat(name(), '&#x20;')"/>
			</xsl:for-each>
		</xsl:variable>
		<!-- Merge the two nodesets -->
		<MQMD>
			<xsl:for-each select="$NEW_MQMD_NODESET/MQMD/*">
				<xsl:copy-of select="."/>
			</xsl:for-each>
			<xsl:for-each select="$OLD_MQMD_NODESET/MQMD/*[not(contains($MQMD_NODESET_NAMES, concat(name(),
				'&#x20;')))]">
				<xsl:copy-of select="."/>
			</xsl:for-each>
		</MQMD>
	</xsl:template>
	<!-- Template to remove all current HTTP request headers -->
	<xsl:template name="DeleteHttpRequestHeaders">
		<!-- An optional list of headers to preserve (header names should be in lower case) -->
		<xsl:param name="PRESERVE_HEADER_MANIFEST">
			<headers>
				<!-- <header>content-type</header> -->
			</headers>
		</xsl:param>
		<xsl:variable name="HEADER_MANIFEST" select="dp:variable($DP_SERVICE_HEADER_MANIFEST)"/>
		<xsl:for-each select="$HEADER_MANIFEST/headers/header">
			<xsl:variable name="LC_NAME" select="translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
			<xsl:if test="not($PRESERVE_HEADER_MANIFEST/headers/header = $LC_NAME)">
				<dp:remove-http-request-header name="{.}"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<!-- Template to remove all current HTTP response headers -->
	<xsl:template name="DeleteHttpResponseHeaders">
		<!-- An optional list of headers to preserve (header names should be in lower case) -->
		<xsl:param name="PRESERVE_HEADER_MANIFEST">
			<headers>
				<!-- <header>content-type</header> -->
			</headers>
		</xsl:param>
		<xsl:variable name="HEADER_MANIFEST" select="dp:variable($DP_SERVICE_HEADER_MANIFEST)"/>
		<xsl:for-each select="$HEADER_MANIFEST/headers/header">
			<xsl:variable name="LC_NAME" select="translate(.,'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
			<xsl:if test="not($PRESERVE_HEADER_MANIFEST/headers/header = $LC_NAME)">
				<dp:remove-http-response-header name="{.}"/>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<!-- Template to copy 'xop:Include' referenced attachments to a new (default - RESULT_DOC) context -->
	<xsl:template name="CopyAttachments">
		<xsl:param name="FROM_CONTEXT" select="'INPUT'"/>
		<xsl:param name="TO_CONTEXT" select="'RESULT_DOC'"/>
		<xsl:param name="STRIP_ATTACHMENTS" select="'true'"/>
		<xsl:variable name="FROM_MANIFEST" select="dp:variable(concat('var://context/',$FROM_CONTEXT,'/attachment-manifest'))"/>
		<!--		<dp:set-variable name="'var://context/ESB_Services/MIME/IN_MANIFEST'" value="$FROM_MANIFEST"/>-->
		<xsl:if test="$FROM_MANIFEST != ''">
			<xsl:variable name="CONTENT_TYPE" select="normalize-space($FROM_MANIFEST/manifest/media-type/value/text())"/>
			<!-- Store ContentType var -->
			<dp:set-variable name="'var://context/ESB_Services/MIME/contentType'" value="string($CONTENT_TYPE)"/>
			<!-- Loop through attachment manifest attachment refs -->
			<xsl:for-each select="$FROM_MANIFEST//attachment">
				<xsl:variable name="CID" select="current()/uri"/>
				<xsl:call-template name="CopyAttachment">
					<xsl:with-param name="FROM_CONTEXT" select="$FROM_CONTEXT"/>
					<xsl:with-param name="TO_CONTEXT" select="$TO_CONTEXT"/>
					<xsl:with-param name="CID" select="$CID"/>
				</xsl:call-template>
			</xsl:for-each>
			<!-- Write MIME content-type header -->
			<dp:set-mime-header name="MIME-Version"
				value="'1.0'"/>
			<!-- Set ContentType var -->
			<dp:set-mime-header name="'Content-Type'"
				value="$CONTENT_TYPE" context="{$TO_CONTEXT}"/>
			<!-- Optionally remove attachments from the INPUT context-->
			<xsl:if test="$STRIP_ATTACHMENTS = 'true'">
				<dp:strip-attachments context="{$FROM_CONTEXT}"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	<!-- Template to copy a nominated 'xop:Include' referenced attachment to a new (default - RESULT_DOC) context -->
	<xsl:template name="CopyAttachment">
		<xsl:param name="FROM_CONTEXT" select="'INPUT'"/>
		<xsl:param name="TO_CONTEXT" select="'RESULT_DOC'"/>
		<xsl:param name="CID" select="''"/>
		<xsl:if test="$CID != ''">
			<!-- var://context/INPUT/attachment-manifest describes an attachment -->
			<xsl:variable name="FROM_ATT_STRING" select="concat('attachment://',$FROM_CONTEXT,'/',$CID)"/>
			<xsl:variable name="TO_ATT_STRING" select="concat('attachment://',$TO_CONTEXT,'/',$CID)"/>
			<!-- Read (binary) attachment from the INPUT context. Write attachment to context "RESULT_DOC"  -->
			<xsl:variable name="ATTACHMENT">
				<dp:url-open target="{$FROM_ATT_STRING}" response="binaryNode"/>
			</xsl:variable>
			<dp:url-open target="{$TO_ATT_STRING}" response="ignore">
				<xsl:copy-of select="$ATTACHMENT/result/binary/node()"/>
			</dp:url-open>
		</xsl:if>
	</xsl:template>
	<!-- Template to decode named attachment and remove -->
	<xsl:template name="DecodeAttachment">
		<xsl:param name="ATTACHMENT_CID" select="''"/>
		<xsl:param name="ATTACHMENT_NUMBER" select="'1'"/>
		<xsl:variable name="ATTACHMENT_MANIFEST" select="dp:variable($DP_LOCAL_ATTACHMENT_MANIFEST)"/>
		<xsl:variable name="ATTACHMENTS_METADATA" select="$ATTACHMENT_MANIFEST/manifest/attachments"/>
		<xsl:variable name="ATTACHMENT_URL">
			<xsl:choose>
				<xsl:when test="$ATTACHMENT_CID != ''">
					<xsl:value-of select="concat('attachment://RESULT_DOC/',$ATTACHMENT_CID)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('attachment://RESULT_DOC/',$ATTACHMENTS_METADATA/attachment[number($ATTACHMENT_NUMBER)]/uri)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="ATTACHMENT">
			<dp:url-open target="{$ATTACHMENT_URL}" response="binaryNode"/>
		</xsl:variable>
		<xsl:value-of select="dp:binary-decode($ATTACHMENT)"/>
		<!-- Remove attachment from the RESULT_DOC context-->
		<dp:strip-attachments uri="$ATTACHMENT_CID" context="'RESULT_DOC'"/>
	</xsl:template>
	<!-- Template to store point log data depending on configuration state -->
	<xsl:template name="StorePointLog">
		<xsl:param name="MSG"/>
		<xsl:param name="POINT_LOG_VAR_NAME" select="''"/>
		<xsl:variable name="ERROR_CODE" select="dp:variable($ERROR_CODE_VAR_NAME)"/>
		<xsl:variable name="CAPTURE_POINT_LOGS">
			<xsl:call-template name="GetCapturePointLogsProperty"/>
		</xsl:variable>
		<xsl:if test="$CAPTURE_POINT_LOGS != 'none'">
			<xsl:variable name="SERIALIZED_MSG">
				<xsl:choose>
					<xsl:when test="$MSG/*">
						<dp:serialize select="exslt:node-set($MSG)" omit-xml-decl="yes"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$MSG"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<!-- Store the message to point log -->
			<dp:set-variable name="$POINT_LOG_VAR_NAME" value="$SERIALIZED_MSG"/>
			<!-- Write DP log -->
			<xsl:choose>
				<xsl:when test="$POINT_LOG_VAR_NAME = $POINT_LOG_REQ_INMSG_VAR_NAME">	
					<xsl:call-template name="WriteSysLogNoticeMsg">
						<xsl:with-param name="LOG_EVENT_KEY">
							<xsl:text>InboundRequest</xsl:text>
						</xsl:with-param>
						<xsl:with-param name="KEY_VALUES">
							<xsl:text>ServiceIdentifier=</xsl:text>
							<xsl:value-of select="dp:variable($SERVICE_IDENTIFIER_VAR_NAME)"/>
							<xsl:text>,ServiceOperation=</xsl:text>
							<xsl:value-of select="dp:variable($REQ_WSA_ACTION_VAR_NAME)"/>
							<xsl:text>,ReqMsgFormat=</xsl:text>
							<xsl:value-of select="dp:variable($REQ_IN_MSG_FORMAT_VAR_NAME)"/>
							<xsl:text>,ServiceUrlIn='</xsl:text>
							<xsl:value-of select="dp:variable($DP_SERVICE_URL_IN)"/>
							<xsl:if test="dp:variable($REQ_WSA_TO_VAR_NAME) != ''">
								<xsl:text>,WSATo=</xsl:text>
								<xsl:value-of select="dp:variable($REQ_WSA_TO_VAR_NAME)"/>
							</xsl:if>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$POINT_LOG_VAR_NAME = $POINT_LOG_REQ_OUTMSG_VAR_NAME">
					<xsl:variable name="REQ_MQMD">
						<xsl:call-template name="GetReqMQMD"/>
					</xsl:variable>		
					<xsl:call-template name="WriteSysLogInfoMsg">
						<xsl:with-param name="LOG_EVENT_KEY">
							<xsl:text>OutboundRequest</xsl:text>
						</xsl:with-param>
						<xsl:with-param name="KEY_VALUES">
							<xsl:text>ServiceProvider=</xsl:text>
							<xsl:value-of select="string(dp:variable($PROVIDER_VAR_NAME))"/>
							<xsl:text>,ReqOutMsg=</xsl:text>
							<xsl:value-of select="dp:variable($STATS_LOG_REQ_OUTMSG_ROOT_VAR_NAME)"/>
							<xsl:text>,ReqOutMsgFormat=</xsl:text>
							<xsl:value-of select="dp:variable($REQ_OUT_MSG_FORMAT_VAR_NAME)"/>
							<xsl:if test="$REQ_MQMD/*">
								<xsl:text>,ReqOutMsgId=</xsl:text>
								<xsl:value-of select="normalize-space($REQ_MQMD//MsgId)"/>
							</xsl:if>
							<xsl:text>,BackendProtocol=</xsl:text>
							<xsl:value-of select="dp:variable($BACKEND_PROTOCOL_VAR_NAME)"/>
							<xsl:text>,ServiceUrlOut='</xsl:text>
							<xsl:value-of select="dp:variable($DP_SERVICE_URL_OUT)"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$POINT_LOG_VAR_NAME = $POINT_LOG_RES_INMSG_VAR_NAME">
					<xsl:variable name="RES_MQMD">
						<xsl:call-template name="GetCurrentResMQMD"/>
					</xsl:variable>		
					<xsl:call-template name="WriteSysLogInfoMsg">
						<xsl:with-param name="LOG_EVENT_KEY">
							<xsl:text>InboundResponse</xsl:text>
						</xsl:with-param>
						<xsl:with-param name="KEY_VALUES">
							<xsl:text>ServiceProvider=</xsl:text>
							<xsl:value-of select="string(dp:variable($PROVIDER_VAR_NAME))"/>
							<xsl:text>,ResponseMsg=</xsl:text>
							<xsl:value-of select="dp:variable($STATS_LOG_RES_INMSG_ROOT_VAR_NAME)"/>
							<xsl:if test="$RES_MQMD/*">
								<xsl:text>,ResInMsgId=</xsl:text>
								<xsl:value-of select="normalize-space($RES_MQMD//MsgId)"/>
							</xsl:if>
							<xsl:text>,ResInMsgFormat=</xsl:text>
							<xsl:value-of select="dp:variable($RES_IN_MSG_FORMAT_VAR_NAME)"/>
							<xsl:text>,BackendProtocol=</xsl:text>
							<xsl:value-of select="dp:variable($BACKEND_PROTOCOL_VAR_NAME)"/>
							<xsl:text>,ServiceUrlOut='</xsl:text>
							<xsl:value-of select="dp:variable($DP_SERVICE_URL_OUT)"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
