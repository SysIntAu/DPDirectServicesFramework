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
	extension-element-prefixes="dp" version="1.0" exclude-result-prefixes="dp">
	<!--========================================================================
		Purpose:
		Performs finalisation of the generic policy flow and boundary logging 
		
		History:
		2016-03-06	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="TX_RULE_TYPE" select="normalize-space(dp:variable($DP_SERVICE_TRANSACTION_RULE_TYPE))"/>
		<!-- Output message root name -->
		<xsl:variable name="MSG_ROOT_NAME">
			<xsl:choose>
				<xsl:when test="dp:variable($RESULT_DOC_CONTEXT_NAME)/*[local-name() = 'Envelope']/*[local-name() = 'Body']/*">
					<xsl:text>{</xsl:text>
					<xsl:value-of select="normalize-space(namespace-uri(dp:variable($RESULT_DOC_CONTEXT_NAME)/*[local-name() =
						'Envelope'][1]/*[local-name() = 'Body'][1]/*[1]))"/>
					<xsl:text>}</xsl:text>
					<xsl:value-of select="local-name(dp:variable($RESULT_DOC_CONTEXT_NAME)/*[local-name() = 'Envelope'][1]/*[local-name() = 'Body'][1]/*[1])"
					/>
				</xsl:when>
				<xsl:when test="dp:variable($RESULT_DOC_CONTEXT_NAME)/*">
					<xsl:text>{</xsl:text>
					<xsl:value-of select="normalize-space(namespace-uri(dp:variable($RESULT_DOC_CONTEXT_NAME)/*[1]))"/>
					<xsl:text>}</xsl:text>
					<xsl:value-of select="local-name(dp:variable($RESULT_DOC_CONTEXT_NAME)/*[1])"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<!-- Stop the timer event -->
		<xsl:variable name="ELAPSED_MILLIS">
			<xsl:call-template name="StopTimerEvent">
				<xsl:with-param name="EVENT_ID">
					<xsl:choose>
						<xsl:when test="$TX_RULE_TYPE = 'request'">
							<xsl:text>RequestFlow</xsl:text>
						</xsl:when>
						<xsl:when test="$TX_RULE_TYPE = 'response'">
							<xsl:text>ResponseFlow</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>ErrorFlow</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<!-- Cusom Log Type -->
		<xsl:variable name="CAPTURE_POINT_LOGS">
			<xsl:call-template name="GetCapturePointLogsProperty"/>
		</xsl:variable>
		<!-- Output Msg Format -->
		<xsl:variable name="ATTACHMENT_MANIFEST" select="dp:variable(concat($RESULT_DOC_CONTEXT_NAME, 'attachment-manifest'))"/>
		<xsl:variable name="MSG_FORMAT">
			<xsl:choose>
				<xsl:when test="$ATTACHMENT_MANIFEST/manifest/media-type/value">
					<xsl:value-of select="'MIME'"/>
				</xsl:when>
				<xsl:when test="not(dp:variable($RESULT_DOC_CONTEXT_NAME)/*)">
					<xsl:value-of select="'non-XML'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'XML'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$TX_RULE_TYPE = 'request'">
			<!-- Save output message root name to the environment -->
			<dp:set-variable name="$STATS_LOG_REQ_OUTMSG_ROOT_VAR_NAME" value="$MSG_ROOT_NAME"/>
			<!-- Store the Message Format -->
			<dp:set-variable name="$REQ_OUT_MSG_FORMAT_VAR_NAME" value="$MSG_FORMAT"/>
			<!-- Store  consumer MsgId (eg TRN, optionally set via xslt) if it is provided -->
			<xsl:variable name="CONSUMER_TRANSACTION_ID" select="dp:variable($TRANSACTION_ID_VAR_NAME)"/>
			<xsl:if test="$CONSUMER_TRANSACTION_ID != ''">
				<xsl:call-template name="StoreMsgIdentifier">
					<xsl:with-param name="TYPE" select="dp:variable($TRANSACTION_ID_TYPE_VAR_NAME)"/>
					<xsl:with-param name="APPLIES_TO" select="'REQ'"/>
					<xsl:with-param name="IDENTIFIER_VALUE" select="$CONSUMER_TRANSACTION_ID"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="$CAPTURE_POINT_LOGS != 'none'">
				<!-- Store the request output message to point log -->
				<xsl:call-template name="StorePointLog">
					<xsl:with-param name="MSG" select="dp:variable($RESULT_DOC_CONTEXT_NAME)"/>
					<!--<xsl:with-param name="MSG" select="(dp:variable($RESULT_DOC_CONTEXT_NAME)/*)[1]"/>-->
					<xsl:with-param name="POINT_LOG_VAR_NAME" select="$POINT_LOG_REQ_OUTMSG_VAR_NAME"/>
				</xsl:call-template>
			</xsl:if>
			<!-- Clear the local context error variables -->
			<dp:set-variable name="$ERROR_CODE_VAR_NAME" value="''"/>
		</xsl:if>
		<xsl:if test="$TX_RULE_TYPE = 'response'">
			<!-- Save output message root name to the environment -->
			<dp:set-variable name="$STATS_LOG_RES_OUTMSG_ROOT_VAR_NAME" value="$MSG_ROOT_NAME"/>
			<!-- Store the Message Format -->
			<dp:set-variable name="$RES_OUT_MSG_FORMAT_VAR_NAME" value="$MSG_FORMAT"/>
			<!-- Store  consumer MsgId (eg TRN, optionally set via xslt) if it is provided -->
			<xsl:variable name="CONSUMER_TRANSACTION_ID" select="dp:variable($TRANSACTION_ID_VAR_NAME)"/>
			<xsl:if test="$CONSUMER_TRANSACTION_ID != ''">
				<xsl:call-template name="StoreMsgIdentifier">
					<xsl:with-param name="TYPE" select="dp:variable($TRANSACTION_ID_TYPE_VAR_NAME)"/>
					<xsl:with-param name="APPLIES_TO" select="'RES'"/>
					<xsl:with-param name="IDENTIFIER_VALUE" select="$CONSUMER_TRANSACTION_ID"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:if test="$CAPTURE_POINT_LOGS != 'none'">
				<!-- Store the response output message to point log -->
				<xsl:call-template name="StorePointLog">
					<xsl:with-param name="MSG" select="dp:variable($RESULT_DOC_CONTEXT_NAME)"/>
					<xsl:with-param name="POINT_LOG_VAR_NAME" select="$POINT_LOG_RES_OUTMSG_VAR_NAME"/>
				</xsl:call-template>
			</xsl:if>
			<!-- Delete response headers -->
			<xsl:call-template name="DeleteHttpResponseHeaders"/>
			<!-- Clear the local context error variables -->
			<dp:set-variable name="$ERROR_CODE_VAR_NAME" value="''"/>
			<!-- Do success logging -->
			<xsl:call-template name="SendLogMsg"/>
		</xsl:if>
		<xsl:if test="$TX_RULE_TYPE = 'error'">
			<!-- Save output message root name to the environment -->
			<dp:set-variable name="$STATS_LOG_RES_OUTMSG_ROOT_VAR_NAME" value="$MSG_ROOT_NAME"/>
			<xsl:if test="$CAPTURE_POINT_LOGS != 'none'">
				<!-- Store the response output message to point log -->
				<xsl:call-template name="StorePointLog">
					<xsl:with-param name="MSG" select="dp:variable($RESULT_DOC_CONTEXT_NAME)"/>
					<xsl:with-param name="POINT_LOG_VAR_NAME" select="$POINT_LOG_RES_OUTMSG_VAR_NAME"/>
				</xsl:call-template>
			</xsl:if>
			<!-- Do error logging -->
			<xsl:call-template name="SendLogMsg"/>
		</xsl:if>
	</xsl:template>
	<!-- Standard identity template -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
