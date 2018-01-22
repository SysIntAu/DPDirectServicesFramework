<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common"
	extension-element-prefixes="exslt" version="1.0">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>Tim Goodwille</dc:creator>
			<dc:date>2016-01-09</dc:date>
			<dc:title>DataPower exported configuration file (xcfg) component-renaming transform.</dc:title>
			<dc:subject>Transforms property names within a DataPower exported configuration file (xcfg) based on a set
				of configured search/replace parameters for a specific environment.</dc:subject>
			<dc:contributor>N.A.</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--========================================================================
		History:
		2016-01-09	v0.1	Tim Goodwill	Initial Version.
		2016-04-17	v0.1	N.A.		Updated to strip clear-text HTTP front side handler/s in higher environments (E6,E7/E8/E9).
		========================================================================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="yes" version="1.0"/>
	<!--============== Whitespace Handling ==========================-->
	<xsl:strip-space elements="*"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:param name="ENV" select="'E0'"/>
	<xsl:param name="DOMAIN" select="'MSG'"/>
	<xsl:param name="HOSTNAME" select="'none'"/>
	<xsl:variable name="DOC_NAME" select="string(concat($ENV,'/', $ENV, '.xml'))"/>
	<xsl:variable name="ENV_DOC" select="document($DOC_NAME)"/>
	<xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'"/>
	<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
	<xsl:variable name="injection" select="$ENV_DOC//injection"/>
	<xsl:variable name="insertions" select="$ENV_DOC//insertions"/>
	<xsl:variable name="container" select="$ENV_DOC//location[@name =
		'datapower_deployment_server']/host/container[@name = 'dps']"/>
	<xsl:variable name="dpDomain">
		<xsl:value-of select="$container/parameter[@name = 'domain']/@value"/>
	</xsl:variable>
	<xsl:variable name="localHostAlias">
		<xsl:value-of select="$injection/parameter[@name = 'localHostAlias']/@value"/>
	</xsl:variable>
	<xsl:variable name="applianceHostName1">
		<xsl:value-of select="$injection/parameter[@name = 'applianceHostName1']/@value"/>
	</xsl:variable>
	<xsl:variable name="applianceHostName2">
		<xsl:value-of select="$injection/parameter[@name = 'applianceHostName2']/@value"/>
	</xsl:variable>

	<!--============== Stylesheet Parameter Declarations ============-->
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<xsl:template match="LocalAddress[parent::HTTPSourceProtocolHandler | parent::HTTPSSourceProtocolHandler | parent::XMLFirewallService]" priority="10">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="$localHostAlias != ''">
					<xsl:value-of select="$localHostAlias"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(.)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="LocalEndpointHostname[parent::WSEndpointLocalRewriteRule]" priority="10">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="$localHostAlias != ''">
					<xsl:value-of select="$localHostAlias"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(.)"/>
				</xsl:otherwise>
			</xsl:choose>
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
			<xsl:otherwise>
				<!-- Bail out -->
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
