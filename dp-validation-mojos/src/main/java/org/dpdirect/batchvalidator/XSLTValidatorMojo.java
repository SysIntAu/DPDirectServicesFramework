package org.dpdirect.batchvalidator;

import java.io.File;
import java.io.FileInputStream;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamSource;

import org.apache.maven.plugin.MojoExecutionException;

import org.dpdirect.commons.XMLTools;
import org.dpdirect.dp.AbstractDPMojo;

/**
 * A file validator for XSLT 1.0 and 2.0 schema files.
 * 
 * @author N.A.
 * 
 * @goal xslValidate
 * @phase compile
 * @requiresDependencyResolution
 */
public class XSLTValidatorMojo extends AbstractDPMojo
{

    /**
     * A flag to indicate the occurrence of errors.
     */
    private boolean hasErrors = false;

    /**
     * A flag to indicate whether to allow XSLT 2.0 files.
     */
    private boolean allowXslt2 = true;

    /**
     * An error handler.
     */
    private ValidationErrorHandler errorHandler = null;

    /**
     * Constructs a new <code>XSLTValidator</code> object.
     */
    public XSLTValidatorMojo()
    {
    }

    @Override
    public void execute() throws MojoExecutionException
    {
        performNamespaceBinding();
        try
        {
            String[] srcFiles = retrieveSchemaFiles();
            for (String srcFile : srcFiles)
            {
                File xslToValidate = new File(buildDirectory, srcFile);
                this.setValidationErrorHandler(new ValidationErrorHandler()
                {
                    @Override
                    public void handleValidationError(String msg)
                    {
                        getLog().error("Validation Error: " + msg);
                    }
                });
                validate(xslToValidate);
                validateDependencies(xslToValidate);
                System.out.println(xslToValidate + " successfully validated.");
            }
        }
        catch (Exception e)
        {
            throw new MojoExecutionException(e.getMessage(), e);
        }
    }

    /**
     * Determines whether XSLT 2.0 files will be allowed and validated using Saxon.
     * 
     * @param enabled true to the enable the feature; false otherwise.
     */
    public void setAllowXslt2(boolean enabled)
    {
        allowXslt2 = enabled;
    }

    /*
     * (non-Javadoc)
     * @see au.gov.diac.oxygen.plugins.batchvalidator.FileValidator# getFileTypeDescription()
     */
    @Override
    public String getFileTypeDescription()
    {
        return "XSLT Stylesheet";
    }

    /*
     * (non-Javadoc)
     * @see au.gov.diac.oxygen.plugins.batchvalidator.FileValidator# getFilenameFilterPattern()
     */
    @Override
    public String getFilenameFilterPattern()
    {
        return ".*\\.(xsl|xslt)";
    }

    /*
     * (non-Javadoc)
     * @see au.gov.diac.oxygen.plugins.batchvalidator.FileValidator#validate(java .io.File)
     */
    @Override
    public void validate(File file) throws Exception
    {
        // Initialise the error flag.
        hasErrors = false;

        // Determine if the stylesheet if version 1.0 or 2.0.
        String version = XMLTools.evaluateXPath("(/xsl:stylesheet/@version|/xsl:transform/@version)[1]",
                                                XMLTools.parseDocument(new FileInputStream(file)));
        boolean isVersion2 = false;
        try
        {
            isVersion2 = "2.0".equals(version.trim());
        }
        catch (Exception e)
        {
            // Ignore.
        }
        if (isVersion2 && (false == allowXslt2))
        {
            throw new Exception("XSLT Version 2.0 specified in file " + file.getAbsolutePath());
        }

        StreamSource xslSource = new StreamSource(new FileInputStream(file));
        xslSource.setSystemId(file.getAbsolutePath());
        TransformerFactory factory = (isVersion2) ? new net.sf.saxon.TransformerFactoryImpl()
            : TransformerFactory.newInstance();
        // Only load the custom xml error handler if there is a
        // ValidationErrorHandler object for it to make call-backs on.
        if (null != errorHandler)
        {
            factory.setErrorListener(new CustomErrorListener());
        }
        factory.newTemplates(xslSource);
        if (hasErrors)
        {
            throw new Exception("One or more validation errors occurred in file " + file.getName());
        }
    }

    /**
     * A custom error handler for the transformer factory.
     */
    class CustomErrorListener implements ErrorListener
    {

        public void warning(TransformerException ex) throws TransformerException
        {
            // if (null != errorHandler) {
            // errorHandler.handleValidationError("[warning=" + ex.toString()
            // + "]");
            // }
            // hasErrors = true;
        }

        public void error(TransformerException ex) throws TransformerException
        {
            if (null != errorHandler)
            {
                errorHandler.handleValidationError("[error=" + ex.toString() + "]");
            }
            hasErrors = true;
        }

        public void fatalError(TransformerException ex) throws TransformerException
        {
            if (null != errorHandler)
            {
                errorHandler.handleValidationError("[fatal-error=" + ex.toString() + "]");
            }
            hasErrors = true;
        }

    }
}
