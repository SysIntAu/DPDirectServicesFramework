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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<!--========================================================================
		Purpose:
		DataPower exported configuration file (xcfg)  configuration file injection transform.
		Adds environment specific objects from the  configuration file.
		
		History:
		2016-12-12	v0.1	Tim Goodwill		Initial Version.
		========================================================================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="yes" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:param name="XCONFIG_PATH" select="''"/>
	<xsl:variable name="XCONFIG_DOC" select="document($XCONFIG_PATH)"/>
	<!--============== Stylesheet Parameter Declarations ============-->
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to perform a Standard Identity Transform -->
	<xsl:template match="*[parent::configuration]" priority="10">
		<xsl:variable name="CURRENT_NODE_NAME" select="local-name()"/>
		<xsl:variable name="CURRENT_NODE_NAME_ATTR" select="normalize-space(@name)"/>
		<xsl:variable name="LAST_BOOL" select="boolean(count(following-sibling::node()[local-name() = $CURRENT_NODE_NAME]) = 0)"/>
		<xsl:variable name="REPLACEMENT_NODE" select="$XCONFIG_DOC/datapower-configuration/configuration/*[local-name() = $CURRENT_NODE_NAME][normalize-space(@name) = $CURRENT_NODE_NAME_ATTR]"/>
		<xsl:choose>
			<!-- Remove placeholders -->
			<xsl:when test="count(node()) = 0">
				<!--  Remove -->
			</xsl:when>
			<!-- overwrite existing config with replacement config (same type, same name)-->
			<xsl:when test="$REPLACEMENT_NODE != ''">
				<xsl:apply-templates select="$REPLACEMENT_NODE" mode="newConfig"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="node()|@*"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
		<!-- follow existing config with new config (same type)-->
		<xsl:if test="$LAST_BOOL">
			<xsl:apply-templates select="$XCONFIG_DOC/datapower-configuration/configuration/*[local-name() = $CURRENT_NODE_NAME][normalize-space(@name) != $CURRENT_NODE_NAME_ATTR]"  mode="newConfig"/>
		</xsl:if>
	</xsl:template>
	<!-- Template to perform a Standard Identity Transform -->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Template to perform a Standard Identity Transform, 'newConfig' node -->
	<xsl:template match="node()|@*" mode="newConfig">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
