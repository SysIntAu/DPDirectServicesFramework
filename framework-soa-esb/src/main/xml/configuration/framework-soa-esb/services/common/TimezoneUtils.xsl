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
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:regexp="http://exslt.org/regular-expressions"
	xmlns:dp="http://www.datapower.com/extensions" 
	extension-element-prefixes="dp date regexp" version="1.0" 
	exclude-result-prefixes="dp date regexp">
	<xs:annotation xmlns:xs="http://www.w3.org/2001/XMLSchema">
		<xs:appinfo xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:creator>Tim Goodwill</dc:creator>
			<dc:date>2016-12-12</dc:date>
			<dc:title>General utilities</dc:title>
			<dc:subject>A collection of timezone utility templates</dc:subject>
			<dc:contributor>Tim Goodwill</dc:contributor>
			<dc:publisher>DPDIRECT</dc:publisher>
		</xs:appinfo>
	</xs:annotation>
	<!--========================================================================
		History:
		2016-12-12	v1.0	N.A.		Initial Version.
		2016-12-12	v1.1	Tim Goodwill	Update RejectToErrorFlow template.
		========================================================================-->
	<!--============== Included Stylesheets =========================-->
	<!--============== Output Configuration =========================-->
	<xsl:output encoding="UTF-8" method="xml" indent="no" version="1.0"/>
	<!--============== Global Variable Declarations =================-->
	<!--=============================================================-->
	<!-- NAMED TEMPLATES                                             -->
	<!--=============================================================-->
	<!-- Get current timezone standard notation and boundaries-->
	<xsl:template name="GetCurrentTimezoneStatus">
		<!-- EST-10EDT,M10.1.0/2:00,M4.1.0/3:00 -->
		<xsl:copy-of select="dp:variable('var://service/system/status/DateTimeStatus')"/>
	</xsl:template>
	<!-- Gets current timezone offset 
		E.g. '2016-12-12T10:10:10.100+10:00' -->
	<xsl:template name="GetCurrentTimezoneOffset">
		<xsl:variable name="DATE_TIME" select="date:date-time()"/>
		<xsl:value-of select="substring($DATE_TIME,20)"/>
	</xsl:template>
	<!-- Gets timezone offset for any date-time in the current timezone
		E.g. '+10:00' -->
	<xsl:template name="GetTimezoneOffset">
		<!-- example '2016-12-12' -->
		<xsl:param name="DATE"/>
		<!-- example 'T10:50:50.158' -->
		<xsl:param name="TIME"/>
		<!-- example '2016-12-12T10:10:10.100' or '2016-12-12T10:10:10.100+10:00' -->
		<xsl:param name="DATE_TIME" select="date:date-time()"/>
		<xsl:variable name="A_TIME">
			<xsl:choose>
				<xsl:when test="$TIME">
					<xsl:value-of select="$TIME"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-after($DATE_TIME, 'T')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="A_DATE">
			<xsl:choose>
				<xsl:when test="$DATE">
					<xsl:value-of select="$DATE"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-before($DATE_TIME, 'T')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="HOUR_MINUTES" select="concat(substring-before($A_TIME, ':'), ':', substring-before(substring-after($A_TIME, ':'), ':'))"/>
		<!-- derive day, month, year -->
		<xsl:variable name="YEAR" select="substring-before($A_DATE,'-')"/>
		<xsl:variable name="MONTH" select="substring-before(substring-after($A_DATE,'-'),'-')"/>
		<xsl:variable name="DAY" select="substring-after(substring-after($A_DATE,'-'),'-')"/>
		<!-- calculate day of the week - move start of the year to March 1 to set up regular pattern-->
		<xsl:variable name="A" select="floor((14 - $MONTH) div 12)"/>
		<xsl:variable name="Y" select="$YEAR - $A"/>
		<xsl:variable name="M" select="$MONTH + 12 * $A - 2"/>
		<xsl:variable name="DAY_OF_THE_WEEK" select="($DAY + $Y + floor($Y div 4) - floor($Y div 100) + floor($Y div 400) + floor((31 * $M) div 12)) mod 7"/>
		<!-- calculate week of the month -->
		<xsl:variable name="WEEK_OF_THE_MONTH" select="ceiling((($DAY - ($DAY_OF_THE_WEEK + 1)) + 7) div 7)"/>
		<!-- calculate timezone offset info 
			EST-10EDT,M10.1.0/2:00,M4.1.0/3:00 -->
		<xsl:variable name="DATE_TIME_STATUS">
			<xsl:call-template name="GetCurrentTimezoneStatus"/>
		</xsl:variable>
		<!-- EST-10EDT,M10.1.0/2:00,M4.1.0/3:00 -->
		<xsl:variable name="STATUS_BEGIN" select="substring-before(substring-after($DATE_TIME_STATUS/tzspec , ',M'), ',M')"/>
		<xsl:variable name="STATUS_END" select="substring-after(substring-after($DATE_TIME_STATUS/tzspec , ',M'), ',M')"/>
		<xsl:variable name="MONTH_BEGIN" select="substring-before($STATUS_BEGIN, '.')"/>
		<xsl:variable name="MONTH_END" select="substring-before($STATUS_END, '.')"/>
		<xsl:variable name="WEEK_BEGIN" select="substring-before(substring-after($STATUS_BEGIN, '.'), '.')"/>
		<xsl:variable name="WEEK_END" select="substring-before(substring-after($STATUS_END, '.'), '.')"/>
		<xsl:variable name="DAYWEEK_BEGIN" select="substring(substring-before($STATUS_BEGIN, '/'), string-length(substring-before($STATUS_BEGIN, '/'))-1, 1)"/>
		<xsl:variable name="DAYWEEK_END" select="substring(substring-before($STATUS_END, '/'), string-length(substring-before($STATUS_END, '/'))-1, 1)"/>
		<xsl:variable name="TIME_BEGIN" select="substring-after($STATUS_BEGIN, '/')"/>
		<xsl:variable name="TIME_END" select="substring-after($STATUS_END, '/')"/>
		<!-- derive the offset -->
		<xsl:variable name="TIMEZONE" select="substring-before($DATE_TIME_STATUS, ',')"/>
		<xsl:variable name="UTC_OFFSET" select="regexp:replace($TIMEZONE, '[a-zA-Z]', 'g', '')"/>
		<xsl:variable name="UTC_OFFSET_HOUR_PART">
			<xsl:choose>
				<xsl:when test="contains($UTC_OFFSET, ':')">
					<xsl:value-of select="-1 * number(substring-before($UTC_OFFSET, ':'))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="-1 * number($UTC_OFFSET)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="UTC_OFFSET_MIN_PART">
			<xsl:choose>
				<xsl:when test="contains($UTC_OFFSET, ':')">
					<xsl:value-of select="substring-after($UTC_OFFSET, ':')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'00'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<!-- test tz span (hemisphere) -->
			<xsl:when test="$MONTH_END &gt; $MONTH_BEGIN">
				<xsl:choose>
					<xsl:when test="(($MONTH &gt; $MONTH_BEGIN)
						and ($MONTH &lt; $MONTH_END))
						or 
						(($MONTH = $MONTH_BEGIN)
						and ($WEEK_OF_THE_MONTH &gt; $WEEK_BEGIN))
						or
						(($MONTH = $MONTH_BEGIN)
						and ($WEEK_OF_THE_MONTH = $WEEK_BEGIN)
						and ($DAY_OF_THE_WEEK &gt; $DAYWEEK_BEGIN))
						or
						(($MONTH = $MONTH_BEGIN)
						and ($WEEK_OF_THE_MONTH = $WEEK_BEGIN)
						and ($DAY_OF_THE_WEEK = $DAYWEEK_BEGIN)
						and ($HOUR_MINUTES &gt; $TIME_BEGIN))
						or
						(($MONTH = $MONTH_END)
						and ($WEEK_OF_THE_MONTH &lt; $WEEK_END))
						or
						(($MONTH = $MONTH_END)
						and ($WEEK_OF_THE_MONTH = $WEEK_END)
						and ($DAY_OF_THE_WEEK &lt; $DAYWEEK_END))
						or
						(($MONTH = $MONTH_END)
						and ($WEEK_OF_THE_MONTH = $WEEK_END)
						and ($DAY_OF_THE_WEEK = $DAYWEEK_END)
						and ($HOUR_MINUTES &lt; $TIME_END))">
						<xsl:choose>
							<xsl:when test="(number($UTC_OFFSET_HOUR_PART) + 1) &gt;= 0">
								<xsl:value-of select="'+'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'-'"/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:value-of select="string(number($UTC_OFFSET_HOUR_PART) + 1)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="number($UTC_OFFSET_HOUR_PART) &gt;= 0">
								<xsl:value-of select="'+'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'-'"/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:value-of select="string($UTC_OFFSET_HOUR_PART)"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="':'"/>
				<xsl:value-of select="$UTC_OFFSET_MIN_PART"/>
			</xsl:when>
			<xsl:when test="$MONTH_END &lt;= $MONTH_BEGIN">
				<xsl:choose>
					<xsl:when test="(($MONTH &gt; $MONTH_BEGIN)
						or ($MONTH &lt; $MONTH_END))
						or 
						(($MONTH = $MONTH_BEGIN)
						and ($WEEK_OF_THE_MONTH &gt; $WEEK_BEGIN))
						or
						(($MONTH = $MONTH_BEGIN)
						and ($WEEK_OF_THE_MONTH = $WEEK_BEGIN)
						and ($DAY_OF_THE_WEEK &gt; $DAYWEEK_BEGIN))
						or
						(($MONTH = $MONTH_BEGIN)
						and ($WEEK_OF_THE_MONTH = $WEEK_BEGIN)
						and ($DAY_OF_THE_WEEK = $DAYWEEK_BEGIN)
						and ($HOUR_MINUTES &gt; $TIME_BEGIN))
						or
						(($MONTH = $MONTH_END)
						and ($WEEK_OF_THE_MONTH &lt; $WEEK_END))
						or
						(($MONTH = $MONTH_END)
						and ($WEEK_OF_THE_MONTH = $WEEK_END)
						and ($DAY_OF_THE_WEEK &lt; $DAYWEEK_END))
						or
						(($MONTH = $MONTH_END)
						and ($WEEK_OF_THE_MONTH = $WEEK_END)
						and ($DAY_OF_THE_WEEK = $DAYWEEK_END)
						and ($HOUR_MINUTES &lt; $TIME_END))">
						<xsl:choose>
							<xsl:when test="(number($UTC_OFFSET_HOUR_PART) + 1) &gt;= 0">
								<xsl:value-of select="'+'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'-'"/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:value-of select="string(number($UTC_OFFSET_HOUR_PART) + 1)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="number($UTC_OFFSET_HOUR_PART) &gt;= 0">
								<xsl:value-of select="'+'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'-'"/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:value-of select="string($UTC_OFFSET_HOUR_PART)"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="':'"/>
				<xsl:value-of select="$UTC_OFFSET_MIN_PART"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
