<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xpath-default-namespace="http://hl7.org/fhir" xmlns="http://hl7.org/fhir"
    xmlns:mp="http://ws.gematik.de/fa/amtss/AMTS_Document/v1.1"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:uuid="java.util.UUID"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs xd" version="2.0">
    <xsl:output indent="yes" method="xml"/>

    <xsl:variable name="PATIENT">
        <xsl:apply-templates mode="Patient" select="/mp:MP/mp:P[1]"/>
    </xsl:variable>

    <xsl:variable name="AUTHOR">
        <xsl:apply-templates mode="Author" select="/mp:MP/mp:A"/>
    </xsl:variable>

    <xsl:variable name="CUSTODIAN">
        <xsl:call-template name="Custodian"/>
    </xsl:variable>

    <xsl:variable name="OBSERVATIONS">
        <xsl:apply-templates mode="Observation" select="/mp:MP/mp:O"/>
    </xsl:variable>

    <xsl:variable name="MEDICATIONS">
        <xsl:apply-templates mode="Medications-Block" select="/mp:MP/mp:S"/>
    </xsl:variable>

    <xsl:template match="/">
        <xsl:apply-templates mode="Bundle" select="/mp:MP"/>
    </xsl:template>

    <xsl:template name="Bundle" mode="Bundle" match="mp:MP[not(ancestor::mp:MP)]">
        <xsl:param name="this" select="."/>
        <Bundle>
            <meta>
                <versionId value="{$this/@v}"/>
                <profile value="http://fhir.de/StructureDefinition/medikationsplanplus/bundle"/>
            </meta>
            <identifier>
                <system value="urn:ietf:rfc:3986"/>
                <value value="{concat('urn:uuid:',$this/@U)}"/>
            </identifier>
            <type value="document"/>
            <xsl:call-template name="Composition"/>
            <xsl:copy-of select="$PATIENT/entry[resource]"/>
            <xsl:copy-of select="$AUTHOR/entry[resource]"/>
            <xsl:copy-of select="$CUSTODIAN/entry[resource]"/>
            <xsl:copy-of select="$OBSERVATIONS/entry[resource]"/>
            <xsl:copy-of select="$MEDICATIONS/entry[resource]"/>
        </Bundle>
    </xsl:template>

    <xsl:template name="Composition" mode="Composition" match="mp:MP">
        <xsl:param name="this" select="."/>
        <xsl:variable name="COMP-ID" select="uuid:randomUUID()"/>
        <entry>
            <fullUrl value="{concat('http://mein.medikationsplan.de/composition/',$COMP-ID)}"/>
            <resource>
                <Composition>
                    <meta>
                        <versionId value="{$this/@v}"/>
                        <profile
                            value="http://fhir.de/StructureDefinition/medikationsplanplus/composition"
                        />
                    </meta>
                    <language value="{$this/@l}"/>
                    <identifier>
                        <system value="http://fhir.de/composition-identifier"/>
                        <value value="{$COMP-ID}"/>
                    </identifier>
                    <status value="final"/>
                    <type>
                        <coding>
                            <system value="http://loinc.org"/>
                            <code value="77603-9"/>
                            <display value="Medication treatment plan.extended Document"/>
                        </coding>
                    </type>
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <date value="{$this/mp:A/@t}"/>
                    <author>
                        <reference value="{$AUTHOR/entry/fullUrl/@value}"/>
                    </author>
                    <title value="Patientenbezogener Medikationsplan"/>
                    <confidentiality value="N"/>
                    <custodian>
                        <reference value="{$CUSTODIAN/entry/fullUrl/@value}"/>
                    </custodian>
                    <xsl:call-template name="medikationsplanSection"/>
                    <xsl:call-template name="allergienSection"/>
                    <xsl:call-template name="gesundheitsBelange"/>
                    <xsl:call-template name="klinischeParameter"/>
                    <xsl:call-template name="hinweiseSection"/>
                </Composition>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="medikationsplanSection">
        <xsl:param name="this" select="."/>
        <section>
            <title value="Aktuelle Medikation"/>
            <code>
                <coding>
                    <system value="http://loinc.org"/>
                    <code value="19009-0"/>
                </coding>
            </code>
            <xsl:for-each select="$MEDICATIONS/entry[resource/List]">
                <entry>
                    <reference value="{./fullUrl/@value}"/>
                </entry>
            </xsl:for-each>
        </section>
    </xsl:template>

    <xsl:template name="allergienSection">
        <xsl:param name="this" select="."/>
        <section>
            <title value="Allergien und Unverträglichkeiten"/>
            <code>
                <coding>
                    <system value="http://loinc.org"/>
                    <code value="48765-2"/>
                </coding>
            </code>
            <xsl:for-each select="$OBSERVATIONS/entry[resource/AllergyIntolerance]">
                <entry>
                    <reference value="{./fullUrl/@value}"/>
                </entry>
            </xsl:for-each>
        </section>
    </xsl:template>

    <xsl:template name="gesundheitsBelange">
        <xsl:param name="this" select="."/>
        <section>
            <title value="Gesundheitsbelange"/>
            <code>
                <coding>
                    <system value="http://loinc.org"/>
                    <code value="75310-3"/>
                </coding>
            </code>
            <xsl:for-each
                select="
                    $OBSERVATIONS/entry[resource/Observation/code/coding[system/@value = 'http://loinc.org']
                    [code[@value = '11449-6' or @value = '63895-7']]]">
                <entry>
                    <reference value="{./fullUrl/@value}"/>
                </entry>
            </xsl:for-each>
        </section>
    </xsl:template>

    <xsl:template name="klinischeParameter">
        <xsl:param name="this" select="."/>
        <section>
            <title value="Klinische Parameter"/>
            <code>
                <coding>
                    <system value="http://loinc.org"/>
                    <code value="75310-3"/>
                </coding>
            </code>
            <xsl:for-each
                select="
                    $OBSERVATIONS/entry[resource/Observation/code/coding[system/@value = 'http://loinc.org']
                    [code[@value = '29463-7' or @value = '8302-2' or @value = '2160-0']]]">
                <entry>
                    <reference value="{./fullUrl/@value}"/>
                </entry>
            </xsl:for-each>
        </section>
    </xsl:template>

    <xsl:template name="hinweiseSection">
        <xsl:param name="this" select="."/>
        <section>
            <title value="Wichtige Hinweise"/>
            <code>
                <coding>
                    <system value="http://loinc.org"/>
                    <code value="69730-0"/>
                </coding>
            </code>
            <text>
                <status value="additional"/>
                <xhtml:div>
                    <xsl:value-of select="/mp:MP/mp:O/@x"/>
                </xhtml:div>
            </text>
        </section>
    </xsl:template>

    <xsl:template name="Patient" mode="Patient" match="mp:P">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('Patient/',uuid:randomUUID())}"/>
            <resource>
                <Patient>
                    <identifier>
                        <system value="http://kvnummer.gkvnet.de"/>
                        <value value="{$this/@egk}"/>
                    </identifier>
                    <active value="true"/>
                    <name>
                        <text value="{concat($this/@g,' ',$this/@f)}"/>
                        <family value="{$this/@f}">
                            <extension
                                url="http://fhir.de/StructureDefinition/humanname-namenszusatz">
                                <valueString value="{$this/@z}"/>
                            </extension>
                            <extension
                                url="http://hl7.org/fhir/StructureDefinition/humanname-own-prefix">
                                <valueString value="{$this/@v}"/>
                            </extension>
                            <!-- extension
                                url="http://hl7.org/fhir/StructureDefinition/humanname-own-name">
                                <valueString value="{$this/@g}"/>
                            </extension -->
                        </family>
                        <given value="{$this/@g}"/>
                        <prefix value="{$this/@t}"/>
                    </name>
                    <xsl:choose>
                        <xsl:when test="$this/@s = 'M'">
                            <gender value="male"/>
                        </xsl:when>
                        <xsl:when test="$this/@s = 'W'">
                            <gender value="female"/>
                        </xsl:when>
                        <xsl:when test="$this/@s = 'X'">
                            <gender value="other"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <gender value="unknown"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <birthDate value="{$this/@b}"/>
                </Patient>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="Author" mode="Author" match="mp:A">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('Author/',uuid:randomUUID())}"/>
            <resource>
                <Practitioner>
                    <meta>
                        <versionId value="201"/>
                        <profile value="http://fhir.hl7.de/medikationsplan/practitioner"/>
                    </meta>
                    <identifier>
                        <system value="http://kbv.de/LANR"/>
                        <value value="{$this/@lanr}"/>
                    </identifier>
                    <identifier>
                        <system value="http://kbv.de/IDF"/>
                        <value value="{$this/@idf}"/>
                    </identifier>
                    <identifier>
                        <system value="http://kbv.de/KIK"/>
                        <value value="{$this/@kik}"/>
                    </identifier>
                    <name>
                        <text value="{$this/@n}"/>
                    </name>
                    <telecom>
                        <system value="phone"/>
                        <value value="{concat('tel:',$this/@p)}"/>
                        <use value="work"/>
                    </telecom>
                    <telecom>
                        <system value="email"/>
                        <value value="{concat('mailto:',$this/@e)}"/>
                        <use value="work"/>
                    </telecom>
                    <address>
                        <use value="work"/>
                        <line value="{$this/@s}"/>
                        <line value="{concat($this/@z,' ',$this/@c)}"/>
                    </address>
                </Practitioner>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="Custodian" mode="Custodian" match="mp:C">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('Custodian/',uuid:randomUUID())}"/>
            <resource>
                <Organization>
                    <identifier>
                        <system value="urn:oid:2.99"/>
                        <value value="999999"/>
                    </identifier>
                </Organization>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="Observation" mode="Observation" match="mp:O">
        <xsl:param name="this" select="."/>
        <xsl:apply-templates mode="AllergyIntolerance" select="$this/@ai"/>
        <xsl:apply-templates mode="observation-pregnancystatus" select="$this/@p"/>
        <xsl:apply-templates mode="observation-breastfeeding" select="$this/@b"/>
        <xsl:apply-templates mode="observation-bodyweight" select="$this/@w"/>
        <xsl:apply-templates mode="observation-bodyheight" select="$this/@h"/>
        <xsl:apply-templates mode="observation-creatinine" select="$this/@c"/>
    </xsl:template>

    <xsl:template name="observation-bodyweight" mode="observation-bodyweight" match="mp:O/@w">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('BodyWeight/',uuid:randomUUID())}"/>
            <resource>
                <Observation>
                    <status value="final"/>
                    <code>
                        <coding>
                            <system value="http://loinc.org"/>
                            <code value="29463-7"/>
                        </coding>
                    </code>
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <valueQuantity>
                        <value value="{$this}"/>
                        <unit value="kg"/>
                        <system value="http://unitsofmeasure.org"/>
                        <code value="kg"/>
                    </valueQuantity>
                </Observation>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="observation-bodyheight" mode="observation-bodyheight" match="mp:O/@h">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('BodyHeight/',uuid:randomUUID())}"/>
            <resource>
                <Observation>
                    <status value="final"/>
                    <code>
                        <coding>
                            <system value="http://loinc.org"/>
                            <code value="8302-2"/>
                        </coding>
                    </code>
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <valueQuantity>
                        <value value="{$this}"/>
                        <unit value="cm"/>
                        <system value="http://unitsofmeasure.org"/>
                        <code value="cm"/>
                    </valueQuantity>
                </Observation>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="observation-creatinine" mode="observation-creatinine" match="mp:O/@c">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('creatinine/',uuid:randomUUID())}"/>
            <resource>
                <Observation>
                    <status value="final"/>
                    <code>
                        <coding>
                            <system value="http://loinc.org"/>
                            <code value="2160-0"/>
                        </coding>
                    </code>
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <valueQuantity>
                        <value value="{$this}"/>
                        <unit value="mg/dl"/>
                        <system value="http://unitsofmeasure.org"/>
                        <code value="mg/dl"/>
                    </valueQuantity>
                </Observation>
            </resource>
        </entry>
    </xsl:template>


    <xsl:template name="observation-pregnancystatus" mode="observation-pregnancystatus"
        match="mp:O/@p">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('pregnancystatus/',uuid:randomUUID())}"/>
            <resource>
                <Observation>
                    <status value="final"/>
                    <code>
                        <coding>
                            <system value="http://loinc.org"/>
                            <code value="11449-6"/>
                        </coding>
                    </code>
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <valueCodeableConcept>
                        <coding>
                            <system
                                value="http://fhir.de/ValueSet/medikationsplanplus/pregnancystatus"/>
                            <code value="{$this}"/>
                        </coding>
                    </valueCodeableConcept>
                    <!-- component>
                        <code>
                            <coding>
                                <system value="http://loinc.org"/>
                                <code value="11778-8"/>
                            </coding>
                        </code>
                        <valueDateTime value="1999-01-01"/> 
                    </component -->
                </Observation>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="observation-breastfeeding" mode="observation-breastfeeding" match="mp:O/@b">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('breastfeeding/',uuid:randomUUID())}"/>
            <resource>
                <Observation>
                    <status value="final"/>
                    <code>
                        <coding>
                            <system value="http://loinc.org"/>
                            <code value="63895-7"/>
                        </coding>
                    </code>
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <valueBoolean value="{$this}"/>
                </Observation>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="AllergyIntolerance" mode="AllergyIntolerance" match="mp:O/@ai">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('AllergyIntolerance/',uuid:randomUUID())}"/>
            <resource>
                <AllergyIntolerance>
                    <text>
                        <status value="additional"/>
                        <xhtml:div>
                            <xsl:value-of select="$this"/>
                        </xhtml:div>
                    </text>
                    <clinicalStatus value="active"/>
                    <verificationStatus value="confirmed"/>
                    <patient>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </patient>
                </AllergyIntolerance>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="Medications-Block" mode="Medications-Block" match="mp:S">
        <xsl:param name="this" select="."/>

        <xsl:variable name="ZEILEN">
            <xsl:apply-templates mode="MedicationStatement" select="mp:*"/>
        </xsl:variable>

        <entry>
            <fullUrl value="{concat('medicationstatementlist/',uuid:randomUUID())}"/>
            <resource>
                <List>
                    <meta>
                        <profile
                            value="http://fhir.de/StructureDefinition/medikationsplanplus/medicationstatementlist"
                        />
                    </meta>
                    <status value="current"/>
                    <mode value="snapshot"/>
                    <xsl:choose>
                        <xsl:when test="$this/@c">
                            <code>
                                <coding>
                                    <system
                                        value="http://fhir.de/CodeSystem/kbv/s-bmp-zwischenueberschrift"/>
                                    <code value="{$this/@c}"/>
                                    <display value="{concat('text #',$this/@c)}"/>
                                </coding>
                            </code>
                        </xsl:when>
                        <xsl:when test="$this/@t">
                            <code>
                                <text value="{$this/@t}"/>
                            </code>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                    <xsl:for-each select="$ZEILEN/entry[resource/MedicationStatement]">
                        <entry>
                            <item>
                                <reference value="{./fullUrl/@value}"/>
                            </item>
                        </entry>
                    </xsl:for-each>
                </List>
            </resource>
        </entry>
        <xsl:copy-of select="$ZEILEN"/>
    </xsl:template>

    <xsl:template name="MedicationStatement" mode="MedicationStatement" match="mp:S/mp:M">
        <xsl:param name="this" select="."/>

        <xsl:variable name="Medication">
            <xsl:apply-templates mode="Medication" select="$this"/>
        </xsl:variable>

        <entry>
            <fullUrl value="{concat('MedicationStatement/',uuid:randomUUID())}"/>
            <resource>
                <MedicationStatement>
                    <status value="active"/>
                    <medicationReference>
                        <reference value="{$Medication/entry/fullUrl/@value}"/>
                    </medicationReference>
                    <!-- informationSource>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </informationSource -->
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <taken value="na"/>
                    <reasonCode>
                        <text value="{$this/@r}"/>
                    </reasonCode>
                    <xsl:if test="$this/@x">
                        <note>
                            <text value="{$this/@x}"/>
                        </note>
                    </xsl:if>
                    <xsl:if test="$this/@t">
                        <dosage>
                            <text value="{$this/@t}"/>
                            <xsl:if test="$this/@i">
                                <patientInstruction value="{$this/@i}"/>
                            </xsl:if>
                            <doseQuantity>
                                <!-- value value="1"/ -->
                                <unit value="{$this/@du}"/>
                                <system value="http://unitsofmeasure.org"/>
                                <code value="{$this/@dud}"/>
                            </doseQuantity>
                        </dosage>
                    </xsl:if>
                    <xsl:if test="$this/@m"> <!-- morgens -->
                        <dosage>
                            <xsl:if test="$this/@i">
                                <patientInstruction value="{$this/@i}"/>
                            </xsl:if>
                            <timing>
                                <code>
                                    <coding>
                                        <system value="http://hl7.org/fhir/v3/TimingEvent"/>
                                        <code value="CM"/>
                                        <display value="morgens"/>
                                    </coding>
                                </code>
                            </timing>
                            <doseQuantity>
                                <value value="{$this/@m}"/>
                                <unit value="{$this/@du}"/>
                                <system value="http://unitsofmeasure.org"/>
                                <code value="{$this/@dud}"/>
                            </doseQuantity>
                        </dosage>
                    </xsl:if>
                    <xsl:if test="$this/@d"> <!-- mittags -->
                        <dosage>
                            <xsl:if test="$this/@i">
                                <patientInstruction value="{$this/@i}"/>
                            </xsl:if>
                            <timing>
                                <code>
                                    <coding>
                                        <system value="http://hl7.org/fhir/v3/TimingEvent"/>
                                        <code value="CD"/>
                                        <display value="mittags"/>
                                    </coding>
                                </code>
                            </timing>
                            <doseQuantity>
                                <value value="{$this/@d}"/>
                                <unit value="{$this/@du}"/>
                                <system value="http://unitsofmeasure.org"/>
                                <code value="{$this/@dud}"/>
                            </doseQuantity>
                        </dosage>
                    </xsl:if>
                    <xsl:if test="$this/@v"> <!-- abends -->
                        <dosage>
                            <xsl:if test="$this/@i">
                                <patientInstruction value="{$this/@i}"/>
                            </xsl:if>
                            <timing>
                                <code>
                                    <coding>
                                        <system value="http://hl7.org/fhir/v3/TimingEvent"/>
                                        <code value="CV"/>
                                        <display value="abends"/>
                                    </coding>
                                </code>
                            </timing>
                            <doseQuantity>
                                <value value="{$this/@v}"/>
                                <unit value="{$this/@du}"/>
                                <system value="http://unitsofmeasure.org"/>
                                <code value="{$this/@dud}"/>
                            </doseQuantity>
                        </dosage>
                    </xsl:if>
                    <xsl:if test="$this/@h"> <!-- nachts -->
                        <dosage>
                            <xsl:if test="$this/@i">
                                <patientInstruction value="{$this/@i}"/>
                            </xsl:if>
                            <timing>
                                <code>
                                    <coding>
                                        <system value="http://hl7.org/fhir/v3/TimingEvent"/>
                                        <code value="HS"/>
                                        <display value="zur Nacht"/>
                                    </coding>
                                </code>
                            </timing>
                            <doseQuantity>
                                <value value="{$this/@h}"/>
                                <unit value="{$this/@du}"/>
                                <system value="http://unitsofmeasure.org"/>
                                <code value="{$this/@dud}"/>
                            </doseQuantity>
                        </dosage>
                    </xsl:if>
                </MedicationStatement>
            </resource>
        </entry>
        <xsl:copy-of select="$Medication"/>
    </xsl:template>

    <xsl:template name="MedicationStatement-R" mode="MedicationStatement" match="mp:S/mp:R">
        <xsl:param name="this" select="."/>

        <entry>
            <fullUrl value="{concat('MedicationStatement-R/',uuid:randomUUID())}"/>
            <resource>
                <MedicationStatement>
                    <status value="active"/>
                    <medicationCodeableConcept>
                        <text value="{$this/@t}"/>
                    </medicationCodeableConcept>
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <taken value="na"/>
                    <xsl:if test="$this/@x">
                        <note>
                            <text value="{$this/@x}"/>
                        </note>
                    </xsl:if>
                </MedicationStatement>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="MedicationStatement-X" mode="MedicationStatement" match="mp:S/mp:X">
        <xsl:param name="this" select="."/>

        <entry>
            <fullUrl value="{concat('MedicationStatement-X/',uuid:randomUUID())}"/>
            <resource>
                <MedicationStatement>
                    <status value="active"/>
                    <medicationCodeableConcept>
                        <text value="{$this/@t}"/>
                    </medicationCodeableConcept>
                    <subject>
                        <reference value="{$PATIENT/entry/fullUrl/@value}"/>
                    </subject>
                    <taken value="na"/>
                    <xsl:if test="$this/@x">
                        <note>
                            <text value="{$this/@x}"/>
                        </note>
                    </xsl:if>
                </MedicationStatement>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="Medication" mode="Medication" match="mp:S/mp:M">
        <xsl:param name="this" select="."/>
        <entry>
            <fullUrl value="{concat('Medication:',uuid:randomUUID())}"/>
            <resource>
                <Medication>
                    <code>
                        <coding>
                            <system value="http://www.ifaffm.de/pzn"/>
                            <code value="{$this/@p}"/>
                            <display value="{$this/@a}"/>
                        </coding>
                    </code>
                    <form>
                        <coding>
                            <system value="http://hl7.org/fhir/v3/orderableDrugForm"/>
                            <code value="{$this/@f}"/>
                            <display value="{$this/@fd}"/>
                        </coding>
                    </form>
                    <xsl:apply-templates mode="Ingredient" select="$this/mp:W"/>
                </Medication>
            </resource>
        </entry>
    </xsl:template>

    <xsl:template name="Ingredient" mode="Ingredient" match="mp:W">
        <xsl:param name="this" select="."/>

        <xsl:variable name="strength-text" select="normalize-space($this/@s)"/>
        <xsl:variable name="strength-value">
            <xsl:choose>
                <xsl:when test="substring-before($strength-text, ' ')">
                    <xsl:value-of select="substring-before($strength-text, ' ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="strength-unit">
            <xsl:choose>
                <xsl:when test="substring-after($strength-text, ' ')">
                    <xsl:value-of select="substring-after($strength-text, ' ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="1"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <ingredient>
            <itemCodeableConcept>
                <text value="{$this/@w}"/>
            </itemCodeableConcept>
            <amount>
                <numerator>
                    <value value="{$strength-value}"/>
                    <system value="http://unitsofmeasure.org"/>
                    <code value="{$strength-unit}"/>
                </numerator>
                <denominator>
                    <value value="1"/>
                    <system value="http://unitsofmeasure.org"/>
                    <code value="1"/>
                </denominator>
            </amount>
            <xsl:comment>strength: <xsl:value-of select="$this/@s"/>}"</xsl:comment>
        </ingredient>
    </xsl:template>

</xsl:stylesheet>
