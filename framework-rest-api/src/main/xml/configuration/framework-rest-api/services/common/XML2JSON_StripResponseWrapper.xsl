<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" 
	exclude-result-prefixes="dp">
	<!--========================================================================
		History:
		2016-06-03	v0.1			Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<!--<xsl:include href="Utils.xsl"/>-->
	<!--============== Output Configuration =========================-->
	<xsl:output method="text" encoding="utf-8"/>
	<!--============== Global Variable Declarations =================-->
	<!--========================================================================
		MATCH TEMPLATES
	========================================================================-->
	<!-- Root Template -->
	<xsl:template match="/*[node()]">
		<xsl:choose>
			<!-- Where response root is type 'Response', strip the response wrapper. -->
			<xsl:when test="*[local-name() = 'Body']/*[local-name() = concat(substring-before(local-name(), 'Response'), 'Response')]">
				<xsl:text>{</xsl:text>
				<xsl:apply-templates select="*[local-name() = 'Body']/*/*" mode="detect"/>
				<xsl:text>}</xsl:text>
			</xsl:when>
			<!-- Strip SOAP envelope -->
			<xsl:when test="*[local-name() = 'Body']">
				<xsl:text>{</xsl:text>
				<xsl:apply-templates select="*[local-name() = 'Body']/*" mode="detect"/>
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>{</xsl:text>
				<xsl:apply-templates select="." mode="detect"/>
				<xsl:text>}</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<dp:set-http-response-header name="'Content-Type'" value="'application/json'"/>
	</xsl:template>
	<xsl:template match="*" mode="detect">
		<xsl:choose>
			<xsl:when test="local-name(preceding-sibling::*[1]) = local-name(current()) and local-name(following-sibling::*[1]) != local-name(current())">
				<xsl:apply-templates select="." mode="obj-content"/>
				<xsl:text>]</xsl:text>
				<xsl:if test="count(following-sibling::*[local-name() != local-name(current())]) &gt; 0">, </xsl:if>
			</xsl:when>
			<xsl:when test="local-name(preceding-sibling::*[1]) = local-name(current())">
				<xsl:apply-templates select="." mode="obj-content"/>
				<xsl:if test="local-name(following-sibling::*) = local-name(current())">, </xsl:if>
			</xsl:when>
			<xsl:when test="following-sibling::*[1][local-name() = local-name(current())]">
				<xsl:text>"</xsl:text>
				<xsl:value-of select="local-name()"/>
				<xsl:text>" : [</xsl:text>
				<xsl:apply-templates select="." mode="obj-content"/>
				<xsl:text>, </xsl:text>
			</xsl:when>
			<xsl:when test="count(./child::*) > 0 or count(@*) > 0">
				<xsl:text>"</xsl:text><xsl:value-of select="local-name()"/>" : <xsl:apply-templates select="." mode="obj-content"/>
				<xsl:if test="count(following-sibling::*) &gt; 0">, </xsl:if>
			</xsl:when>
			<xsl:when test="count(./child::*) = 0">
				<xsl:text>"</xsl:text><xsl:value-of select="local-name()"/>" : "<xsl:apply-templates select="."/><xsl:text>"</xsl:text>
				<xsl:if test="count(following-sibling::*) &gt; 0">, </xsl:if>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="*" mode="obj-content">
		<xsl:text>{</xsl:text>
		<xsl:apply-templates select="@*" mode="attr"/>
		<xsl:if test="count(@*) &gt; 0 and (count(child::*) &gt; 0 or text())">, </xsl:if>
		<xsl:apply-templates select="./*" mode="detect"/>
		<xsl:if test="count(child::*) = 0 and text() and not(@*)">
			<xsl:text>"</xsl:text><xsl:value-of select="local-name()"/>" : "<xsl:value-of select="text()"/><xsl:text>"</xsl:text>
		</xsl:if>
		<xsl:if test="count(child::*) = 0 and text() and @*">
			<xsl:text>"text" : "</xsl:text>
			<xsl:value-of select="text()"/>
			<xsl:text>"</xsl:text>
		</xsl:if>
		<xsl:text>}</xsl:text>
		<xsl:if test="position() &lt; last()">, </xsl:if>
	</xsl:template>
	<xsl:template match="@*" mode="attr">
		<xsl:text>"</xsl:text><xsl:value-of select="local-name()"/>" : "<xsl:value-of select="."/><xsl:text>"</xsl:text>
		<xsl:if test="position() &lt; last()">,</xsl:if>
	</xsl:template>
	<xsl:template match="node/@TEXT | text()" name="removeBreaks">
		<xsl:param name="pText" select="normalize-space(.)"/>
		<xsl:choose>
			<xsl:when test="not(contains($pText, '&#xA;'))">
				<xsl:copy-of select="$pText"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat(substring-before($pText, '&#xD;&#xA;'), ' ')"/>
				<xsl:call-template name="removeBreaks">
					<xsl:with-param name="pText" select="substring-after($pText, '&#xD;&#xA;')"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
