<?xml version="1.0" encoding="utf-8"?>
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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions"
	extension-element-prefixes="dp" exclude-result-prefixes="dp" version="1.0">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>N.A.</dc:creator>
			<dc:date>2016-04-11</dc:date>
			<dc:title>An XSLT Wrapper for the WrapBinary.ffd file.</dc:title>
			<dc:subject>Uses the custom dp:input-mapping element to perform binary transformation of the input content
				via an FFD transform map. Its output is the binary format input file serialised as the single text node
				content of the xml wrapper elements "Input/WrappedText".</dc:subject>
			<dc:contributor>N.A.</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--========================================================================
		History:
		2016-04-11	v1.0	N.A.		Initial Version.
		========================================================================-->
	<dp:input-mapping href="WrapBinary.ffd" type="ffd"/>
	<xsl:output method="xml"/>
	<xsl:template match="/">
		<xsl:copy-of select="/"/>
		<!-- reset INPUT context to pass xml to error handler in case of error -->
		<dp:set-variable name="'var://context/INPUT/'" value="/"/>
	</xsl:template>
</xsl:stylesheet>
