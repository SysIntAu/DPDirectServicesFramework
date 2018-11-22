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
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="yes" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="RUNTIME_PROPERTY_PREFIX" select="'propkey://'"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="/">
		<!-- Create the root output element -->
		<PropertiesList xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:noNamespaceSchemaLocation="PropertiesList.xsd">
			<xsl:apply-templates select="//runtime/parameter"/>
		</PropertiesList>
	</xsl:template>
	<!-- Template to create "Property" output elements -->
	<xsl:template match="parameter">
		<Property key="{concat($RUNTIME_PROPERTY_PREFIX, normalize-space(@name))}" value="{normalize-space(@value)}"/>
	</xsl:template>
</xsl:stylesheet>