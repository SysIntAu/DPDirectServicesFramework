<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<axsl:stylesheet xmlns:axsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:iso="http://purl.oclc.org/dsdl/schematron" xmlns:sch="http://www.ascc.net/xml/schematron"
	xmlns:soap="http://www.w3.org/2003/05/soap-envelope" soap:dummy-for-xmlns=""
	xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing"
	xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
	wsse:dummy-for-xmlns="" version="1.0">
	<!--Implementers: please note that overriding process-prolog or process-root is 
    the preferred method for meta-stylesheets to use where possible. -->
	<axsl:param name="archiveDirParameter"/>
	<axsl:param name="archiveNameParameter"/>
	<axsl:param name="fileNameParameter"/>
	<axsl:param name="fileDirParameter"/>

	<!--PHASES-->


	<!--PROLOG-->
	<axsl:output xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
		xmlns:schold="http://www.ascc.net/xml/schematron"
		xmlns:xs="http://www.w3.org/2001/XMLSchema" indent="yes" standalone="yes"
		omit-xml-declaration="no" method="xml"/>

	<!--KEYS-->


	<!--DEFAULT RULES-->


	<!--MODE: SCHEMATRON-SELECT-FULL-PATH-->
	<!--This mode can be used to generate an ugly though full XPath for locators-->
	<axsl:template mode="schematron-select-full-path" match="*">
		<axsl:apply-templates mode="schematron-get-full-path" select="."/>
	</axsl:template>

	<!--MODE: SCHEMATRON-FULL-PATH-->
	<!--This mode can be used to generate an ugly though full XPath for locators-->
	<axsl:template mode="schematron-get-full-path" match="*">
		<axsl:apply-templates mode="schematron-get-full-path" select="parent::*"/>
		<axsl:text>/</axsl:text>
		<axsl:choose>
			<axsl:when test="namespace-uri()=''">
				<axsl:value-of select="name()"/>
				<axsl:variable select="1+    count(preceding-sibling::*[name()=name(current())])"
					name="p_1"/>
				<axsl:if test="$p_1&gt;1 or following-sibling::*[name()=name(current())]"
						>[<axsl:value-of select="$p_1"/>]</axsl:if>
			</axsl:when>
			<axsl:otherwise>
				<axsl:text>*[local-name()='</axsl:text>
				<axsl:value-of select="local-name()"/>
				<axsl:text>' and namespace-uri()='</axsl:text>
				<axsl:value-of select="namespace-uri()"/>
				<axsl:text>']</axsl:text>
				<axsl:variable
					select="1+   count(preceding-sibling::*[local-name()=local-name(current())])"
					name="p_2"/>
				<axsl:if
					test="$p_2&gt;1 or following-sibling::*[local-name()=local-name(current())]"
						>[<axsl:value-of select="$p_2"/>]</axsl:if>
			</axsl:otherwise>
		</axsl:choose>
	</axsl:template>
	<axsl:template mode="schematron-get-full-path" match="@*">
		<axsl:text>/</axsl:text>
		<axsl:choose>
			<axsl:when test="namespace-uri()=''">@<axsl:value-of select="name()"/>
			</axsl:when>
			<axsl:otherwise>
				<axsl:text>@*[local-name()='</axsl:text>
				<axsl:value-of select="local-name()"/>
				<axsl:text>' and namespace-uri()='</axsl:text>
				<axsl:value-of select="namespace-uri()"/>
				<axsl:text>']</axsl:text>
			</axsl:otherwise>
		</axsl:choose>
	</axsl:template>

	<!--MODE: SCHEMATRON-FULL-PATH-2-->
	<!--This mode can be used to generate prefixed XPath for humans-->
	<axsl:template mode="schematron-get-full-path-2" match="node() | @*">
		<axsl:for-each select="ancestor-or-self::*">
			<axsl:text>/</axsl:text>
			<axsl:value-of select="name(.)"/>
			<axsl:if test="preceding-sibling::*[name(.)=name(current())]">
				<axsl:text>[</axsl:text>
				<axsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
				<axsl:text>]</axsl:text>
			</axsl:if>
		</axsl:for-each>
		<axsl:if test="not(self::*)">
			<axsl:text/>/@<axsl:value-of select="name(.)"/>
		</axsl:if>
	</axsl:template>

	<!--MODE: GENERATE-ID-FROM-PATH -->
	<axsl:template mode="generate-id-from-path" match="/"/>
	<axsl:template mode="generate-id-from-path" match="text()">
		<axsl:apply-templates mode="generate-id-from-path" select="parent::*"/>
		<axsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/>
	</axsl:template>
	<axsl:template mode="generate-id-from-path" match="comment()">
		<axsl:apply-templates mode="generate-id-from-path" select="parent::*"/>
		<axsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/>
	</axsl:template>
	<axsl:template mode="generate-id-from-path" match="processing-instruction()">
		<axsl:apply-templates mode="generate-id-from-path" select="parent::*"/>
		<axsl:value-of
			select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"
		/>
	</axsl:template>
	<axsl:template mode="generate-id-from-path" match="@*">
		<axsl:apply-templates mode="generate-id-from-path" select="parent::*"/>
		<axsl:value-of select="concat('.@', name())"/>
	</axsl:template>
	<axsl:template priority="-0.5" mode="generate-id-from-path" match="*">
		<axsl:apply-templates mode="generate-id-from-path" select="parent::*"/>
		<axsl:text>.</axsl:text>
		<axsl:value-of
			select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"
		/>
	</axsl:template>
	<!--MODE: SCHEMATRON-FULL-PATH-3-->
	<!--This mode can be used to generate prefixed XPath for humans 
	(Top-level element has index)-->
	<axsl:template mode="schematron-get-full-path-3" match="node() | @*">
		<axsl:for-each select="ancestor-or-self::*">
			<axsl:text>/</axsl:text>
			<axsl:value-of select="name(.)"/>
			<axsl:if test="parent::*">
				<axsl:text>[</axsl:text>
				<axsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
				<axsl:text>]</axsl:text>
			</axsl:if>
		</axsl:for-each>
		<axsl:if test="not(self::*)">
			<axsl:text/>/@<axsl:value-of select="name(.)"/>
		</axsl:if>
	</axsl:template>

	<!--MODE: GENERATE-ID-2 -->
	<axsl:template mode="generate-id-2" match="/">U</axsl:template>
	<axsl:template priority="2" mode="generate-id-2" match="*">
		<axsl:text>U</axsl:text>
		<axsl:number count="*" level="multiple"/>
	</axsl:template>
	<axsl:template mode="generate-id-2" match="node()">
		<axsl:text>U.</axsl:text>
		<axsl:number count="*" level="multiple"/>
		<axsl:text>n</axsl:text>
		<axsl:number count="node()"/>
	</axsl:template>
	<axsl:template mode="generate-id-2" match="@*">
		<axsl:text>U.</axsl:text>
		<axsl:number count="*" level="multiple"/>
		<axsl:text>_</axsl:text>
		<axsl:value-of select="string-length(local-name(.))"/>
		<axsl:text>_</axsl:text>
		<axsl:value-of select="translate(name(),':','.')"/>
	</axsl:template>
	<!--Strip characters-->
	<axsl:template priority="-1" match="text()"/>

	<!--SCHEMA METADATA-->
	<axsl:template match="/">
		<svrl:schematron-output xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
			xmlns:schold="http://www.ascc.net/xml/schematron"
			xmlns:xs="http://www.w3.org/2001/XMLSchema" schemaVersion=""
			title="A Schematron Schema for assertion of SOAP header fields.">
			<axsl:comment>
				<axsl:value-of select="$archiveDirParameter"/>   <axsl:value-of
					select="$archiveNameParameter"/>   <axsl:value-of select="$fileNameParameter"/>
				  <axsl:value-of select="$fileDirParameter"/>
			</axsl:comment>
			<svrl:ns-prefix-in-attribute-values prefix="soap"
				uri="http://schemas.xmlsoap.org/soap/envelope/"/>
			<svrl:ns-prefix-in-attribute-values prefix="wsa"
				uri="http://www.w3.org/2005/08/addressing"/>
			<svrl:ns-prefix-in-attribute-values prefix="wsse"
				uri="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"/>
			<svrl:active-pattern>
				<axsl:apply-templates/>
			</svrl:active-pattern>
			<axsl:apply-templates mode="M4" select="/"/>
		</svrl:schematron-output>
	</axsl:template>

	<!--SCHEMATRON PATTERNS-->
	<!--<svrl:text xmlns:svrl="http://purl.oclc.org/dsdl/svrl" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:xs="http://www.w3.org/2001/XMLSchema">A Schematron Schema for assertion of SOAP header fields.</svrl:text>-->

	<!--PATTERN -->


	<!--RULE -->
	<axsl:template mode="M4" priority="1000" match="soap:Header">
		<svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
			xmlns:schold="http://www.ascc.net/xml/schematron"
			xmlns:xs="http://www.w3.org/2001/XMLSchema" context="soap:Header"/>

		<!--ASSERT -->
		<axsl:choose>
			<axsl:when test="normalize-space(wsse:security/wsse:UsernameToken/wsse:Username) != ''"/>
			<axsl:otherwise>
				<svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl"
					xmlns:schold="http://www.ascc.net/xml/schematron"
					xmlns:xs="http://www.w3.org/2001/XMLSchema"
					test="normalize-space(wsse:security/wsse:UsernameToken/wsse:Username) != ''">
					<axsl:attribute name="location">
						<axsl:apply-templates mode="schematron-get-full-path" select="."/>
					</axsl:attribute>
					<svrl:text>The request 'soap:Header' must have a valid
						'wsse:security/wsse:UsernameToken/wsse:Username' descendant
						element.</svrl:text>
				</svrl:failed-assert>
			</axsl:otherwise>
		</axsl:choose>
		<axsl:apply-templates mode="M4" select="*|comment()|processing-instruction()"/>
	</axsl:template>
	<axsl:template mode="M4" priority="-1" match="text()"/>
	<axsl:template mode="M4" priority="-2" match="@*|node()">
		<axsl:apply-templates mode="M4" select="*|comment()|processing-instruction()"/>
	</axsl:template>
</axsl:stylesheet>
