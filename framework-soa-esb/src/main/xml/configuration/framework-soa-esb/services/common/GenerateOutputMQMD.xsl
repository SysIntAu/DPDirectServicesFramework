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
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust"
	xmlns:wss="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:date="http://exslt.org/dates-and-times"
	extension-element-prefixes="dp regexp date" version="1.0" exclude-result-prefixes="dp date soapenv wst wss">
	<!--
		=================================================================
		Purpose:
		Generate generic output MQMD Header for outbound MQ Put
		
		History:
		2016-12-12	v0.1	Tim Goodwill		Initial Version - generic.
		=================================================================
	-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///ESB_Services/framework/Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="USER_NAME" select="normalize-space(dp:variable($REQ_USER_NAME_VAR_NAME))"/>
	<xsl:variable name="REQ_MQMD" select="dp:variable($REQ_MQMD_VAR_NAME)"/>
	<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
	<xsl:variable name="NOTIFICATION_REQ" select="$SERVICE_METADATA/PolicyConfig/*[1][@async='true']"/>
	<xsl:variable name="REPLY_TO_Q">
		<xsl:choose>
			<xsl:when test="$SERVICE_METADATA/PolicyConfig/*[1]/MQRouting[1]/ReplyQueue">
				<xsl:value-of select="$SERVICE_METADATA/PolicyConfig/*[1]/MQRouting[1]/ReplyQueue[1]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="' '"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable> 
	<xsl:variable name="NEW_MSG_ID" select="dp:radix-convert(dp:random-bytes(24),64,16)"/>
	<xsl:variable name="MSG_ID">
		<xsl:choose>
			<!-- Pass MsgId from request if present -->
			<xsl:when test="normalize-space($REQ_MQMD/MsgId[1]) != ''">
				<xsl:value-of select="$REQ_MQMD/MsgId[1]"/>
			</xsl:when>
			<!-- Otherwise default to the new message id -->
			<xsl:otherwise>
				<xsl:value-of select="$NEW_MSG_ID"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="WSA_REPLY_TO" select="normalize-space(dp:variable($REQ_WSA_REPLY_TO_VAR_NAME))"/>
	<xsl:variable name="WSA_RELATES_TO_ID" select="normalize-space(dp:variable($REQ_WSA_RELATES_TO_VAR_NAME))"/>
	<xsl:variable name="CORREL_ID">
		<xsl:choose>
			<!-- MQ Msg Id is 48 char hexdec -->
			<xsl:when test="(string-length($WSA_RELATES_TO_ID) = 48)
				and regexp:match($WSA_RELATES_TO_ID, '^[a-fA-F0-9]*$')">
				<xsl:value-of select="$WSA_RELATES_TO_ID"/>
			</xsl:when>
			<!-- Introduced late in BR02 : remove the RELATES_TO test BR03 -->
			<xsl:when test="($WSA_RELATES_TO_ID != '') and normalize-space($REQ_MQMD/CorrelId[1]) != ''">
				<xsl:value-of select="$REQ_MQMD/CorrelId[1]"/>
			</xsl:when>
			<!-- Otherwise default to the new message id -->
			<xsl:otherwise>
				<xsl:value-of select="$MSG_ID"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root template -->
	<xsl:template match="/">
		<MQMD>
			<StrucId>
				<xsl:value-of select="$MQMD_STRUC_ID"/>
			</StrucId>
			<Version>
				<xsl:value-of select="$MQMD_VERSION_1"/>
			</Version>
			<Report>
				<xsl:choose>
					<xsl:when test="$NOTIFICATION_REQ">
						<xsl:value-of select="$MQRO_NONE"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$MQRO_COPY_MSG_ID_TO_CORREL_ID"/>
					</xsl:otherwise>
				</xsl:choose>
			</Report>
			<MsgType>
				<xsl:choose>
					<xsl:when test="$NOTIFICATION_REQ">
						<xsl:value-of select="$MQMT_DATAGRAM"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$MQMT_REQUEST"/>
					</xsl:otherwise>
				</xsl:choose>
			</MsgType>
			<Expiry>
				<xsl:choose>
					<!-- Notifications do not expire -->
					<xsl:when test="$NOTIFICATION_REQ">
						<xsl:value-of select="$MQEI_UNLIMITED"/>
					</xsl:when>
					<!-- Pass expiry from request if present -->
					<xsl:when test="normalize-space($REQ_MQMD/Expiry[1]) != ''">
						<xsl:value-of select="normalize-space($REQ_MQMD/Expiry[1])"/>
					</xsl:when>
					<!-- Otherwise default to no expiry -->
					<xsl:otherwise>
						<xsl:value-of select="$MQEI_UNLIMITED"/>
					</xsl:otherwise>
				</xsl:choose>
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
				<xsl:value-of select="'5'"/>
			</Priority>
			<Persistence>
				<xsl:choose>
					<!-- All notifications persistent -->
					<xsl:when test="$NOTIFICATION_REQ">
						<xsl:value-of select="$MQPER_PERSISTENT"/>
					</xsl:when>
					<!-- Pass persistence from request if present -->
					<xsl:when test="normalize-space($REQ_MQMD/Persistence[1]) != ''">
						<xsl:value-of select="normalize-space($REQ_MQMD/Persistence[1])"/>
					</xsl:when>
					<!-- Otherwise default to non-persistent -->
					<xsl:otherwise>
						<xsl:value-of select="$MQPER_NOT_PERSISTENT"/>
					</xsl:otherwise>
				</xsl:choose>
			</Persistence>
			<MsgId>
				<xsl:value-of select="$MSG_ID"/>
			</MsgId>
			<CorrelId>
				<xsl:value-of select="$CORREL_ID"/>
			</CorrelId>
			<BackoutCount>
				<xsl:value-of select="'0'"/>
			</BackoutCount>
			<ReplyToQ>
				<xsl:value-of select="$REPLY_TO_Q"/>
			</ReplyToQ>
			<ReplyToQMgr>
				<!-- Leave blank - The DP MQ client will populate with the underlying QMgr from the MQ QMgr Group -->
				<xsl:value-of select="''"/>
			</ReplyToQMgr>
			<UserIdentifier>
				<xsl:value-of select="$USER_NAME"/>
			</UserIdentifier>
			<AccountingToken>
				<xsl:value-of select="'0000000000000000000000000000000000000000000000000000000000000000'"/>
			</AccountingToken>
			<ApplIdentityData/>
			<PutApplType>
				<xsl:value-of select="'0'"/>
			</PutApplType>
			<PutApplName>
				<!-- Default to current policy -->
				<xsl:value-of select="$POLICY_CONFIG_NODE_ID"/>
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
