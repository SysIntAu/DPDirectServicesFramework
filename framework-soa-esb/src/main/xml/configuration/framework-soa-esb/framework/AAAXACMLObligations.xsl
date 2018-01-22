<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp"
	version="1.0">
	<!--
	Checks XACML obligations and returns true. Currently meaningless.
	-->
	<xsl:template match="/">
		<xsl:value-of select="'true'"/>
	</xsl:template>
	
</xsl:stylesheet>