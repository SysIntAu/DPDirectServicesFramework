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
	xmlns:dpdirect="http://www.dpdirect.org/Namespace/Integration/DataPower/V1.0"
	exclude-result-prefixes="" version="1.0">
	<!--========================================================================
		Purpose:
		Provides generic templates to resolve DataPower Event codes to associated metadata.
		
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		========================================================================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!-- The Input Configuration Document -->
	<xsl:variable name="CODES_DOC" select="document('DataPowerEventCodes.xml')"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Variant of the Identity Transform to add the 'dpdirect' namespace to an input node -->
	<xsl:template match="node()" mode="addDPDirectDpNamespace">
		<xsl:element name="dpdirect:{local-name(.)}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="node()" mode="addDPDirectDpNamespace"/>
		</xsl:element>
	</xsl:template>
	<!-- Template to copy text nodes for other mode="addDPDirectDpNamespace" template/s -->
	<xsl:template match="text()" mode="addDPDirectDpNamespace">
		<xsl:value-of select="."/>
	</xsl:template>
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to get the 'EventType' parent node associated with an EventCode-->
	<xsl:template name="GetEventTypeNode">
		<xsl:param name="CODE" select="''"/>
		<xsl:apply-templates select="$CODES_DOC/DatapowerEventCodes/EventType[EventCode = $CODE]"
			mode="addDPDirectDpNamespace"/>
	</xsl:template>
	<!-- Template to get the 'Description' associated with an EventCode-->
	<xsl:template name="GetEventDescription">
		<xsl:param name="CODE" select="''"/>
		<xsl:value-of select="$CODES_DOC/DatapowerEventCodes/EventType[EventCode = $CODE]/Description"/>
	</xsl:template>
	<!-- Template to get the 'Explanation' associated with an EventCode-->
	<xsl:template name="GetEventExplanation">
		<xsl:param name="CODE" select="''"/>
		<xsl:value-of select="$CODES_DOC/DatapowerEventCodes/EventType[EventCode = $CODE]/Explanation"/>
	</xsl:template>
	<!-- Template to get the 'Severity' associated with an EventCode-->
	<xsl:template name="GetEventSeverity">
		<xsl:param name="CODE" select="''"/>
		<xsl:value-of select="$CODES_DOC/DatapowerEventCodes/EventType[EventCode = $CODE]/Severity"/>
	</xsl:template>
</xsl:stylesheet>
