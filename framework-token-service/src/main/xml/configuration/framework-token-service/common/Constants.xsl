<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="" version="1.0">
	<!--========================================================================
		Purpose:
		A collection of constant DataPower variable and context definitions (URIs) for common use across
		stylesheets within the DataPower SecureTokenService policy flows.
		
		History:
		2016-03-06	v1.0	N.A.		Initial Version.
		2016-03-20	v2.0	Tim Goodwill		Init MSG instance
		========================================================================-->
	<!--============== Global Variable Declarations =================-->
	<!--
		Local File Path variable names
	-->
	<xsl:variable name="SERVICE_SCHEMA_ROOT_FOLDER" select="'local:///service-schema/'"/>
	<!--
		'SecureTokenService' context variable names
	-->
	<xsl:variable name="REQ_HTTP_HEADERS_IN_VAR_NAME" select="'var://context/SecureTokenService/requestHttpHeadersIn'"/>
	<xsl:variable name="REQ_HTTP_HEADERS_OUT_VAR_NAME" select="'var://context/SecureTokenService/requestHttpHeadersOut'"/>
	<xsl:variable name="REQ_IN_MSG_FORMAT_VAR_NAME" select="'var://context/SecureTokenService/requestInMsgFormat'"/>
	<xsl:variable name="REQ_OUT_MSG_FORMAT_VAR_NAME" select="'var://context/SecureTokenService/requestOutMsgFormat'"/>
	<xsl:variable name="REQ_SOAP_ENV_VAR_NAME" select="'var://context/SecureTokenService/requestSOAPEnv'"/>
	<xsl:variable name="REQ_SOAP_NAMESPACE_VAR_NAME" select="'var://context/SecureTokenService/reqestSOAPNamespace'"/>
	<xsl:variable name="REQ_USER_NAME_VAR_NAME" select="'var://context/SecureTokenService/requestUserName'"/>
	<xsl:variable name="REQ_WSA_ACTION_VAR_NAME" select="'var://context/SecureTokenService/wsaRequestAction'"/>
	<xsl:variable name="REQ_WSA_MSG_ID_VAR_NAME" select="'var://context/SecureTokenService/requestWsaMsgId'"/>
	<xsl:variable name="REQ_WSA_TO_VAR_NAME" select="'var://context/SecureTokenService/requestWsaTo'"/>
	<xsl:variable name="REQ_WSA_FROM_VAR_NAME" select="'var://context/SecureTokenService/requestWsaFrom'"/>
	<xsl:variable name="REQ_WSA_REPLY_TO_VAR_NAME" select="'var://context/SecureTokenService/requestWsaReplyTo'"/>
	<xsl:variable name="REQ_WSA_FAULT_TO_VAR_NAME" select="'var://context/SecureTokenService/requestWsaFaultTo'"/>
	<xsl:variable name="REQ_WSA_SECURITY_VAR_NAME" select="'var://context/SecureTokenService/requestWsaSecurity'"/>
	<xsl:variable name="REQ_WSU_TIMESTAMP_VAR_NAME" select="'var://context/SecureTokenService/wsuTimestamp'"/>
	<xsl:variable name="RES_HTTP_HEADERS_IN_VAR_NAME" select="'var://context/SecureTokenService/responseHttpHeadersIn'"/>
	<xsl:variable name="RES_HTTP_HEADERS_OUT_VAR_NAME" select="'var://context/SecureTokenService/responseHttpHeadersOut'"/>
	<xsl:variable name="RES_IN_MSG_FORMAT_VAR_NAME" select="'var://context/SecureTokenService/responseInMsgFormat'"/>
	<xsl:variable name="RES_IN_MSG_NAME_VAR_NAME" select="'var://context/SecureTokenService/responseInMsgName'"/>
	<xsl:variable name="RES_OUT_MSG_FORMAT_VAR_NAME" select="'var://context/SecureTokenService/responseOutMsgFormat'"/>
	<xsl:variable name="RES_WSA_MSG_ID_VAR_NAME" select="'var://context/SecureTokenService/responseWsaMsgId'"/>
	<xsl:variable name="RES_WSA_ACTION_VAR_NAME" select="'var://context/SecureTokenService/wsaResponseAction'"/>
	<xsl:variable name="RES_WSA_RELATES_TO_VAR_NAME" select="'var://context/SecureTokenService/responseWsaRelatesTo'"/>
	<xsl:variable name="RES_WSA_TO_VAR_NAME" select="'var://context/SecureTokenService/responseWsaTo'"/>
	<xsl:variable name="SERVICE_IDENTIFIER_VAR_NAME" select="'var://context/SecureTokenService/serviceIdentifier'"/>
	<xsl:variable name="SERVICE_NAME_VAR_NAME" select="'var://context/SecureTokenService/serviceName'"/>
	<xsl:variable name="STATS_LOG_REQ_ROOT_VAR_NAME" select="'var://context/SecureTokenService/statsLogReqInMsgRoot'"/>
	<xsl:variable name="STATS_LOG_REQ_SIZE_VAR_NAME" select="'var://context/SecureTokenService/statsLogReqInMsgSize'"/>
	<xsl:variable name="STATS_LOG_RES_SIZE_VAR_NAME" select="'var://context/ESB_Services/statsLogResInMsgSize'"/>
	<xsl:variable name="STATS_LOG_RES_ROOT_VAR_NAME" select="'var://context/ESB_Services/statsLogResOutMsgRoot'"/>
	<xsl:variable name="TIMER_START_VAR_NAME" select="'var://context/SecureTokenService/timerStart'"/>
	<xsl:variable name="TRANSACTION_ID_VAR_NAME" select="'var://context/SecureTokenService/transactionId'"/>
	
	<!--
		Datapower pre-defined context names
	-->
	<xsl:variable name="INPUT_CONTEXT_NAME" select="'var://context/INPUT/'"/>
	<!--
		Custom context names
	-->
	<xsl:variable name="SERVICE_METADATA_CONTEXT_NAME" select="'var://context/SERVICE_METADATA/'"/>
	<!-- CallService handling of Binary or MTOM messages -->
	<xsl:variable name="VALIDATE_RESULT_CONTEXT_NAME" select="'var://context/VALIDATE_RESULT/'"/>
	<!-- 
		Log event key values
	-->
	<xsl:variable name="DP_INTERNAL_FAULT_EVENT_CODE" select="'0x00c30010'"/>
	<xsl:variable name="LOG_EVENT_KEY_SUCCESS" select="'ServiceComplete'"/>
	<xsl:variable name="LOG_EVENT_KEY_ERROR" select="'ServiceError'"/>
	<xsl:variable name="LOG_EVENT_KEY_EVENT" select="'ServiceEvent'"/>
	<!--
		Datapower defined xml names
	-->
	<!-- The SOA QMgr Group name -->
	<xsl:variable name="LOG_QMGR_GROUP_NAME" select="'ESB_Internal_Grp_RealTime_10M_V1'"/>
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
	<xsl:variable name="DP_SERVICE_TRANSACTION_RULE_NAME" select="'var://service/transaction-rule-name'"/>
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
	
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_HOST" select="'dpdirect://authorisation/ldapConf/hostName'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_PORT" select="'dpdirect://authorisation/ldapConf/portNumber'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_BIND_DN" select="'dpdirect://authorisation/ldapConf/bindDN'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_TARGET_DN_TEMPLATE" select="'dpdirect://authorisation/ldapConf/targetDnTemplate'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_BIND_PASSWORD" select="'dpdirect://authorisation/ldapConf/bindPassword'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_EXT_GROUP_PREFIX" select="'dpdirect://authorisation/ldapConf/groupPrefix'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_EXT_GROUP_LIST" select="'dpdirect://authorisation/ldapConf/groupList'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_GROUP_ATTRIBUTE_NAME" select="'dpdirect://authorisation/ldapConf/groupAttributeName'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_SEARCH_SCOPE" select="'dpdirect://authorisation/ldapConf/searchScope'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_VERSION" select="'dpdirect://authorisation/ldapConf/ldapVersion'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_HMAC_SECRET" select="'dpdirect://authentication/jwt/hmacSecret'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_BLACKLIST_GROUP" select="'dpdirect://authorisation/ldapConf/blacklistGroup'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_LB_GROUP" select="'dpdirect://authorisation/ldapConf/loadBalancerGroup'"/>
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_LDAP_SSL_PROXY_PROFILE" select="'dpdirect://authorisation/ldapConf/sslProxyProfile'"/>
	
	<xsl:variable name="DPDIRECT.PROPKEY_AUTH_TOKEN_SIGNING_KEY" select="'dpdirect://authorisation/signature/signingKey'"/>
	
	<xsl:variable name="DPDIRECT.PROPKEY_LDAP_GROUP_URL" select="'dpdirect://authorisation/ldapConf/groupsUrl'"/>
		
	<!-- 
		Miscellaneous variables
	-->
	<xsl:variable name="GATEWAY_BASE_ADDR" select="'https://dpdirect.org'"/>
	<xsl:variable name="JWT_ISSUE_URI" select="'/jwtTokenService/issue'"/>
	<xsl:variable name="JWT_VALIDATE_URI" select="'/jwtTokenService/validate'"/>
	<xsl:variable name="JWT_TOKEN_NS" select="'x-gateway'"/>
	<xsl:variable name="JWT_TOKEN_LABLE" select="concat($JWT_TOKEN_NS, '-token')"/>
	<xsl:variable name="SOAP11_NAMESPACE_URI" select="'http://schemas.xmlsoap.org/soap/envelope/'"/>
	<xsl:variable name="SOAP12_NAMESPACE_URI" select="'http://www.w3.org/2003/05/soap-envelope'"/>
	<xsl:variable name="WSA_NAMESPACE_URI" select="'http://www.w3.org/2005/08/addressing'"/>
	<xsl:variable name="WSA_ANONYMOUS_DESTINATION" select="'http://www.w3.org/2005/08/addressing/anonymous'"/>
	<xsl:variable name="DP_MANUAL_REJECT_EVENT_CODE" select="'0x00d30003'"/>
	<xsl:variable name="DP_FALLBACK_ERROR_CODE" select="'ENTR00001'"/>
	<xsl:variable name="SERVICES_PROXY_NAME_SUFFIX" select="'_ServicesProxy'"/>
	<xsl:variable name="RULE_NAME_PREFIX" select="'SecureTokenService_V1_'"/>
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
