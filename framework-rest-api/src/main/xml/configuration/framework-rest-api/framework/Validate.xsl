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
	xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
	xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2"
	xmlns:xop="http://www.w3.org/2004/08/xop/include" 
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="dp date" version="1.0"
	exclude-result-prefixes="dp date wsnt svrl xop">
	<!--========================================================================
		Purpose:
		Validate the input document with the schema specified in the policy config
				
		History:
		2016-10-26	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="VAL_RESULT_ERROR_VAR_NAME" select="concat($VALIDATE_RESULT_CONTEXT_NAME,'_extension/error')"/>
		<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
		<xsl:variable name="SCHEMA_LOCATION" select="$SERVICE_METADATA//OperationConfig/Validate[1]/Schema"/>
		<xsl:variable name="SUBSTITUTE_MIME_REFS"
			select="$SERVICE_METADATA//OperationConfig/Validate[1]/@substituteMimeRefs"/>
		<xsl:variable name="ALLOW_SOAP_FAULTS"
			select="$SERVICE_METADATA//OperationConfig[1]/@allowSoapFaults"/>
		<xsl:variable name="WARNING_ONLY" select="$SERVICE_METADATA//OperationConfig/Validate[1]/@warningOnly"/>
		<xsl:variable name="SCHEMATRON_LOCATION" select="$SERVICE_METADATA//OperationConfig/Validate[1]/Schematron"/>
		<xsl:variable name="ENT_ERRORS_SCHEMA_LOCATION" select="concat($SERVICE_SCHEMA_ROOT_FOLDER,'Enterprise/ErrorMessages/V1.0/EnterpriseErrors.xsd')"/>
		<!-- Schema Validation -->
		<xsl:variable name="SCHEMA_VALIDATION_RESULTS">
			<xsl:choose>
				<xsl:when test="normalize-space($SCHEMA_LOCATION) = ''">
					<NoValidationRequired/>
				</xsl:when>
				<xsl:when test="normalize-space($ALLOW_SOAP_FAULTS) = 'true' and *[local-name() = 'Envelope']/*[local-name() = 'Body']/*[local-name() = 'Fault']/detail">
					<xsl:copy-of select="dp:schema-validate($ENT_ERRORS_SCHEMA_LOCATION,*[local-name() = 'Envelope']/*[local-name() = 'Body']/*[local-name() = 'Fault']/detail/*)"/>
				</xsl:when>
				<xsl:when test="normalize-space($ALLOW_SOAP_FAULTS) = 'true' and *[local-name() = 'Envelope']/*[local-name() = 'Body']/*[local-name() = 'Fault']/*[local-name() = 'Detail']">
					<xsl:copy-of select="dp:schema-validate($ENT_ERRORS_SCHEMA_LOCATION,*[local-name() = 'Envelope']/*[local-name() = 'Body']/*[local-name() = 'Fault']/*[local-name() = 'Detail']/*)"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- Validate the payload node -->
					<xsl:variable name="PAYLOAD_NODE">
						<xsl:choose>
							<xsl:when test="*[local-name() = 'Envelope']/*[local-name() = 'Body']/*">
								<xsl:choose>
									<xsl:when test="normalize-space($SUBSTITUTE_MIME_REFS) = 'true'">
										<xsl:apply-templates select="*[local-name() = 'Envelope']/*[local-name() = 'Body']/*"
											mode="substituteMimeRefs"/>
									</xsl:when>
									<xsl:when test="*[local-name() = 'Envelope']/*[local-name() = 'Body']/wsnt:Notify/wsnt:NotificationMessage/wsnt:Message/*">
										<xsl:copy-of select="*[local-name() = 'Envelope']/*[local-name() = 'Body']/wsnt:Notify/wsnt:NotificationMessage/wsnt:Message/*[1]"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="*[local-name() = 'Envelope']/*[local-name() = 'Body']/*"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="normalize-space($SUBSTITUTE_MIME_REFS) = 'true'">
										<xsl:apply-templates select="." mode="substituteMimeRefs"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="."/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:copy-of select="dp:schema-validate($SCHEMA_LOCATION,$PAYLOAD_NODE)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- Schematron Validation -->
		<xsl:variable name="SCHEMATRON_OUTPUT">
			<xsl:if test="normalize-space($SCHEMATRON_LOCATION) != ''">
				<!-- Generate the 'svrl:schematron-output' document -->
				<xsl:copy-of select="dp:transform($SCHEMATRON_LOCATION,.)"/>
			</xsl:if>
		</xsl:variable>
		<xsl:choose>
			<!-- Reject if schema validation failed -->
			<xsl:when test="not($SCHEMA_VALIDATION_RESULTS/*)">
				<xsl:variable name="VALIDATION_ERR_MSG" select="dp:variable($VAL_RESULT_ERROR_VAR_NAME)"/>
				<xsl:choose>
					<xsl:when test="normalize-space($WARNING_ONLY) = 'true'">
						<!-- Log a warning message -->
						<xsl:call-template name="WriteSysLogWarnMsg">
							<xsl:with-param name="MSG">
								<xsl:text>One or more XML Schema Validation Errors (@warningOnly=true): </xsl:text>
								<xsl:value-of select="$VALIDATION_ERR_MSG"/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- Reject to error flow -->
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="MSG">
								<xsl:text>One or more XML Schema Validation Errors: </xsl:text>
								<xsl:value-of select="$VALIDATION_ERR_MSG"/>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'FRWK00022'"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- Reject if schematron validation failed -->
			<xsl:when test="$SCHEMATRON_OUTPUT//svrl:failed-assert">
				<xsl:variable name="VALIDATION_ERR_MSG" select="dp:variable($VAL_RESULT_ERROR_VAR_NAME)"/>
				<xsl:choose>
					<xsl:when test="normalize-space($WARNING_ONLY) = 'true'">
						<!-- Log a warning message -->
						<xsl:call-template name="WriteSysLogWarnMsg">
							<xsl:with-param name="MSG">
								<xsl:text>One or more Schematron Validation Errors (@warningOnly=true): </xsl:text>
								<xsl:value-of select="$SCHEMATRON_OUTPUT//svrl:failed-assert[1]/svrl:text[1]"/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- Reject to error flow -->
						<xsl:call-template name="RejectToErrorFlow">
							<xsl:with-param name="MSG">
								<xsl:text>One or more Schematron Validation Errors: </xsl:text>
								<xsl:value-of select="$SCHEMATRON_OUTPUT//svrl:failed-assert[1]/svrl:text[1]"/>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'FRWK00023'"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- Continue in the case of no validation errors -->
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>
	<!-- Modified Standard identity template (mode="substituteMimeRefs")-->
	<xsl:template match="node()|@*" mode="substituteMimeRefs">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="substituteMimeRefs"/>
		</xsl:copy>
	</xsl:template>
	<!-- Template to subsitute xop:Include (MTOM) references for a snippet of dummy Base64 data, for XML Schema validation purposes only.
	The original input context is preserved in the following pipeline -->
	<xsl:template match="xop:Include" mode="substituteMimeRefs">
		<!-- Insert dummy base64 value -->
		<xsl:value-of select="'MA=='"/>
	</xsl:template>
</xsl:stylesheet>
