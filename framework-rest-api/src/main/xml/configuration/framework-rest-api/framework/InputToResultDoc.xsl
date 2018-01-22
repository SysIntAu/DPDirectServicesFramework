<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions"
	xmlns:dpconfig="http://www.datapower.com/param/config" extension-element-prefixes="dp" exclude-result-prefixes="dp dpconfig">
	<!--========================================================================
		History:
		2016-10-03	v0.1			Initial Version.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output method="text"/>
	<!--============== Global Variable Declarations =================-->
	<!--========================================================================
		MATCH TEMPLATES
	========================================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="INPUT" select="dp:variable(concat($INPUT_CONTEXT_NAME, '_roottree'))"/>
		<xsl:copy-of select="$INPUT"/>
	</xsl:template>
</xsl:stylesheet>
