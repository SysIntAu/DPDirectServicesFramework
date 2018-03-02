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
	xmlns:dp="http://www.datapower.com/extensions" xmlns:date="http://exslt.org/dates-and-times"
	extension-element-prefixes="dp date" version="1.0" exclude-result-prefixes="dp date soapenv wst wss">
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="local:///ondisk/ESB_Services/framework/Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="NEW_MSG_ID" select="dp:radix-convert(dp:random-bytes(24),64,16)"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root template -->
	<xsl:template match="/">
		<xsl:variable name="REQ_MQMD" select="dp:variable($REQ_MQMD_VAR_NAME)"/>
		<MQMD>
			<StrucId>
				<xsl:value-of select="$MQMD_STRUC_ID"/>
			</StrucId>
			<Version>
				<xsl:value-of select="$MQMD_VERSION_1"/>
			</Version>
			<Report>
				<xsl:value-of select="($MQRO_PASS_MSG_ID + $MQRO_PASS_CORREL_ID)"/>
			</Report>
			<MsgType>
				<xsl:value-of select="$MQMT_REQUEST"/>
			</MsgType>
			<Expiry>
				<xsl:value-of select="$MQEI_UNLIMITED"/>
			</Expiry>
			<Feedback>
				<xsl:value-of select="$MQFB_NONE"/>
			</Feedback>
			<Encoding>
				<xsl:value-of select="'785'"/>
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
				<xsl:value-of select="$MQPER_NOT_PERSISTENT"/>
			</Persistence>
			<MsgId>
				<xsl:choose>
					<!-- Pass CorrelId from request if present -->
					<xsl:when test="normalize-space($REQ_MQMD/MsgId[1]) != ''">
						<xsl:value-of select="normalize-space($REQ_MQMD/MsgId[1])"/>
					</xsl:when>
					<!-- Otherwise default to the new message id -->
					<xsl:otherwise>
						<xsl:value-of select="$NEW_MSG_ID"/>
					</xsl:otherwise>
				</xsl:choose>
			</MsgId>
			<CorrelId>
				<xsl:choose>
					<!-- Pass CorrelId from request if present -->
					<xsl:when test="normalize-space($REQ_MQMD/MsgId[1]) != ''">
						<xsl:value-of select="normalize-space($REQ_MQMD/MsgId[1])"/>
					</xsl:when>
					<!-- Otherwise default to the new message id -->
					<xsl:otherwise>
						<xsl:value-of select="'010000000000000000000000000000000000000000000000'"/>
					</xsl:otherwise>
				</xsl:choose>
			</CorrelId>
			<BackoutCount>
				<xsl:value-of select="'0'"/>
			</BackoutCount>
			<ReplyToQ>
				<xsl:value-of select="'DP.ESB.DP.SERVICE.LOG'"/>
			</ReplyToQ>
			<ReplyToQMgr>
				<!-- Leave blank - The DP MQ client will populate with the underlying QMgr from the MQ QMgr Group -->
				<xsl:value-of select="''"/>
			</ReplyToQMgr>
			<UserIdentifier>
				<xsl:value-of select="'DESB'"/>
			</UserIdentifier>
			<AccountingToken>
				<xsl:value-of select="'0000000000000000000000000000000000000000000000000000000000000000'"/>
			</AccountingToken>
			<PutApplType>
				<xsl:value-of select="'0'"/>
			</PutApplType>
			<PutApplName>
				<xsl:value-of select="'DESB'"/>
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
