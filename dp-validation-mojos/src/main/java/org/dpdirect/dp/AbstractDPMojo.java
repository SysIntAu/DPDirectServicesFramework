/*_____________________________________________________________________                                      
*
* Copyright (c) 2016 DPDirect
* _____________________________________________________________________
*/

package org.dpdirect.dp;

import java.io.File;
import java.util.HashMap;
import java.util.List;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.project.MavenProject;
import org.codehaus.plexus.util.DirectoryScanner;

import org.dpdirect.batchvalidator.FileValidator;
import org.dpdirect.batchvalidator.ValidationErrorHandler;
import org.dpdirect.commons.FilePatternFilter;
import org.dpdirect.commons.XMLTools;

/**
 * TODO Provide description
 * 
 * @author N.A.
 * 
 */
public abstract class AbstractDPMojo extends AbstractMojo implements FileValidator
{

    /**
     * The Maven Project Object.
     * 
     * @parameter default-value="${project}"
     * @required
     * @readonly
     */
    protected MavenProject project;

    /**
     * The standard 'failonerror' flag.
     * 
     * @parameter expression="${failOnError}" default-value="true"
     * @required
     */
    protected boolean failOnError;

    /**
     * The target or source file to apply the schematron assertions to.
     * 
     * @parameter expression="${includes}"
     * @required
     */
    protected List<String> includes;

    /**
     * The target or source file to exclude from the schematron assertions to.
     * 
     * @parameter expression="${excludes}"
     * @required
     */
    protected List<String> excludes;

    /**
     * The base directory, relative to which directory names are interpreted.
     * 
     * @parameter expression="${buildDirectory}" default-value="${project.build.outputDirectory}"
     */
    protected File buildDirectory;

    /**
     * An XPath expression to select resource paths of imported or included resources within xsd, xslt or wsdl files.
     */
    public static final String GET_RESOURCE_PATHS_XPATH = "//(xsl:import/@href|xsl:include/@href|xs:import/@schemaLocation|xs:include/@schemaLocation)";

    /**
     * An map of xmlns/prefix bindings for xpath queries.
     */
    private HashMap<String, String> namespaceBindingMap = new HashMap<String, String>();

    /**
     * An error handler.
     */
    protected ValidationErrorHandler errorHandler = null;

    /**
     * @return String array of potential matches for schema files
     */
    protected String[] retrieveSchemaFiles()
    {
        DirectoryScanner scanner = new DirectoryScanner();
        String[] includesArray = includes.toArray(new String[includes.size()]);
        String[] excludesArray = excludes.toArray(new String[excludes.size()]);
        scanner.setIncludes(includesArray);
        scanner.setExcludes(excludesArray);
        scanner.setBasedir(buildDirectory);
        scanner.setCaseSensitive(false);
        scanner.scan();
        return scanner.getIncludedFiles();
    }

    protected void validateDependencies(final File file) throws Exception
    {
        List<String> results = XMLTools.evaluateXPathToStrings(GET_RESOURCE_PATHS_XPATH, file.getAbsolutePath(),
                                                               namespaceBindingMap);
        for (String result : results)
        {
            String dependencyPath = FilePatternFilter.normaliseDirPath(file.getParentFile().getAbsolutePath(), false)
                                    + result.trim();
            dependencyPath = FilePatternFilter.normaliseFilePath(dependencyPath, false);
            File dependentFile = new File(dependencyPath);
            if (!dependentFile.exists())
            {
                throw new MojoExecutionException("Failed to read imported file at path '" + dependencyPath
                                                 + "' referenced from file '" + file.getAbsolutePath() + "'");
            }
        }
    }

    protected void performNamespaceBinding()
    {
        this.namespaceBindingMap.put("xs", "http://www.w3.org/2001/XMLSchema");
        this.namespaceBindingMap.put("xsd", "http://www.w3.org/2001/XMLSchema");
        this.namespaceBindingMap.put("xsi", "http://www.w3.org/2001/XMLSchema-instance");
        this.namespaceBindingMap.put("xsl", "http://www.w3.org/1999/XSL/Transform");
        this.namespaceBindingMap.put("wsdl", "http://schemas.xmlsoap.org/wsdl");
    }

    @Override
    public void setValidationErrorHandler(ValidationErrorHandler errorHandler)
    {
        this.errorHandler = errorHandler;

    }

}
