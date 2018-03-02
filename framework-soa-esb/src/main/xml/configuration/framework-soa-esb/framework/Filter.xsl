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
	xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="soapenv dp date" version="1.0"
	exclude-result-prefixes="dp date soapenv">
	<!--========================================================================
		Purpose:
		Filters a message based on the dp:accept and dp:reject functions in a custom stylesheet
		
		History:
		2016-12-12	v1.0	Tim Goodwill		Initial Version.
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
<!--		<dp:set-variable name="$DP_SERVICE_STRICT_ERROR_MODE" value="'true'"/>-->
		<!-- Set the error code that will identify the reject to the HandleErrors.xsl as a filter action -->
		<dp:set-variable name="$ERROR_CODE_VAR_NAME" value="string($DP_FILTER_ERROR_CODE)"/>
		<xsl:variable name="SERVICE_METADATA" select="dp:variable($SERVICE_METADATA_CONTEXT_NAME)"/>
		<!-- Start a timer event for the rule -->
		<xsl:call-template name="StartTimerEvent">
			<xsl:with-param name="EVENT_ID" select="$SERVICE_METADATA/OperationConfig/Filter[1]/@timerId"/>
		</xsl:call-template>
		<!-- Location of the filter timesheet -->
		<xsl:variable name="XSLT_LOCATION" select="$SERVICE_METADATA//OperationConfig/Filter[1]/Stylesheet"/>
		<xsl:copy-of select="dp:transform($XSLT_LOCATION,.)"/>
	</xsl:template>
</xsl:stylesheet>
