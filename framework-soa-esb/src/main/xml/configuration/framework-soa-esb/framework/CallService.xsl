<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:errcore="http://www.dpdirect.org/Namespace/Enterprise/ErrorMessages/V1.0"
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
	xmlns:logcore="http://www.dpdirect.org/Namespace/EnterpriseLogging/Core/V1.0"
	xmlns:dp="http://www.datapower.com/extensions" extension-element-prefixes="dp" version="1.0"
	exclude-result-prefixes="dp errcore logcore soapenv">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>N.A.</dc:creator>
			<dc:date>2016-03-06</dc:date>
			<dc:title>Call Service</dc:title>
			<dc:subject>Calls a sub-service as part of a service request or response
				flow</dc:subject>
			<dc:contributor>N.A.</dc:contributor>
			<dc:contributor>Tim Goodwill</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--========================================================================
		History:
		2016-03-06	v1.0	N.A.			Initial Version.
		2016-02-26	v1.1	Tim Goodwill		Add CallService Timeout.
		2016-05-14	v1.1	Tim Goodwill		Add MQ Service call.
		2016-02-10  v1.2    Vikram Geevanathan	Masked StopTimerEvent template within a variable  
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="FrameworkUtils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!-- Default service timout, only used if the configuration does not specify a timeout value -->
	<xsl:variable name="DEFAULT_TIMEOUT_SECONDS" select="30"/>
	<xsl:variable name="MAX_TIMEOUT_SECONDS" select="120"/>
	<!-- Service Metadata document -->
	<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
	<!-- Optional FAIL_ON_ERROR attribute will prevent dp:reject when set to 'false'.  Default is 'true' -->
	<xsl:variable name="FAIL_ON_ERROR">
		<xsl:choose>
			<xsl:when
				test="normalize-space($SERVICE_METADATA/OperationConfig/CallService[1]/@failOnError) = ''">
				<xsl:value-of select="'true'"/>
			</xsl:when>
			<xsl:when
				test="(normalize-space($SERVICE_METADATA/OperationConfig/CallService[1]/@failOnError)
				= 'true') or
				(normalize-space($SERVICE_METADATA/OperationConfig/CallService[1]/@failOnError)
				= '1')">
				<xsl:value-of select="'true'"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'false'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- Optional 'async' attribute will not wait for a reply when set to 'true'. Default is 'false'.-->
	<xsl:variable name="ASYNC" select="normalize-space($SERVICE_METADATA/OperationConfig/CallService[1]/@async)"/>
	<!-- Optional 'OutputVar' and UrlOpenOutputVar attributes will save the response message to the environment -->
	<xsl:variable name="OUTPUT_VAR_NAME"
		select="normalize-space($SERVICE_METADATA/OperationConfig/CallService[1]/OutputVar[1])"/>
	<xsl:variable name="URL_OPEN_OUTPUT_VAR_NAME"
		select="normalize-space($SERVICE_METADATA/OperationConfig/CallService[1]/UrlOpenOutputVar[1])"/>
	<xsl:variable name="PROVIDER_NAME"
		select="string($SERVICE_METADATA/OperationConfig/CallService[1]/@provider)"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<!-- Save provider name to the environment -->
		<dp:set-variable name="$PROVIDER_SUB_VAR_NAME"
			value="string($PROVIDER_NAME)"/>
		<!-- Start a timer event for the rule -->
		<xsl:call-template name="StartTimerEvent">
			<xsl:with-param name="EVENT_ID"
				select="$SERVICE_METADATA/OperationConfig/CallService[1]/@timerId"/>
		</xsl:call-template>
		<!-- Timeout for the service call -->
		<xsl:variable name="TIMEOUT_SECONDS">
			<xsl:choose>
				<!-- When incoming msg expiry is set and is larger than 19 tenths/sec -->
				<xsl:when test="$ASYNC = 'true' and $SERVICE_METADATA/OperationConfig/CallService[1]/MQRouting">
					<xsl:value-of select="''"/>
				</xsl:when>
				<!-- Source timeout value from the service policy configuration when provided -->
				<xsl:when test="$SERVICE_METADATA/OperationConfig/CallService[1]/TimeoutSeconds[1]">
					<xsl:value-of
						select="$SERVICE_METADATA/OperationConfig/CallService[1]/TimeoutSeconds[1]"/>
				</xsl:when>
				<!-- Otherwise use default timeout value -->
				<xsl:otherwise>
					<xsl:value-of select="$DEFAULT_TIMEOUT_SECONDS"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<dp:set-variable name="$PROVIDER_TIMEOUT_MILLIS_VAR_NAME" value="number($TIMEOUT_SECONDS *
			1000)"/>
		<!-- Optional stylesheet to transform the input document to create the request doc for the service call -->
		<xsl:variable name="XSLT_LOCATION"
			select="$SERVICE_METADATA/OperationConfig/CallService[1]/Transform[1]/Stylesheet[1]"/>
		<xsl:variable name="SOAP_XSLT_LOCATION"
			select="$SERVICE_METADATA/OperationConfig/CallService[1]/SOAPConfig[1]"/>
		<!-- Generate the request document or use the input context if no stylesheet has been provided -->
		<xsl:variable name="REQ_DOC">
			<xsl:choose>
				<xsl:when test="normalize-space($XSLT_LOCATION) != ''">
					<xsl:call-template name="ApplyTranformPipeline">
						<xsl:with-param name="INPUT_NODE" select="."/>
						<xsl:with-param name="TRANSFORM_NODE"
							select="$SERVICE_METADATA/OperationConfig/CallService[1]/Transform[1]"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="normalize-space($SOAP_XSLT_LOCATION) != ''">
					<xsl:call-template name="ApplySOAPTransform">
						<xsl:with-param name="INPUT_NODE" select="."/>
						<xsl:with-param name="XSLT_LOCATION" select="$SOAP_XSLT_LOCATION"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="dp:variable($CONTENT_BINARY_VAR_NAME) = 'true'">
					<!-- CallService handling of Binary or MTOM messages -->
					<dp:serialize select="." omit-xml-decl="yes"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<!-- Test if optional transforms within the CallService context have rejected to error flow -->
			<xsl:when test="dp:variable($ERROR_CODE_VAR_NAME) != ''      and
				dp:variable($ERROR_CODE_VAR_NAME) != $DP_FILTER_ERROR_CODE"/>
			<!-- HTTP Service Call -->
			<xsl:when test="$SERVICE_METADATA/OperationConfig/CallService[1]/HTTPEndpoint">
				<xsl:variable name="ENDPOINT_URL"
					select="normalize-space($SERVICE_METADATA/OperationConfig/CallService[1]/HTTPEndpoint[1]/Address[1])"/>
				<!-- Set the back end URL for logging and skipBackend scenario -->
				<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$ENDPOINT_URL"/>
				<!-- Delete all existing HTTP request headers -->
				<xsl:call-template name="DeleteHttpRequestHeaders"/>
				<!-- Set HTTP Headers provided in the policy config -->
				<xsl:variable name="ATTACHMENT_MANIFEST"
					select="dp:variable($DP_LOCAL_ATTACHMENT_MANIFEST)"/>
				<xsl:variable name="HEADER_LIST">
					<xsl:choose>
						<xsl:when test="$SERVICE_METADATA/OperationConfig/CallService[1]/HTTPEndpoint[1]/HeaderList">
							<xsl:copy-of select="$SERVICE_METADATA/OperationConfig/CallService[1]/HTTPEndpoint[1]/HeaderList[1]"/>
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
				<!-- Store the request output message to point log for async and echo-endpoint transactions -->
				<xsl:call-template name="StorePointLog">
					<xsl:with-param name="MSG" select="$REQ_DOC"/>
					<xsl:with-param name="POINT_LOG_VAR_NAME"
						select="$POINT_LOG_REQ_OUTMSG_VAR_NAME"/>
				</xsl:call-template>
				<!-- Timestamp for the request -->
				<xsl:variable name="REQUEST_TIMEVALUE">
					<xsl:value-of select="string(dp:time-value())"/>
				</xsl:variable>
				<!-- Start a timer event for the flow -->
				<xsl:call-template name="StartTimerEvent">
					<xsl:with-param name="EVENT_ID" select="'CallService'"/>
				</xsl:call-template>
				<!-- Open URL and capture the response -->
				<xsl:variable name="RESPONSE">
					<!-- For logging and error generation -->
					<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$ENDPOINT_URL"/>
					<!-- Make the service call -->
					<dp:url-open target="{$ENDPOINT_URL}" http-headers="$HTTP_HEADERS"
						response="responsecode" timeout="{number($TIMEOUT_SECONDS)}"
						content-type="{$CONTENT_TYPE}">
						<xsl:copy-of select="$REQ_DOC"/>
					</dp:url-open>
				</xsl:variable>
				<!-- Handle the response -->
				<xsl:variable name="CALL_RES_DOC">
					<xsl:copy-of select="$RESPONSE/url-open/response/*"/>
				</xsl:variable>
				<xsl:if test="$OUTPUT_VAR_NAME != ''">
					<dp:set-variable name="$OUTPUT_VAR_NAME" value="$CALL_RES_DOC"/>
				</xsl:if>
				<xsl:if test="$URL_OPEN_OUTPUT_VAR_NAME != ''">
					<dp:set-variable name="$URL_OPEN_OUTPUT_VAR_NAME" value="$RESPONSE"/>
				</xsl:if>
				<!-- Stop timer event for the flow -->
				<xsl:variable name="MASK_TIMER_CALL_VAR">
					<xsl:call-template name="StopTimerEvent">
						<xsl:with-param name="EVENT_ID" select="'CallService'"/>
					</xsl:call-template>
				</xsl:variable>
				<!-- Store the HTTP request headers -->
				<xsl:call-template name="StoreHTTPHeadersForLog">
					<xsl:with-param name="LOGPOINT" select="'SUB_CALL'"/>
					<xsl:with-param name="TARGET_URL" select="$ENDPOINT_URL"/>
					<xsl:with-param name="HEADERS">
						<headers>
							<xsl:copy-of select="$HTTP_HEADERS"/>
						</headers>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:choose>
					<!-- SOAP fault -->
					<xsl:when test="($FAIL_ON_ERROR = 'true') 
						and $RESPONSE/url-open/response//soapenv:Fault//errcore:Code">
						<!-- Read error information -->
						<xsl:variable name="ERROR_CODE" select="$RESPONSE/url-open/response//errcore:Code[1]"/>
						<xsl:variable name="ORIGINATOR_NAME">
							<xsl:choose>
								<xsl:when test="$RESPONSE/url-open/response//errcore:SubCode">
									<xsl:value-of select="$RESPONSE/url-open/response//errcore:SubCode[1]"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$PROVIDER_NAME"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="ADD_DETAILS" select="$RESPONSE/url-open/response//errcore:SubDescription[1]"/>
						<!-- Reject to error flow -->
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="ERROR_CODE" select="$ERROR_CODE"/>
							<xsl:with-param name="ORIGINATOR_NAME" select="$ORIGINATOR_NAME"/>
							<xsl:with-param name="ADD_DETAILS" select="$ADD_DETAILS"/>
						</xsl:call-template>
					</xsl:when>
					<!-- 0x01130006 response: Determine if HTTP/S timeout. Test time-elapsed against service backend timeout -->
					<xsl:when test="($FAIL_ON_ERROR = 'true') and $RESPONSE/url-open[
						(string(responsecode) != '200') or (errorcode) or (errorstring)]
						and (number(dp:variable($DP_SERVICE_TIME_ELAPSED)) &gt;= number($TIMEOUT_SECONDS)*1000)">
						<!-- Read error information -->
						<xsl:variable name="ERROR_CODE">
							<xsl:choose>
								<xsl:when test="$RESPONSE/url-open/response//errcore:Code">
									<xsl:value-of select="$RESPONSE/url-open/response//errcore:Code[1]"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="'ENTR00004'"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="ORIGINATOR_NAME">
							<xsl:choose>
								<xsl:when test="$RESPONSE/url-open/response//errcore:SubCode">
									<xsl:value-of select="$RESPONSE/url-open/response//errcore:SubCode[1]"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$PROVIDER_NAME"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="ADD_DETAILS">
							<xsl:choose>
								<xsl:when test="$RESPONSE/url-open/response//errcore:SubDescription">
									<xsl:value-of select="$RESPONSE/url-open/response//errcore:SubDescription[1]"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="normalize-space(concat('A response was not received from '
										,normalize-space($ORIGINATOR_NAME),' within the timeout period and your request may not have been completed.'))"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- Reject to error flow -->
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="ERROR_CODE" select="$ERROR_CODE"/>
							<xsl:with-param name="ORIGINATOR_NAME" select="$ORIGINATOR_NAME"/>
							<xsl:with-param name="ADD_DETAILS" select="$ADD_DETAILS"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="($FAIL_ON_ERROR = 'true') and $RESPONSE/url-open[
						(string(responsecode) != '200') or (errorcode) or (errorstring)]">
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="MSG">
								<xsl:choose>
									<xsl:when
										test="$RESPONSE/url-open/response//errcore:Description">
										<xsl:value-of
											select="$RESPONSE/url-open/response//errcore:Description[1]"
										/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>CallService url-open error: [provider=</xsl:text>
										<xsl:value-of select="$PROVIDER_NAME"/>
										<xsl:text>] [errorcode=</xsl:text>
										<xsl:value-of select="$RESPONSE/url-open/errorcode"/>
										<xsl:text>] [errorstring=</xsl:text>
										<xsl:value-of select="$RESPONSE/url-open/errorstring"/>
										<xsl:text>] [responsecode=</xsl:text>
										<xsl:value-of select="$RESPONSE/url-open/responsecode"/>
										<xsl:text>]</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
							<xsl:with-param name="ORIGINATOR_NAME"
								select="$RESPONSE/url-open/response//errcore:SubCode[1]"/>
							<xsl:with-param name="ORIGINATOR_LOC"
								select="$RESPONSE/url-open/response//errcore:MessageOrigin[1]"/>
							<xsl:with-param name="ADD_DETAILS"
								select="$RESPONSE/url-open/response//errcore:SubDescription[1]"/>
							<xsl:with-param name="ERROR_CODE">
								<xsl:choose>
									<xsl:when test="$RESPONSE/url-open/response//errcore:Code">
										<xsl:value-of
											select="$RESPONSE/url-open/response//errcore:Code[1]"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="'ENTR00004'"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="($FAIL_ON_ERROR = 'true') and ($ASYNC != 'true') and
						not($RESPONSE/url-open/response/*)">
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="MSG">
								<xsl:text>CallService url-open error: Null or empty response document.</xsl:text>
								<xsl:text> [provider=</xsl:text>
								<xsl:value-of select="$PROVIDER_NAME"/>
								<xsl:text>]</xsl:text>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'ENTR00004'"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- Copy input to output -->
						<xsl:copy-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- MQ Service Call -->
			<xsl:when test="$SERVICE_METADATA/OperationConfig/CallService[1]/MQRouting">
				<!-- Compile the dpmq url -->
				<xsl:variable name="QMGR_NAME"
					select="$SERVICE_METADATA/OperationConfig/CallService[1]/MQRouting[1]/QueueMgr[1]"/>
				<xsl:variable name="REQ_QUEUE_NAME"
					select="$SERVICE_METADATA/OperationConfig/CallService[1]/MQRouting[1]/RequestQueue[1]"/>
				<xsl:variable name="PUBLISH_TOPIC_NAME"
					select="$SERVICE_METADATA/OperationConfig/CallService[1]/MQRouting[1]/PublishTopicString[1]"/>
				<xsl:variable name="RES_QUEUE_NAME">
					<xsl:choose>
						<xsl:when
							test="$SERVICE_METADATA/OperationConfig/CallService[1]/MQRouting[1]/ReplyQueue">
							<xsl:value-of
								select="$SERVICE_METADATA/OperationConfig/CallService[1]/MQRouting[1]/ReplyQueue[1]"
							/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="' '"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="GMO">
					<xsl:choose>
						<xsl:when test="normalize-space($RES_QUEUE_NAME) != ''">
							<xsl:value-of select="$MQGMO_CONVERT"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="''"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="MQMD_CONFIG_XSLT"
					select="$SERVICE_METADATA/OperationConfig/CallService[1]/MQRouting[1]/MQMDConfig[1]"/>
				<xsl:variable name="ENDPOINT_URL">
					<xsl:call-template name="ConstructDpmqUrl">
						<xsl:with-param name="QMGR_NAME" select="$QMGR_NAME"/>
						<xsl:with-param name="REQ_QUEUE_NAME" select="$REQ_QUEUE_NAME"/>
						<xsl:with-param name="PUBLISH_TOPIC_NAME" select="$PUBLISH_TOPIC_NAME"/>
						<xsl:with-param name="RES_QUEUE_NAME" select="$RES_QUEUE_NAME"/>
						<xsl:with-param name="SET_REPLY_TO" select="'false'"/>
						<xsl:with-param name="PMO" select="$MQPMO_SET_ALL_CONTEXT"/>
						<xsl:with-param name="GMO" select="$GMO"/>
						<xsl:with-param name="TIMEOUT_SECONDS" select="$TIMEOUT_SECONDS"/>
						<xsl:with-param name="ASYNC" select="$ASYNC"/>
					</xsl:call-template>
				</xsl:variable>
				<!-- Set the back end URL for logging and skipBackend scenario -->
				<dp:set-variable name="$DP_SERVICE_ROUTING_URL" value="$ENDPOINT_URL"/>
				<!-- Generate the output MQMD -->
				<xsl:variable name="REQ_MQMD">
					<xsl:call-template name="GetReqMQMD"/>
				</xsl:variable>
				<xsl:variable name="OUTPUT_MQMD" select="dp:transform($MQMD_CONFIG_XSLT,*)"/>
				<xsl:variable name="SERIALIZED_MQMD">
					<dp:serialize select="$OUTPUT_MQMD" omit-xml-decl="yes"/>
				</xsl:variable>
				<!-- Generate the output MQMP iv set in the environment -->
				<xsl:variable name="OUTPUT_MQMP" select="dp:variable($BACKEND_MQMP_VAR_NAME)"/>
				<xsl:variable name="SERIALIZED_MQMP">
					<xsl:if test="$OUTPUT_MQMP != ''">
						<dp:serialize select="$OUTPUT_MQMP" omit-xml-decl="yes"/>
					</xsl:if>
				</xsl:variable>
				<!-- Create Headers -->
				<xsl:variable name="HEADERS">
					<header name="MQMD">
						<xsl:value-of select="$SERIALIZED_MQMD"/>
					</header>
					<xsl:if test="$SERIALIZED_MQMP != ''">
						<header name="MQMP">
							<xsl:value-of select="$SERIALIZED_MQMP"/>
						</header>
					</xsl:if>
				</xsl:variable>
				<dp:set-variable name="'var://context/ESB_Services/debug/CallServiceHeaders'"
					value="$HEADERS"/>
				<!-- Store the request output message to point log for async and echo-endpoint transactions -->
				<xsl:call-template name="StorePointLog">
					<xsl:with-param name="MSG" select="$REQ_DOC"/>
					<xsl:with-param name="POINT_LOG_VAR_NAME"
						select="$POINT_LOG_REQ_OUTMSG_VAR_NAME"/>
				</xsl:call-template>
				<!-- Start a timer event for the flow -->
				<xsl:call-template name="StartTimerEvent">
					<xsl:with-param name="EVENT_ID" select="'CallService'"/>
				</xsl:call-template>
				<!-- Create the url-open call -->
				<xsl:call-template name="PutMsgToUrl">
					<xsl:with-param name="ENDPOINT_URL" select="$ENDPOINT_URL"/>
					<xsl:with-param name="OUTPUT_MQMD" select="$OUTPUT_MQMD"/>
					<xsl:with-param name="REQ_DOC" select="$REQ_DOC"/>
					<xsl:with-param name="HEADERS" select="$HEADERS"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<!-- Template to apply pre Service-Call XSLT Transform pipeline to the current context node -->
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
	<!-- Template to apply pre Service-Call SOAPConfig XSLT Transform to the current context node -->
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
	<!-- Template to put the message to the Queue and perform error checking.
		Contains workaround for Error code '2095' issue where re-used handles are not appropriate for higher PMO value
		Fix in Firmware 5.0.12 --> 
	<xsl:template name="PutMsgToUrl">
		<xsl:param name="ENDPOINT_URL"/>
		<xsl:param name="HEADERS"/>
		<xsl:param name="OUTPUT_MQMD"/>
		<xsl:param name="REQ_DOC"/>
		<!-- Retry count should only be used for recursive calls - see logic below within this template. -->
		<xsl:param name="RETRY_COUNT" select="0"/>
		<!-- Timestamp for the request -->
		<xsl:variable name="REQUEST_TIMEVALUE">
			<xsl:value-of select="string(dp:time-value())"/>
		</xsl:variable>
		<!-- Create the url-open call -->
		<xsl:variable name="RESPONSE_URL">
			<dp:url-open target="{$ENDPOINT_URL}" http-headers="$HEADERS"
				response="responsecode">
				<xsl:copy-of select="$REQ_DOC"/>
			</dp:url-open>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="normalize-space($RESPONSE_URL/url-open/responsecode) = '2095'
				and (6 > $RETRY_COUNT)">
				<!-- Retry logic - This is a workaround to an intermittent issue that occurs on the current DP firmware. -->
				<!-- Log a warning level msg to the syslog -->
				<xsl:message dp:type="multistep" dp:priority="warn">
					<xsl:text>[RouteToLegacyBroker.xsl] - Handling MQRC 2095 error. Performing a retry of the 'PutMsgToUrl' template. Retry count = </xsl:text>
					<xsl:value-of select="number($RETRY_COUNT + 1)"/>
				</xsl:message>
				<!-- Increment the retry count and recurse. -->
				<xsl:call-template name="PutMsgToUrl">
					<xsl:with-param name="ENDPOINT_URL" select="$ENDPOINT_URL"/>
					<xsl:with-param name="REQ_DOC" select="$REQ_DOC"/>
					<xsl:with-param name="HEADERS" select="$HEADERS"/>
					<xsl:with-param name="OUTPUT_MQMD" select="$OUTPUT_MQMD"/>
					<xsl:with-param name="RETRY_COUNT" select="number($RETRY_COUNT + 1)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<!-- Call Response document-->
				<xsl:variable name="CALL_RES_DOC">
					<xsl:if test="$ASYNC != 'true'">
						<xsl:copy-of select="$RESPONSE_URL/url-open/response/*"/>
					</xsl:if>
				</xsl:variable>
				<xsl:if test="$OUTPUT_VAR_NAME != ''">
					<dp:set-variable name="$OUTPUT_VAR_NAME" value="$CALL_RES_DOC"/>
				</xsl:if>
				<xsl:if test="$URL_OPEN_OUTPUT_VAR_NAME != ''">
					<dp:set-variable name="$URL_OPEN_OUTPUT_VAR_NAME" value="$RESPONSE_URL"/>
				</xsl:if>
				<!-- Stop timer event for the flow -->
				<xsl:variable name="MASK_TIMER_CALL_VAR">
					<xsl:call-template name="StopTimerEvent">
						<xsl:with-param name="EVENT_ID" select="'CallService'"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="($FAIL_ON_ERROR = 'true') and ($ASYNC != 'true') and
						(normalize-space($RESPONSE_URL/url-open/responsecode) = '2033')">
						<!-- Retrieve provider name -->
						<xsl:variable name="ORIGINATOR_NAME">
							<xsl:choose>
								<xsl:when test="$PROVIDER_NAME != ''">
									<xsl:value-of select="$PROVIDER_NAME"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="'the PROVIDER'"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<!-- Reject to error flow -->
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="ERROR_CODE" select="'ENTR00004'"/>
							<xsl:with-param name="ORIGINATOR_NAME" select="$ORIGINATOR_NAME"/>
							<xsl:with-param name="ADD_DETAILS" select="normalize-space(concat('A response was not received from '
								,normalize-space($ORIGINATOR_NAME),' within the timeout period and your request may not have been completed.'))"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="($FAIL_ON_ERROR = 'true') and ($RESPONSE_URL/url-open/responsecode &gt; '0')">
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="MSG">
								<xsl:text>MQ PUT Failure - Failed to put current message to URL '</xsl:text>
								<xsl:value-of select="$ENDPOINT_URL"/>
								<xsl:text>'. CallService url-open error: [errorcode=</xsl:text>
								<xsl:value-of select="$RESPONSE_URL/url-open/errorcode"/>
								<xsl:text>] [errorstring=</xsl:text>
								<xsl:value-of select="$RESPONSE_URL/url-open/errorstring"/>
								<xsl:text>] [responsecode=</xsl:text>
								<xsl:value-of select="$RESPONSE_URL/url-open/responsecode"/>
								<xsl:text>]</xsl:text>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'ENTR00004'"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
