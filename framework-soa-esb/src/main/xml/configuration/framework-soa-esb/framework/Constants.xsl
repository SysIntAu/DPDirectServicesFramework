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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="" version="1.0">
	<!--========================================================================
		Purpose:
		A collection of constant DataPower variable and context definitions (URIs) for common use across
		stylesheets within the DataPower ESB_Services policy flows.
				
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		2016-12-12	v2.0	Tim Goodwill		Init Gateway  instance
		========================================================================-->
	<!--============== Global Variable Declarations =================-->
	<!--
		Local File Path variable names
	-->
	<xsl:variable name="DPDIRECT_SERVICES_ROOT_FOLDER" select="'local:///ESB_Services/'"/>
	<xsl:variable name="SERVICE_SCHEMA_ROOT_FOLDER" select="'local:///service-schema/'"/>
	<xsl:variable name="GENERIC_MQMD_XSLT_PATH" select="'local:///ESB_Services/services/common/GenerateOutputMQMD.xsl'"/>
	<!--
		'ESB_Services' context variable names
	-->
	<xsl:variable name="AUTHZ_RESULT_SET_VAR_NAME" select="'var://context/ESB_Services/authorisationResultSet'"/>
	<xsl:variable name="BACKEND_MQMD_VAR_NAME" select="'var://context/ESB_Services/backendMQMD'"/>
	<xsl:variable name="BACKEND_MQMP_VAR_NAME" select="'var://context/ESB_Services/backendMQMP'"/>
	<xsl:variable name="BACKEND_PROTOCOL_VAR_NAME" select="'var://context/ESB_Services/backsideProtocol'"/>
	<xsl:variable name="CALL_SERVICE_RES_DOC_BASEVAR_NAME" select="'var://context/ESB_Services/callServiceResponseDoc/'"/>
	<xsl:variable name="TRANSACTION_ID_VAR_NAME" select="'var://context/ESB_Services/consumerTransactionId'"/>
	<xsl:variable name="TRANSACTION_ID_TYPE_VAR_NAME" select="'var://context/ESB_Services/consumerTransactionIdType'"/>
	<xsl:variable name="ENTERPRISE_FAULT_DTL_VAR_NAME" select="'var://context/ESB_Services/enterpriseFaultDetail'"/>
	<xsl:variable name="ERROR_ADD_DETAILS_VAR_NAME" select="'var://context/ESB_Services/errorSubDescription'"/>
	<xsl:variable name="ERROR_CODE_VAR_NAME" select="'var://context/ESB_Services/errorCode'"/>
	<xsl:variable name="ERROR_TO_WSA_ENDPOINT_RESULT_VAR_NAME" select="'var://context/ESB_Services/errorToWSAEndpointResult'"/>
	<xsl:variable name="ERROR_TO_WSA_ENDPOINT_RETURN_CODE_VAR_NAME" select="'var://context/ESB_Services/errorToWSAEndpointReturnCode'"/>
	<xsl:variable name="EVENT_CODE_VAR_NAME" select="'var://context/ESB_Services/eventCode'"/>
	<xsl:variable name="EVENT_SUBCODE_VAR_NAME" select="'var://context/ESB_Services/eventSubCode'"/>
	<xsl:variable name="EVENT_MESSAGE_VAR_NAME" select="'var://context/ESB_Services/eventMsg'"/>
	<xsl:variable name="ERROR_DOMAIN_VAR_NAME" select="'var://context/ESB_Services/errorDomain'"/>
	<xsl:variable name="ERROR_MSG_VAR_NAME" select="'var://context/ESB_Services/errorMsg'"/>
	<xsl:variable name="ERROR_ORIG_LOC_VAR_NAME" select="'var://context/ESB_Services/errorOriginatorLoc'"/>
	<xsl:variable name="ERROR_ORIG_NAME_VAR_NAME" select="'var://context/ESB_Services/errorSubCode'"/>
	<xsl:variable name="ERROR_PROVIDER_NAME_VAR_NAME" select="'var://context/ESB_Services/errorProviderName'"/>
	<xsl:variable name="ERROR_SERVICE_NAME_VAR_NAME" select="'var://context/ESB_Services/errorServiceName'"/>
	<xsl:variable name="ERROR_SUBCODE_VAR_NAME" select="'var://context/ESB_Services/errorSubCode'"/>
	<xsl:variable name="ERROR_OVERRIDE_VAR_NAME" select="'var://context/ESB_Services/errorOverride'"/>
	<xsl:variable name="EXTENSION_VARS_VAR_NAME" select="'var://context/ESB_Services/_extension/variables'"/>
	<xsl:variable name="FLOW_DIRECTION_VAR_NAME" select="'var://context/ESB_Services/flowDirection'"/>
	<xsl:variable name="HTTP_HEADERS_LIST_VAR_NAME" select="'var://context/ESB_Services/httpHeadersList'"/>
	<xsl:variable name="MSG_IDENTIFIERS_VAR_NAME" select="'var://context/ESB_Services/msgIdentifiers'"/>
	<xsl:variable name="NEXT_RULE_NAME_VAR_NAME" select="'var://context/ESB_Services/nextRuleName'"/>
	<xsl:variable name="POINT_LOG_REQ_INMSG_VAR_NAME" select="'var://context/ESB_Services/pointLogReqInMsg'"/>
	<xsl:variable name="POINT_LOG_REQ_OUTMSG_VAR_NAME" select="'var://context/ESB_Services/pointLogReqOutMsg'"/>
	<xsl:variable name="POINT_LOG_RES_INMSG_VAR_NAME" select="'var://context/ESB_Services/pointLogResInMsg'"/>
	<xsl:variable name="POINT_LOG_RES_OUTMSG_VAR_NAME" select="'var://context/ESB_Services/pointLogResOutMsg'"/>
	<xsl:variable name="POLICY_CONFIG_NODE_ID_VAR_NAME" select="'var://context/ESB_Services/operationConfigNodeId'"/>
	<xsl:variable name="OPERATION_CONFIG_NODE_ID_VAR_NAME" select="'var://context/ESB_Services/operationConfigNodeId'"/>
	<xsl:variable name="OPERATION_CONFIG_PROVIDER_VAR_NAME" select="'var://context/ESB_Services/operationConfigProvider'"/>
	<xsl:variable name="PROVIDER_VAR_NAME" select="'var://context/ESB_Services/providerName'"/>
	<xsl:variable name="PROVIDER_TIMEOUT_MILLIS_VAR_NAME" select="'var://context/ESB_Services/providerTimeoutMillis'"/>
	<xsl:variable name="REQ_HTTP_HEADERS_IN_VAR_NAME" select="'var://context/ESB_Services/requestHttpHeadersIn'"/>
	<xsl:variable name="REQ_HTTP_HEADERS_OUT_VAR_NAME" select="'var://context/ESB_Services/requestHttpHeadersOut'"/>
	<xsl:variable name="RES_HTTP_HEADERS_IN_VAR_NAME" select="'var://context/ESB_Services/responseHttpHeadersIn'"/>
	<xsl:variable name="RES_HTTP_HEADERS_OUT_VAR_NAME" select="'var://context/ESB_Services/responseHttpHeadersOut'"/>
	<xsl:variable name="RES_IN_MSG_FORMAT_VAR_NAME" select="'var://context/ESB_Services/responseInMsgFormat'"/>
	<xsl:variable name="RES_IN_MSG_NAME_VAR_NAME" select="'var://context/ESB_Services/responseInMsgName'"/>
	<xsl:variable name="RES_OUT_MSG_FORMAT_VAR_NAME" select="'var://context/ESB_Services/responseOutMsgFormat'"/>
	<xsl:variable name="REQ_IN_MSG_FORMAT_VAR_NAME" select="'var://context/ESB_Services/requestInMsgFormat'"/>
	<xsl:variable name="REQ_OUT_MSG_FORMAT_VAR_NAME" select="'var://context/ESB_Services/requestOutMsgFormat'"/>
	<xsl:variable name="REQ_OUT_MSG_ASYNC_VAR_NAME" select="'var://context/ESB_Services/requestOutMsgAsync'"/>
	<xsl:variable name="REQ_SOAP_ENV_VAR_NAME" select="'var://context/ESB_Services/requestSOAPEnv'"/>
	<xsl:variable name="REQ_SOAP_NAMESPACE_VAR_NAME" select="'var://context/ESB_Services/reqestSOAPNamespace'"/>
	<xsl:variable name="REQ_USER_NAME_VAR_NAME" select="'var://context/ESB_Services/requestUserName'"/>
	<xsl:variable name="REQ_WSA_ACTION_VAR_NAME" select="'var://context/ESB_Services/wsaRequestAction'"/>
	<xsl:variable name="REQ_WSA_MSG_ID_VAR_NAME" select="'var://context/ESB_Services/requestWsaMsgId'"/>
	<xsl:variable name="REQ_WSA_RELATES_TO_VAR_NAME" select="'var://context/ESB_Services/requestWsaRelatesTo'"/>
	<xsl:variable name="REQ_WSA_TO_VAR_NAME" select="'var://context/ESB_Services/requestWsaTo'"/>
	<xsl:variable name="REQ_WSA_FROM_VAR_NAME" select="'var://context/ESB_Services/requestWsaFrom'"/>
	<xsl:variable name="REQ_WSA_REPLY_TO_VAR_NAME" select="'var://context/ESB_Services/requestWsaReplyTo'"/>
	<xsl:variable name="REQ_WSA_FAULT_TO_VAR_NAME" select="'var://context/ESB_Services/requestWsaFaultTo'"/>
	<xsl:variable name="REQ_WSA_SECURITY_VAR_NAME" select="'var://context/ESB_Services/requestWsaSecurity'"/>
	<xsl:variable name="REQ_WSM_OPERATION_VAR_NAME" select="'var://context/ESB_Services/requestWsmOperation'"/>
	<xsl:variable name="RES_WSA_MSG_ID_VAR_NAME" select="'var://context/ESB_Services/responseWsaMsgId'"/>
	<xsl:variable name="RES_WSA_RELATES_TO_VAR_NAME" select="'var://context/ESB_Services/responseWsaRelatesTo'"/>
	<xsl:variable name="RES_WSA_TO_VAR_NAME" select="'var://context/ESB_Services/responseWsaTo'"/>
	<xsl:variable name="RES_WSA_FAULT_TO_VAR_NAME" select="'var://context/ESB_Services/responseWsaFaultTo'"/>
	<xsl:variable name="SAML_ASSERTION_VAR_NAME" select="'var://context/ESB_Services/samlAssertion'"/>
	<xsl:variable name="SERVICE_IDENTIFIER_VAR_NAME" select="'var://context/ESB_Services/serviceIdentifier'"/>
	<xsl:variable name="SERVICE_NAME_VAR_NAME" select="'var://context/ESB_Services/serviceName'"/>
	<xsl:variable name="SERVICE_TRANSACTION_ID_VAR_NAME" select="'var://context/ESB_Services/serviceTransactionId'"/>
	<xsl:variable name="SFTP_OUTPUT_FILE_NAME" select="'var://context/ESB_Services/sftpOutputFileName'"/>
	<xsl:variable name="SERVICE_CHAIN_METADATA_VAR_NAME" select="'var://context/ESB_Services/serviceChainMetadata'"/>
	<xsl:variable name="STATS_REPORT_VAR_NAME" select="'var://context/ESB_Services/statsReport'"/>
	<xsl:variable name="WSU_TIMESTAMP_VAR_NAME" select="'var://context/ESB_Services/wsuTimestamp'"/>
	<xsl:variable name="STATS_LOG_REQ_INMSG_ROOT_VAR_NAME" select="'var://context/ESB_Services/statsLogReqInMsgRoot'"/>
	<xsl:variable name="STATS_LOG_REQ_INMSG_SIZE_VAR_NAME" select="'var://context/ESB_Services/statsLogReqInMsgSize'"/>
	<xsl:variable name="STATS_LOG_REQ_OUTMSG_ROOT_VAR_NAME" select="'var://context/ESB_Services/statsLogReq OutMsgRoot'"/>
	<xsl:variable name="STATS_LOG_RES_INMSG_ROOT_VAR_NAME" select="'var://context/ESB_Services/statsLogResInMsgRoot'"/>
	<xsl:variable name="STATS_LOG_RES_INMSG_SIZE_VAR_NAME" select="'var://context/ESB_Services/statsLogResInMsgSize'"/>
	<xsl:variable name="STATS_LOG_RES_OUTMSG_ROOT_VAR_NAME" select="'var://context/ESB_Services/statsLogResOutMsgRoot'"/>
	<xsl:variable name="TIMER_ELAPSED_BASEVAR_NAME" select="'var://context/ESB_Services/timerElapsed/'"/>
	<xsl:variable name="TIMER_START_BASEVAR_NAME" select="'var://context/ESB_Services/timerStart/'"/>
	<!--
		Custom context names
	-->
	<xsl:variable name="SERVICE_METADATA_CONTEXT_NAME" select="'var://context/SERVICE_METADATA/'"/>
	<xsl:variable name="RESULT_DOC_CONTEXT_NAME" select="'var://context/RESULT_DOC/'"/>
	<!-- CallService handling of Binary or MTOM messages -->
	<xsl:variable name="CONTENT_BINARY_VAR_NAME" select="'var://context/ESB_Services/contentBinary'"/>
	<xsl:variable name="VALIDATE_RESULT_CONTEXT_NAME" select="'var://context/VALIDATE_RESULT/'"/>
	<!-- 
		Log event key values
	-->
	<xsl:variable name="LOG_EVENT_KEY_SUCCESS" select="'ServiceComplete'"/>
	<xsl:variable name="LOG_EVENT_KEY_ERROR" select="'ServiceError'"/>
	<xsl:variable name="LOG_EVENT_KEY_EVENT" select="'ServiceEvent'"/>
	<!--
		Datapower pre-defined context names
	-->
	<xsl:variable name="INPUT_CONTEXT_NAME" select="'var://context/INPUT/'"/>
	<!--
		Datapower defined xml names
	-->
	<!-- The Internal QMgr Group name -->
	<xsl:variable name="LOG_QMGR_GROUP_NAME" select="'ESB_Internal_Grp_RealTime_V1'"/>
	<xsl:variable name="BACKEND_QMGR_GROUP_NAME" select="'ESB_Internal_Grp_RealTime_V1'"/>
	<!--
		Datapower pre-defined service variable names
	-->
	<xsl:variable name="DP_SERVICE_BACKEND_TIMEOUT" select="'var://service/mpgw/backend-timeout'"/>
	<xsl:variable name="DP_SERVICE_LOCAL_SERVICE_ADDRESS" select="'var://service/local-service-address'"/>
	<xsl:variable name="DP_SERVICE_CLIENT_SERVICE_ADDRESS" select="'var://service/client-service-address'"/>
	<xsl:variable name="DP_SERVICE_DOMAIN_NAME" select="'var://service/domain-name'"/>
	<xsl:variable name="DP_SERVICE_URI" select="'var://service/URI'"/>
	<xsl:variable name="DP_SERVICE_URL_IN" select="'var://service/URL-in'"/>
	<xsl:variable name="DP_SERVICE_URL_OUT" select="'var://service/URL-out'"/>
	<xsl:variable name="DP_SERVICE_MQ_CCSI" select="'var://service/mq-ccsi'"/>
	<xsl:variable name="DP_SERVICE_TIME_ELAPSED" select="'var://service/time-elapsed'"/>
	<xsl:variable name="DP_SERVICE_ERROR_CODE" select="'var://service/error-code'"/>
	<xsl:variable name="DP_SERVICE_ERROR_HEADERS" select="'var://service/error-headers'"/>
	<xsl:variable name="DP_SERVICE_ERROR_IGNORE" select="'var://service/error-ignore'"/>
	<xsl:variable name="DP_SERVICE_ERROR_MSG" select="'var://service/error-message'"/>
	<xsl:variable name="DP_SERVICE_ERROR_PROTOCOL_REASON_PHRASE" select="'var://service/error-protocol-reason-phrase'"/>
	<xsl:variable name="DP_SERVICE_ERROR_PROTOCOL_RESPONSE" select="'var://service/error-protocol-response'"/>
	<xsl:variable name="DP_SERVICE_ERROR_SUBCODE" select="'var://service/error-subcode'"/>
	<xsl:variable name="DP_SERVICE_FORMATTED_ERROR_MSG" select="'var://service/formatted-error-message'"/>
	<xsl:variable name="DP_SERVICE_HEADER_MANIFEST" select="'var://service/header-manifest'"/>
	<xsl:variable name="DP_LOCAL_ATTACHMENT_MANIFEST" select="'var://local/attachment-manifest'"/>
	<xsl:variable name="DP_SERVICE_STRICT_ERROR_MODE" select="'var://service/strict-error-mode'"/>
	<xsl:variable name="DP_SERVICE_PROCESSOR_NAME" select="'var://service/processor-name'"/>
	<xsl:variable name="DP_SERVICE_ROUTING_URL" select="'var://service/routing-url'"/>
	<xsl:variable name="DP_SERVICE_ROUTING_URL_DELAY_CONTENT_TYPE" select="'var://service/routing-url-delay-content-type-determination'"/>
	<xsl:variable name="DP_SERVICE_TRANSACTION_ID" select="'var://service/transaction-id'"/>
	<xsl:variable name="DP_SERVICE_TRANSACTION_RULE_TYPE" select="'var://service/transaction-rule-type'"/>
	<xsl:variable name="DP_SERVICE_FRONT_PROTOCOL" select="'var://service/wsm/front-protocol'"/>
	<xsl:variable name="DP_SERVICE_TRANSACTION_TIMEOUT" select="'var://service/transaction-timeout'"/>
	<xsl:variable name="DP_SERVICE_WSM_OPERATION" select="'var://service/wsm/operation'"/>
	<!--
		Datapower pre-defined WSM context variable names
	-->
	<xsl:variable name="DP_CONTEXT_WSM_IDENT_CREDENTIALS" select="'var://context/WSM/identity/credentials'"/>
	<!--
		Datapower pre-defined log level (priority) values
	-->
	<xsl:variable name="DP_LOG_LEVEL_EMERG" select="'emerg'"/>
	<xsl:variable name="DP_LOG_LEVEL_ALERT" select="'alert'"/>
	<xsl:variable name="DP_LOG_LEVEL_CRITIC" select="'critic'"/>
	<xsl:variable name="DP_LOG_LEVEL_ERROR" select="'error'"/>
	<xsl:variable name="DP_LOG_LEVEL_WARN" select="'warn'"/>
	<xsl:variable name="DP_LOG_LEVEL_NOTICE" select="'notice'"/>
	<xsl:variable name="DP_LOG_LEVEL_INFO" select="'info'"/>
	<xsl:variable name="DP_LOG_LEVEL_DEBUG" select="'debug'"/>
	<!--
		'dpdirect://' properties prefix and property keys
	-->
	<xsl:variable name="DPDIRECT.PROP_URI_PREFIX" select="'dpdirect://'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_LOGCAT_DPDIRECT.STATS" select="'dpdirect://logCategory/dpdirectStats'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_LOGCAT_DPDIRECT.SERVICE" select="'dpdirect://logCategory/dpdirectService'"/>
	<xsl:variable name="DPDIRECT.LOGCAT_DPDIRECT.STATS_SUFFIX" select="'_DPDirectStats'"/>
	<xsl:variable name="DPDIRECT.LOGCAT_DPDIRECT.SERVICE_SUFFIX" select="'_DPDirectService'"/>
	<!-- 
		Miscellaneous variables
	-->
	<xsl:variable name="SOAP11_NAMESPACE_URI" select="'http://schemas.xmlsoap.org/soap/envelope/'"/>
	<xsl:variable name="SOAP12_NAMESPACE_URI" select="'http://www.w3.org/2003/05/soap-envelope'"/>
	<xsl:variable name="WSA_NAMESPACE_URI" select="'http://www.w3.org/2005/08/addressing'"/>
	<xsl:variable name="WSA_ANONYMOUS_DESTINATION" select="'http://www.w3.org/2005/08/addressing/anonymous'"/>
	<xsl:variable name="DP_MANUAL_REJECT_EVENT_CODE" select="'0x00d30003'"/>
	<xsl:variable name="DP_FALLBACK_ERROR_CODE" select="'ERROR0001'"/>
	<xsl:variable name="DP_FILTER_ERROR_CODE" select="'FRMWK0031'"/>
	<xsl:variable name="DP_FILTER_FLAG_NAME" select="'DP_MSG_FILTER'"/>
	<xsl:variable name="COMMON_ERROR_DOMAIN_LIST" select="'Framework,Enterprise'"/>
	<xsl:variable name="SERVICES_PROXY_NAME_SUFFIX" select="'_ServicesProxy'"/>
	<xsl:variable name="RULE_NAME_PREFIX" select="'ESB_Services_V1_'"/>
	<xsl:variable name="EMPTY_SOAP_11_DOC">
		<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
			<soap:Header/>
			<soap:Body/>
		</soap:Envelope>
	</xsl:variable>
	<xsl:variable name="EMPTY_SOAP_12_DOC">
		<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope">
			<soap:Header/>
			<soap:Body/>
		</soap:Envelope>
	</xsl:variable>
</xsl:stylesheet>
