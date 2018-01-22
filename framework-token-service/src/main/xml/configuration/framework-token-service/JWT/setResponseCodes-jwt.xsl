<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx"
    xmlns:date="http://exslt.org/dates-and-times" xmlns:dp="http://www.datapower.com/extensions"
    extension-element-prefixes="dp" version="1.0">
    
    <xsl:variable name="CREATEDTOKEN" select="dp:variable('var://context/service/createdtoken')"/>
    
    <xsl:template match="/">
        <dp:set-variable name="'var://service/set-response-header/content-type'" value="'application/json'" />
        <dp:remove-http-response-header name="Host"/>
        <dp:remove-http-response-header name="Via"/>
        <dp:remove-http-response-header name="X-Client-IP"/>
        <dp:remove-http-response-header name="X-Archived-Client-IP"/>
    	<!-- CORS support -->
        <dp:set-http-response-header name="'Access-Control-Allow-Origin'" value="'*'"/>
        <xsl:value-of select="$CREATEDTOKEN"/>
    </xsl:template>
</xsl:stylesheet>