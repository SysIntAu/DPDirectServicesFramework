<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:dpquery="http://www.datapower.com/param/query"    
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	extension-element-prefixes="dp"
	exclude-result-prefixes="dp"
	version="1.0">
	
	<xsl:template match="/">
		
		<xsl:variable name="url" select="dp:variable('var://service/URL-in')"/>
		
		<xsl:choose>
			<xsl:when test="contains ($url, '/projects/')">
				<xsl:variable name="id" select="substring-after($url,'ServiceRequest/rest/')"/>
				<soapenv:Envelope xmlns:soapenv=
					"http://schemas.xmlsoap.org/soap/envelope/" xmlns:demo=
					"http://datapower.ibm.com/demoService/">
					<soapenv:Header/>
					<soapenv:Body>
						<demo:getProjectRequest>
							<demo:id><xsl:value-of select="$id"/></demo:id>
						</demo:getProjectRequest>
					</soapenv:Body>
				</soapenv:Envelope>
			</xsl:when>
			<xsl:otherwise>
				<soapenv:Envelope xmlns:soapenv=
					"http://schemas.xmlsoap.org/soap/envelope/" xmlns:demo=
					"http://datapower.ibm.com/demoService/">
					<soapenv:Header/>
					<soapenv:Body>
						<demo:listProjectsRequest>true</demo:listProjectsRequest>
					</soapenv:Body>
				</soapenv:Envelope>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
</xsl:stylesheet>