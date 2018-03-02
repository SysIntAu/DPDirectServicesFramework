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
	exclude-result-prefixes="" version="1.0">
	<!--========================================================================
		Purpose:
		MQ constant values (as defined in the "WebSphere MQ Constants Version 6.0" document)
				
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Global Variable Declarations =================-->
	<!-- MQ CCSID constants (not official MQ Constant names, just defined here for convenience)-->
	<xsl:variable name="MQ_CCSID_UCS2" select="1200"/>
	<xsl:variable name="MQ_CCSID_UTF8" select="1208"/>
	<!--
		MQ constant values (as defined in the "WebSphere MQ Constants Version 6.0" document).
	-->
	<!-- MQMD constants -->
	<xsl:variable name="MQMD_STRUC_ID" select="'MD&#x20;&#x20;'"/>
	<xsl:variable name="MQMD_VERSION_1" select="1"/>
	<xsl:variable name="MQMD_VERSION_2" select="2"/>
	<xsl:variable name="MQMD_CURRENT_VERSION" select="2"/>
	<!-- MQEI constants -->
	<xsl:variable name="MQEI_UNLIMITED" select="-1"/>
	<!-- MQENC constants -->
	<xsl:variable name="MQENC_NATIVE" select="273"/>
	<!-- MQFB constants -->
	<xsl:variable name="MQFB_NONE" select="0"/>
	<xsl:variable name="MQFB_SYSTEM_FIRST" select="1"/>
	<xsl:variable name="MQFB_QUIT" select="256"/>
	<xsl:variable name="MQFB_EXPIRATION" select="258"/>
	<xsl:variable name="MQFB_COA" select="259"/>
	<xsl:variable name="MQFB_COD" select="260"/>
	<xsl:variable name="MQFB_CHANNEL_COMPLETED" select="262"/>
	<xsl:variable name="MQFB_CHANNEL_FAIL_RETRY" select="263"/>
	<xsl:variable name="MQFB_CHANNEL_FAIL" select="264"/>
	<xsl:variable name="MQFB_APPL_CANNOT_BE_STARTED" select="265"/>
	<xsl:variable name="MQFB_TM_ERROR" select="266"/>
	<xsl:variable name="MQFB_APPL_TYPE_ERROR" select="267"/>
	<xsl:variable name="MQFB_STOPPED_BY_MSG_EXIT" select="268"/>
	<xsl:variable name="MQFB_ACTIVITY" select="269"/>
	<xsl:variable name="MQFB_XMIT_Q_MSG_ERROR" select="271"/>
	<xsl:variable name="MQFB_PAN" select="275"/>
	<xsl:variable name="MQFB_NAN" select="276"/>
	<!-- MQFMT constants -->
	<xsl:variable name="MQFMT_RF_HEADER_2" select="'MQHRF2'"/>
	<!-- MQPER constants -->
	<xsl:variable name="MQPER_NOT_PERSISTENT" select="0"/>
	<xsl:variable name="MQPER_PERSISTENT" select="1"/>
	<xsl:variable name="MQPER_PERSISTENCE_AS_Q_DEF" select="2"/>
	<!-- MQFMT constants -->
	<xsl:variable name="MQFMT_STRING" select="'MQSTR'"/>
	<!-- MQAT constants -->
	<xsl:variable name="MQAT_BROKER" select="26"/>
	<!-- MQMT constants -->
	<xsl:variable name="MQMT_SYSTEM_FIRST" select="1"/>
	<xsl:variable name="MQMT_REQUEST" select="1"/>
	<xsl:variable name="MQMT_REPLY" select="2"/>
	<xsl:variable name="MQMT_REPORT" select="4"/>
	<xsl:variable name="MQMT_DATAGRAM" select="8"/>
	<xsl:variable name="MQMT_MQE_FIELDS_FROM_MQE" select="112"/>
	<xsl:variable name="MQMT_MQE_FIELDS" select="113"/>
	<xsl:variable name="MQMT_SYSTEM_LAST" select="65535"/>
	<xsl:variable name="MQMT_APPL_FIRST" select="65536"/>
	<xsl:variable name="MQMT_APPL_LAST" select="999999999"/>
	<!-- MQPMO constants -->
	<xsl:variable name="MQPMO_SYNCPOINT" select="2"/>
	<xsl:variable name="MQPMO_NO_SYNCPOINT" select="4"/>
	<xsl:variable name="MQPMO_NEW_MSG_ID" select="64"/>
	<xsl:variable name="MQPMO_NEW_CORREL_ID" select="128"/>
	<xsl:variable name="MQPMO_LOGICAL_ORDER" select="32728"/>
	<xsl:variable name="MQPMO_NO_CONTEXT" select="16384"/>
	<xsl:variable name="MQPMO_DEFAULT_CONTEXT" select="32"/>
	<xsl:variable name="MQPMO_PASS_IDENTITY_CONTEXT" select="256"/>
	<xsl:variable name="MQPMO_PASS_ALL_CONTEXT" select="512"/>
	<xsl:variable name="MQPMO_SET_IDENTITY_CONTEXT" select="1024"/>
	<xsl:variable name="MQPMO_SET_ALL_CONTEXT" select="2048"/>
	<xsl:variable name="MQPMO_ALTERNATE_USER_AUTHORITY" select="4096"/>
	<xsl:variable name="MQPMO_FAIL_IF_QUIESCING" select="8192"/>
	<xsl:variable name="MQPMO_RESOLVE_LOCAL_Q" select="262144"/>
	<xsl:variable name="MQPMO_NONE" select="0"/>
	<!-- MQGMO constants -->
	<xsl:variable name="MQGMO_WAIT" select="1"/>
	<xsl:variable name="MQGMO_NO_WAIT" select="0"/>
	<xsl:variable name="MQGMO_SET_SIGNAL" select="8"/>
	<xsl:variable name="MQGMO_FAIL_IF_QUIESCING" select="8192"/>
	<xsl:variable name="MQGMO_SYNCPOINT" select="2"/>
	<xsl:variable name="MQGMO_SYNCPOINT_IF_PERSISTENT" select="4096"/>
	<xsl:variable name="MQGMO_NO_SYNCPOINT" select="4"/>
	<xsl:variable name="MQGMO_MARK_SKIP_BACKOUT" select="128"/>
	<xsl:variable name="MQGMO_BROWSE_FIRST" select="16"/>
	<xsl:variable name="MQGMO_BROWSE_NEXT" select="32"/>
	<xsl:variable name="MQGMO_BROWSE_MSG_UNDER_CURSOR" select="2048"/>
	<xsl:variable name="MQGMO_MSG_UNDER_CURSOR" select="256"/>
	<xsl:variable name="MQGMO_LOCK" select="512"/>
	<xsl:variable name="MQGMO_UNLOCK" select="1024"/>
	<xsl:variable name="MQGMO_ACCEPT_TRUNCATED_MSG" select="64"/>
	<xsl:variable name="MQGMO_CONVERT" select="16384"/>
	<xsl:variable name="MQGMO_LOGICAL_ORDER" select="32768"/>
	<xsl:variable name="MQGMO_COMPLETE_MSG" select="65536"/>
	<xsl:variable name="MQGMO_ALL_MSGS_AVAILABLE" select="131072"/>
	<xsl:variable name="MQGMO_ALL_SEGMENTS_AVAILABLE" select="262144"/>
	<xsl:variable name="MQGMO_DELETE_MSG" select="524288"/>
	<xsl:variable name="MQGMO_NONE" select="0"/>
	<!-- MQRO constants -->
	<xsl:variable name="MQRO_NEW_MSG_ID" select="0"/>
	<xsl:variable name="MQRO_COPY_MSG_ID_TO_CORREL_ID" select="0"/>
	<xsl:variable name="MQRO_DEAD_LETTER_Q" select="0"/>
	<xsl:variable name="MQRO_NONE" select="0"/>
	<xsl:variable name="MQRO_PAN" select="1"/>
	<xsl:variable name="MQRO_NAN" select="2"/>
	<xsl:variable name="MQRO_ACTIVITY" select="4"/>
	<xsl:variable name="MQRO_PASS_CORREL_ID" select="64"/>
	<xsl:variable name="MQRO_PASS_MSG_ID" select="128"/>
	<xsl:variable name="MQRO_COA" select="256"/>
	<xsl:variable name="MQRO_COA_WITH_DATA" select="768"/>
	<xsl:variable name="MQRO_COA_WITH_FULL_DATA" select="1792"/>
	<xsl:variable name="MQRO_COD" select="2048"/>
	<xsl:variable name="MQRO_COD_WITH_DATA" select="6144"/>
	<xsl:variable name="MQRO_COD_WITH_FULL_DATA" select="14336"/>
	<xsl:variable name="MQRO_PASS_DISCARD_AND_EXPIRY" select="16384"/>
	<xsl:variable name="MQRO_EXPIRATION" select="2097152"/>
	<xsl:variable name="MQRO_EXPIRATION_WITH_DATA" select="6291456"/>
	<xsl:variable name="MQRO_EXPIRATION_WITH_FULL_DATA" select="14680064"/>
	<xsl:variable name="MQRO_EXCEPTION" select="16777216"/>
	<xsl:variable name="MQRO_EXCEPTION_WITH_DATA" select="50331648"/>
	<xsl:variable name="MQRO_EXCEPTION_WITH_FULL_DATA" select="117440512"/>
	<xsl:variable name="MQRO_DISCARD_MSG" select="134217728"/>
	<!-- MQMF constants -->
	<xsl:variable name="MQMF_SEGMENTATION_INHIBITED" select="0"/>
	<xsl:variable name="MQMF_SEGMENTATION_ALLOWED" select="1"/>
	<xsl:variable name="MQMF_MSG_IN_GROUP" select="8"/>
	<xsl:variable name="MQMF_LAST_MSG_IN_GROUP" select="16"/>
	<xsl:variable name="MQMF_SEGMENT" select="2"/>
	<xsl:variable name="MQMF_LAST_SEGMENT" select="4"/>
	<xsl:variable name="MQMF_NONE" select="0"/>
</xsl:stylesheet>
