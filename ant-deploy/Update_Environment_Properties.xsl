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
		DataPower exported configuration file (xcfg) component-renaming transform.
		Transforms property names within a DataPower exported configuration file (xcfg) based on a set
		of configured search/replace parameters for a specific environment.
		
		History:
		2016-12-12	v0.1	Tim Goodwill, N.A.	Initial Version.
		========================================================================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="yes" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:param name="ENV" select="'E0'"/>
	<xsl:param name="DOMAIN" select="'DPSOA'"/>
	<xsl:param name="HOSTNAME" select="'none'"/>
	<xsl:variable name="DOC_NAME" select="string(concat($ENV,'/', $ENV, '.xml'))"/>
	<xsl:variable name="ENV_DOC" select="document($DOC_NAME)"/>
	<xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'"/>
	<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
	<xsl:variable name="injection" select="$ENV_DOC//configuration"/>
	<xsl:variable name="insertions" select="$ENV_DOC//insertions"/>
	<xsl:variable name="deployment" select="$ENV_DOC//deployment[@name = 'dpsoa']"/>
	<xsl:variable name="domainHostAlias">
		<xsl:value-of select="$DOMAIN"/>
	</xsl:variable>
	<xsl:variable name="localHostAlias">
		<xsl:choose>
			<xsl:when test="$injection/parameter[@name = 'localHostAlias']/@value != ''">
				<xsl:value-of select="$injection/parameter[@name = 'localHostAlias']/@value"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$DOMAIN"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<!--============== Stylesheet Parameter Declarations ============-->
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="LocalAddress[parent::HTTPSourceProtocolHandler | parent::HTTPSSourceProtocolHandler | parent::XMLFirewallService]" priority="10">
		<xsl:copy>
			<xsl:value-of select="$localHostAlias"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="LocalEndpointHostname[parent::WSEndpointLocalRewriteRule]" priority="10">
		<xsl:copy>
			<xsl:value-of select="$localHostAlias"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="LoadBalancerGroup" priority="10">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:for-each select="node()">
				<xsl:if test="local-name(.) = 'TryEveryServerBeforeFailing'">
					<xsl:variable name="LBGName" select="@name"/>
					<xsl:copy-of select="$insertions/insertion[@parentClass='LoadBalancerGroup'][@parentName   = $LBGName]/*"/>
				</xsl:if>
				<xsl:apply-templates select="."/>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	<!--=============================================================-->
	<!-- SERVICE CONFIG FILES                                             -->
	<!--=============================================================-->
	<!-- Template to override the identity template for attributes -->
	<xsl:template match="@*" priority="10">
		<xsl:attribute name="{local-name()}" namespace="{namespace-uri()}">
			<xsl:choose>
				<xsl:when test="contains(.,'${')">
					<xsl:call-template name="PropertyReplacement">
						<xsl:with-param name="TEXT" select="."/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>
	<!-- Template to override the build-in template for text() nodes -->
	<xsl:template match="text()" priority="10">
		<xsl:choose>
			<xsl:when test="contains(.,'${')">
				<xsl:call-template name="PropertyReplacement">
					<xsl:with-param name="TEXT" select="."/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Named Template to perform property replacement -->
	<xsl:template name="PropertyReplacement">
		<xsl:param name="TEXT"/>
		<!-- Attempt property lookup and replacement -->
		<xsl:variable name="KEY" select="normalize-space(substring-before(substring-after($TEXT,'${'),'}'))"/>
		<xsl:variable name="VALUE" select="normalize-space(($injection/parameter[@name =    $KEY]/@value)[1])"/>
		<xsl:choose>
			<xsl:when test="$KEY != '' and $VALUE != ''">
				<xsl:variable name="PRE_TEXT" select="substring-before($TEXT,'${')"/>
				<xsl:variable name="POST_TEXT" select="substring-after($TEXT,concat('${',$KEY,'}'))"/>
				<!-- Perform replacement -->
				<xsl:value-of select="$PRE_TEXT"/>
				<xsl:value-of select="$VALUE"/>
				<!-- Cater for multiple properties in a single text node via recursion -->
				<xsl:choose>
					<xsl:when test="contains($POST_TEXT,'${')">
						<xsl:call-template name="PropertyReplacement">
							<xsl:with-param name="TEXT" select="$POST_TEXT"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$POST_TEXT"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- default values for mandatory injection params -->
			<xsl:when test="$KEY = 'localHostAlias' or $KEY = 'domainHostAlias'">
				<xsl:value-of select="$domainHostAlias"/>
			</xsl:when>
			<xsl:when test="$KEY = 'logCategoryServiceLog'">
				<xsl:value-of select="$DOMAIN"/>
				<xsl:value-of select="'_ServiceLog'"/>
			</xsl:when>
			<xsl:when test="$KEY = 'logCategoryServiceStats'">
				<xsl:value-of select="$DOMAIN"/>
				<xsl:value-of select="'_ServiceStats'"/>
			</xsl:when>
			<!-- unaltered text -->
			<xsl:otherwise>
				<xsl:value-of select="$TEXT"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!--=============================================================-->
	<!-- Standard Identity template -->
	<!--=============================================================-->
	<xsl:template match="node()|@*">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
