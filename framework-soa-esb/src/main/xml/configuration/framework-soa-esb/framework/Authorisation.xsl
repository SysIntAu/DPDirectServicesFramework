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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:os="urn:oasis:names:tc:xacml:2.0:policy:schema:os" 
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
	xmlns:dp="http://www.datapower.com/extensions"
	xmlns:regexp="http://exslt.org/regular-expressions"
	extension-element-prefixes="dp regexp" exclude-result-prefixes="dp regexp os saml"
	version="1.0">
	<!--========================================================================
		Purpose:Performs authorisation against a local XACML policy file
		
		History:
		2016-12-12	v1.0	N.A. , Tim Goodwill		Initial Version
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<xsl:include href="Utils.xsl"/>
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<xsl:variable name="XACML_POLICY_SET" select="document('local:///security/soa-services-xacml-auth.xml')//os:PolicySet"/>
	<!--=============================================================-->
	<!-- MATCH TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Root Template -->
	<xsl:template match="/">
		<xsl:variable name="RESOURCE_NSURI"
			select="normalize-space((/container/mapped-resource/resource/item[@type='request-uri'])[1])"/>
		<xsl:variable name="RESOURCE_LOCALNAME"
			select="normalize-space((/container/mapped-resource/resource/item[@type='request-opname'])[1])"/>
		<xsl:variable name="RESOURCE_ID" select="concat('{',$RESOURCE_NSURI,'}',$RESOURCE_LOCALNAME)"/>
		<xsl:choose>
			<xsl:when test="/container/mapped-credentials[@au-success = 'false']">
				<!-- Output an 'no-authorisation-required' element -->
				<!-- Note: This element is not recognised by DataPower which treates anything but 'approved' as an authorisation failure. -->
				<!-- The name 'no-authorisation-required' was considered more useful for debugging purposes than 'unapproved' -->
				<no-authorisation-required>
					<xsl:text>Authentication failure - invalid or missing credentials.</xsl:text>
				</no-authorisation-required>
			</xsl:when>
			<xsl:otherwise>
				<!--<xsl:variable name="GROUP_ATTRIBUTES" select="/container/mapped-credentials/entry[@type='saml-attributes']"/>-->
				<xsl:variable name="GROUP_ATTRIBUTES" select="/container/identity/entry[@type='saml-attr-name']"/>
				<!-- Query the XACML Policy Set -->
				<xsl:variable name="AUTHORISATION_RESULT_SET">
					<AuthorisationResultSet>
						<xsl:for-each select="$GROUP_ATTRIBUTES//saml:Attribute[@name='group']/saml:AttributeValue">
							<xsl:variable name="GROUP_NAME" select="normalize-space(current())"></xsl:variable>
							<!-- Debu authz vars -->
							<dp:set-variable name="concat('var://context/framework-soa-esb/debug/',position(),'/SUBJECT_ID')" value="$GROUP_NAME"/>
							<dp:set-variable name="concat('var://context/framework-soa-esb/debug/',position(),'/RESOURCE_ID')" value="$RESOURCE_ID"/>
							<xsl:element name="AuthorisationResult">
								<xsl:attribute name="groupName">
									<xsl:value-of select="$GROUP_NAME"/>
								</xsl:attribute>
								<xsl:attribute name="isDenied">
									<xsl:call-template name="deniedMatch">
										<xsl:with-param name="SUBJECT_ID" select="$GROUP_NAME"/>
										<xsl:with-param name="RESOURCE_ID" select="$RESOURCE_ID"/>
									</xsl:call-template>
								</xsl:attribute>
								<xsl:attribute name="isPermitted">
									<xsl:call-template name="permitMatch">
										<xsl:with-param name="SUBJECT_ID" select="$GROUP_NAME"/>
										<xsl:with-param name="RESOURCE_ID" select="$RESOURCE_ID"/>
									</xsl:call-template>
								</xsl:attribute>
							</xsl:element>
						</xsl:for-each>
					</AuthorisationResultSet>
				</xsl:variable>
				<dp:set-variable name="$AUTHZ_RESULT_SET_VAR_NAME" value="$AUTHORISATION_RESULT_SET"/>
				<xsl:choose>
					<!-- Membership of any 'denied' group takes precedence -->
					<xsl:when test="$AUTHORISATION_RESULT_SET//AuthorisationResult[@isDenied='true']">
						<!-- Reject to error flow for error handling/mapping -->
						<xsl:call-template name="RejectToErrorFlow">
							<!-- Do not log in prod -->
							<xsl:with-param name="MSG">
								<xsl:text>The presented group attribute [</xsl:text>
								<xsl:value-of select="normalize-space($AUTHORISATION_RESULT_SET//AuthorisationResult[@isDenied='true'][1]/@groupName)"/>
								<xsl:text>] is denied access to the resource [</xsl:text>
								<xsl:value-of select="$RESOURCE_ID"/>
								<xsl:text>]</xsl:text>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'ERROR0010'"/>
						</xsl:call-template>
						<!-- Output an 'unauthorised' element -->
						<!-- Note: This element is not recognised by DataPower which treates anything but 'approved' as an authorisation failure. -->
						<!-- The name 'unauthorised' was considered more useful for debugging purposes than 'unapproved' -->
						<unauthorised>
							<xsl:text>The presented group attribute [</xsl:text>
							<xsl:value-of select="normalize-space($AUTHORISATION_RESULT_SET//AuthorisationResult[@isDenied='true'][1]/@groupName)"/>
							<xsl:text>] is denied access to the resource [</xsl:text>
							<xsl:value-of select="$RESOURCE_ID"/>
							<xsl:text>]</xsl:text>
						</unauthorised>
					</xsl:when>
					<xsl:when test="$AUTHORISATION_RESULT_SET//AuthorisationResult[@isPermitted='true']">
						<!-- Output a single 'approved' element allowing authorised access -->
						<!-- This element is required by DataPower as the output element for successful authorisation -->
						<approved>
							<xsl:text>The presented group attribute [</xsl:text>
							<xsl:value-of select="normalize-space($AUTHORISATION_RESULT_SET//AuthorisationResult[@isPermitted='true'][1]/@groupName)"/>
							<xsl:text>] is permitted access to the resource [</xsl:text>
							<xsl:value-of select="$RESOURCE_ID"/>
							<xsl:text>]</xsl:text>
						</approved>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="GROUP_NAMES">
							<xsl:for-each select="$GROUP_ATTRIBUTES//saml:Attribute[@name='group']/saml:AttributeValue">
								<xsl:value-of select="normalize-space(current())"/>
								<xsl:if test="count(following-sibling::saml:AttributeValue) &gt; 0">
									<xsl:value-of select="','"/>
								</xsl:if>
							</xsl:for-each>
						</xsl:variable>
						<!-- Reject to error flow for error handling/mapping -->
						<xsl:call-template name="RejectToErrorFlow">
							<!-- Do not log in prod -->
							<xsl:with-param name="MSG">
								<xsl:text>The presented group attributes [</xsl:text>
								<xsl:value-of select="$GROUP_NAMES"/>
								<xsl:text>] NOT permitted access to the resource [</xsl:text>
								<xsl:value-of select="$RESOURCE_ID"/>
								<xsl:text>]</xsl:text>
							</xsl:with-param>
							<xsl:with-param name="ERROR_CODE" select="'ERROR0010'"/>
						</xsl:call-template>
						<!-- Output an 'unauthorised' element -->
						<!-- Note: This element is not recognised by DataPower which treates anything but 'approved' as an authorisation failure. -->
						<!-- The name 'unauthorised' was considered more useful for debugging purposes than 'unapproved' -->
						<unauthorised>
							<xsl:text>The presented group attributes [</xsl:text>
							<xsl:value-of select="$GROUP_NAMES"/>
							<xsl:text>] NOT permitted access to the resource [</xsl:text>
							<xsl:value-of select="$RESOURCE_ID"/>
							<xsl:text>]</xsl:text>
						</unauthorised>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="permitMatch">
		<xsl:param name="SUBJECT_ID"/>
		<xsl:param name="RESOURCE_ID"/>
		<!-- Query the XACML Policy Set -->
		<xsl:value-of select="string(0 &lt;
			count($XACML_POLICY_SET/os:Policy[os:Rule/@Effect='Permit'][os:Target
			[os:Subjects/os:Subject/
			os:SubjectMatch[@MatchId='urn:oasis:names:tc:xacml:1.0:function:string-equal']/os:AttributeValue = $SUBJECT_ID]
			[os:Resources/os:Resource[
			os:ResourceMatch[@MatchId='urn:oasis:names:tc:xacml:1.0:function:string-equal']/os:AttributeValue[text()=$RESOURCE_ID] or 
			os:ResourceMatch[@MatchId='urn:oasis:names:tc:xacml:1.0:function:string-regexp-match']/os:AttributeValue[regexp:match($RESOURCE_ID, text()) != '']
			]]]))"/>
	</xsl:template>
	<xsl:template name="deniedMatch">
		<xsl:param name="SUBJECT_ID"/>
		<xsl:param name="RESOURCE_ID"/>
		<!-- Query the XACML Policy Set -->
		<xsl:value-of select="string(0 &lt;
			count($XACML_POLICY_SET/os:Policy[os:Rule/@Effect='Deny'][os:Target
			[os:Subjects/os:Subject/
			os:SubjectMatch[@MatchId='urn:oasis:names:tc:xacml:1.0:function:string-equal']/os:AttributeValue = $SUBJECT_ID]
			[os:Resources/os:Resource[
			os:ResourceMatch[@MatchId='urn:oasis:names:tc:xacml:1.0:function:string-equal']/os:AttributeValue[text()=$RESOURCE_ID] or 
			os:ResourceMatch[@MatchId='urn:oasis:names:tc:xacml:1.0:function:string-regexp-match']/os:AttributeValue[regexp:match($RESOURCE_ID, text()) != '']
			]]]))"/>
	</xsl:template>
</xsl:stylesheet>
